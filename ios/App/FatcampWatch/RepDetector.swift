import Foundation
import CoreMotion

/// Beta: notices a set from wrist motion, so you can lift without tapping.
///
/// A rep is a swing in wrist acceleration: rise above a threshold, then fall back
/// below a lower one, with hysteresis so one rep isn't counted twice. Reps that
/// come 0.6–6 s apart make up a set. When the reps stop for `quietToEnd`
/// seconds and there were at least `minReps`, the set is reported.
///
/// This is honest about its limits. It hears that you *moved like a set*, not
/// which lift it was, so the set goes to the movement you're on and the wrist
/// offers an Undo. Machine work with a still wrist (leg press, calf raise)
/// won't trigger it; tapping always works.
final class RepDetector {
    var onRep: ((Int) -> Void)?             // running rep count inside the current set
    var onSet: ((Int) -> Void)?             // a finished set and its rep count

    var minReps = 4
    var quietToEnd: TimeInterval = 5
    private let hi = 0.16, lo = 0.07        // g, on the smoothed magnitude
    private let minGap: TimeInterval = 0.6, maxGap: TimeInterval = 6

    private let motion = CMMotionManager()
    private var smooth = 0.0
    private var armed = true
    private var reps = 0
    private var lastRep: Date?
    private var quietTimer: Timer?

    var isAvailable: Bool { motion.isDeviceMotionAvailable }

    func start() {
        guard motion.isDeviceMotionAvailable, !motion.isDeviceMotionActive else { return }
        motion.deviceMotionUpdateInterval = 1.0 / 50
        /* 50 Hz on the main queue is cheap on a watch and keeps every counter on one thread */
        motion.startDeviceMotionUpdates(to: .main) { [weak self] dm, _ in
            guard let self, let a = dm?.userAcceleration else { return }
            self.feed(sqrt(a.x * a.x + a.y * a.y + a.z * a.z), at: Date())
        }
    }

    func stop() {
        motion.stopDeviceMotionUpdates()
        quietTimer?.invalidate()
        reps = 0; lastRep = nil
    }

    private func feed(_ g: Double, at t: Date) {
        smooth += 0.2 * (g - smooth)
        if armed, smooth > hi {
            armed = false
            if let last = lastRep {
                let gap = t.timeIntervalSince(last)
                if gap < minGap { return }
                reps = gap > maxGap ? 1 : reps + 1
            } else {
                reps = 1
            }
            lastRep = t
            onRep?(reps)
            armQuietTimer()
        } else if !armed, smooth < lo {
            armed = true
        }
    }

    private func armQuietTimer() {
        quietTimer?.invalidate()
        quietTimer = Timer.scheduledTimer(withTimeInterval: quietToEnd, repeats: false) { [weak self] _ in
            guard let self else { return }
            let n = self.reps
            self.reps = 0; self.lastRep = nil
            if n >= self.minReps { self.onSet?(n) }
        }
    }
}
