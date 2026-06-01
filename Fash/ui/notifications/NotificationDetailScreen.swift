import SwiftUI

struct NotificationDetailScreen: View {
    @Environment(AppDependencies.self) private var deps
    let item: InboxNotificationItem
    var onDismiss: () -> Void
    var onOpenOrder: (String) -> Void = { _ in }
    var onOpenListing: (String, String?) -> Void = { _, _ in }
    var onOpenChat: (String) -> Void = { _ in }
    var onOpenFollowConnections: (Int) -> Void = { _ in }
    var onOpenExplore: () -> Void = {}
    var onOpenInviteFriends: () -> Void = {}

    @State private var showRawPayload = false
    @State private var promoGalleryIndex = 0

    private var promoCampaign: AppPromoCampaign? {
        NotificationPromoDetail.parseAppPromoCampaignFromInbox(item)
    }

    private var actions: NotificationDetailActions {
        NotificationNavigation.parseNotificationDetailActions(item)
    }

    private var payloadLines: [NotificationDetailPayload.FriendlyLine] {
        NotificationDetailPayload.buildFriendlyLines(item)
    }

    private var rawPayloadDump: String {
        NotificationDetailPayload.buildRawPayloadDump(item.dataMap)
    }

    private var displayTitle: String {
        if let title = promoCampaign?.remoteTitle?.trimmingCharacters(in: .whitespacesAndNewlines), !title.isEmpty {
            return title
        }
        return item.title.isEmpty ? L10n.notificationDetailNoTitle : item.title
    }

