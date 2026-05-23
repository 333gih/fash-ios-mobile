import Foundation

enum HttpJson {
    static func post(url: String, body: [String: Any], bearer: String? = nil) async throws -> Data {
        guard let u = URL(string: url) else { throw URLError(.badURL) }
        var req = URLRequest(url: u)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue("Fash-iOS/1.0.3", forHTTPHeaderField: "User-Agent")
        if let bearer, !bearer.isEmpty {
            req.setValue("Bearer \(bearer)", forHTTPHeaderField: "Authorization")
        }
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        guard (200..<300).contains(http.statusCode) else {
            throw CoreServiceHttpException(statusCode: http.statusCode, message: CoreServiceErrors.parseMessage(data: data, statusCode: http.statusCode))
        }
        return data
    }

    static func dictionary(_ data: Data) throws -> [String: Any] {
        guard let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw URLError(.cannotParseResponse)
        }
        return obj
    }

    static func array(_ data: Data) throws -> [[String: Any]] {
        guard let obj = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            throw URLError(.cannotParseResponse)
        }
        return obj
    }
}

struct CoreServiceHttpException: Error, LocalizedError {
    let statusCode: Int
    let message: String
    var errorDescription: String? { message }
}

enum CoreServiceErrors {
    static func parseMessage(data: Data, statusCode: Int) -> String {
        if let json = try? HttpJson.dictionary(data) {
            if let msg = json["message"] as? String, !msg.isEmpty { return msg }
            if let err = json["error"] as? String, !err.isEmpty { return err }
        }
        return "HTTP \(statusCode)"
    }
}
