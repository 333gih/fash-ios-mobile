import Foundation

/// Port of Android `CoreServiceErrors` (data.http).
enum CoreServiceErrors {
    static func parseMessage(data: Data, statusCode: Int) -> String {
        if let json = try? HttpJson.dictionary(data) {
            if let msg = json["message"] as? String, !msg.isEmpty { return msg }
            if let err = json["error"] as? String, !err.isEmpty { return err }
        }
        return "HTTP \(statusCode)"
    }
}
