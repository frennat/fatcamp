import SwiftUI
import UIKit

/// The movement's 3D figure on the wrist. The app's rig is JavaScript, which
/// watchOS can't run, so every motion is pre-rendered at build time
/// (tools/render-watch-rigs.mjs) into a strip of frames in Rigs.xcassets. This
/// plays the strip down and back up: one rep, on loop.
struct RigPlayer: View {
    let arch: String
    private let frames: [UIImage]

    init(arch: String) {
        self.arch = arch
        self.frames = RigPlayer.frames(for: arch)
    }

    static func has(_ arch: String?) -> Bool {
        guard let a = arch, !a.isEmpty else { return false }
        return UIImage(named: "rig_\(a)") != nil
    }

    var body: some View {
        if frames.isEmpty {
            Image(systemName: "figure.strengthtraining.traditional").font(.largeTitle).foregroundStyle(Color.fcDim)
        } else {
            TimelineView(.periodic(from: .now, by: 1.0 / 14.0)) { ctx in
                let n = frames.count
                let cycle = max(1, n * 2 - 2)
                let t = Int(ctx.date.timeIntervalSinceReferenceDate * 14) % cycle
                let i = t < n ? t : cycle - t          // down, then back up
                Image(uiImage: frames[i]).resizable().scaledToFit()
            }
        }
    }

    private static func frames(for arch: String) -> [UIImage] {
        guard let strip = UIImage(named: "rig_\(arch)"), let cg = strip.cgImage else { return [] }
        let count = 12                                   // must match FRAMES in render-watch-rigs.mjs
        let w = cg.width / count, h = cg.height
        return (0..<count).compactMap { i in
            cg.cropping(to: CGRect(x: i * w, y: 0, width: w, height: h)).map { UIImage(cgImage: $0) }
        }
    }
}

/// The full-screen 3D view, opened from the small mark on the movement screen.
struct RigSheet: View {
    let name: String
    let arch: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 4) {
            RigPlayer(arch: arch)
            Text(name).fcHeading(13).multilineTextAlignment(.center).lineLimit(2)
        }
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
        .onTapGesture { dismiss() }
    }
}
