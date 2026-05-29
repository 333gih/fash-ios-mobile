import SwiftUI

// MARK: - Deal banner (STATE B)

struct ChatDealBanner: View {
    let isBuyer: Bool
    let orderStatus: String?
    let agreedAmountVnd: Int64
    let statusSubtitle: String?
    let onViewOrder: () -> Void
    var onOpenFulfillmentChoice: (() -> Void)?
    var onScheduleMeetup: (() -> Void)?

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

            if isBuyer, norm == "fulfillment_pending", let onOpenFulfillmentChoice {
                dealCtaButton(title: L10n.chatFulfillmentBannerCta, systemImage: "shippingbox", action: onOpenFulfillmentChoice)
            }
            if isBuyer, norm == "cash_meetup_open", let onScheduleMeetup {
                dealCtaButton(title: L10n.chatDealScheduleMeetupCta, systemImage: "calendar", action: onScheduleMeetup)
            }
        }
        .background(FashColors.surfaceContainerHigh)
    }

    private func dealCtaButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                Text(title)
                    .font(FashTypography.labelLarge.weight(.semibold))
            }
            .foregroundStyle(FashColors.brandPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(FashColors.brandPrimary.opacity(0.55)))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
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
    let timestamp: String
    let formatTime: (String) -> String

    var body: some View {
        VStack(spacing: 2) {
            if !text.isEmpty {
                Text(text)
                    .font(FashTypography.bodySmall.italic())
                    .foregroundStyle(FashColors.textSecondary.opacity(0.65))
                    .multilineTextAlignment(.center)
            }
            if !timestamp.isEmpty {
                Text(formatTime(timestamp))
                    .font(FashTypography.labelSmall)
                    .foregroundStyle(FashColors.textSecondary.opacity(0.4))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .padding(.horizontal, 24)
    }
}

// MARK: - Order cancelled card

struct ChatOrderCancelledCardBubble: View {
    let message: ChatMessage
    let payload: OrderCancelledChatPayload
    let isBuyer: Bool
    let formatTime: (String) -> String
    let onViewOrder: () -> Void

    private var whoText: String {
        if payload.cancelledBy.hasPrefix("system") {
            return L10n.chatOrderCancelledBySystem
        }
        if isBuyer, message.isFromMe {
            return L10n.chatMessageOrderCancelledByBuyer
        }
        return L10n.chatOrderCancelledByBuyer
    }

    private var reasonLine: String? {
        let label = OrderCancelReasons.label(forCode: payload.reasonCode)
        if label != payload.reasonCode, !label.isEmpty {
            return L10n.chatOrderCancelledReason(label)
        }
        let note = payload.reasonNote.trimmingCharacters(in: .whitespacesAndNewlines)
        if !note.isEmpty {
            return L10n.chatOrderCancelledReason(note)
        }
        return nil
    }

    var body: some View {
        VStack(spacing: 4) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(FashColors.error)
                    Text(L10n.chatOrderCancelledCardLabel)
                        .font(FashTypography.labelMedium.weight(.semibold))
                        .foregroundStyle(FashColors.error)
                }
                Text(whoText)
                    .font(FashTypography.titleMedium.weight(.semibold))
                    .foregroundStyle(FashColors.textPrimary)
                if let reasonLine {
                    Text(reasonLine)
                        .font(FashTypography.bodyMedium)
                        .foregroundStyle(FashColors.textSecondary)
                }
                if payload.amountVnd > 0 {
                    Text(FeedPriceFormat.format(payload.amountVnd))
                        .font(FashTypography.headlineSmall.weight(.bold))
                        .foregroundStyle(FashColors.textPrimary)
                }
                Button(action: onViewOrder) {
                    Text(L10n.chatOrderCancelledViewOrder)
                        .font(FashTypography.labelLarge)
                        .foregroundStyle(FashColors.brandPrimary)
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(FashColors.surfaceContainerLow)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(FashColors.error.opacity(0.45), lineWidth: 1)
            )

            Text(formatTime(message.timestamp))
                .font(FashTypography.labelSmall)
                .foregroundStyle(FashColors.textSecondary.opacity(0.6))
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Meeting proposal card

struct ChatMeetingProposalCard: View {
    let message: ChatMessage
    let appointment: MeetingAppointmentPayload
    let isViewerBuyer: Bool
    let hasLinkedEscrowOrder: Bool
    let formatTime: (String) -> String
    let mutationInFlight: Bool
    let onConfirm: () -> Void
    let onWithdrawOrReject: () -> Void
    var onOnMyWay: (() -> Void)?
    var onCheckIn: (() -> Void)?

    private var status: String { appointment.status.lowercased() }
    private var preferVi: Bool { AppLocale.currentTag != AppLocale.tagEN }

    private var myCheckInAt: String {
        isViewerBuyer ? appointment.buyerCheckInAt : appointment.sellerCheckInAt
    }

    private var otherCheckInAt: String {
        isViewerBuyer ? appointment.sellerCheckInAt : appointment.buyerCheckInAt
    }

    private var myOnMyWayAt: String {
        isViewerBuyer ? appointment.buyerOnMyWayAt : appointment.sellerOnMyWayAt
    }

    private var otherOnMyWayAt: String {
        isViewerBuyer ? appointment.sellerOnMyWayAt : appointment.buyerOnMyWayAt
    }

    private var showOnMyWayCta: Bool {
        status == "confirmed" && onOnMyWay != nil && myOnMyWayAt.isEmpty && myCheckInAt.isEmpty
    }

    private var showCheckInCta: Bool {
        status == "confirmed"
            && onCheckIn != nil
            && myCheckInAt.isEmpty
            && !myOnMyWayAt.isEmpty
            && MeetingUi.isWithinMeetingActionWindow(scheduledAtIso: appointment.scheduledAt)
    }

    private var showConfirm: Bool { status == "pending" && !appointment.isProposerMe }
    private var showWithdraw: Bool { status == "pending" && appointment.isProposerMe }

    var body: some View {
        VStack(spacing: 4) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: 18))
                        .foregroundStyle(FashColors.brandPrimary)
                    Text(L10n.chatMeetingCardTitle)
                        .font(FashTypography.labelMedium.weight(.semibold))
                        .foregroundStyle(FashColors.brandPrimary)
                }

                Text(MeetingUi.meetingStatusLabel(status))
                    .font(FashTypography.labelMedium.weight(.semibold))
                    .foregroundStyle(MeetingUi.meetingStatusChipForeground(status))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(MeetingUi.meetingStatusChipBackground(status))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                Text(MeetingUi.meetingStateDescription(status))
                    .font(FashTypography.bodySmall)
                    .foregroundStyle(FashColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                if !appointment.scheduledAt.isEmpty {
                    Text(MeetingUi.formatMeetingWhen(appointment.scheduledAt, preferVi: preferVi))
                        .font(FashTypography.bodyMedium)
                        .foregroundStyle(FashColors.textPrimary)
                }

                if !appointment.safeZoneName.isEmpty {
                    Text(appointment.safeZoneName)
                        .font(FashTypography.bodySmall.weight(.medium))
                        .foregroundStyle(FashColors.textPrimary)
                }

                if !appointment.locationUrl.isEmpty, let url = URL(string: appointment.locationUrl) {
                    Button {
                        UIApplication.shared.open(url)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.up.right.square")
                            Text(L10n.chatMeetingOpenMaps)
                        }
                        .font(FashTypography.labelLarge)
                        .foregroundStyle(FashColors.brandPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(FashColors.brandPrimary.opacity(0.5), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(mutationInFlight)
                } else if status == "confirmed" {
                    Text(L10n.chatMeetingConfirmedNoMapsHint)
                        .font(FashTypography.bodySmall)
                        .foregroundStyle(FashColors.textSecondary.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)
                }

                if status == "confirmed", !myOnMyWayAt.isEmpty {
                    Text(L10n.meetingSelfOnMyWay)
                        .font(FashTypography.bodySmall.weight(.medium))
                        .foregroundStyle(FashColors.brandPrimary)
                }
                if status == "confirmed", !otherOnMyWayAt.isEmpty {
                    Text(L10n.meetingOtherOnMyWay)
                        .font(FashTypography.bodySmall.weight(.medium))
                        .foregroundStyle(FashColors.brandPrimary)
                }

                if status == "confirmed", !otherCheckInAt.isEmpty || !myCheckInAt.isEmpty {
                    Divider().opacity(0.4)
                    if !otherCheckInAt.isEmpty {
                        Text(L10n.chatMeetingOtherCheckedInAt(formatTime(otherCheckInAt)))
                            .font(FashTypography.bodySmall)
                            .foregroundStyle(FashColors.textSecondary)
                    }
                    if !myCheckInAt.isEmpty {
                        Text(L10n.chatMeetingYouCheckedInAt(formatTime(myCheckInAt)))
                            .font(FashTypography.bodySmall.weight(.medium))
                            .foregroundStyle(FashColors.textPrimary)
                    }
                }

                if status == "confirmed", hasLinkedEscrowOrder {
                    Text(L10n.chatMeetingCheckInNotOrderComplete)
                        .font(FashTypography.bodySmall)
                        .foregroundStyle(FashColors.textSecondary)
                    Text(isViewerBuyer
                        ? L10n.chatMeetingNextStepsBuyerAfterCheckIn
                        : L10n.chatMeetingNextStepsSellerAfterCheckIn)
                        .font(FashTypography.bodySmall)
                        .foregroundStyle(FashColors.textSecondary)
                }

                if showOnMyWayCta, let onOnMyWay {
                    meetingOutlineButton(title: L10n.meetingOnMyWay, action: onOnMyWay)
                }

                if showCheckInCta, let onCheckIn {
                    Divider().opacity(0.4)
                    Text(L10n.chatMeetingCheckInWindowHint)
                        .font(FashTypography.labelSmall)
                        .foregroundStyle(FashColors.textSecondary.opacity(0.85))
                    meetingPrimaryButton(title: L10n.chatMeetingCheckInCta, action: onCheckIn)
                }

                if showConfirm || showWithdraw {
                    Divider().opacity(0.4)
                    if showConfirm {
                        meetingOutlineButton(title: L10n.chatMeetingReject, action: onWithdrawOrReject)
                        meetingPrimaryButton(title: L10n.chatMeetingConfirm, action: onConfirm)
                    } else {
                        meetingOutlineButton(title: L10n.chatMeetingWithdraw, action: onWithdrawOrReject)
                    }
                }

                Text(formatTime(message.timestamp))
                    .font(FashTypography.labelSmall)
                    .foregroundStyle(FashColors.textSecondary.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(FashColors.surfaceContainerLow)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(FashColors.outlineMuted.opacity(0.68))
            )
        }
        .padding(.horizontal, 4)
    }

    private func meetingOutlineButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            meetingButtonLabel(title: title, inverted: false)
        }
        .buttonStyle(.plain)
        .disabled(mutationInFlight)
    }

    private func meetingPrimaryButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            meetingButtonLabel(title: title, inverted: true)
        }
        .buttonStyle(.plain)
        .disabled(mutationInFlight)
    }

    @ViewBuilder
    private func meetingButtonLabel(title: String, inverted: Bool) -> some View {
        ZStack {
            if mutationInFlight {
                ProgressView()
                    .tint(inverted ? .white : FashColors.brandPrimary)
            }
            Text(title)
                .font(FashTypography.labelLarge.weight(.semibold))
                .opacity(mutationInFlight ? 0 : 1)
        }
        .foregroundStyle(inverted ? Color.white : FashColors.brandPrimary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background {
            if inverted {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(FashColors.brandPrimary)
            } else {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(inverted ? Color.clear : FashColors.brandPrimary.opacity(0.45), lineWidth: 1)
            }
        }
    }
}

