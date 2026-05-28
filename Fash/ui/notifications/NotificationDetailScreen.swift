import SwiftUI

struct NotificationDetailScreen: View {
    let item: InboxNotificationItem
    var onDismiss: () -> Void
    var onOpenOrder: (String) -> Void = { _ in }
    var onOpenListing: (String) -> Void = { _ in }
    var onOpenChat: (String) -> Void = { _ in }

    @State private var showRawPayload = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(displayTitle)
                    .font(FashTypography.headlineMedium)
                    .foregroundStyle(FashColors.textPrimary)
                if !displayBody.isEmpty {
                    Text(displayBody)
                        .font(FashTypography.bodyMedium)
                        .foregroundStyle(FashColors.textSecondary)
                }
                if !item.createdAtIso.isEmpty {
                    Text(L10n.notificationDetailTime(item.createdAtIso))
                        .font(FashTypography.labelSmall)
                        .foregroundStyle(FashColors.textSecondary)
                }
                if let readAt = item.readAtIso, !readAt.isEmpty {
                    Text(L10n.notificationDetailReadAt(readAt))
                        .font(FashTypography.labelSmall)
                        .foregroundStyle(FashColors.textSecondary)
                }
                if let actions = parsedActions, !actions.isEmpty {
                    Text(L10n.notificationDetailActionsHeading)
                        .font(FashTypography.titleSmall)
                        .foregroundStyle(FashColors.textPrimary)
                    ForEach(actions, id: \.title) { action in
                        Button(action.title) { handleAction(action) }
                            .font(FashTypography.labelLarge)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(FashColors.surfaceContainer)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
                if let payloadType = item.payloadType, !payloadType.isEmpty {
                    detailRow(
                        L10n.notificationDetailPayloadType,
                        NotificationInboxLabels.payloadTypeLabel(payloadType) ?? payloadType
                    )
                }
                if let source = item.source, !source.isEmpty {
                    detailRow(
                        L10n.notificationDetailSource,
                        NotificationInboxLabels.sourceLabel(source) ?? source
                    )
                }
                if item.dataMap != nil {
                    Button(showRawPayload ? L10n.notificationDetailMoreLabel : L10n.notificationDetailPayloadTitle) {
                        showRawPayload.toggle()
                    }
                    .font(FashTypography.labelLarge)
                    .foregroundStyle(FashColors.brandPrimary)
                    if showRawPayload, let dump = rawPayloadDump {
                        Text(dump)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(FashColors.textSecondary)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(FashColors.surfaceContainer)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
            }
            .padding(20)
        }
        .background(FashColors.screen)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: onDismiss) {
                    Image(systemName: "chevron.left")
                }
            }
        }
    }

    private var displayTitle: String {
        item.title.isEmpty ? L10n.notificationDetailNoTitle : item.title
    }

    private var displayBody: String {
        item.body
    }

    private var rawPayloadDump: String? {
        guard let map = item.dataMap,
              let data = try? JSONSerialization.data(withJSONObject: map, options: [.prettyPrinted, .sortedKeys]),
              let text = String(data: data, encoding: .utf8) else { return nil }
        return text
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(FashTypography.labelSmall)
                .foregroundStyle(FashColors.textSecondary)
            Text(value)
                .font(FashTypography.bodyMedium)
                .foregroundStyle(FashColors.textPrimary)
        }
    }

    private struct NotificationAction {
        let title: String
        let kind: String
        let payload: String
    }

    private var parsedActions: [NotificationAction]? {
        guard let map = item.dataMap else { return nil }
        var actions: [NotificationAction] = []
        if let orderId = stringValue(map, "order_id", "orderId") {
            actions.append(.init(title: L10n.notificationActionOpenOrder, kind: "order", payload: orderId))
        }
        if let listingId = stringValue(map, "listing_id", "listingId") {
            actions.append(.init(title: L10n.notificationActionOpenListing, kind: "listing", payload: listingId))
        }
        if let convId = stringValue(map, "conversation_id", "conversationId") {
            actions.append(.init(title: L10n.notificationActionOpenChat, kind: "chat", payload: convId))
        }
        return actions.isEmpty ? nil : actions
    }

    private func stringValue(_ map: [String: Any], _ keys: String...) -> String? {
        for key in keys {
            if let v = map[key] as? String, !v.isEmpty { return v }
        }
        return nil
    }

    private func handleAction(_ action: NotificationAction) {
        switch action.kind {
        case "order": onOpenOrder(action.payload)
        case "listing": onOpenListing(action.payload)
        case "chat": onOpenChat(action.payload)
        default: break
        }
    }
}
