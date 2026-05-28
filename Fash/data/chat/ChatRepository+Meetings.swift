import Foundation

extension ChatRepository {
    func proposeMeeting(
        conversationId: String,
        locationUrl: String,
        scheduledAtRfc3339: String,
        reminderEnabled: Bool,
        reminderOffsetMinutes: Int,
        safeZoneId: String? = nil,
        safeZoneName: String? = nil
    ) async -> Result<Void, Error> {
        let convId = conversationId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !convId.isEmpty else { return .failure(URLError(.badURL)) }
        var body: [String: Any] = [
            "conversation_id": convId,
            "location_url": locationUrl.trimmingCharacters(in: .whitespacesAndNewlines),
            "scheduled_at": scheduledAtRfc3339.trimmingCharacters(in: .whitespacesAndNewlines),
            "reminder_enabled": reminderEnabled,
            "reminder_offset_minutes": reminderOffsetMinutes,
        ]
        if let zid = safeZoneId?.trimmingCharacters(in: .whitespacesAndNewlines), !zid.isEmpty {
            body["safe_zone_id"] = zid
        }
        if let zname = safeZoneName?.trimmingCharacters(in: .whitespacesAndNewlines), !zname.isEmpty {
            body["safe_zone_name"] = zname
        }
        do {
            _ = try await postJSON(relativePath: "api/v1/chat/meetings/propose", body: body)
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    func confirmMeeting(appointmentId: String) async -> Result<Void, Error> {
        let id = appointmentId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !id.isEmpty else { return .failure(URLError(.badURL)) }
        do {
            _ = try await postJSON(relativePath: "api/v1/chat/meetings/\(id)/confirm", body: [:])
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    func cancelMeeting(appointmentId: String) async -> Result<MeetingCancelResult, Error> {
        let id = appointmentId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !id.isEmpty else { return .failure(URLError(.badURL)) }
        do {
            let data = try await postJSON(relativePath: "api/v1/chat/meetings/\(id)/cancel", body: [:])
            let obj = (try? RepositoryHttp.jsonObject(data)) ?? [:]
            let root = (obj["data"] as? [String: Any]) ?? obj
            let suggest = RepositoryHttp.optBool(root, "suggest_seller_reopen_listing", "SuggestSellerReopenListing", default: false)
            return .success(MeetingCancelResult(suggestSellerReopenListing: suggest))
        } catch {
            return .failure(error)
        }
    }

    func meetingOnMyWay(appointmentId: String) async -> Result<MeetingAppointmentPayload, Error> {
        let id = appointmentId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !id.isEmpty else { return .failure(URLError(.badURL)) }
        do {
            let data = try await postJSON(relativePath: "api/v1/chat/meetings/\(id)/on-my-way", body: [:])
            let obj = (try? RepositoryHttp.jsonObject(data)) ?? [:]
            let root = (obj["data"] as? [String: Any]) ?? obj
            guard let appt = parseMeetingAppointmentPayload(root) else {
                return .failure(URLError(.cannotParseResponse))
            }
            return .success(appt)
        } catch {
            return .failure(error)
        }
    }

    func checkInMeeting(appointmentId: String, lat: Double? = nil, lng: Double? = nil) async -> Result<MeetingCheckInResult, Error> {
        let id = appointmentId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !id.isEmpty else { return .failure(URLError(.badURL)) }
        var body: [String: Any] = [:]
        if let lat, let lng { body["lat"] = lat; body["lng"] = lng }
        do {
            let data = try await postJSON(relativePath: "api/v1/chat/meetings/\(id)/check-in", body: body)
            return .success(parseMeetingCheckInResponse(data))
        } catch let err as CoreServiceHttpException where [404, 405, 501].contains(err.statusCode) {
            return .success(MeetingCheckInResult(endpointAvailable: false, alreadyCheckedIn: false, yourCheckInAt: nil, role: nil, meetingAppointment: nil))
        } catch let error {
            let msg = (error as? CoreServiceHttpException)?.message ?? error.localizedDescription
            if msg.contains("404") || msg.contains("405") || msg.contains("501") {
                return .success(MeetingCheckInResult(endpointAvailable: false, alreadyCheckedIn: false, yourCheckInAt: nil, role: nil, meetingAppointment: nil))
            }
            return .failure(error)
        }
    }

    private func parseMeetingCheckInResponse(_ data: Data) -> MeetingCheckInResult {
        let obj = (try? RepositoryHttp.jsonObject(data)) ?? [:]
        let root = (obj["data"] as? [String: Any]) ?? obj
        let already = RepositoryHttp.optBool(root, "already_checked_in", "AlreadyCheckedIn", default: false)
        let yourAt = RepositoryHttp.optString(root, "your_check_in_at", "YourCheckInAt")
        let yourAtOpt = yourAt.isEmpty ? nil : yourAt
        let role = RepositoryHttp.optString(root, "role", "Role")
        let roleOpt = role.isEmpty ? nil : role
        let apptObj = (root["meeting_appointment"] as? [String: Any]) ?? (root["MeetingAppointment"] as? [String: Any])
        let appt = apptObj.flatMap { parseMeetingAppointmentPayload($0) }
        return MeetingCheckInResult(
            endpointAvailable: true,
            alreadyCheckedIn: already,
            yourCheckInAt: yourAtOpt,
            role: roleOpt,
            meetingAppointment: appt
        )
    }
}
