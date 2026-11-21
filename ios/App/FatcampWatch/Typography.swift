import SwiftUI
import UIKit

/// The iPhone app's type system, carried to the wrist:
///   display  — Avenir Next 800, uppercase, tight tracking (headings, the wordmark, big buttons)
///   mono     — SF Mono, uppercase, wide tracking (eyebrows and small labels: "MUSCLE COVERAGE")
///   num      — SF Mono with tabular figures (every number: sets, timers, points)
///   body     — system text (anything you read as a sentence)
/// Avenir Next ships on iPhone but not necessarily on watchOS. It's used when the
/// watch has it; otherwise a heavy SF stands in, keeping the same weight and case.
enum FC {
    private static let avenir: String? = {
        for name in ["AvenirNext-Heavy", "AvenirNext-Bold"] where UIFont(name: name, size: 12) != nil { return name }
        return nil
    }()

    static func display(_ size: CGFloat) -> Font {
        if let a = avenir { return .custom(a, size: size) }
        return .system(size: size, weight: .heavy)
    }
    static func mono(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
    static func num(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .monospaced).monospacedDigit()
    }
}

extension View {
    /// Heading style: uppercase display face, tracking pulled in like the phone's h1–h3.
    func fcHeading(_ size: CGFloat, lines: Int = 2) -> some View {
        font(FC.display(size)).textCase(.uppercase).tracking(-0.3).lineLimit(lines).minimumScaleFactor(0.6)
    }
    /// Eyebrow style: small mono caps with the phone's wide .18em spacing.
    func fcEyebrow(_ size: CGFloat = 10, color: Color = .fcDim) -> some View {
        font(FC.mono(size)).textCase(.uppercase).tracking(size * 0.16).foregroundStyle(color)
    }
}
