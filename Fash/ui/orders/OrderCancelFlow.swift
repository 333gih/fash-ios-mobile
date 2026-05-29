import SwiftUI

struct OrderCancelFlowSheet: View {
    let orderId: String
    var onDismiss: () -> Void
    var onSuccess: () -> Void

    @Environment(AppDependencies.self) private var deps
    @State private var selected: OrderCancelReasonOption?
    @State private var note = ""
    @State private var busy = false
    @State private var errorText: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(L10n.orderCancelReasonSubtitle)
                        .font(FashTypography.bodyMedium)
                        .foregroundStyle(FashColors.textSecondary)
                    ForEach(OrderCancelReasons.options) { opt in
                        Button {
                            selected = opt
                        } label: {
                            HStack {
                                Image(systemName: selected?.code == opt.code ? "largecircle.fill.circle" : "circle")
                                    .foregroundStyle(FashColors.brandPrimary)
                                Text(opt.label)
                                    .foregroundStyle(FashColors.textPrimary)
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    if selected?.requiresNote == true {
                        TextField(L10n.orderCancelReasonNoteHint, text: $note, axis: .vertical)
                            .lineLimit(3...6)
                            .textFieldStyle(.roundedBorder)
                    }
                    if let errorText {
                        Text(errorText)
                            .font(FashTypography.bodySmall)
                            .foregroundStyle(.red)
                    }
                    Button {
                        Task { await submit() }
                    } label: {
                        HStack {
                            if busy { ProgressView().scaleEffect(0.85) }
                            Text(L10n.orderCancelConfirmAction)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(FashColors.brandPrimary)
                    .disabled(busy || selected == nil)
                }
                .padding(20)
            }
            .navigationTitle(L10n.orderCancelReasonTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.orderCancelConfirmDismiss) { if !busy { onDismiss() } }
                }
            }
        }
    }

    private func submit() async {
        guard let selected else { return }
        if selected.requiresNote, note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorText = L10n.orderCancelReasonNoteRequired
            return
        }
        busy = true
        errorText = nil
        defer { busy = false }
        switch await deps.orderRepository.cancelOrder(
            orderId: orderId,
            reasonCode: selected.code,
            reasonNote: note
        ) {
        case .success:
            onSuccess()
            onDismiss()
        case .failure(let error):
            errorText = FashErrorPresentation.userMessage(for: error)
        }
    }
}
