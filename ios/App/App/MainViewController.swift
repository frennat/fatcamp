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
        bridge?.registerPluginInstance(SharePlugin())
        bridge?.registerPluginInstance(ReviewPlugin())
        bridge?.registerPluginInstance(WatchPlugin())
        if #available(iOS 15.0, *) { bridge?.registerPluginInstance(StorePlugin()) }
        lockHorizontalScroll()
    }

    /// The app scrolls up and down only. The web view's scroll view is pinned
    /// sideways, so even content a few pixels too wide can't pan the screen.
    private func lockHorizontalScroll() {
        guard let sv = webView?.scrollView else { return }
        sv.alwaysBounceHorizontal = false
        sv.showsHorizontalScrollIndicator = false
        sv.isDirectionalLockEnabled = true
        xLock = sv.observe(\.contentOffset, options: [.new]) { sv, _ in
            if sv.contentOffset.x != 0 { sv.contentOffset.x = 0 }
        }
    }
    private var xLock: NSKeyValueObservation?
}
