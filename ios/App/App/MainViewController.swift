import UIKit
import Capacitor

/// Capacitor auto-registers plugins that ship inside Swift packages; one defined
/// in the app target has to be handed to the bridge by hand.
///
/// Worth knowing where this gets used: SceneDelegate builds the root controller
/// in code, so the storyboard is never consulted for it. Subclassing and
/// pointing the storyboard here does nothing — SceneDelegate has to name it.
class MainViewController: CAPBridgeViewController {
    override func capacitorDidLoad() {
        bridge?.registerPluginInstance(HealthPlugin())
        bridge?.registerPluginInstance(NotifyPlugin())
        bridge?.registerPluginInstance(TextScanPlugin())
        bridge?.registerPluginInstance(HapticsPlugin())
        if #available(iOS 15.0, *) { bridge?.registerPluginInstance(StorePlugin()) }
    }
}
