import Foundation
import WatchKit

/// Where the wrist can be: a movement (by its index) or the cardio block.
enum Route: Hashable { case move(Int), cardio }

/// Glue between the session, the workout and the motion detector. It runs the
/// workout's start / pause / resume, ticks sets, keeps the rest clock and
/// offers an undo when the wrist guessed. It also owns navigation, so
/// "Start workout" and "Resume" can put you on the right screen.
@MainActor
final class Coach: ObservableObject {
    static let shared = Coach()

    enum Phase { case idle, active, paused }

    @Published var path: [Route] = []
    @Published private(set) var phase: Phase = .idle
    @Published private(set) var pausedAt: Route?
    @Published private(set) var restEndsAt: Date?
    @Published private(set) var restTotal: Int = 0
    @Published private(set) var liveReps: Int = 0
    @Published private(set) var lastAuto: (move: Int, set: Int, reps: Int)?

    let store = SessionStore.shared
    let workout = WorkoutManager.shared
    private let detector = RepDetector()
    private var restTimer: Timer?
    private var restLeftWhenPaused: TimeInterval?
    private var undoTimer: Timer?

    init() {
        detector.onRep = { [weak self] n in self?.liveReps = n }
        detector.onSet = { [weak self] n in self?.autoSet(reps: n) }
        workout.onTargetHit = { [weak self] mins, kcal, km, hr in
            self?.store.logCardio(minutes: mins, kcal: kcal, km: km, avgHR: hr, auto: true)
        }
    }

    /// The first thing left to do: an unfinished movement, else unlogged cardio.
    var nextRoute: Route? {
        guard let s = store.session else { return nil }
        if let m = s.moves.first(where: { !$0.complete }) { return .move(m.i) }
        if let c = s.cardio, !c.done { return .cardio }
        return nil
    }

    // MARK: start / pause / resume

    /// Start (or carry on with) the workout and land on the first thing to do.
    func start() {
        if phase == .paused { resume(); return }
        if phase == .idle {
            phase = .active
            /* the Health workout starts in the background; the wrist doesn't wait
               for it, so the movement opens instantly even before Health answers */
            Task { await workout.start(.strength) }
            if store.autoDetect { detector.start() }
            Buzz.start()
        }
        if let r = nextRoute { path = [r] }
    }

    /// Pause from a movement (or cardio): freeze the workout and the rest clock,
    /// remember where you were, and go back to the home screen.
    func pause(at route: Route) {
        guard phase == .active else { return }
        phase = .paused
        pausedAt = route
        if workout.running && !workout.paused { workout.togglePause() }
        detector.stop()
        if let end = restEndsAt {
            restLeftWhenPaused = max(0, end.timeIntervalSinceNow)
            restTimer?.invalidate(); restTimer = nil
            restEndsAt = nil
        }
        Buzz.stop()
        path = []
    }

    /// Pick up exactly where the pause left off: same screen, same rest time left.
    func resume() {
        guard phase == .paused else { return }
        phase = .active
        if workout.running && workout.paused { workout.togglePause() }
        if store.autoDetect && workout.kind != .cardio { detector.start() }
        if let left = restLeftWhenPaused, left > 0.5 { runRest(seconds: left, total: restTotal) }
        restLeftWhenPaused = nil
        Buzz.start()
        path = [pausedAt ?? nextRoute].compactMap { $0 }
        pausedAt = nil
    }

    func setAutoDetect(_ on: Bool) {
        store.autoDetect = on
        if on && phase == .active && workout.kind != .cardio { detector.start() } else { detector.stop() }
    }

    // MARK: sets

    /// Tick the next set of a movement and start its rest clock. On the last set,
    /// move on to whatever is next.
    func completeNextSet(of move: WatchSession.Move) {
        if phase == .idle { phase = .active; Task { await workout.start(.strength) } }
        guard let set = store.nextSet(of: move.i) else { return }
        let finished = store.setDone(move: move.i, set: set, true)
        Buzz.set()   // the phone buzzes the same light tap for every set, last one included
        if finished { stopRest(); advance() } else { startRest(move.rest) }
    }

