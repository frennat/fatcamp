import Capacitor
import UIKit

/// The phone's taptic engine, two verbs wide. `impact` is the thud of a set
/// logged or a session forged; `notify` is the success flourish when a
/// workout banks. Kept deliberately tiny — the web side decides when, this
/// side only decides how it feels.
@objc(HapticsPlugin)
public class HapticsPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "HapticsPlugin"
    public let jsName = "Haptics"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "impact", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "notify", returnType: CAPPluginReturnPromise)
    ]

    @objc func impact(_ call: CAPPluginCall) {
        let style = call.getString("style") ?? "medium"
        DispatchQueue.main.async {
            let s: UIImpactFeedbackGenerator.FeedbackStyle =
                style == "light" ? .light : style == "heavy" ? .heavy : .medium
            let gen = UIImpactFeedbackGenerator(style: s)
            gen.prepare()
            gen.impactOccurred()
        }
        call.resolve()
    }

    @objc func notify(_ call: CAPPluginCall) {
        let type = call.getString("type") ?? "success"
        DispatchQueue.main.async {
            let gen = UINotificationFeedbackGenerator()
            gen.prepare()
            gen.notificationOccurred(type == "warning" ? .warning : type == "error" ? .error : .success)
        }
        call.resolve()
    }
}
