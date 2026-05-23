import Foundation
import Observation

@Observable
@MainActor
final class ChatViewModel {
    var conversationIds: [String] = []
    func refresh() async {}
}
