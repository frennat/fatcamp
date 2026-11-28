import SwiftUI

/// No session yet: one button, the Fatcamp mark. Tap it and it bursts open (the
/// same rings and bolts as banking) into the mic: "Speak today's lift into
/// existence". Say it, and the session is forged on the server — over cellular
/// if the phone isn't around — and lands here ready to train.
struct SpeakView: View {
    @EnvironmentObject var store: SessionStore
    /// Opened from the widget: skip the logo and go straight to the mic.
    var startListening = false
    /// Presented over the app (widget): called when it's done or cancelled.
    var onFinish: (() -> Void)? = nil

    enum Stage: Equatable { case idle, listening, forging, failed(String) }
    @State private var stage: Stage = .idle
    @State private var burst = false
    @State private var pulse = false
    @State private var flicker = false
    @State private var spin = false

    private let blue = Color(red: 0.31, green: 0.85, blue: 1.0)    // #4FD9FF, the mark's bolt
    private let orange = Color(red: 0.97, green: 0.40, blue: 0.18) // #F8672F
    private let bolts: [(x: CGFloat, y: CGFloat, s: CGFloat, r: Double)] =
        [(-62, -64, 0.9, -18), (64, -52, 0.7, 20), (-66, 46, 0.6, 12), (60, 58, 0.85, -22), (2, -84, 0.55, 8)]

    var body: some View {
        ZStack {
            if stage != .idle { sparks }
            switch stage {
            case .idle:            markButton
            case .listening:       listening
            case .forging:         forging
            case .failed(let msg): failed(msg)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: stage)
        .onAppear { if startListening && stage == .idle { openMic() } }
    }

    // MARK: the button

    private var markButton: some View {
        Button { openMic() } label: {
            Image("BankMark").resizable().frame(width: 104, height: 104).clipShape(Circle())
                .shadow(color: blue.opacity(pulse ? 0.55 : 0.25), radius: pulse ? 14 : 6)
                .scaleEffect(pulse ? 1.03 : 0.97)
                .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: pulse)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Speak a workout")
        .onAppear {
            pulse = true
            #if DEBUG
            /* simulator test hook: -fcSpeak "push day, go hard" stands in for dictation */
            let args = ProcessInfo.processInfo.arguments
            if let i = args.firstIndex(of: "-fcSpeak"), i + 1 < args.count, !store.forgeTried {
                store.forgeTried = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { go(args[i + 1]) }
            }
            #endif
        }
    }

    // MARK: the mic

    private var listening: some View {
        VStack(spacing: 10) {
            TextFieldLink(prompt: Text("Push day, go hard")) {
                ZStack {
                    Circle().fill(Color.fcAccent).frame(width: 76, height: 76)
                        .shadow(color: Color.fcAccent.opacity(0.6), radius: 12)
                    Image(systemName: "mic.fill").font(.system(size: 32, weight: .bold)).foregroundStyle(.white)
                }
                .scaleEffect(burst ? 1 : 0.3)
            } onSubmit: { text in
                let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
                guard t.count > 1 else { return }
                go(t)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dictate your workout")

            Text("Speak today's lift into existence")
                .fcHeading(15).multilineTextAlignment(.center)
                .opacity(burst ? 1 : 0)
                .padding(.horizontal, 6)
            Button("Cancel") { reset() }
                .font(.system(size: 12)).foregroundStyle(Color.fcDim).buttonStyle(.plain)
        }
    }

    private func go(_ text: String) {
        stage = .forging
        spin = true
        Task {
            do {
                _ = try await store.forge(text)
                // store.session is now set; the home screen takes over
                reset()
            } catch {
                Buzz.stop()
                stage = .failed(error.localizedDescription)
            }
        }
    }

    // MARK: forging / failed

    private var forging: some View {
        VStack(spacing: 10) {
            Image("BankMark").resizable().frame(width: 70, height: 70).clipShape(Circle())
                .rotationEffect(.degrees(spin ? 360 : 0))
                .animation(.linear(duration: 1.1).repeatForever(autoreverses: false), value: spin)
            Text("Forging").fcEyebrow(10, color: .white)
        }
    }

    private func failed(_ msg: String) -> some View {
        VStack(spacing: 10) {
            Text(msg).font(.footnote).multilineTextAlignment(.center).foregroundStyle(Color.fcPaper)
            Button { stage = .listening } label: {
                HStack(spacing: 6) { Image(systemName: "mic.fill"); Text("Try again").fcHeading(14) }
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent).tint(.fcAccent)
            Button("Cancel") { reset() }.font(.footnote)
        }
        .padding(.horizontal, 6)
    }

    private func openMic() {
        Buzz.set()
        burst = false
        stage = .listening
        withAnimation(.easeOut(duration: 0.6)) { burst = true }
        pulse = true; flicker = true
    }

    private func reset() {
        stage = .idle; burst = false; spin = false; flicker = false
        onFinish?()
    }

    // MARK: the burst (shared look with the bank celebration)

    private var sparks: some View {
        ZStack {
            ForEach(0..<3) { i in
                Circle().stroke(Color.fcAccent.opacity(0.5), lineWidth: 2)
                    .frame(width: 80, height: 80)
                    .scaleEffect(burst ? 2.5 : 0.6)
                    .opacity(burst ? 0 : 0.9)
                    .animation(.easeOut(duration: 1.5).repeatForever(autoreverses: false).delay(Double(i) * 0.2),
                               value: burst)
            }
            ForEach(0..<bolts.count, id: \.self) { i in
                let b = bolts[i]
                Image(systemName: "bolt.fill")
                    .font(.system(size: 17 * b.s, weight: .heavy))
                    .foregroundStyle([blue, orange, Color.fcPaper][i % 3])
                    .rotationEffect(.degrees(b.r))
                    .offset(x: burst ? b.x : b.x * 0.3, y: burst ? b.y : b.y * 0.3)
                    .opacity(flicker ? (i.isMultiple(of: 2) ? 1 : 0.25) : (i.isMultiple(of: 2) ? 0.25 : 1))
                    .animation(.easeInOut(duration: 0.24).repeatForever(autoreverses: true).delay(Double(i) * 0.07),
                               value: flicker)
                    .animation(.spring(response: 0.6, dampingFraction: 0.6), value: burst)
            }
        }
        .allowsHitTesting(false)
    }
}
