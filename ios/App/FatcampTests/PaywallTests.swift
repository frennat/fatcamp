import XCTest
import StoreKit
import StoreKitTest

/// The paywall purchase flow, end to end, against the local StoreKit
/// environment defined by Products.storekit — the same StoreKit 2 calls
/// StorePlugin makes, minus the webview between. If these pass, the chain the
/// app relies on is sound: products load, a purchase completes and verifies,
/// the entitlement is current (what storeSync reads), and an upgrade within
/// the subscription group supersedes the lower tier.
final class PaywallTests: XCTestCase {

    private let proID = "com.frennat.fatcamp.pro.monthly"
    private let maxID = "com.frennat.fatcamp.max.monthly"

    private struct Timeout: Error, CustomStringConvertible {
        let what: String
        var description: String { what + " did not return in time — StoreKit call hung" }
    }

    /// StoreKit calls against a wedged daemon hang forever and eat the whole
    /// run; racing a clock turns that into a named failure in seconds.
    private func within<T: Sendable>(_ seconds: Double, _ label: String,
                                     _ op: @escaping @Sendable () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask { try await op() }
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw Timeout(what: label)
            }
            let first = try await group.next()!
            group.cancelAll()
            return first
        }
    }

    private func currentEntitlements() async throws -> Set<String> {
        try await within(20, "Transaction.currentEntitlements") {
            var active: Set<String> = []
            for await e in Transaction.currentEntitlements {
                if case .verified(let t) = e { active.insert(t.productID) }
            }
            return active
        }
    }

    func testPurchaseFlow() async throws {
        let session = try SKTestSession(configurationFileNamed: "Products")
        session.disableDialogs = true
        session.clearTransactions()

        // 1 — both subscriptions load from the configuration
        let products = try await within(25, "Product.products(for:)") { try await Product.products(for: [self.proID, self.maxID]) }
        XCTAssertEqual(Set(products.map(\.id)), [proID, maxID],
                       "both subscription products should load")

        // 2 — buying Pro completes and the transaction verifies
        let pro = try XCTUnwrap(products.first { $0.id == proID })
        let result = try await within(40, "purchase(pro)") { try await pro.purchase() }
        guard case .success(let verification) = result else {
            XCTFail("purchase did not succeed: \(result)"); return
        }
        let tx = try verification.payloadValue
        XCTAssertEqual(tx.productID, proID)
        await tx.finish()

        // 3 — the entitlement is current: the exact signal storeSync maps
        //     onto vault.plan and the tier limits
        var active = try await currentEntitlements()
        XCTAssertTrue(active.contains(proID), "Pro entitlement current after purchase")

        // 4 — upgrading to Max inside the group supersedes Pro
        let max = try XCTUnwrap(products.first { $0.id == maxID })
        let up = try await within(40, "purchase(max)") { try await max.purchase() }
        guard case .success(let v2) = up else {
            XCTFail("upgrade did not succeed: \(up)"); return
        }
        let tx2 = try v2.payloadValue
        await tx2.finish()

        active = try await currentEntitlements()
        XCTAssertTrue(active.contains(maxID), "Max entitlement current after upgrade")
        XCTAssertFalse(active.contains(proID),
                       "Pro superseded by Max — one group, one active tier")
    }

    func testExpiredSubscriptionDropsEntitlement() async throws {
        let session = try SKTestSession(configurationFileNamed: "Products")
        session.disableDialogs = true
        session.clearTransactions()

        let products = try await within(25, "Product.products(for:)") { try await Product.products(for: [self.proID]) }
        let pro = try XCTUnwrap(products.first)
        guard case .success(let v) = try await within(40, "purchase(pro)", { try await pro.purchase() }) else {
            XCTFail("purchase failed"); return
        }
        let tx = try v.payloadValue
        await tx.finish()
        let before = try await currentEntitlements()
        XCTAssertTrue(before.contains(proID))

        // lapse it — the renewal the user cancels
        try session.expireSubscription(productIdentifier: proID)
        let after = try await currentEntitlements()
        XCTAssertFalse(after.contains(proID),
                       "expired subscription must drop out of entitlements — this is what re-locks the app")
    }
}
