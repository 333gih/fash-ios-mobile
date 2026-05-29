import Foundation

/// Emits when a conversation was marked read in [ChatDetailViewModel] so [ChatViewModel] can refresh
/// the global unread badge and inbox rows without waiting for realtime or back navigation.
enum ChatUnreadRefreshHub {
    private static var continuation: AsyncStream<Void>.Continuation?
    static let signals: AsyncStream<Void> = AsyncStream { continuation = $0 }

    static func notifyMarkedRead() {
        continuation?.yield(())
    }
}
