import Capacitor
import StoreKit
import UIKit

/// Apple's in-app rating sheet. The web side decides when to ask (third
/// banked session, then rarely); the system decides whether the sheet
/// actually shows — three prompts a year at most, and never in TestFlight
/// or development builds. `asked` reports only that the request was made.
@objc(ReviewPlugin)
public class ReviewPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "ReviewPlugin"
    public let jsName = "Review"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "request", returnType: CAPPluginReturnPromise)
    ]

    @objc func request(_ call: CAPPluginCall) {
        Task { @MainActor in
            let scene = self.bridge?.viewController?.view.window?.windowScene
                ?? UIApplication.shared.connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .first { $0.activationState == .foregroundActive }
            guard let scene = scene else { call.resolve(["asked": false]); return }
            if #available(iOS 16.0, *) {
                AppStore.requestReview(in: scene)
            } else {
                SKStoreReviewController.requestReview(in: scene)
            }
            call.resolve(["asked": true])
        }
    }
}
