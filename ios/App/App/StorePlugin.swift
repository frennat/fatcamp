import Foundation
import Capacitor
import StoreKit

/// Subscriptions, via StoreKit 2.
///
/// In-repo for the same reason as the other plugins: an npm Capacitor plugin
/// puts its Swift source in `node_modules`, which a clean Xcode Cloud clone
/// does not have.
///
/// StoreKit 2 rather than the original API because it verifies transactions
/// itself — `Transaction.currentEntitlements` only yields signatures Apple has
/// already checked, so entitlement can be read on device without running a
/// receipt-validation server. That matters here: there is no backend to
/// validate against.
///
/// A note on trust. This grants access from the device's own view of its
/// entitlements. That is right for an app whose data lives on the device and
/// whose paid features are local. If server-side entitlement ever matters —
/// anything the leaderboard pays out, say — this needs App Store Server
/// Notifications behind it, not just this file.
@available(iOS 15.0, *)
@objc(StorePlugin)
public class StorePlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "StorePlugin"
    public let jsName = "Store"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "isAvailable",  returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "products",     returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "purchase",     returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "entitlements", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "restore",      returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "manage",       returnType: CAPPluginReturnPromise)
    ]

    /// Transactions can arrive when the app is not asking — a renewal, a
    /// purchase finished on another device, a parent approving Ask to Buy. If
    /// nothing is listening they queue forever and the user is charged without
    /// being granted anything.
    private var updates: Task<Void, Never>? = nil

    override public func load() {
        updates = Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard case .verified(let t) = result else { continue }
                await t.finish()
                await self?.announce()
            }
        }
    }

    deinit { updates?.cancel() }

    @MainActor private func announce() {
        notifyListeners("entitlementsChanged", data: [:])
    }

    @objc func isAvailable(_ call: CAPPluginCall) {
        call.resolve(["available": AppStore.canMakePayments])
    }

    @objc func products(_ call: CAPPluginCall) {
        let ids = call.getArray("ids", String.self) ?? []
        guard !ids.isEmpty else { call.reject("ids is required"); return }
        Task {
            do {
                let found = try await Product.products(for: ids)
                /* Price is formatted by StoreKit in the storefront's own
                   currency and locale. Never hard-code "$5" in the UI — the
                   same product is a different number in every country. */
                let rows = found.map { p -> [String: Any] in
                    var row: [String: Any] = [
                        "id": p.id,
                        "title": p.displayName,
                        "description": p.description,
                        "price": p.displayPrice
                    ]
                    if let sub = p.subscription {
                        row["period"] = Self.periodName(sub.subscriptionPeriod)
                        if let offer = sub.introductoryOffer {
                            row["introPrice"]  = offer.displayPrice
                            row["introPeriod"] = Self.periodName(offer.period)
                        }
                    }
                    return row
                }
                call.resolve(["products": rows])
            } catch {
                call.reject(error.localizedDescription)
            }
        }
    }

    @objc func purchase(_ call: CAPPluginCall) {
        guard let id = call.getString("id") else { call.reject("id is required"); return }
        Task {
            do {
                guard let product = try await Product.products(for: [id]).first else {
                    call.reject("That plan is not available right now."); return
                }
                let result = try await product.purchase()
                switch result {
                case .success(let verification):
                    switch verification {
                    case .verified(let t):
                        await t.finish()
                        call.resolve(["status": "purchased", "id": id])
                    case .unverified:
                        /* Apple could not vouch for it; treat as a failure
                           rather than granting on an unsigned claim. */
                        call.resolve(["status": "unverified"])
                    }
                case .userCancelled:
                    call.resolve(["status": "cancelled"])
                case .pending:
                    /* Ask to Buy, or a payment method needing action. The
                       transaction may land minutes or days later, which is what
                       the Transaction.updates listener above is for. */
                    call.resolve(["status": "pending"])
                @unknown default:
                    call.resolve(["status": "unknown"])
                }
            } catch {
                call.reject(error.localizedDescription)
            }
        }
    }

    @objc func entitlements(_ call: CAPPluginCall) {
        Task {
            var active: [[String: Any]] = []
            for await result in Transaction.currentEntitlements {
                guard case .verified(let t) = result else { continue }
                if let exp = t.expirationDate, exp < Date() { continue }
                if t.revocationDate != nil { continue }
                var row: [String: Any] = ["id": t.productID]
                if let exp = t.expirationDate {
                    row["expires"] = exp.timeIntervalSince1970 * 1000
                }
                active.append(row)
            }
            call.resolve(["active": active])
        }
    }

    /// Required by App Review: a paying user who reinstalls must be able to get
    /// their subscription back without paying again.
    @objc func restore(_ call: CAPPluginCall) {
        Task {
            do {
                try await AppStore.sync()
                call.resolve(["restored": true])
            } catch {
                call.reject(error.localizedDescription)
            }
        }
    }

    /// Opens Apple's own manage-subscription sheet. Also a review requirement:
    /// cancelling must never be hidden behind a support email.
    @objc func manage(_ call: CAPPluginCall) {
        Task { @MainActor in
            guard let scene = UIApplication.shared.connectedScenes
                    .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else {
                call.reject("No active window"); return
            }
            do {
                try await AppStore.showManageSubscriptions(in: scene)
                call.resolve()
            } catch {
                call.reject(error.localizedDescription)
            }
        }
    }

    private static func periodName(_ p: Product.SubscriptionPeriod) -> String {
        let n = p.value
        switch p.unit {
        case .day:   return n == 1 ? "day"   : "\(n) days"
        case .week:  return n == 1 ? "week"  : "\(n) weeks"
        case .month: return n == 1 ? "month" : "\(n) months"
        case .year:  return n == 1 ? "year"  : "\(n) years"
        @unknown default: return "period"
        }
    }
}