    func toggle(move: WatchSession.Move, set: Int) {
        store.setDone(move: move.i, set: set, !move.isDone(set))
        Buzz.set()
    }

    /// After a finished movement: a beat to see the checkmark, then the next one.
    private func advance() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            guard let self, self.phase == .active else { return }
            self.path = [self.nextRoute].compactMap { $0 }
        }
    }

    private func autoSet(reps: Int) {
        liveReps = 0
        guard let m = store.currentMove, let set = store.nextSet(of: m.i) else { return }
        let finished = store.setDone(move: m.i, set: set, true, auto: true)
        Buzz.detectedSet()
        lastAuto = (m.i, set, reps)
        undoTimer?.invalidate()
        undoTimer = Timer.scheduledTimer(withTimeInterval: 8, repeats: false) { [weak self] _ in
            Task { @MainActor in self?.lastAuto = nil }
        }
        if finished { advance() } else { startRest(m.rest) }
    }

    func undoAuto() {
        guard let a = lastAuto else { return }
        store.setDone(move: a.move, set: a.set, false)
        lastAuto = nil
        stopRest()
    }

    // MARK: rest clock

    func startRest(_ seconds: Int) {
        guard seconds > 0 else { return }
        runRest(seconds: TimeInterval(seconds), total: seconds)
    }

    private func runRest(seconds: TimeInterval, total: Int) {
        restTotal = total
        restEndsAt = Date().addingTimeInterval(seconds)
        restTimer?.invalidate()
        restTimer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false) { [weak self] _ in
            Task { @MainActor in
                Buzz.restDone()
                self?.restEndsAt = nil
            }
        }
    }

    func stopRest() {
        restTimer?.invalidate(); restTimer = nil
        restEndsAt = nil
        restLeftWhenPaused = nil
    }

    // MARK: cardio

    /// Start the conditioning block as its own Apple Watch workout. `pace` is
    /// "walk" or "run" for a treadmill, nil for a machine named by the block.
    func startCardio(_ c: WatchSession.Cardio, pace: String? = nil) async {
        detector.stop()
        phase = .active
        if workout.kind == .strength {
            let s = await workout.end(save: true)
            if s.saved { store.reportWorkout(kind: "strength", minutes: s.minutes, kcal: s.kcal, avgHR: s.avgHR) }
        }
        Buzz.start()
        await workout.start(.cardio, cardioStyle: c.style, cardioName: c.n, pace: pace, targetMinutes: c.target)
    }

    func logCardioByHand() {
        /* by hand: the longer of time moving and time elapsed, never shown as 0 */
        let secs = max(workout.movingSeconds, workout.elapsed)
        store.logCardio(minutes: max(1, Int((secs / 60).rounded(.up))), kcal: Int(workout.kcal.rounded()),
                        km: workout.km, avgHR: Int(workout.avgHeartRate.rounded()), auto: false)
        Buzz.set()
    }

    // MARK: finish

    func endWorkout() async {
        detector.stop(); stopRest()
        phase = .idle; pausedAt = nil
        guard let kind = workout.kind else { return }
        let s = await workout.end(save: true)
        /* only when Health really recorded it; otherwise the phone saves the session itself */
        if s.saved { store.reportWorkout(kind: kind.rawValue, minutes: s.minutes, kcal: s.kcal, avgHR: s.avgHR) }
    }

    /// The bank celebration on the wrist (nil when not showing).
    @Published private(set) var bankFx: (top: String, bottom: String)?

    /// Bank straight away (no confirmation), play the celebration, then clear it.
    func bank() async {
        await endWorkout()
        path = []
        store.bank()
        bankFx = (BankFX.tops.randomElement() ?? "Banked.", BankFX.bottoms.randomElement() ?? "")
        try? await Task.sleep(nanoseconds: 3_200_000_000)
        bankFx = nil
    }
}
