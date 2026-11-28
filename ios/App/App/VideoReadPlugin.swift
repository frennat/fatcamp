import Foundation
import AVFoundation
import Vision
import Speech
import ImageIO
import CoreGraphics
import UniformTypeIdentifiers
#if !VIDEOREAD_CLI
import Capacitor
import UIKit
import PhotosUI
#endif

/// Reads a workout video on the phone for Upload Media.
///
/// The words are the workout. People who film these say the movement and the
/// count out loud and burn the same words into the frame as captions, so the
/// audio (Speech) and the overlay text (Vision) are the primary source here.
/// A handful of small frames go along too, so the agent on the other side can
/// time where each movement is performed and cut a clip of it.
///
/// Everything below `VideoAnalysis` is plain AVFoundation/Vision/Speech, so the
/// same code also builds as a macOS command-line tool for testing against a
/// real video (compile with `-D VIDEOREAD_CLI`).
enum VideoAnalysis {
    struct Span { var t0: Double; var t1: Double; var text: String }
    struct Frame { var t: Double; var b64: String }

    static func folder() -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("fatcamp-videos", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
    static func clipsFolder() -> URL {
        let dir = folder().appendingPathComponent("clips", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
    static func movieURL(_ vid: String) -> URL { folder().appendingPathComponent("\(vid).mov") }

    /// A vid is only ever ours: letters, digits and dashes. Anything else would
    /// let a caller walk the path out of the videos folder.
    static func safeVid(_ s: String?) -> String? {
        guard let s = s, !s.isEmpty, s.count <= 64,
              s.allSatisfy({ $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" }) else { return nil }
        return s
    }

    static func info(_ url: URL) -> (duration: Double, width: Int, height: Int) {
        let asset = AVURLAsset(url: url)
        let d = CMTimeGetSeconds(asset.duration)
        var w = 0, h = 0
        if let track = asset.tracks(withMediaType: .video).first {
            let r = CGRect(origin: .zero, size: track.naturalSize).applying(track.preferredTransform)
            w = Int(abs(r.width).rounded()); h = Int(abs(r.height).rounded())
        }
        return (d.isFinite ? d : 0, w, h)
    }

    // MARK: transcript

    /// The audio track to an m4a, then Speech over it. Any failure, including
    /// the person saying no to speech recognition, is an empty transcript: the
    /// captions and frames still carry the read.
    static func transcript(_ url: URL, done: @escaping ([Span]) -> Void) {
        let asset = AVURLAsset(url: url)
        guard !asset.tracks(withMediaType: .audio).isEmpty,
              let export = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
            done([]); return
        }
        let out = FileManager.default.temporaryDirectory.appendingPathComponent("vr-\(UUID().uuidString).m4a")
        export.outputURL = out
        export.outputFileType = .m4a
        export.exportAsynchronously {
            guard export.status == .completed else { done([]); return }
            authorize { ok in
                guard ok else { try? FileManager.default.removeItem(at: out); done([]); return }
                recognize(out) { spans in
                    try? FileManager.default.removeItem(at: out)
                    done(spans)
                }
            }
        }
    }

    static func authorize(_ done: @escaping (Bool) -> Void) {
        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized: done(true)
        case .denied, .restricted: done(false)
        default: SFSpeechRecognizer.requestAuthorization { done($0 == .authorized) }
        }
    }

    /// Held for the life of a recognition so the task isn't released mid-read.
    private static var live: [SFSpeechRecognitionTask] = []
    private static let liveLock = NSLock()

    static func recognize(_ audio: URL, done: @escaping ([Span]) -> Void) {
        guard let rec = SFSpeechRecognizer(locale: Locale(identifier: "en-US")), rec.isAvailable else {
            done([]); return
        }
        let req = SFSpeechURLRecognitionRequest(url: audio)
        req.shouldReportPartialResults = false
        if rec.supportsOnDeviceRecognition { req.requiresOnDeviceRecognition = true }
        if #available(iOS 16.0, macOS 13.0, *) { req.addsPunctuation = true }

        var finished = false
        let lock = NSLock()
        var task: SFSpeechRecognitionTask?
        func finish(_ spans: [Span]) {
            lock.lock(); let first = !finished; finished = true; lock.unlock()
            guard first else { return }
            liveLock.lock(); live.removeAll { $0 === task }; liveLock.unlock()
            done(spans)
        }
        task = rec.recognitionTask(with: req) { result, error in
            if let result = result, result.isFinal {
                finish(phrases(result.bestTranscription.segments.map {
                    Span(t0: $0.timestamp, t1: $0.timestamp + $0.duration, text: $0.substring)
                }))
            } else if error != nil {
                finish([])
            }
        }
        if let task = task { liveLock.lock(); live.append(task); liveLock.unlock() }
        // A recognition that never calls back must not hang the read forever.
        DispatchQueue.global().asyncAfter(deadline: .now() + 90) { task?.cancel(); finish([]) }
    }

    /// Word segments into phrases: a pause of 0.6 s, a sentence end, or ten
    /// words closes one.
    static func phrases(_ words: [Span]) -> [Span] {
        var out: [Span] = []
        var cur: Span?
        var count = 0
        for w in words {
            let word = w.text.trimmingCharacters(in: .whitespacesAndNewlines)
            if word.isEmpty { continue }
            if var c = cur, w.t0 - c.t1 <= 0.6, count < 10 {
                // Speech says "100" as "1" + "00": glue a leading-zero digit
                // run back onto the number before it.
                let glue = word.first == "0" && word.allSatisfy(\.isNumber) && (c.text.last?.isNumber ?? false)
                c.text += (glue ? "" : " ") + word; c.t1 = max(c.t1, w.t1); cur = c; if !glue { count += 1 }
            } else {
                if let c = cur { out.append(c) }
                cur = Span(t0: w.t0, t1: w.t1, text: word); count = 1
            }
            if let last = word.last, ".?!".contains(last), let c = cur { out.append(c); cur = nil; count = 0 }
        }
        if let c = cur { out.append(c) }
        return out.map { Span(t0: round2($0.t0), t1: round2($0.t1), text: $0.text) }
    }

    // MARK: captions

    /// Overlay text every 0.25 s. The top 12% and bottom 18% are skipped:
    /// on a screen recording that's the status bar, the account name and the
    /// audio credit, which repeat on every frame and say nothing about the
    /// workout.
    static func captions(_ url: URL) -> [Span] {
        let asset = AVURLAsset(url: url)
        let duration = CMTimeGetSeconds(asset.duration)
        guard duration.isFinite, duration > 0 else { return [] }
        let gen = AVAssetImageGenerator(asset: asset)
        gen.appliesPreferredTrackTransform = true
        gen.maximumSize = CGSize(width: 1280, height: 1280)
        let tol = CMTime(seconds: 0.06, preferredTimescale: 600)
        gen.requestedTimeToleranceBefore = tol
        gen.requestedTimeToleranceAfter = tol

        var out: [Span] = []
        var t = 0.0
        while t < duration {
            let at = CMTime(seconds: t, preferredTimescale: 600)
            if let cg = try? gen.copyCGImage(at: at, actualTime: nil) {
                let text = readText(cg)
                if !text.isEmpty {
                    if var last = out.last, last.text == text, t - last.t1 <= 0.3 {
                        last.t1 = round2(t + 0.25); out[out.count - 1] = last
                    } else {
                        out.append(Span(t0: round2(t), t1: round2(t + 0.25), text: text))
                    }
                }
            }
            t += 0.25
        }
        return out
    }

    static func readText(_ cg: CGImage) -> String {
        let req = VNRecognizeTextRequest()
        req.recognitionLevel = .accurate
        req.usesLanguageCorrection = true
        // Vision's origin is bottom-left: y 0.18…0.88 is the band between the
        // bottom 18% and the top 12%.
        req.regionOfInterest = CGRect(x: 0, y: 0.18, width: 1, height: 0.70)
        let handler = VNImageRequestHandler(cgImage: cg, options: [:])
        do { try handler.perform([req]) } catch { return "" }
        let sorted = (req.results ?? []).sorted { a, b in
            let ay = a.boundingBox.midY, by = b.boundingBox.midY
            if abs(ay - by) > 0.012 { return ay > by }
            return a.boundingBox.minX < b.boundingBox.minX
        }
        let lines = sorted.compactMap { o -> String? in
            guard let s = o.topCandidates(1).first?.string.trimmingCharacters(in: .whitespacesAndNewlines),
                  s.count >= 2 else { return nil }
            // A reel's like/comment/share rail runs down the right edge
            // ("39.6K", "2,005"): bare counts over there are chrome, not
            // captions. A centred "100" stays.
            if o.boundingBox.minX > 0.75, isCount(s) { return nil }
            return s
        }
        return lines.joined(separator: " ")
    }

    static func isCount(_ s: String) -> Bool {
        s.range(of: #"^[\d.,\s]+[KkMm]?\.?$"#, options: .regularExpression) != nil
    }

    // MARK: frames

    /// One small frame every 1.5 s, at most 20, longest side 512, JPEG 0.6.
    /// A long video spreads its 20 evenly rather than stopping at 30 s.
    static func frames(_ url: URL) -> [Frame] {
        let asset = AVURLAsset(url: url)
        let duration = CMTimeGetSeconds(asset.duration)
        guard duration.isFinite, duration > 0 else { return [] }
        let gen = AVAssetImageGenerator(asset: asset)
        gen.appliesPreferredTrackTransform = true
        gen.maximumSize = CGSize(width: 512, height: 512)
        let tol = CMTime(seconds: 0.1, preferredTimescale: 600)
        gen.requestedTimeToleranceBefore = tol
        gen.requestedTimeToleranceAfter = tol

        let step = max(1.5, duration / 20)
        var out: [Frame] = []
        var t = min(0.5, duration / 2)
        while t < duration && out.count < 20 {
            if let cg = try? gen.copyCGImage(at: CMTime(seconds: t, preferredTimescale: 600), actualTime: nil),
               let data = jpeg(cg, quality: 0.6) {
                out.append(Frame(t: round2(t), b64: data.base64EncodedString()))
            }
            t += step
        }
        return out
    }

    static func jpeg(_ cg: CGImage, quality: Double) -> Data? {
        let data = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(data, UTType.jpeg.identifier as CFString, 1, nil) else { return nil }
        CGImageDestinationAddImage(dest, cg, [kCGImageDestinationLossyCompressionQuality: quality] as CFDictionary)
        return CGImageDestinationFinalize(dest) ? data as Data : nil
    }

    // MARK: clips

    static func clip(_ url: URL, vid: String, t0: Double, t1: Double, done: @escaping (URL?, String?) -> Void) {
        let asset = AVURLAsset(url: url)
        let duration = CMTimeGetSeconds(asset.duration)
        let a = max(0, min(t0, duration)), b = max(a, min(t1, duration))
        guard b - a >= 0.2 else { done(nil, "That clip is too short."); return }
        guard let export = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetMediumQuality) else {
            done(nil, "Couldn't cut that clip."); return
        }
        let out = clipsFolder().appendingPathComponent("\(vid)_\(Int((a * 1000).rounded())).mp4")
        try? FileManager.default.removeItem(at: out)
        export.outputURL = out
        export.outputFileType = .mp4
        export.shouldOptimizeForNetworkUse = true
        export.timeRange = CMTimeRange(start: CMTime(seconds: a, preferredTimescale: 600),
                                       end: CMTime(seconds: b, preferredTimescale: 600))
        export.exportAsynchronously {
            if export.status == .completed { done(out, nil) }
            else { done(nil, export.error?.localizedDescription ?? "Couldn't cut that clip.") }
        }
    }

    static func round2(_ x: Double) -> Double { (x * 100).rounded() / 100 }

    static func spanDicts(_ s: [Span]) -> [[String: Any]] { s.map { ["t0": $0.t0, "t1": $0.t1, "text": $0.text] } }
}

#if !VIDEOREAD_CLI
@objc(VideoReadPlugin)
public class VideoReadPlugin: CAPPlugin, CAPBridgedPlugin, PHPickerViewControllerDelegate {
    public let identifier = "VideoReadPlugin"
    public let jsName = "VideoRead"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "pick", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "analyze", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "clip", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "forget", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "base", returnType: CAPPluginReturnPromise)
    ]

    private var pickCall: CAPPluginCall?

    // MARK: pick

    @objc func pick(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            guard let vc = self.bridge?.viewController else { call.reject("No view controller"); return }
            if let old = self.pickCall { old.reject("cancelled") }
            var cfg = PHPickerConfiguration()
            cfg.filter = .videos
            cfg.selectionLimit = 1
            cfg.preferredAssetRepresentationMode = .current
            let picker = PHPickerViewController(configuration: cfg)
            picker.delegate = self
            self.pickCall = call
            vc.present(picker, animated: true)
        }
    }

