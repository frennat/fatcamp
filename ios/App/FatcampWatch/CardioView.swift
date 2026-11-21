import SwiftUI

/// The conditioning block. Start it and walk away: once you've been moving for
/// the target minutes, it logs itself on the phone.
struct CardioView: View {
    @EnvironmentObject var store: SessionStore
    @EnvironmentObject var coach: Coach
    @EnvironmentObject var workout: WorkoutManager

    var body: some View {
        ScrollViewReader { proxy in
        ScrollView {
            if let c = store.session?.cardio {
                VStack(alignment: .leading, spacing: 8) {
                    Text(c.n).fcHeading(18).id("top")
                    Text("\(c.styleName) · target \(c.target) min").fcEyebrow(9)

                    if workout.kind == .cardio { live(c) } else { plan(c) }
                }
                .padding(.horizontal, 4)
            }
        }
        /* starting the block jumps to the live timer instead of leaving you at the Walk/Run buttons */
        .onChange(of: workout.kind) { _, k in
            if k == .cardio { withAnimation { proxy.scrollTo("top", anchor: .top) } }
        }
        }
        .navigationTitle("Cardio")
    }

    @ViewBuilder private func plan(_ c: WatchSession.Cardio) -> some View {
        ForEach(Array(c.segs.enumerated()), id: \.offset) { _, s in
            VStack(alignment: .leading, spacing: 0) {
                Text(s.k).fcEyebrow(9, color: .fcAccent)
                Text(s.v).font(.caption2)
            }
        }
        if c.done {
            Label { Text("Logged · \(c.doneMins ?? c.target) min").fcEyebrow(10, color: .fcAccent) } icon: {
                Image(systemName: "checkmark.seal.fill").foregroundStyle(Color.fcAccent) }
        } else {
            if c.isWalkOrRun {
                /* walk or run decides how Fitness files it (Indoor Walk / Indoor Run) */
                HStack(spacing: 6) {
                    Button { Task { await coach.startCardio(c, pace: "walk") } } label: {
                        VStack(spacing: 2) { Image(systemName: "figure.walk"); Text("Walk").fcHeading(14) }
                            .frame(maxWidth: .infinity)
                    }
                    Button { Task { await coach.startCardio(c, pace: "run") } } label: {
                        VStack(spacing: 2) { Image(systemName: "figure.run"); Text("Run").fcHeading(14) }
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent).tint(.fcAccent)
            } else {
                Button {
                    Task { await coach.startCardio(c) }
                } label: {
                    HStack(spacing: 6) { Image(systemName: "figure.run"); Text("Start").fcHeading(15) }.frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent).tint(.fcAccent)
            }
            Text("Logs itself after \(c.target) min of movement · saves to Fitness and Health").fcEyebrow(8)
        }
    }

    @ViewBuilder private func live(_ c: WatchSession.Cardio) -> some View {
        let target = Double(max(1, c.target) * 60)
        ZStack {
            ProgressRing(progress: workout.movingSeconds / target, lineWidth: 8)
            VStack(spacing: 0) {
                Text(timeString(workout.movingSeconds))
                    .font(FC.num(24))
                Text(workout.targetHit || c.done ? "LOGGED" : "of \(c.target):00 moving")
                    .fcEyebrow(8, color: .fcAccent)
            }
        }
        .frame(height: 96)
        .frame(maxWidth: .infinity)

        HStack {
            Stat(icon: "heart.fill", value: workout.heartRate > 0 ? "\(Int(workout.heartRate))" : "--")
            Stat(icon: "flame.fill", value: "\(Int(workout.kcal))")
            Stat(icon: "point.topleft.down.to.point.bottomright.curvepath",
                 value: String(format: "%.2f", workout.km))
        }

        HStack {
            Button { coach.pause(at: .cardio) } label: {
                Image(systemName: "pause.fill").frame(maxWidth: .infinity)
            }
            .accessibilityLabel("Pause workout")
            Button { Buzz.stop(); Task { await coach.endWorkout() } } label: {
                Image(systemName: "stop.fill").frame(maxWidth: .infinity)
            }
            .tint(.fcAccent)
        }
        if !c.done {
            Button { coach.logCardioByHand() } label: { Text("Log it now").fcEyebrow(10, color: .white) }
        }
    }
}

private struct Stat: View {
    let icon: String, value: String
    var body: some View {
        VStack(spacing: 1) {
            Image(systemName: icon).font(.caption2).foregroundStyle(Color.fcAccent)
            Text(value).font(FC.num(13))
        }
        .frame(maxWidth: .infinity)
    }
}
