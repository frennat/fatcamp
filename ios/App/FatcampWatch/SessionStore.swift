import Foundation
import WatchConnectivity
import WatchKit

/// Holds today's session on the wrist and keeps the phone told.
///
/// The session arrives from the phone as application context (the latest
/// copy always wins). It's cached on the watch, so it still opens with the
/// phone left in a locker. Every tick made here is applied locally right away
/// and sent to the phone as an event. A live message goes when the phone is
/// reachable; otherwise a queued transfer goes, which the OS delivers later.
/// Each event carries an id so the phone applies it exactly once.
@MainActor
final class SessionStore: NSObject, ObservableObject {
    static let shared = SessionStore()

    @Published private(set) var session: WatchSession?
    @Published private(set) var phoneReachable = false
    @Published var autoDetect: Bool {
        didSet { UserDefaults.standard.set(autoDetect, forKey: "fc.autoDetect") }
    }

    private let cacheKey = "fc.session"

    override init() {
        autoDetect = UserDefaults.standard.object(forKey: "fc.autoDetect") as? Bool ?? true
        super.init()
        if let data = UserDefaults.standard.data(forKey: cacheKey),
           let s = try? JSONDecoder().decode(WatchSession.self, from: data) {
            session = s
        }
        #if DEBUG
        /* Design preview (debug builds only): `-fcDemo` loads a sample session and
           stays off WatchConnectivity, so every screen can be looked at without a phone. */
        if ProcessInfo.processInfo.arguments.contains("-fcDemo") {
            session = Self.demo
            return
        }
        #endif
        #if DEBUG
        /* simulator: start with no session, ignoring the phone's earlier ones */
        if ProcessInfo.processInfo.arguments.contains("-fcEmpty") {
            session = nil
            forgedAt = Date().timeIntervalSince1970
        }
        #endif
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    #if DEBUG
    static let demo = WatchSession(
        sid: "demo", title: "Push", effort: 3, unit: "lb", streak: 6, points: 286,
        moves: [
            .init(i: 0, n: "Dumbbell Bench Press", sets: 4, reps: "6–8", rest: 120,
                  done: [true, true, false, false], claimed: false, failure: false, weight: "60", a: "bench", cls: "comp"),
            .init(i: 1, n: "Seated Dumbbell Press", sets: 3, reps: "8–10", rest: 90,
                  done: [true, true, true], claimed: true, failure: false, weight: "40", cls: "comp"),
            .init(i: 2, n: "Push-Up", sets: 3, reps: "to failure", rest: 60,
                  done: [], claimed: false, failure: true, weight: "", cls: "acc"),
            .init(i: 3, n: "Cable Triceps Pushdown", sets: 3, reps: "12–15", rest: 60,
                  done: [], claimed: false, failure: false, weight: "", cls: "iso")
        ],
        cardio: .init(n: "Treadmill Run", style: "treadmill", styleName: "Treadmill", mins: 25, target: 20,
                      segs: [.init(k: "Warm-up", v: "3 min walk, building to an easy jog"),
                             .init(k: "Main", v: "20 min at the pace you came for"),
                             .init(k: "Cool-down", v: "2 min walk before you step off")],
                      done: false, doneMins: nil))
    #endif

    // MARK: actions from the wrist

    /// Tick (or untick) one set. Returns true when that finished the movement.
    @discardableResult
    func setDone(move: Int, set: Int, _ done: Bool, auto: Bool = false) -> Bool {
        guard var s = session, let mi = s.moves.firstIndex(where: { $0.i == move }) else { return false }
        var m = s.moves[mi]
        while m.done.count < m.sets { m.done.append(false) }
        guard set < m.done.count, m.done[set] != done else { return false }
        m.done[set] = done
        let finished = done && m.complete
        if finished { m.claimed = true }      // the phone auto-claims on the last set; mirror it
        s.moves[mi] = m
        commit(s)
        send(["type": "set", "move": move, "set": set, "done": done, "src": auto ? "auto" : "tap"])
        return finished
    }

    /// The next unticked set of a movement, if any.
    func nextSet(of move: Int) -> Int? {
        guard let m = session?.moves.first(where: { $0.i == move }) else { return nil }
        return (0..<m.sets).first { !m.isDone($0) }
    }

    /// The first movement with work left — where "auto-detect" credits a set.
    var currentMove: WatchSession.Move? {
        session?.moves.first { !$0.complete }
    }

    func logCardio(minutes: Int, kcal: Int, km: Double, avgHR: Int, auto: Bool) {
        guard var s = session, var c = s.cardio else { return }
        c.done = true
        c.doneMins = minutes
        s.cardio = c
        commit(s)
        send(["type": "cardio", "mins": minutes, "kcal": kcal, "km": km, "hr": avgHR, "auto": auto])
    }

    /// A workout was saved to Health from the watch, so the phone must not
    /// save a second copy when the session is banked.
    func reportWorkout(kind: String, minutes: Int, kcal: Int, avgHR: Int) {
        send(["type": "workout", "kind": kind, "mins": minutes, "kcal": kcal, "hr": avgHR])
    }

    /// Health is recording a workout for this session on the wrist. The phone
    /// then skips writing its own copy when the session is banked there.
    func reportWorkoutStarted() {
        send(["type": "workoutStart"])
    }

    /// The person's kit, limitations, unit and recent history, kept fresh by the
    /// phone. It's what lets the watch forge a session on its own.
    var forgeTried = false   // debug hook guard (see SpeakView)
    private var forgedAt: Double = UserDefaults.standard.double(forKey: "fc.forgedAt")
    private(set) var profileJSON: String = UserDefaults.standard.string(forKey: "fc.profile") ?? ""

    fileprivate func receive(profile json: String) {
        guard !json.isEmpty, json != profileJSON else { return }
        profileJSON = json
        UserDefaults.standard.set(json, forKey: "fc.profile")
    }

    /// Speak a session into existence: forge it on the server, start it here,
    /// and queue it for the phone (it arrives whenever the two reconnect).
    func forge(_ text: String) async throws -> String {
        let r = try await Forge.run(text: text, profile: profileJSON)
        guard let data = r.watch.data(using: .utf8),
              let s = try? JSONDecoder().decode(WatchSession.self, from: data) else {
            throw ForgeError("The session came back unreadable. Try again.")
        }
        commit(s)
        /* anything the phone sent before this moment is older than this session */
        forgedAt = Date().timeIntervalSince1970
        UserDefaults.standard.set(forgedAt, forKey: "fc.forgedAt")
        send(["type": "forged", "packed": r.packed])
        Buzz.forge()
        return r.summary
    }

    /// Called when the phone clears the session (it was banked or discarded there).
    var onCleared: (() -> Void)?

    func bank() {
        send(["type": "bank"])   // the haptic plays with the celebration (BankFX)
    }

    // MARK: plumbing

    private func commit(_ s: WatchSession) {
        session = s
        if let data = try? JSONEncoder().encode(s) { UserDefaults.standard.set(data, forKey: cacheKey) }
    }

    private func send(_ body: [String: Any]) {
        guard let sid = session?.sid else { return }
        var e = body
        e["sid"] = sid
        e["eid"] = UUID().uuidString
        e["at"] = Date().timeIntervalSince1970
        let wc = WCSession.default
        guard wc.activationState == .activated else { return }
        if wc.isReachable {
            wc.sendMessage(e, replyHandler: nil) { _ in wc.transferUserInfo(e) }
        } else {
            wc.transferUserInfo(e)
        }
    }

    fileprivate func receive(json: String, at: Double? = nil) {
        /* a phone update older than a session forged on the wrist (e.g. replayed when
           the watch app relaunches out of range) must not overwrite it */
        if let at, forgedAt > 0, at < forgedAt { return }
        guard !json.isEmpty, let data = json.data(using: .utf8) else {
            let had = session != nil
            session = nil
            UserDefaults.standard.removeObject(forKey: cacheKey)
            if had { onCleared?() }
            return
        }
        guard let s = try? JSONDecoder().decode(WatchSession.self, from: data) else { return }
        if s.sid != session?.sid { Buzz.forge() }   // a new session landed: the phone's forge thud
        if s != session { commit(s) }
    }
}

extension SessionStore: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState,
                             error: Error?) {
        let ctx = session.receivedApplicationContext
        let reach = session.isReachable
        Task { @MainActor in
            self.phoneReachable = reach
            if let p = ctx["profile"] as? String { self.receive(profile: p) }
            if let json = ctx["session"] as? String { self.receive(json: json, at: ctx["at"] as? Double) }
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        let profile = applicationContext["profile"] as? String
        let at = applicationContext["at"] as? Double
        guard let json = applicationContext["session"] as? String else { return }
        Task { @MainActor in
            if let p = profile { self.receive(profile: p) }
            self.receive(json: json, at: at)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        guard message["type"] as? String == "session", let json = message["session"] as? String else { return }
        let profile = message["profile"] as? String
        let at = message["at"] as? Double
        Task { @MainActor in
            if let p = profile { self.receive(profile: p) }
            self.receive(json: json, at: at)
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        let reach = session.isReachable
        Task { @MainActor in self.phoneReachable = reach }
    }
}