// MARK: - Sheets

struct ChatOfferPriceSheet: View {
    @Binding var amountText: String
    let listedPriceVnd: Int64
    var validationError: String?
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
                if let validationError, !validationError.isEmpty {
                    Text(validationError)
                        .font(FashTypography.bodySmall)
                        .foregroundStyle(FashColors.error)
                }
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
                    Button(L10n.createListingCancel, action: onDismiss)
                }
            }
        }
    }

    var parsedAmount: Int64? {
        let digits = amountText.filter(\.isNumber)
        guard let v = Int64(digits), v >= 1000 else { return nil }
        if listedPriceVnd > 0, v >= listedPriceVnd { return nil }
        return v
    }
}

struct ChatCounterOfferSheet: View {
    let buyerAmountVnd: Int64
    @Binding var amountText: String
    let listedPriceVnd: Int64
    var validationError: String?
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
                if listedPriceVnd > 0 {
                    Text(L10n.chatOfferDialogListedPrice(FeedPriceFormat.format(listedPriceVnd)))
                        .font(FashTypography.bodySmall)
                        .foregroundStyle(FashColors.textSecondary)
                }
                TextField(L10n.chatOfferDialogPlaceholder, text: $amountText)
                    .keyboardType(.numberPad)
                    .padding(12)
                    .background(FashColors.surfaceContainer)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                if let validationError, !validationError.isEmpty {
                    Text(validationError)
                        .font(FashTypography.bodySmall)
                        .foregroundStyle(FashColors.error)
                }
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
                    Button(L10n.createListingCancel, action: onDismiss)
                }
            }
        }
    }

    var parsedAmount: Int64? {
        let digits = amountText.filter(\.isNumber)
        guard let v = Int64(digits), v >= 1000 else { return nil }
        if buyerAmountVnd > 0, v <= buyerAmountVnd { return nil }
        if listedPriceVnd > 0, v >= listedPriceVnd { return nil }
        return v
    }
}

