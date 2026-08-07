import Foundation
import Capacitor
import HealthKit

/// Bridges Apple Health to the web app.
///
/// Two jobs, both narrow on purpose:
///   * read workouts logged by *other* apps, so a run recorded by Strava or a
///     ride recorded by Peloton still counts toward the streak;
///   * write Fatcamp sessions back, so the rest of Health knows about them.
///
/// Nothing read here is transmitted anywhere. It is summarised into day keys
/// and minute counts on the device and handed to the calendar, which is exactly
/// what the privacy policy promises.
@objc(HealthPlugin)
public class HealthPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "HealthPlugin"
    public let jsName = "Health"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "isAvailable",          returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "authorizationStatus",  returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "requestAuthorization", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "recentWorkouts",       returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "saveWorkout",          returnType: CAPPluginReturnPromise)
    ]

    private let store = HKHealthStore()

    private var readTypes: Set<HKObjectType> {
        var s: Set<HKObjectType> = [HKObjectType.workoutType()]
        if let e = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) { s.insert(e) }
        if let b = HKObjectType.quantityType(forIdentifier: .bodyMass) { s.insert(b) }
        return s
    }
    private var writeTypes: Set<HKSampleType> {
        var s: Set<HKSampleType> = [HKObjectType.workoutType()]
        if let e = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) { s.insert(e) }
        return s
    }

    @objc func isAvailable(_ call: CAPPluginCall) {
        call.resolve(["available": HKHealthStore.isHealthDataAvailable()])
    }

    /// Health deliberately will not tell you whether *read* access was granted —
    /// that would leak the absence of data. So this reports write status, which
    /// is honest, and the JS side treats a successful read as the real signal.
    @objc func authorizationStatus(_ call: CAPPluginCall) {
        guard HKHealthStore.isHealthDataAvailable() else {
            call.resolve(["status": "unavailable"]); return
        }
        switch store.authorizationStatus(for: HKObjectType.workoutType()) {
        case .sharingAuthorized: call.resolve(["status": "granted"])
        case .sharingDenied:     call.resolve(["status": "denied"])
        default:                 call.resolve(["status": "notDetermined"])
        }
    }

    @objc func requestAuthorization(_ call: CAPPluginCall) {
        guard HKHealthStore.isHealthDataAvailable() else {
            call.reject("Health is not available on this device"); return
        }
        store.requestAuthorization(toShare: writeTypes, read: readTypes) { ok, err in
            if let err = err { call.reject(err.localizedDescription); return }
            call.resolve(["granted": ok])
        }
    }

    /// Every workout in the window, whoever recorded it, as day keys the streak
    /// calendar already understands.
    @objc func recentWorkouts(_ call: CAPPluginCall) {
        guard HKHealthStore.isHealthDataAvailable() else {
            call.resolve(["workouts": []]); return
        }
        let days = call.getInt("days") ?? 400
        let start = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let pred = HKQuery.predicateForSamples(withStart: start, end: Date(), options: .strictStartDate)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        let q = HKSampleQuery(sampleType: HKObjectType.workoutType(),
                              predicate: pred, limit: 2000, sortDescriptors: [sort]) { _, samples, err in
            if let err = err { call.reject(err.localizedDescription); return }
            let fmt = DateFormatter()
            fmt.dateFormat = "yyyy-MM-dd"
            fmt.calendar = Calendar.current
            fmt.timeZone = TimeZone.current

            let out: [[String: Any]] = (samples as? [HKWorkout] ?? []).map { w in
                var row: [String: Any] = [
                    "day":     fmt.string(from: w.startDate),
                    "start":   ISO8601DateFormatter().string(from: w.startDate),
                    "minutes": Int((w.duration / 60).rounded()),
                    "type":    Self.name(for: w.workoutActivityType),
                    "source":  w.sourceRevision.source.name
                ]
                /* our own sessions come back through this query too; the app
                   filters them out by bundle id so nothing is double counted */
                row["mine"] = w.sourceRevision.source.bundleIdentifier == Bundle.main.bundleIdentifier
                return row
            }
            call.resolve(["workouts": out])
        }
        store.execute(q)
    }

    @objc func saveWorkout(_ call: CAPPluginCall) {
        guard HKHealthStore.isHealthDataAvailable() else {
            call.reject("Health is not available on this device"); return
        }
        let minutes = call.getInt("minutes") ?? 0
        guard minutes > 0 else { call.reject("minutes is required"); return }
        let end = Date()
        let start = end.addingTimeInterval(-Double(minutes) * 60)

        let cfg = HKWorkoutConfiguration()
        cfg.activityType = .traditionalStrengthTraining

        let builder = HKWorkoutBuilder(healthStore: store, configuration: cfg, device: .local())
        builder.beginCollection(withStart: start) { ok, err in
            if !ok { call.reject(err?.localizedDescription ?? "Could not start the workout"); return }

            let finish = {
                builder.endCollection(withEnd: end) { ok2, err2 in
                    if !ok2 { call.reject(err2?.localizedDescription ?? "Could not end the workout"); return }
                    builder.finishWorkout { _, err3 in
                        if let err3 = err3 { call.reject(err3.localizedDescription); return }
                        call.resolve(["saved": true])
                    }
                }
            }

            let kcal = call.getInt("calories") ?? 0
            if kcal > 0, let type = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) {
                let q = HKQuantity(unit: .kilocalorie(), doubleValue: Double(kcal))
                let s = HKCumulativeQuantitySample(type: type, quantity: q, start: start, end: end)
                builder.add([s]) { _, _ in finish() }
            } else {
                finish()
            }
        }
    }

    private static func name(for t: HKWorkoutActivityType) -> String {
        switch t {
        case .traditionalStrengthTraining: return "Strength"
        case .functionalStrengthTraining:  return "Functional"
        case .highIntensityIntervalTraining: return "HIIT"
        case .running:   return "Run"
        case .walking:   return "Walk"
        case .cycling:   return "Cycle"
        case .rowing:    return "Row"
        case .swimming:  return "Swim"
        case .yoga:      return "Yoga"
        case .coreTraining: return "Core"
        case .crossTraining: return "Cross training"
        case .elliptical: return "Elliptical"
        case .stairClimbing, .stairs: return "Stairs"
        case .hiking:    return "Hike"
        default:         return "Workout"
        }
    }
}
