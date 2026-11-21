import Foundation
import HealthKit
import WatchKit

/// Runs a real Apple Watch workout: heart rate, active calories and distance.
/// It also keeps the app alive with the wrist down, so rest timers still buzz.
///
/// Two kinds:
///   * strength: the whole lift, filed under Traditional Strength Training;
///   * cardio: the conditioning block. A treadmill or steady block is filed as
///     an indoor run or walk and has a target in minutes. Once you've *moved*
///     for that long, the block logs itself on the phone, no tap needed.
///
/// "Moved" is measured, not assumed: a second only counts toward the target
/// while distance is still climbing (the treadmill belt under you, as the
/// watch's motion sensors see it). Stop to tie a shoe and the clock holds.
/// Where no distance comes in at all (a bike, a rower, the simulator), it falls
/// back to plain elapsed time, minus any paused stretches.
@MainActor
final class WorkoutManager: NSObject, ObservableObject {
    static let shared = WorkoutManager()

    enum Kind: String { case strength, cardio }

    @Published private(set) var kind: Kind?
    @Published private(set) var running = false
    @Published private(set) var paused = false
    @Published private(set) var heartRate: Double = 0
    @Published private(set) var avgHeartRate: Double = 0
    @Published private(set) var kcal: Double = 0
    @Published private(set) var km: Double = 0
    @Published private(set) var elapsed: TimeInterval = 0
    @Published private(set) var movingSeconds: TimeInterval = 0
    @Published private(set) var targetMinutes: Int = 0
    @Published private(set) var targetHit = false

    /// Called once when a cardio target is reached by movement.
    var onTargetHit: ((_ minutes: Int, _ kcal: Int, _ km: Double, _ avgHR: Int) -> Void)?

    private let store = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    private var ticker: Timer?
    private var lastDistanceAt: Date?
    private var sawDistance = false
    private var lastTick = Date()
    private var startedAt = Date()
    private var pausedSince: Date?
    private var pausedTotal: TimeInterval = 0
    /// true while Apple Health is recording this workout (false = Fatcamp-only clock)
    @Published private(set) var healthRecording = false

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    func requestAuthorization() async -> Bool {
        guard isAvailable else { return false }
        var read: Set<HKObjectType> = [HKObjectType.workoutType()]
        var share: Set<HKSampleType> = [HKObjectType.workoutType()]
        for id in [HKQuantityTypeIdentifier.heartRate, .activeEnergyBurned, .distanceWalkingRunning] {
            if let t = HKObjectType.quantityType(forIdentifier: id) { read.insert(t); share.insert(t) }
        }
        share.remove(HKQuantityType(.heartRate))   // we read heart rate, never write it
        do { try await store.requestAuthorization(toShare: share, read: read); return true }
        catch { return false }
    }

    /// The Apple Fitness workout type a conditioning block is filed under.
    /// `pace` is the Commander's pick on the wrist ("walk" / "run"); the movement
    /// name settles the machines; intervals and finishers are HIIT.
    static func activityType(style: String?, name: String?, pace: String?) -> HKWorkoutActivityType {
        let n = (name ?? "").lowercased()
        if pace == "walk" { return .walking }
        if pace == "run" { return .running }
        if n.contains("row") || n.contains("erg") { return .rowing }
        if n.contains("bike") || n.contains("cycl") || n.contains("spin") { return .cycling }
        if n.contains("rope") { return .jumpRope }
        if n.contains("ellip") { return .elliptical }
        if n.contains("stair") { return .stairClimbing }
        if style == "intervals" || style == "finisher" { return .highIntensityIntervalTraining }
        return .running
    }

    func start(_ kind: Kind, cardioStyle: String? = nil, cardioName: String? = nil, pace: String? = nil,
               targetMinutes: Int = 0) async {
        if running { await end(save: true) }

        /* The wrist responds first: the clock, the live view and the cardio target
           start this instant. Health joins in underneath when it can. If access
           hasn't been granted yet (the Allow sheet appears on the iPhone), the
           workout still runs and logs to Fatcamp, it just isn't written to Health. */
        reset()
        self.kind = kind
        self.targetMinutes = targetMinutes
        startedAt = Date()
        lastTick = startedAt
        running = true
        paused = false
        ticker = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }

