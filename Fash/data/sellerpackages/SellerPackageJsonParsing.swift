import Foundation

enum SellerPackageJsonParsing {
    static func parseBoolean(_ value: Any?) -> Bool? {
        switch value {
        case let b as Bool: return b
        case let n as NSNumber: return n.intValue != 0
        case let s as String:
            switch s.trimmingCharacters(in: .whitespaces).lowercased() {
            case "true", "1", "yes": return true
            case "false", "0", "no": return false
            default: return nil
            }
        default: return nil
        }
    }

    static func wireBoolean(_ obj: [String: Any], keys: [String], default defaultValue: Bool = false) -> Bool {
        for key in keys {
            guard let raw = obj[key] else { continue }
            if let parsed = parseBoolean(raw) { return parsed }
        }
        return defaultValue
    }

    static func wireReleasedFlag(_ obj: [String: Any]) -> Bool {
        let topKeys = ["is_released", "isReleased", "IsReleased"]
        if topKeys.contains(where: { obj[$0] != nil }) {
            return wireBoolean(obj, keys: topKeys, default: false)
        }
        let metaRaw = (obj["metadata"] as? String)?.trimmingCharacters(in: .whitespaces) ?? ""
        if !metaRaw.isEmpty,
           let metaData = metaRaw.data(using: .utf8),
           let meta = try? JSONSerialization.jsonObject(with: metaData) as? [String: Any],
           meta["is_released"] != nil || meta["isReleased"] != nil {
            return wireBoolean(meta, keys: ["is_released", "isReleased"], default: false)
        }
        return false
    }
}
