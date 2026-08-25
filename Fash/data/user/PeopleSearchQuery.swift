import Foundation

/// Strips leading @ so Explore autocomplete "@username" matches GET /users/search.
enum PeopleSearchQuery {
    static func normalize(_ raw: String) -> String {
        var q = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        while q.hasPrefix("@") {
            q = String(q.dropFirst()).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return q
    }
}
