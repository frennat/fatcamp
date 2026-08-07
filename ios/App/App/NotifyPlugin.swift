import Foundation
import Capacitor
import UserNotifications

/// Local notification scheduling, written in-repo rather than pulled from npm.
///
/// `@capacitor/local-notifications` would do this too, but it ships its Swift
/// source inside `node_modules` and Package.swift then points at a path that a
/// clean Xcode Cloud clone does not have. Rebuilding that dependency on the
/// build machine means a post-clone script installing Node — the exact thing
/// that broke four builds in a row. This file is committed, so there is
/// nothing to fetch and nothing to install.
///
/// Deliberately local-only: no APNs, no server, no device token. Everything
/// that decides whether to nudge — training days, streak length, whether today
/// is already logged — is computed on the device and never leaves it, which is
/// what the privacy policy promises.
@objc(NotifyPlugin)
public class NotifyPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "NotifyPlugin"
    public let jsName = "Notify"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "requestPermissions", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getPending",         returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "cancel",             returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "schedule",           returnType: CAPPluginReturnPromise)
    ]

    private let center = UNUserNotificationCenter.current()

    /* CAPPlugin already declares this one, so it is an override rather than a
       new method — and it has to stay `public` to match the base class. */
    @objc public override func requestPermissions(_ call: CAPPluginCall) {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { ok, err in
            if let err = err { call.reject(err.localizedDescription); return }
            call.resolve(["display": ok ? "granted" : "denied"])
        }
    }

    @objc func getPending(_ call: CAPPluginCall) {
        center.getPendingNotificationRequests { reqs in
            let out = reqs.compactMap { r -> [String: Any]? in
                guard let id = Int(r.identifier) else { return nil }
                return ["id": id]
            }
            call.resolve(["notifications": out])
        }
    }

    @objc func cancel(_ call: CAPPluginCall) {
        let rows = call.getArray("notifications", JSObject.self) ?? []
        let ids = rows.compactMap { ($0["id"] as? Int).map(String.init) }
        if !ids.isEmpty { center.removePendingNotificationRequests(withIdentifiers: ids) }
        call.resolve()
    }

    /// Accepts the same shape the JS side builds: either a repeating
    /// `schedule.on` of calendar components, or a one-off `schedule.at` in
    /// epoch milliseconds.
    @objc func schedule(_ call: CAPPluginCall) {
        let rows = call.getArray("notifications", JSObject.self) ?? []
        guard !rows.isEmpty else { call.resolve(); return }

        let group = DispatchGroup()
        var failed: String? = nil

        for row in rows {
            guard let id = row["id"] as? Int else { continue }
            let content = UNMutableNotificationContent()
            content.title = row["title"] as? String ?? "Fatcamp"
            content.body  = row["body"]  as? String ?? ""
            content.sound = .default

            var trigger: UNNotificationTrigger? = nil
            if let sch = row["schedule"] as? JSObject {
                if let on = sch["on"] as? JSObject {
                    var c = DateComponents()
                    /* weekday is 1 = Sunday, matching Foundation and the JS side */
                    if let w = on["weekday"] as? Int { c.weekday = w }
                    if let h = on["hour"]    as? Int { c.hour    = h }
                    if let m = on["minute"]  as? Int { c.minute  = m }
                    trigger = UNCalendarNotificationTrigger(dateMatching: c, repeats: true)
                } else if let ms = on_at(sch) {
                    let date = Date(timeIntervalSince1970: ms / 1000)
                    /* a past date would fire immediately; drop it instead */
                    if date <= Date() { continue }
                    let c = Calendar.current.dateComponents(
                        [.year, .month, .day, .hour, .minute], from: date)
                    trigger = UNCalendarNotificationTrigger(dateMatching: c, repeats: false)
                }
            }
            guard let trig = trigger else { continue }

            group.enter()
            center.add(UNNotificationRequest(identifier: String(id),
                                             content: content,
                                             trigger: trig)) { err in
                if let err = err, failed == nil { failed = err.localizedDescription }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            if let f = failed { call.reject(f) } else { call.resolve() }
        }
    }

    /// `at` arrives as milliseconds; JSON has no date type and a serialised
    /// Date crossing the bridge is a string whose format depends on the engine.
    private func on_at(_ sch: JSObject) -> Double? {
        if let d = sch["at"] as? Double { return d }
        if let i = sch["at"] as? Int    { return Double(i) }
        return nil
    }
}
