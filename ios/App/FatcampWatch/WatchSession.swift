import Foundation

/// The session as the phone hands it over: deliberately small, display-ready,
/// and free of anything the wrist doesn't need (no 3D, no muscle maps).
/// The phone stays the source of truth; the watch only reports what you did.
struct WatchSession: Codable, Equatable {
    var sid: String            // the session's creation time on the phone; ties every event to one session
    var title: String
    var effort: Int            // 1–4
    var unit: String           // "lb" | "kg"
    var streak: Int
    var points: Int            // points on offer
    var moves: [Move]
    var cardio: Cardio?

    struct Move: Codable, Equatable, Identifiable {
        var i: Int             // index in the phone's move list
        var n: String          // name
        var sets: Int
        var reps: String       // already formatted: "8–10", "45 s", "8 each"
        var rest: Int          // seconds
        var done: [Bool]
        var claimed: Bool
        var failure: Bool
        var weight: String
        var cls: String        // comp | acc | iso | core
        var id: Int { i }

        var doneCount: Int { done.prefix(sets).filter { $0 }.count }
        var complete: Bool { doneCount >= sets }
        func isDone(_ set: Int) -> Bool { set < done.count && done[set] }
    }

    struct Cardio: Codable, Equatable {
        var n: String          // movement name, e.g. "Treadmill Run"
        var style: String      // treadmill | steady | intervals | finisher
        var styleName: String
        var mins: Int          // planned total minutes
        var target: Int        // minutes that count as "done" — the main block
        var segs: [Seg]
        var done: Bool
        var doneMins: Int?

        struct Seg: Codable, Equatable { var k: String; var v: String }

        /// The workout type Health should file it under.
        var isWalkOrRun: Bool {
            let l = n.lowercased()
            return style == "treadmill" || l.contains("run") || l.contains("treadmill") || l.contains("walk")
        }
    }

    var totalSets: Int { moves.reduce(0) { $0 + $1.sets } }
    var doneSets: Int { moves.reduce(0) { $0 + $1.doneCount } }
    var progress: Double { totalSets == 0 ? 0 : Double(doneSets) / Double(totalSets) }
}
