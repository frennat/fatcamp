import SwiftUI

/// One movement: the sets as dots, a big "set done" button beside the pause
/// button, and the rest clock.
struct MoveView: View {
    let moveIndex: Int
    @EnvironmentObject var store: SessionStore
    @EnvironmentObject var coach: Coach
    @EnvironmentObject var workout: WorkoutManager
    @State private var showRig = false

    private var move: WatchSession.Move? { store.session?.moves.first { $0.i == moveIndex } }

    var body: some View {
        ScrollView {
            if let m = move {
                VStack(alignment: .leading, spacing: 8) {
                    if let s = store.session {
                        /* the whole session, not this movement: climbs with every set logged */
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text("\(Int((s.progress * 100).rounded()))%")
                                .font(FC.display(22)).foregroundStyle(Color.fcAccent)
                                .contentTransition(.numericText())
                                .animation(.easeOut(duration: 0.3), value: s.doneSets)
                            Text("of session").fcEyebrow(9)
                            Spacer(minLength: 0)
                            /* the movement in 3D: a small mark, nothing more */
                            if RigPlayer.has(m.a) {
                                Button { showRig = true } label: {
                                    Image("BankMark").resizable().frame(width: 24, height: 24).clipShape(Circle())
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Show \(m.n) in 3D")
                            }
                        }
                        ProgressView(value: s.progress).tint(.fcAccent)
                    }
                    Text(m.n).fcHeading(18)
                    Text("\(m.sets) × \(m.reps)\(m.failure ? " · to failure" : "") · \(m.rest)s rest").fcEyebrow(9)
                    if !m.weight.isEmpty {
                        Text("\(m.weight) \(store.session?.unit ?? "lb")").font(FC.num(14)).foregroundStyle(Color.fcPaper)
                    }

                    HStack(spacing: 6) {
                        ForEach(0..<m.sets, id: \.self) { i in
                            Button { coach.toggle(move: m, set: i) } label: {
                                Circle()
                                    .fill(m.isDone(i) ? Color.fcAccent : Color.white.opacity(0.15))
                                    .frame(width: 20, height: 20)
                                    .overlay(Text("\(i + 1)").font(FC.num(10, .bold)))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Set \(i + 1) \(m.isDone(i) ? "done" : "not done")")
                        }
                    }
                    .padding(.vertical, 2)

                    if coach.restEndsAt != nil { RestPill() }

                    if let a = coach.lastAuto, a.move == m.i {
                        UndoBanner(text: "Set \(a.set + 1) logged from motion (\(a.reps) reps)") { coach.undoAuto() }
                    } else if workout.kind == .strength, store.autoDetect, coach.liveReps > 0,
                              store.currentMove?.i == m.i {
                        Text("Counting · \(coach.liveReps) reps").fcEyebrow(9, color: .fcAccent)
                    }

                    if m.complete {
                        Label {
                            Text(m.claimed ? "Done · points claimed" : "Done").fcEyebrow(10, color: .fcAccent)
                        } icon: {
                            Image(systemName: "checkmark.seal.fill").foregroundStyle(Color.fcAccent)
                        }
                    } else {
                        HStack(spacing: 6) {
                            if coach.phase == .active {
                                Button { coach.pause(at: .move(m.i)) } label: {
                                    Image(systemName: "pause.fill").font(.system(size: 18, weight: .bold))
                                        .frame(width: 44, height: 44)
                                }
                                .buttonStyle(.bordered)
                                .clipShape(Circle())
                                .accessibilityLabel("Pause workout")
                            }
                            Button {
                                coach.completeNextSet(of: m)
                            } label: {
                                Text("Set \((store.nextSet(of: m.i) ?? 0) + 1) done")
                                    .fcHeading(16, lines: 1)
                                    .frame(maxWidth: .infinity)
                            }
                            .tint(.fcAccent)
                            .buttonStyle(.borderedProminent)
                        }
                    }
                }
                .padding(.horizontal, 4)
            } else {
                Text("This movement was swapped on the phone.").font(.footnote)
            }
        }
        .navigationTitle(move.map { "\($0.doneCount)/\($0.sets)" } ?? "")
        .sheet(isPresented: $showRig) {
            if let m = move, let a = m.a { RigSheet(name: m.n, arch: a) }
        }
    }
}
