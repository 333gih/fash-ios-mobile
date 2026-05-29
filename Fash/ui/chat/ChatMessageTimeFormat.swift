import Foundation

/// Clock time for chat bubbles (Android `ChatDetailViewModel.formatTime`).
enum ChatMessageTimeFormat {
    static func clockTime(_ raw: String) -> String {
        ChatInstantParse.formatClockTime(raw)
    }
}
