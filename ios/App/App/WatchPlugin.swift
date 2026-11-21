import Foundation
import Capacitor
import WatchConnectivity

/// Bridges the web app to the Fatcamp Apple Watch app.
///
/// Phone → watch: the web app hands over today's session as a compact JSON
/// string (`push`). It goes out as the WCSession *application context*, which
/// always carries the latest state, survives the watch being out of range, and
/// replaces anything older. It is also sent as a live message when the watch is
/// reachable, so a tick on the phone shows up on the wrist within a second.
///
/// Watch → phone: set ticks, cardio logs, workout summaries and "bank it"
/// requests arrive as user-info transfers (queued and guaranteed by the OS) or
/// live messages. They're stored here in a small persisted inbox before the
/// web view hears about them. If the web view is asleep when an event lands,
/// nothing is lost: the page drains the inbox on its next load or resume.
@objc(WatchPlugin)
public class WatchPlugin: CAPPlugin, CAPBridgedPlugin, WCSessionDelegate {
    public let identifier = "WatchPlugin"
    public let jsName = "Watch"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "status", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "push",   returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "drain",  returnType: CAPPluginReturnPromise)
    ]

    private static let inboxKey = "fatcamp.watch.inbox"
    private let lock = NSLock()

    override public func load() {
        guard WCSession.isSupported() else { return }
        let s = WCSession.default
        s.delegate = self
        s.activate()
    }

    // MARK: JS API

    @objc func status(_ call: CAPPluginCall) {
        guard WCSession.isSupported() else {
            call.resolve(["supported": false, "paired": false, "installed": false, "reachable": false]); return
        }
        let s = WCSession.default
        call.resolve([
            "supported": true,
            "paired": s.activationState == .activated && s.isPaired,
            "installed": s.activationState == .activated && s.isWatchAppInstalled,
            "reachable": s.isReachable
        ])
    }

    /// `session` is a JSON string (or null to clear the wrist).
    @objc func push(_ call: CAPPluginCall) {
        guard WCSession.isSupported() else { call.resolve(["sent": false]); return }
        let s = WCSession.default
        guard s.activationState == .activated, s.isPaired, s.isWatchAppInstalled else {
            call.resolve(["sent": false]); return
        }
        let json = call.getString("session") ?? ""
        let ctx: [String: Any] = ["session": json, "at": Date().timeIntervalSince1970]
        do { try s.updateApplicationContext(ctx) } catch {
            call.reject(error.localizedDescription); return
        }
        if s.isReachable {
            s.sendMessage(["type": "session", "session": json], replyHandler: nil, errorHandler: nil)
        }
        call.resolve(["sent": true])
    }

    /// Hand every queued watch event to the page and forget them.
    @objc func drain(_ call: CAPPluginCall) {
        lock.lock()
        let events = UserDefaults.standard.array(forKey: Self.inboxKey) ?? []
        UserDefaults.standard.removeObject(forKey: Self.inboxKey)
        lock.unlock()
        call.resolve(["events": events])
    }

    // MARK: inbound

    private func enqueue(_ event: [String: Any]) {
        guard event["type"] is String else { return }
        lock.lock()
        var q = UserDefaults.standard.array(forKey: Self.inboxKey) ?? []
        q.append(event)
        if q.count > 500 { q.removeFirst(q.count - 500) }
        UserDefaults.standard.set(q, forKey: Self.inboxKey)
        lock.unlock()
        /* a nudge, not the payload: the page drains, so an event is applied
           once whether it hears this or only finds it on the next resume */
        DispatchQueue.main.async { self.notifyListeners("watchEvents", data: ["pending": true]) }
    }

    public func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        enqueue(userInfo)
    }

    public func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        enqueue(message)
    }

    public func session(_ session: WCSession, didReceiveMessage message: [String: Any],
                        replyHandler: @escaping ([String: Any]) -> Void) {
        enqueue(message)
        replyHandler(["ok": true])
    }

    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState,
                        error: Error?) {
        DispatchQueue.main.async { self.notifyListeners("watchStatus", data: ["active": activationState == .activated]) }
    }

    public func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async { self.notifyListeners("watchStatus", data: ["reachable": session.isReachable]) }
    }

    public func sessionDidBecomeInactive(_ session: WCSession) {}
    public func sessionDidDeactivate(_ session: WCSession) { WCSession.default.activate() }
}
