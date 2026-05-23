import SwiftUI

struct ChatScreen: View {
    @Bindable var viewModel: ChatViewModel
    var onConversationTap: (String) -> Void

    var body: some View {
        List(viewModel.conversationIds, id: \.self) { id in
            Button(id) { onConversationTap(id) }
        }
        .listStyle(.plain)
        .task { await viewModel.refresh() }
    }
}
