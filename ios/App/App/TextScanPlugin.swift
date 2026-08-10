import Foundation
import Capacitor
import Vision
import UIKit

/// On-device text recognition for the Upload Media flow.
///
/// Apple's Vision framework reads the words off a photo or a sampled video
/// frame entirely on the phone: no network, no API key, no per-use cost, and
/// nothing about somebody's training leaves the device. That last part is the
/// reason this exists rather than a cloud vision call — the equipment picker
/// already tells people "Fatcamp runs entirely on your device with no
/// internet", and a feature that quietly posted their camera roll to a server
/// would make that line false.
///
/// The trade is coverage: this reads text, so it finds the lift when the media
/// names it and finds nothing when it doesn't. The JS side treats an empty
/// result as a normal outcome and falls through to a picker rather than an
/// error.
@objc(TextScanPlugin)
public class TextScanPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "TextScanPlugin"
    public let jsName = "TextScan"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "read", returnType: CAPPluginReturnPromise)
    ]

    @objc func read(_ call: CAPPluginCall) {
        guard let frames = call.getArray("frames", String.self), !frames.isEmpty else {
            call.reject("No frames to read.")
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            var ordered: [String] = []
            var seen = Set<String>()

            /* A clip's overlay is burned into every frame it spans, so the same
               line arrives once per frame. Dedupe case-insensitively and keep
               the first sighting, which preserves the order it was written in. */
            for b64 in frames.prefix(12) {
                for line in TextScanPlugin.lines(fromBase64: b64) {
                    let key = line.lowercased()
                    if seen.insert(key).inserted { ordered.append(line) }
                }
            }

            call.resolve([
                "lines": ordered,
                "text": ordered.joined(separator: "\n")
            ])
        }
    }

    /// One frame to its text, in reading order.
    private static func lines(fromBase64 b64: String) -> [String] {
        guard let data = Data(base64Encoded: b64),
              let image = UIImage(data: data),
              let cg = image.cgImage else { return [] }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cg, options: [:])
        do { try handler.perform([request]) } catch { return [] }

        let obs = request.results ?? []

        /* Vision hands back observations in no guaranteed order, and its
           bounding boxes have their origin at the bottom-left — so a larger y
           is higher up the frame. Sorting top-down, then left-to-right within a
           row, keeps a written list in the order somebody actually wrote it.
           That ordering is most of why a screenshot of a workout parses well. */
        let sorted = obs.sorted { a, b in
            let ay = a.boundingBox.midY, by = b.boundingBox.midY
            if abs(ay - by) > 0.012 { return ay > by }
            return a.boundingBox.minX < b.boundingBox.minX
        }

        return sorted.compactMap { o -> String? in
            guard let top = o.topCandidates(1).first else { return nil }
            let s = top.string.trimmingCharacters(in: .whitespacesAndNewlines)
            return s.isEmpty ? nil : s
        }
    }
}