    public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let call = pickCall else { return }
        pickCall = nil
        guard let item = results.first?.itemProvider,
              item.hasItemConformingToTypeIdentifier(UTType.movie.identifier) else {
            call.reject("cancelled"); return
        }
        item.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { tmp, error in
            // The provider's file is deleted when this block returns: copy now.
            guard let tmp = tmp else {
                call.reject(error?.localizedDescription ?? "Couldn't open that video."); return
            }
            let vid = String(UUID().uuidString.prefix(12)).lowercased()
            let dest = VideoAnalysis.movieURL(vid)
            do {
                try? FileManager.default.removeItem(at: dest)
                try FileManager.default.copyItem(at: tmp, to: dest)
            } catch {
                call.reject("Couldn't copy that video: \(error.localizedDescription)"); return
            }
            let info = VideoAnalysis.info(dest)
            call.resolve(["vid": vid, "duration": info.duration, "width": info.width, "height": info.height])
        }
    }

    // MARK: analyze

    @objc func analyze(_ call: CAPPluginCall) {
        guard let vid = VideoAnalysis.safeVid(call.getString("vid")) else { call.reject("Missing vid."); return }
        let url = VideoAnalysis.movieURL(vid)
        guard FileManager.default.fileExists(atPath: url.path) else { call.reject("That video is gone."); return }

        VideoAnalysis.transcript(url) { transcript in
            DispatchQueue.global(qos: .userInitiated).async {
                let captions = VideoAnalysis.captions(url)
                let frames = VideoAnalysis.frames(url)
                call.resolve([
                    "duration": VideoAnalysis.info(url).duration,
                    "transcript": VideoAnalysis.spanDicts(transcript),
                    "captions": VideoAnalysis.spanDicts(captions),
                    "frames": frames.map { ["t": $0.t, "b64": $0.b64] }
                ])
            }
        }
    }

    // MARK: clip

    @objc func clip(_ call: CAPPluginCall) {
        guard let vid = VideoAnalysis.safeVid(call.getString("vid")) else { call.reject("Missing vid."); return }
        guard let t0 = call.getDouble("t0"), let t1 = call.getDouble("t1") else { call.reject("Missing t0/t1."); return }
        let url = VideoAnalysis.movieURL(vid)
        guard FileManager.default.fileExists(atPath: url.path) else { call.reject("That video is gone."); return }
        VideoAnalysis.clip(url, vid: vid, t0: t0, t1: t1) { out, err in
            guard let out = out else { call.reject(err ?? "Couldn't cut that clip."); return }
            DispatchQueue.main.async {
                let src = self.bridge?.portablePath(fromLocalURL: out)?.absoluteString ?? out.absoluteString
                call.resolve(["path": out.path, "src": src])
            }
        }
    }

    // MARK: forget

    /// Where clips live *this launch*, as a web-view URL. iOS can move the app's
    /// data folder between installs (TestFlight updates included), so the page
    /// stores only a clip's file name and rebuilds the link from this.
    @objc func base(_ call: CAPPluginCall) {
        let dir = VideoAnalysis.clipsFolder()
        let src = bridge?.portablePath(fromLocalURL: dir)?.absoluteString ?? dir.absoluteString
        call.resolve(["src": src.hasSuffix("/") ? src : src + "/"])
    }

    @objc func forget(_ call: CAPPluginCall) {
        guard let vid = VideoAnalysis.safeVid(call.getString("vid")) else { call.reject("Missing vid."); return }
        try? FileManager.default.removeItem(at: VideoAnalysis.movieURL(vid))
        call.resolve()
    }
}
#endif
