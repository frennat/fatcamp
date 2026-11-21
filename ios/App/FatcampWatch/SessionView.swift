import SwiftUI

/// Home screen: today's session at a glance, every movement one tap away.
/// The big button is the workout's front door: Start → Continue → Resume.
struct SessionView: View {
    @EnvironmentObject var store: SessionStore
    @EnvironmentObject var coach: Coach
    @EnvironmentObject var workout: WorkoutManager

    var body: some View {
        Group {
            if let s = store.session { session(s) } else { empty }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Text("FATCAMP").font(FC.display(16)).tracking(-0.3).foregroundStyle(Color.fcAccent)
            }
        }
    }

    private var empty: some View {
        VStack(spacing: 8) {
            Image(systemName: "dumbbell.fill").font(.title2).foregroundStyle(Color.fcAccent)
            Text("No session yet").fcHeading(17)
            Text("Type what you want to train on your phone. It lands here.")
                .font(.footnote).foregroundStyle(Color.fcDim).multilineTextAlignment(.center)
        }
        .padding()
    }

    private func session(_ s: WatchSession) -> some View {
        List {
            Section {
                HStack(spacing: 10) {
                    ProgressRing(progress: s.progress, lineWidth: 6)
                        .frame(width: 46, height: 46)
                        .overlay(Text("\(s.doneSets)").font(FC.num(15)))
                    VStack(alignment: .leading, spacing: 3) {
                        Text(s.title).fcHeading(20)
                        Text("\(s.doneSets)/\(s.totalSets) sets · \(s.points) pts").fcEyebrow(9)
                    }
                }
                .listRowBackground(Color.clear)

                if let a = coach.lastAuto, let m = s.moves.first(where: { $0.i == a.move }) {
                    UndoBanner(text: "\(m.n): set \(a.set + 1) logged (\(a.reps) reps)") { coach.undoAuto() }
                }
                if coach.phase == .active, workout.running { liveRow }
                workoutButton(s)
            }

            Section {
                ForEach(s.moves) { m in
                    NavigationLink(value: Route.move(m.i)) { MoveRow(move: m) }
                }
            } header: { Text("Movements").fcEyebrow(9) }

            if let c = s.cardio {
                Section {
                    NavigationLink(value: Route.cardio) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(c.n).fcHeading(14)
                                Text("\(c.styleName) · \(c.mins) min").fcEyebrow(9)
                            }
                            Spacer()
                            if c.done { Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.fcAccent) }
                        }
                    }
                } header: { Text("Conditioning").fcEyebrow(9) }
            }

            Section {
                Toggle(isOn: Binding(get: { store.autoDetect }, set: { coach.setAutoDetect($0) })) {
                    Text("Auto-detect sets · beta").fcEyebrow(9, color: .white)
                }
                Button {
                    Task { await coach.bank() }
                } label: {
                    Text("Bank it").fcHeading(15).frame(maxWidth: .infinity)
                }
                .disabled(s.doneSets == 0 && !(s.cardio?.done ?? false))
            } footer: {
                Text(store.phoneReachable ? "Phone connected" : "Phone away · sets sync later").fcEyebrow(8)
            }
        }
    }

    private var liveRow: some View {
        HStack {
            Image(systemName: "heart.fill").foregroundStyle(Color.fcAccent)
            Text(workout.heartRate > 0 ? "\(Int(workout.heartRate))" : "--").font(FC.num(15))
            Spacer()
            Text(timeString(workout.elapsed)).font(FC.num(15))
        }
        .listRowBackground(Color.clear)
    }

    /// Start → goes to the first unfinished movement. While active → Continue.
    /// After a pause → Resume, which lands exactly where you paused.
    private func workoutButton(_ s: WatchSession) -> some View {
        let label: (String, String) = {
            switch coach.phase {
            case .idle:   return ("Start workout", "play.fill")
            case .active: return ("Continue", "arrow.right")
            case .paused: return ("Resume", "play.fill")
            }
        }()
        return Button { coach.start() } label: {
            HStack(spacing: 6) {
                Image(systemName: label.1)
                Text(label.0).fcHeading(15)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(.fcAccent)
        .disabled(coach.nextRoute == nil && coach.phase != .paused)
        .listRowBackground(Color.clear)
    }
}

struct MoveRow: View {
    let move: WatchSession.Move
    var body: some View {
        HStack(spacing: 8) {
            ProgressRing(progress: Double(move.doneCount) / Double(max(1, move.sets)), lineWidth: 3)
                .frame(width: 22, height: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(move.n).fcHeading(13)
                Text("\(move.sets) × \(move.reps)").font(FC.num(10, .regular)).foregroundStyle(Color.fcDim)
            }
            Spacer(minLength: 0)
            if move.complete { Image(systemName: "checkmark").foregroundStyle(Color.fcAccent) }
        }
        .opacity(move.complete ? 0.6 : 1)
    }
}

struct ProgressRing: View {
    var progress: Double
    var lineWidth: CGFloat
    var body: some View {
        ZStack {
            Circle().stroke(Color.white.opacity(0.15), lineWidth: lineWidth)
            Circle().trim(from: 0, to: max(0.001, min(1, progress)))
                .stroke(Color.fcAccent, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.3), value: progress)
        }
    }
}

struct UndoBanner: View {
    let text: String
    let undo: () -> Void
    var body: some View {
        HStack {
            Image(systemName: "waveform.path.ecg").foregroundStyle(Color.fcAccent)
            Text(text).font(.caption2).lineLimit(2)
            Spacer(minLength: 0)
            Button("Undo", action: undo).font(FC.mono(10, .semibold)).buttonStyle(.bordered)
        }
    }
}

struct RestPill: View {
    @EnvironmentObject var coach: Coach
    var body: some View {
        if let end = coach.restEndsAt {
            HStack {
                Image(systemName: "timer").foregroundStyle(Color.fcAccent)
                Text("Rest").fcEyebrow(9, color: .white)
                Spacer()
                Text(timerInterval: Date()...end, countsDown: true).font(FC.num(18))
                Button { coach.stopRest() } label: { Image(systemName: "forward.fill") }
                    .buttonStyle(.plain)
            }
        }
    }
}

func timeString(_ t: TimeInterval) -> String {
    let s = Int(t)
    return s >= 3600 ? String(format: "%d:%02d:%02d", s / 3600, (s % 3600) / 60, s % 60)
                     : String(format: "%d:%02d", s / 60, s % 60)
}
