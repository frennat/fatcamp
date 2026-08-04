import UIKit
import Capacitor

/// Capacitor auto-discovers plugins that ship inside Swift packages, but a
/// plugin defined in the app target has to be handed to the bridge explicitly.
/// Without this the class compiles, links, and is simply never reachable from
/// JavaScript — which is exactly what happened the first time.
class MainViewController: CAPBridgeViewController {
    override func capacitorDidLoad() {
        bridge?.registerPluginInstance(HealthPlugin())
    }
}
