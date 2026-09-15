import Capacitor
import UIKit

/// The system share sheet for a banked receipt. Resolves once the sheet
/// closes with whether the person actually sent it somewhere, so the web
/// side counts real shares rather than sheets opened and dismissed.
@objc(SharePlugin)
public class SharePlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "SharePlugin"
    public let jsName = "Share"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "share", returnType: CAPPluginReturnPromise)
    ]

    @objc func share(_ call: CAPPluginCall) {
        var items: [Any] = []
        if let text = call.getString("text") { items.append(text) }
        if let url = call.getString("url"), let u = URL(string: url) { items.append(u) }
        guard !items.isEmpty else { call.reject("Nothing to share"); return }
        DispatchQueue.main.async {
            guard let vc = self.bridge?.viewController else { call.reject("No view controller"); return }
            let sheet = UIActivityViewController(activityItems: items, applicationActivities: nil)
            sheet.completionWithItemsHandler = { activity, completed, _, _ in
                call.resolve(["completed": completed, "activity": activity?.rawValue ?? ""])
            }
            // iPad presents the sheet as a popover and crashes without an anchor.
            if let pop = sheet.popoverPresentationController {
                pop.sourceView = vc.view
                pop.sourceRect = CGRect(x: vc.view.bounds.midX, y: vc.view.bounds.maxY - 80, width: 1, height: 1)
                pop.permittedArrowDirections = []
            }
            vc.present(sheet, animated: true)
        }
    }
}
