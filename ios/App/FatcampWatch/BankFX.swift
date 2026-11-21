import SwiftUI
import WatchKit

/// The phone's haptics, one name each, so a tap feels the same on both:
///   set  — light thud on every logged set (iPhone: light impact)
///   forge — a new session just landed (iPhone: medium impact when you forge)
///   bank — the session is banked (iPhone: success notification)
/// Watch-only moments (rest over, workout start/stop, motion-detected set) keep
/// the watch's own patterns.
enum Buzz {
    static func set()   { WKInterfaceDevice.current().play(.click) }
    static func forge() { WKInterfaceDevice.current().play(.directionUp) }
    static func bank()  { WKInterfaceDevice.current().play(.success) }
    static func restDone()    { WKInterfaceDevice.current().play(.notification) }
    static func detectedSet() { WKInterfaceDevice.current().play(.notification) }
    static func start() { WKInterfaceDevice.current().play(.start) }
    static func stop()  { WKInterfaceDevice.current().play(.stop) }
}

/// The phone's bank celebration, cut down to a wrist: the Fatcamp mark rising out
/// of pulsing rings, bolts crackling around it, a dumbbell drifting across, and
/// the same pair of lines the phone picks from.
struct BankFX: View {
    let top: String
    let bottom: String

    static let tops = ["Banked.", "Paid in iron", "Another one down", "The bar yielded",
                       "Work got done", "Forged & finished", "That's the standard",
                       "Heavy. Honest. Done.", "Session sealed", "Receipts printed"]
    static let bottoms = ["Nobody lifted that for you.",
                          "The couch never stood a chance today.",
                          "Strength is rent, and you just paid it.",
                          "Every set in that vault is yours to keep.",
                          "Show up again and the streak keeps its teeth.",
                          "Gravity fought fair. You didn't need it to.",
                          "That's one more day the quit didn't win.",
                          "The plates go home. The work stays with you.",
                          "Soreness tomorrow, capital today.",
                          "You against yesterday — and yesterday lost."]

    @State private var rise = false
    @State private var pulse = false
    @State private var flicker = false

    private let boltColors: [Color] = [Color(red: 0.31, green: 0.85, blue: 1.0),   // #4FD9FF, the logo's bolt
                                       Color(red: 0.97, green: 0.40, blue: 0.18),  // #F8672F
                                       .fcPaper]
    private let bolts: [(x: CGFloat, y: CGFloat, s: CGFloat, r: Double)] =
        [(-62, -70, 0.9, -18), (64, -56, 0.7, 20), (-70, 40, 0.6, 12), (60, 62, 0.85, -22), (4, -92, 0.55, 8)]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // rings pulsing out from the mark
            ForEach(0..<3) { i in
                Circle()
                    .stroke(Color.fcAccent.opacity(0.55), lineWidth: 2)
                    .frame(width: 70, height: 70)
                    .scaleEffect(pulse ? 2.6 : 0.6)
                    .opacity(pulse ? 0 : 0.9)
                    .animation(.easeOut(duration: 1.4).repeatForever(autoreverses: false).delay(Double(i) * 0.18),
                               value: pulse)
            }

            // bolts crackling around it
            ForEach(0..<bolts.count, id: \.self) { i in
                let b = bolts[i]
                Image(systemName: "bolt.fill")
                    .font(.system(size: 18 * b.s, weight: .heavy))
                    .foregroundStyle(boltColors[i % boltColors.count])
                    .rotationEffect(.degrees(b.r))
                    .offset(x: b.x, y: b.y)
                    .opacity(flicker ? (i.isMultiple(of: 2) ? 1 : 0.25) : (i.isMultiple(of: 2) ? 0.25 : 1))
                    .animation(.easeInOut(duration: 0.22).repeatForever(autoreverses: true).delay(Double(i) * 0.07),
                               value: flicker)
            }

            // a dumbbell drifting across, like the phone's
            Image(systemName: "dumbbell")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(Color.fcPaper.opacity(0.35))
                .rotationEffect(.degrees(-30))
                .offset(x: rise ? 70 : 110, y: rise ? -78 : -110)
                .animation(.easeOut(duration: 1.6), value: rise)

            VStack(spacing: 6) {
                Image("BankMark")
                    .resizable()
                    .frame(width: 70, height: 70)
                    .clipShape(Circle())
                    .shadow(color: Color(red: 0.31, green: 0.85, blue: 1.0).opacity(0.6), radius: rise ? 10 : 0)
                    .scaleEffect(rise ? 1 : 0.3)
                    .rotationEffect(.degrees(rise ? 0 : -40))
                Text(top).fcHeading(17).multilineTextAlignment(.center)
                Text(bottom).font(.system(size: 12)).foregroundStyle(Color.fcPaper.opacity(0.85))
                    .multilineTextAlignment(.center).lineLimit(2).padding(.horizontal, 8)
            }
            .opacity(rise ? 1 : 0)
            .offset(y: rise ? 0 : 24)
            .animation(.spring(response: 0.55, dampingFraction: 0.62), value: rise)
        }
        .onAppear {
            Buzz.bank()
            rise = true; pulse = true; flicker = true
        }
    }
}
