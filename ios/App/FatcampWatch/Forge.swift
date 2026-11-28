import Foundation

/// Speech to session, from the wrist alone. The dictated sentence and the
/// person's saved profile go to the `forge` function, which runs the same
/// generator as the phone (copied out of index.html at build time). Works over
/// cellular with the phone out of range.
enum Forge {
    /* the project's public (publishable) key — the same one the web app ships */
    static let url = URL(string: "https://chghvwnytjlakuvkkluv.supabase.co/functions/v1/forge")!
    static let key = "sb_publishable_H69bdgZ5FdZIojX5LHK3aQ_2Vz2CZif"

    struct Reply: Decodable {
        let watch: String?
        let error: String?
        let summary: String?
    }

    /// Returns (watch JSON, phone JSON) or throws a human-readable message.
    static func run(text: String, profile: String) async throws -> (watch: String, packed: String, summary: String) {
        var req = URLRequest(url: url, timeoutInterval: 25)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(key, forHTTPHeaderField: "apikey")
        var prof: Any = [String: Any]()
        if let d = profile.data(using: .utf8), let o = try? JSONSerialization.jsonObject(with: d) { prof = o }
        req.httpBody = try JSONSerialization.data(withJSONObject: ["text": text, "profile": prof])

        let data: Data, resp: URLResponse
        do { (data, resp) = try await URLSession.shared.data(for: req) }
        catch { throw ForgeError("No connection. Check cellular or Wi-Fi and try again.") }

        let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
        guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ForgeError("The forge didn't answer. Try again.")
        }
        if code != 200 { throw ForgeError((obj["error"] as? String) ?? "Something went wrong (\(code)).") }
        guard let watch = obj["watch"] as? String,
              let packedObj = obj["packed"],
              let packedData = try? JSONSerialization.data(withJSONObject: packedObj),
              let packed = String(data: packedData, encoding: .utf8) else {
            throw ForgeError("The session came back incomplete. Try again.")
        }
        return (watch, packed, (obj["summary"] as? String) ?? "")
    }
}

struct ForgeError: LocalizedError {
    let message: String
    init(_ m: String) { message = m }
    var errorDescription: String? { message }
}