        /* This is a real Apple Watch workout session: it shows the workout indicator
           on the watch face, fills the Move and Exercise rings, and is saved to Health,
           so the Fitness app lists it as "Indoor Run" / "Indoor Walk" / "Traditional
           Strength Training" with Fatcamp as the source. Apple doesn't let other apps
           open its own Workout app, and it doesn't need to: this is the same kind of record. */
        let cfg = HKWorkoutConfiguration()
        cfg.locationType = .indoor
        switch kind {
        case .strength: cfg.activityType = .traditionalStrengthTraining
        case .cardio:   cfg.activityType = Self.activityType(style: cardioStyle, name: cardioName, pace: pace)
        }
        guard isAvailable else { return }
        do {
            let s = try HKWorkoutSession(healthStore: store, configuration: cfg)
            let b = s.associatedWorkoutBuilder()
            b.dataSource = HKLiveWorkoutDataSource(healthStore: store, workoutConfiguration: cfg)
            s.delegate = self
            b.delegate = self
            session = s; builder = b
            s.startActivity(with: startedAt)
            try await b.beginCollection(at: startedAt)
            /* indoor flag: Fitness files it as a treadmill/indoor workout and the watch
               estimates distance from wrist motion instead of waiting on GPS */
            var meta: [String: Any] = [HKMetadataKeyIndoorWorkout: true, "FatcampBlock": kind.rawValue]
            if let n = cardioName, kind == .cardio { meta["FatcampMovement"] = n }
            try? await b.addMetadata(meta)
            healthRecording = true
        } catch {
            /* no Health access yet: keep the local clock running, drop the half-made session */
            session?.end()
            session = nil; builder = nil
            healthRecording = false
        }
    }

    func togglePause() {
        if let s = session {
            if paused { s.resume() } else { s.pause() }
        }
        /* the local clock pauses too, whether or not Health is recording */
        if paused {
            pausedTotal += Date().timeIntervalSince(pausedSince ?? Date())
            pausedSince = nil
            paused = false
            lastTick = Date()
        } else {
            pausedSince = Date()
            paused = true
        }
    }

    /// Ends the workout and (by default) saves it to Health.
    /// Returns minutes / kcal / avg HR for the phone, and whether Health got it.
    @discardableResult
    func end(save: Bool = true) async -> (minutes: Int, kcal: Int, avgHR: Int, saved: Bool) {
        ticker?.invalidate(); ticker = nil
        tick()
        let saved = healthRecording && save
        let summary = (Int((elapsed / 60).rounded()), Int(kcal.rounded()), Int(avgHeartRate.rounded()), saved)
        if let s = session, let b = builder {
            s.end()
            do {
                try await b.endCollection(at: Date())
                if save { _ = try await b.finishWorkout() } else { b.discardWorkout() }
            } catch {}
        }
        session = nil; builder = nil
        running = false; paused = false
        healthRecording = false
        kind = nil
        return summary
    }

    private func reset() {
        heartRate = 0; avgHeartRate = 0; kcal = 0; km = 0
        elapsed = 0; movingSeconds = 0; targetHit = false
        sawDistance = false; lastDistanceAt = nil
        pausedSince = nil; pausedTotal = 0
    }

    private func tick() {
        let now = Date()
        let dt = now.timeIntervalSince(lastTick)
        lastTick = now
        let own = now.timeIntervalSince(startedAt) - pausedTotal - (pausedSince.map { now.timeIntervalSince($0) } ?? 0)
        elapsed = builder?.elapsedTime(at: now) ?? max(0, own)
        guard !paused else { return }

        /* counts as moving if distance rose within the last 12 s; before any
           distance shows up at all, fall back to time on the clock */
        let moving: Bool
        if sawDistance, let last = lastDistanceAt { moving = now.timeIntervalSince(last) < 12 }
        else { moving = true }
        if moving { movingSeconds += dt }

        if kind == .cardio, targetMinutes > 0, !targetHit, movingSeconds >= Double(targetMinutes * 60) {
            targetHit = true
            Buzz.bank()   // cardio logged itself: the same success buzz as banking
            onTargetHit?(targetMinutes, Int(kcal.rounded()), km, Int(avgHeartRate.rounded()))
        }
    }

    fileprivate func absorb(_ stats: HKStatistics) {
        switch stats.quantityType {
        case HKQuantityType(.heartRate):
            let u = HKUnit.count().unitDivided(by: .minute())
            heartRate = stats.mostRecentQuantity()?.doubleValue(for: u) ?? heartRate
            avgHeartRate = stats.averageQuantity()?.doubleValue(for: u) ?? avgHeartRate
        case HKQuantityType(.activeEnergyBurned):
            kcal = stats.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? kcal
        case HKQuantityType(.distanceWalkingRunning):
            let d = stats.sumQuantity()?.doubleValue(for: .meterUnit(with: .kilo)) ?? km
            if d > km + 0.0005 { lastDistanceAt = Date(); sawDistance = true }
            km = d
        default: break
        }
    }
}

extension WorkoutManager: HKWorkoutSessionDelegate {
    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState,
                                    from fromState: HKWorkoutSessionState, date: Date) {
        Task { @MainActor in
            if toState == .running { self.lastTick = Date() }
        }
    }
    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        Task { @MainActor in self.running = false }
    }
}

extension WorkoutManager: HKLiveWorkoutBuilderDelegate {
    nonisolated func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}
    nonisolated func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for t in collectedTypes {
            guard let q = t as? HKQuantityType, let stats = workoutBuilder.statistics(for: q) else { continue }
            Task { @MainActor in self.absorb(stats) }
        }
    }
}