    private var displayBody: String {
        if let body = promoCampaign?.remoteMessage?.trimmingCharacters(in: .whitespacesAndNewlines), !body.isEmpty {
            return body
        }
        return item.body
    }

    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 16) {
                mediaSection
                badgeSection
                Text(displayTitle)
                    .font(FashTypography.titleMedium.weight(.semibold))
                    .foregroundStyle(FashColors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                if !displayBody.isEmpty {
                    Text(displayBody)
                        .font(FashTypography.bodyLarge)
                        .foregroundStyle(FashColors.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                promoCtaSection
                richDetailSection
                timestampSection
                Divider().overlay(FashColors.outlineMuted.opacity(0.35))
                actionsSection
                Divider().overlay(FashColors.outlineMuted.opacity(0.35))
                metadataSection
                friendlyPayloadSection
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
        }
        .scrollBounceBehavior(.basedOnSize, axes: .vertical)
        .background(FashColors.screen)
        .navigationTitle(L10n.notificationDetailTitle)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: onDismiss) {
                    FashBackButton.toolbarLabel()
                }
                .accessibilityLabel(L10n.cdBack)
            }
        }
    }

    @ViewBuilder
    private var mediaSection: some View {
        if let promo = promoCampaign {
            let urls = promo.remoteImageUrls.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            if urls.count == 1 {
                boundedNotificationHeroImage(url: urls[0], height: 220)
            } else if urls.count > 1 {
                TabView(selection: $promoGalleryIndex) {
                    ForEach(Array(urls.enumerated()), id: \.offset) { index, raw in
                        boundedNotificationHeroImage(url: raw, height: 220)
                            .tag(index)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .tabViewStyle(.page(indexDisplayMode: .automatic))
                .accessibilityLabel(L10n.notificationDetailPromoGalleryCd(promoGalleryIndex + 1, urls.count))
            }
        } else if let raw = actions.imageUrl {
            boundedNotificationHeroImage(url: raw, height: 200)
        }
    }

    /// Wide promo banners must not expand the scroll view horizontally (intrinsic image width).
    private func boundedNotificationHeroImage(url: String, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(FashColors.surfaceContainerHigh)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .overlay {
                FashAsyncImage(url: url, contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            }
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    @ViewBuilder
    private var badgeSection: some View {
        if let badge = RemoteAppPromoModels.sanitizePromoDisplayString(promoCampaign?.remoteBadge) {
            Text(badge)
                .font(FashTypography.labelSmall.weight(.semibold))
                .foregroundStyle(FashColors.brandPrimary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(FashColors.brandPrimary.opacity(0.12))
                .clipShape(Capsule())
        }
    }

    @ViewBuilder
    private var promoCtaSection: some View {
        if let promo = promoCampaign {
            VStack(spacing: 8) {
                if let primary = RemoteAppPromoModels.sanitizePromoDisplayString(promo.remotePrimaryLabel),
                   promo.primaryAction != nil {
                    Button(primary) {
                        applyPromoPrimary(promo)
                    }
                    .font(FashTypography.labelLarge.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .foregroundStyle(FashColors.readableOnBrandPrimary)
                    .background(FashColors.brandPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                if let secondary = RemoteAppPromoModels.sanitizePromoDisplayString(promo.remoteSecondaryLabel),
                   promo.secondaryAction != nil {
                    Button(secondary) {
                        applyPromoSecondary(promo)
                    }
                    .font(FashTypography.labelLarge)
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(FashColors.textSecondary)
                }
            }
        }
    }

    @ViewBuilder
    private var richDetailSection: some View {
        if promoCampaign == nil,
           let extra = actions.richDetailBody?.trimmingCharacters(in: .whitespacesAndNewlines),
           !extra.isEmpty,
           extra != item.body {
            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.notificationDetailMoreLabel)
                    .font(FashTypography.labelLarge.weight(.semibold))
                    .foregroundStyle(FashColors.textPrimary)
                Text(extra)
                    .font(FashTypography.bodyMedium)
                    .foregroundStyle(FashColors.textPrimary)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(FashColors.surfaceContainerLow)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    @ViewBuilder
    private var timestampSection: some View {
        if !item.createdAtIso.isEmpty {
            Text(L10n.notificationDetailTime(formatNotificationInstant(item.createdAtIso)))
                .font(FashTypography.bodySmall)
                .foregroundStyle(FashColors.textSecondary)
        }
        if let readAt = item.readAtIso, !readAt.isEmpty {
            Text(L10n.notificationDetailReadAt(formatNotificationInstant(readAt)))
                .font(FashTypography.bodySmall)
                .foregroundStyle(FashColors.textSecondary)
        }
    }

    @ViewBuilder
    private var actionsSection: some View {
        let hasActions = actions.orderId != nil
            || actions.listingId != nil
            || actions.conversationId != nil
            || actions.openFollowersTab
            || actions.openFollowingTab
            || actions.openExploreTab
            || actions.openInviteFriends
        if hasActions {
            Text(L10n.notificationDetailActionsHeading)
                .font(FashTypography.labelLarge.weight(.semibold))
                .foregroundStyle(FashColors.textPrimary)
            VStack(spacing: 8) {
                if let orderId = actions.orderId {
                    actionButton(L10n.notificationActionOpenOrder) { onOpenOrder(orderId) }
                }
                if let listingId = actions.listingId {
                    actionButton(L10n.notificationActionOpenListing) {
                        onOpenListing(listingId, actions.sellerUserId)
                    }
                }
                if let conversationId = actions.conversationId {
                    actionButton(L10n.notificationActionOpenChat) { onOpenChat(conversationId) }
                }
                if actions.openFollowersTab {
                    actionButton(L10n.notificationActionOpenFollowers) { onOpenFollowConnections(1) }
                }
                if actions.openFollowingTab {
                    actionButton(L10n.notificationActionOpenFollowing) { onOpenFollowConnections(0) }
                }
                if actions.openExploreTab {
                    actionButton(L10n.notificationActionOpenExplore, action: onOpenExplore)
                }
                if actions.openInviteFriends {
                    actionButton(L10n.notificationActionOpenInviteFriends, action: onOpenInviteFriends)
                }
            }
        }
    }

    @ViewBuilder
    private var metadataSection: some View {
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
        if let sourceEventId = item.sourceEventId, !sourceEventId.isEmpty {
            detailRow(L10n.notificationDetailSourceEvent, sourceEventId)
        }
    }

    @ViewBuilder
    private var friendlyPayloadSection: some View {
        if promoCampaign == nil,
           item.dataMap != nil,
           !payloadLines.isEmpty || !rawPayloadDump.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text(L10n.notificationDetailPayloadTitle)
                    .font(FashTypography.labelLarge.weight(.semibold))
                    .foregroundStyle(FashColors.textPrimary)
                if payloadLines.isEmpty, !rawPayloadDump.isEmpty {
                    Text(L10n.notificationDataRawOnlyHint)
                        .font(FashTypography.bodySmall)
                        .foregroundStyle(FashColors.textSecondary)
                } else {
                    ForEach(Array(payloadLines.enumerated()), id: \.offset) { index, line in
                        if index > 0 {
                            Divider().overlay(FashColors.outlineMuted.opacity(0.25))
                        }
                        payloadLineView(line)
                    }
                }
                if !rawPayloadDump.isEmpty {
                    Button(showRawPayload ? L10n.notificationDataHideRaw : L10n.notificationDataShowRaw) {
                        showRawPayload.toggle()
                    }
                    .font(FashTypography.labelLarge)
                    .foregroundStyle(FashColors.brandPrimary)
                    if showRawPayload {
                        Text(rawPayloadDump)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(FashColors.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(12)
                            .background(FashColors.surfaceContainer)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(FashColors.surfaceContainerLow)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    @ViewBuilder
    private func payloadLineView(_ line: NotificationDetailPayload.FriendlyLine) -> some View {
        switch line {
        case .text(let label, let value):
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(FashTypography.labelMedium)
                    .foregroundStyle(FashColors.textSecondary)
                switch value {
                case .plain(let text):
                    Text(text)
                        .font(FashTypography.bodyMedium)
                        .foregroundStyle(FashColors.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                case .titleWithId(let title, let id):
                    Text(L10n.notificationDataTitleWithId(title, id))
                        .font(FashTypography.bodyMedium)
                        .foregroundStyle(FashColors.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        case .nav(let label, let rawNav):
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(FashTypography.labelMedium)
                    .foregroundStyle(FashColors.textSecondary)
                Text(NotificationDetailPayload.navTargetDisplay(rawNav))
                    .font(FashTypography.bodyMedium)
                    .foregroundStyle(FashColors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func actionButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(FashTypography.labelLarge)
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.bordered)
        .tint(FashColors.brandPrimary)
    }

    private func applyPromoPrimary(_ promo: AppPromoCampaign) {
        guard let router = deps.navigationRouter else { return }
        router.dismissNotifications {
            AppPromoNavigation.applyPrimary(campaign: promo, router: router)
        }
    }

    private func applyPromoSecondary(_ promo: AppPromoCampaign) {
        guard let router = deps.navigationRouter else { return }
        router.dismissNotifications {
            AppPromoNavigation.applySecondary(campaign: promo, router: router)
        }
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(FashTypography.labelMedium)
                .foregroundStyle(FashColors.textSecondary)
            Text(value)
                .font(FashTypography.bodyMedium)
                .foregroundStyle(FashColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