// MARK: - Typing indicator (Android `TypingIndicator`)

struct ChatTypingIndicator: View {
    let displayName: String

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            Circle()
                .fill(FashColors.brandPrimary.opacity(0.1))
                .frame(width: 28, height: 28)
                .overlay {
                    FashDefaultProfileAvatar()
                        .clipShape(Circle())
                }
            VStack(alignment: .leading, spacing: 3) {
                Text(displayName)
                    .font(FashTypography.labelSmall)
                    .foregroundStyle(FashColors.textSecondary.opacity(0.55))
                    .padding(.leading, 2)
                ChatTypingDots()
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                    .background(FashColors.surfaceContainerHigh)
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 18,
                            bottomLeadingRadius: 4,
                            bottomTrailingRadius: 18,
                            topTrailingRadius: 18
                        )
                    )
            }
            Spacer(minLength: 48)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }
}

private struct ChatTypingDots: View {
    @State private var animating = false

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(FashColors.textSecondary.opacity(0.55))
                    .frame(width: 8, height: 8)
                    .scaleEffect(animating ? 1 : 0.5)
                    .animation(
                        .easeInOut(duration: 0.42)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.11),
                        value: animating
                    )
            }
        }
        .frame(height: 16)
        .onAppear { animating = true }
    }
}
