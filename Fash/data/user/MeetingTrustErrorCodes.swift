import Foundation

/// Error codes from core-service meeting trust flows — Android `MeetingTrustErrorCodes`.
enum MeetingTrustErrorCodes {
    static let meetingIdentityReverifyRequired = "MEETING_IDENTITY_REVERIFY_REQUIRED"

    static func isIdentityReverifyRequired(_ message: String?) -> Bool {
        let m = message?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !m.isEmpty else { return false }
        return m.localizedCaseInsensitiveContains("code=\(meetingIdentityReverifyRequired)")
            || m.localizedCaseInsensitiveContains(meetingIdentityReverifyRequired)
    }
}
