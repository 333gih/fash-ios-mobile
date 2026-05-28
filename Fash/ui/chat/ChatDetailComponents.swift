import SwiftUI

// MARK: - Deal banner (STATE B)

struct ChatDealBanner: View {
    let isBuyer: Bool
    let orderStatus: String?
    let agreedAmountVnd: Int64
    let statusSubtitle: String?
    let onViewOrder: () -> Void

    private var norm: String { ChatOrderStatusCopy.normalize(orderStatus) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: onViewOrder) {
                HStack(spacing: 10) {
                    Image(systemName: "bag.fill")
                        .foregroundStyle(FashColors.brandPrimary)
                    Text(ChatOrderStatusCopy.dealBannerTitle(isBuyer: isBuyer, orderStatus: orderStatus))
                        .font(FashTypography.bodySmall.weight(.semibold))
                        .foregroundStyle(FashColors.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(L10n.chatDealBannerViewOrder)
                        .font(FashTypography.labelSmall)
                        .foregroundStyle(FashColors.brandPrimary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)

            if let sub = statusSubtitle, !sub.isEmpty {
                Text(sub)
                    .font(FashTypography.bodySmall)
                    .foregroundStyle(FashColors.textSecondary)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 4)
            }

            if agreedAmountVnd >= 1000, norm == "fulfillment_pending" || norm == "payment_pending" {
                Text(L10n.dealAgreedPriceNegotiated(FeedPriceFormat.format(agreedAmountVnd)))
                    .font(FashTypography.bodySmall)
                    .foregroundStyle(FashColors.textPrimary)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(FashColors.surfaceContainer)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
            }
        }
        .background(FashColors.surfaceContainerHigh)
    }
}

// MARK: - Offer limit policy (buyer)

struct ChatOfferLimitPolicyBanner: View {
    let usedCount: Int
    let maxOffers: Int

    var body: some View {
        if maxOffers < 1 { EmptyView() } else {
            let used = max(0, usedCount)
            let atLimit = used >= maxOffers
            let lastRemaining = !atLimit && maxOffers - used == 1 && maxOffers > 1
            let text: String = {
                if atLimit { return L10n.chatOfferPolicyAtLimit(used, maxOffers) }
                if lastRemaining { return L10n.chatOfferPolicyLast(maxOffers) }
                if used == 0 { return L10n.chatOfferPolicyIntro(maxOffers) }
                return L10n.chatOfferPolicyProgress(used, maxOffers)
            }()
            HStack(spacing: 10) {
                Image(systemName: atLimit ? "exclamationmark.circle" : "info.circle")
                    .foregroundStyle(atLimit ? FashColors.error : FashColors.textSecondary)
                Text(text)
                    .font(FashTypography.bodySmall)
                    .foregroundStyle(atLimit ? FashColors.error : FashColors.textSecondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(atLimit ? FashColors.error.opacity(0.12) : FashColors.surfaceContainerHighest)
        }
    }
}

// MARK: - Offer message card

struct ChatOfferMessageBubble: View {
    let message: ChatMessage
    let isBuyer: Bool
    let hasOrder: Bool
    let isResponding: Bool
    let formatTime: (String) -> String
    let onAccept: () -> Void
    let onDecline: () -> Void
    let onCounter: (() -> Void)?

    private var isCounterOffer: Bool { message.messageType == "counter_offer" }

    private var showSellerActions: Bool {
        !isBuyer && message.offerStatus == "pending" && !message.isFromMe && !hasOrder && !isCounterOffer
    }

    private var showBuyerActionsOnCounter: Bool {
        isBuyer && message.offerStatus == "pending" && !message.isFromMe && !hasOrder && isCounterOffer
    }

    var body: some View {
        VStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "tag.fill")
                        .foregroundStyle(FashColors.brandPrimary)
                    Text(isCounterOffer ? L10n.chatCounterOfferLabel : L10n.chatOfferLabel)
                        .font(FashTypography.labelMedium.weight(.semibold))
                        .foregroundStyle(FashColors.brandPrimary)
                }
                Text(FeedPriceFormat.format(message.offerAmountVnd))
                    .font(FashTypography.headlineSmall.weight(.bold))
                    .foregroundStyle(FashColors.textPrimary)
                ChatOfferStatusBadge(status: message.offerStatus)

                if isBuyer && message.offerStatus == "pending" && message.isFromMe && !isCounterOffer {
                    Text(L10n.chatOfferWaitingSeller)
                        .font(FashTypography.bodySmall.italic())
                        .foregroundStyle(FashColors.textSecondary.opacity(0.7))
                } else if !isBuyer && message.offerStatus == "pending" && message.isFromMe && isCounterOffer {
                    Text(L10n.chatCounterWaitingBuyer)
                        .font(FashTypography.bodySmall.italic())
                        .foregroundStyle(FashColors.textSecondary.opacity(0.7))
                } else if showSellerActions || showBuyerActionsOnCounter {
                    if isResponding {
                        ProgressView().frame(maxWidth: .infinity)
                    } else {
                        HStack(spacing: 10) {
                            Button(L10n.chatOfferDecline, action: onDecline)
                                .font(FashTypography.labelMedium)
                                .foregroundStyle(FashColors.error)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(FashColors.error.opacity(0.6)))
                            Button(L10n.chatOfferAccept, action: onAccept)
                                .font(FashTypography.labelMedium.weight(.semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color(red: 0.18, green: 0.49, blue: 0.20))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        if showSellerActions, let onCounter {
                            Button(L10n.chatOfferCounterCta, action: onCounter)
                                .font(FashTypography.labelMedium)
                                .foregroundStyle(FashColors.brandPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(FashColors.brandPrimary.opacity(0.5)))
                        }
                    }
                }

                Text(formatTime(message.timestamp))
                    .font(FashTypography.labelSmall)
                    .foregroundStyle(FashColors.textSecondary.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(FashColors.surfaceContainerLow)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(FashColors.outlineMuted.opacity(0.68))
            )
        }
        .padding(.horizontal, 4)
    }
}

