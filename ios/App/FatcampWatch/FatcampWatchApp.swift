import SwiftUI
import WatchKit
import WatchConnectivity

/// When the phone sends a new session while the watch app is in the
/// background, watchOS wakes it with a connectivity task. The task has to stay
/// open until WatchConnectivity has handed over everything pending, otherwise
/// the update waits until the next time the app is opened.
final class WatchAppDelegate: NSObject, WKApplicationDelegate {
    private var pending: [WKWatchConnectivityRefreshBackgroundTask] = []

    func applicationDidFinishLaunching() { _ = SessionStore.shared }

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        for task in backgroundTasks {
            if let wc = task as? WKWatchConnectivityRefreshBackgroundTask {
                _ = SessionStore.shared
                pending.append(wc)
                drainWhenIdle()
            } else {
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }

    private func drainWhenIdle() {
        if WCSession.default.activationState == .activated, !WCSession.default.hasContentPending {
            pending.forEach { $0.setTaskCompletedWithSnapshot(false) }
            pending.removeAll()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { self.drainWhenIdle() }
        }
    }
}

@main
struct FatcampWatchApp: App {
    @WKApplicationDelegateAdaptor private var delegate: WatchAppDelegate
    @StateObject private var store = SessionStore.shared
    @StateObject private var coach = Coach.shared
    @StateObject private var workout = WorkoutManager.shared

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $coach.path) {
                root.navigationDestination(for: Route.self) { r in
                    switch r {
                    case .move(let i): MoveView(moveIndex: i)
                    case .cardio:      CardioView()
                    }
                }
            }
                .environmentObject(store)
                .environmentObject(coach)
                .environmentObject(workout)
                .tint(.fcAccent)
                .overlay {
                    if let fx = coach.bankFx {
                        BankFX(top: fx.top, bottom: fx.bottom).transition(.opacity)
                    }
                }
                .animation(.easeInOut(duration: 0.25), value: coach.bankFx == nil)
                /* ask for Health once, up front, so the prompt is answered before the first workout */
                .task { _ = await workout.requestAuthorization() }
        }
    }

    /// Debug builds can open straight onto one screen for design review:
    /// `-fcScreen move` or `-fcScreen cardio` (pair with `-fcDemo`).
    @ViewBuilder private var root: some View {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "-fcScreen"), i + 1 < args.count {
            switch args[i + 1] {
            case "move":   MoveView(moveIndex: 0)
            case "cardio": CardioView()
            default:       SessionView()
            }
        } else {
            SessionView()
        }
        #else
        SessionView()
        #endif
    }
}

extension Color {
    static let fcAccent = Color(red: 0xD8 / 255, green: 0x38 / 255, blue: 0x2B / 255)   // #D8382B
    static let fcPaper  = Color(red: 0xEF / 255, green: 0xED / 255, blue: 0xE7 / 255)   // #EFEDE7
    static let fcDim    = Color.white.opacity(0.55)
}