struct ChatOfferStatusBadge: View {
    let status: String

    var body: some View {
        Text(ChatOfferStatusLabel.text(for: status))
            .font(FashTypography.labelSmall.weight(.semibold))
            .foregroundStyle(foreground)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(background)
            .clipShape(Capsule())
    }

    private var foreground: Color {
        switch status.lowercased() {
        case "accepted": return Color(red: 0.1, green: 0.45, blue: 0.2)
        case "declined": return FashColors.error
        case "pending": return Color(red: 0.72, green: 0.53, blue: 0.04)
        default: return FashColors.textSecondary
        }
    }

    private var background: Color {
        switch status.lowercased() {
        case "accepted": return Color(red: 0.88, green: 0.96, blue: 0.89)
        case "declined": return FashColors.error.opacity(0.12)
        case "pending": return Color(red: 1, green: 0.97, blue: 0.88)
        default: return FashColors.surfaceContainer
        }
    }
}

struct ChatSystemMessageBubble: View {
    let text: String

    var body: some View {
        Text(text)
            .font(FashTypography.bodySmall.italic())
            .foregroundStyle(FashColors.textSecondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
    }
}

struct ChatMeetingProposalCard: View {
    let appointment: MeetingAppointmentPayload
    let formatTime: (String) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.chatMeetingCardTitle)
                .font(FashTypography.labelMedium.weight(.semibold))
                .foregroundStyle(FashColors.brandPrimary)
            if !appointment.scheduledAt.isEmpty {
                Text(appointment.scheduledAt)
                    .font(FashTypography.bodySmall)
                    .foregroundStyle(FashColors.textPrimary)
            }
            if !appointment.locationUrl.isEmpty {
                Text(appointment.locationUrl)
                    .font(FashTypography.bodySmall)
                    .foregroundStyle(FashColors.textSecondary)
                    .lineLimit(2)
            }
            Text(appointment.status.capitalized)
                .font(FashTypography.labelSmall)
                .foregroundStyle(FashColors.textSecondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FashColors.surfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .padding(.horizontal, 4)
    }
}

// MARK: - Sheets

struct ChatOfferPriceSheet: View {
    @Binding var amountText: String
    let listedPriceVnd: Int64
    let isSubmitting: Bool
    let onSubmit: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text(L10n.chatOfferDialogTitle)
                    .font(FashTypography.titleMedium.weight(.bold))
                if listedPriceVnd > 0 {
                    Text(L10n.chatOfferDialogListedPrice(FeedPriceFormat.format(listedPriceVnd)))
                        .font(FashTypography.bodySmall)
                        .foregroundStyle(FashColors.textSecondary)
                }
                Text(L10n.chatOfferDialogHelper)
                    .font(FashTypography.bodySmall)
                    .foregroundStyle(FashColors.textSecondary)
                TextField(L10n.chatOfferDialogPlaceholder, text: $amountText)
                    .keyboardType(.numberPad)
                    .padding(12)
                    .background(FashColors.surfaceContainer)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                FashPrimaryButton(
                    title: L10n.chatOfferDialogSubmit,
                    isLoading: isSubmitting,
                    enabled: parsedAmount != nil
                ) { onSubmit() }
                Spacer()
            }
            .padding(20)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.dialogCancel, action: onDismiss)
                }
            }
        }
    }

    var parsedAmount: Int64? {
        let digits = amountText.filter(\.isNumber)
        guard let v = Int64(digits), v >= 1000 else { return nil }
        return v
    }
}

struct ChatCounterOfferSheet: View {
    let buyerAmountVnd: Int64
    @Binding var amountText: String
    let isSubmitting: Bool
    let onSubmit: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text(L10n.chatCounterSheetTitle)
                    .font(FashTypography.titleMedium.weight(.bold))
                Text(L10n.chatCounterSheetBuyerOffer(FeedPriceFormat.format(buyerAmountVnd)))
                    .font(FashTypography.bodySmall)
                    .foregroundStyle(FashColors.textSecondary)
                TextField(L10n.chatOfferDialogPlaceholder, text: $amountText)
                    .keyboardType(.numberPad)
                    .padding(12)
                    .background(FashColors.surfaceContainer)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                FashPrimaryButton(
                    title: L10n.chatCounterSheetSubmit,
                    isLoading: isSubmitting,
                    enabled: parsedAmount != nil
                ) { onSubmit() }
                Spacer()
            }
            .padding(20)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.dialogCancel, action: onDismiss)
                }
            }
        }
    }

    var parsedAmount: Int64? {
        let digits = amountText.filter(\.isNumber)
        guard let v = Int64(digits), v >= 1000 else { return nil }
        return v
    }
}
