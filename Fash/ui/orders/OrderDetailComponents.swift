import SwiftUI

enum OrderDetailComponents {
    static func statusBadge(_ status: String) -> some View {
        Text(OrderFormatting.statusLabel(status))
            .font(FashTypography.labelSmall.weight(.semibold))
            .foregroundStyle(FashColors.brandPrimary)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(FashColors.brandPrimary.opacity(0.12))
            .clipShape(Capsule())
    }

    static func sectionCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FashColors.surfaceContainer)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    static func stickyOutlineButton(
        title: String,
        isBusy: Bool,
        enabled: Bool = true,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isBusy {
                    ProgressView().scaleEffect(0.85)
                }
                Text(title)
                    .font(FashTypography.labelLarge.weight(.medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(FashColors.outlineMuted.opacity(0.45), lineWidth: 1)
            )
        }
        .foregroundStyle(FashColors.textPrimary)
        .disabled(!enabled || isBusy)
    }

    static func infoRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(FashTypography.bodySmall)
                .foregroundStyle(FashColors.textSecondary)
            Spacer(minLength: 12)
            Text(value)
                .font(FashTypography.bodyMedium)
                .foregroundStyle(FashColors.textPrimary)
                .multilineTextAlignment(.trailing)
        }
    }

    static func heroCard(detail: OrderDetailPayload, role: OrderViewerRole) -> some View {
        let hero = OrderDetailLogic.heroContent(detail, role: role, formatDate: OrderFormatting.formatShortDate)
        return sectionCard {
            HStack(spacing: 8) {
                Circle().fill(FashColors.brandPrimary).frame(width: 8, height: 8)
                Text(L10n.orderDetailStatusCaption)
                    .font(FashTypography.labelSmall)
                    .foregroundStyle(FashColors.textSecondary)
            }
            Text(hero.title)
                .font(FashTypography.headlineSmall.weight(.bold))
                .foregroundStyle(hero.useAccent ? FashColors.brandPrimary : FashColors.textPrimary)
            if !hero.subtitle.isEmpty {
                Text(hero.subtitle)
                    .font(FashTypography.bodySmall)
                    .foregroundStyle(FashColors.textSecondary)
            }
        }
    }

    static func timelineSection(detail: OrderDetailPayload) -> some View {
        let steps = OrderDetailLogic.timelineSteps(detail, formatDate: OrderFormatting.formatShortDate)
        return sectionCard {
            Text(L10n.orderTimelineTitle)
                .font(FashTypography.labelSmall)
                .foregroundStyle(FashColors.textSecondary)
            ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                timelineRow(step: step, isLast: index == steps.count - 1)
            }
        }
    }

    private static func timelineRow(step: TimelineStepUi, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 0) {
                Image(systemName: step.state == .done ? "checkmark.circle.fill" : "circle.fill")
                    .foregroundStyle(FashColors.brandPrimary)
                if !isLast {
                    Rectangle()
                        .fill(FashColors.brandPrimary.opacity(0.35))
                        .frame(width: 2, height: 28)
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(step.title)
                    .font(FashTypography.bodyMedium.weight(.semibold))
                    .foregroundStyle(FashColors.textPrimary)
                if !step.subtitle.isEmpty {
                    Text(step.subtitle)
                        .font(FashTypography.bodySmall)
                        .foregroundStyle(FashColors.textSecondary)
                }
            }
            Spacer(minLength: 0)
        }
    }

    static func meetupDeadlineStrip(detail: OrderDetailPayload) -> some View {
        let raw = detail.meetupDeadlineAt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty,
              OrderFormatting.normalizeStatus(detail.status) == "payment_pending" else {
            return AnyView(EmptyView())
        }
        return AnyView(
            sectionCard {
                Text(L10n.orderDetailMeetupPayBy(OrderFormatting.formatShortDate(raw)))
                    .font(FashTypography.bodyMedium.weight(.semibold))
                    .foregroundStyle(FashColors.brandPrimary)
            }
        )
    }

    static func meetingSection(detail: OrderDetailPayload) -> some View {
        guard let appt = detail.meetingAppointment else { return AnyView(EmptyView()) }
        return AnyView(
            sectionCard {
                Text(L10n.orderDetailMeetupSectionTitle)
                    .font(FashTypography.titleSmall.weight(.semibold))
                if !appt.status.isEmpty {
                    Text(L10n.orderDetailMeetupStatus(OrderFormatting.statusLabel(appt.status)))
                        .font(FashTypography.bodyMedium)
                }
                if !appt.scheduledAt.isEmpty {
                    Text(L10n.orderDetailMeetupWhen(OrderFormatting.formatShortDate(appt.scheduledAt)))
                        .font(FashTypography.bodyMedium)
                }
                if !appt.buyerCheckInAt.isEmpty {
                    Text(L10n.orderDetailMeetupBuyerCheckIn(OrderFormatting.formatShortDate(appt.buyerCheckInAt)))
                        .font(FashTypography.bodySmall)
                        .foregroundStyle(FashColors.textSecondary)
                }
                if !appt.sellerCheckInAt.isEmpty {
                    Text(L10n.orderDetailMeetupSellerCheckIn(OrderFormatting.formatShortDate(appt.sellerCheckInAt)))
                        .font(FashTypography.bodySmall)
                        .foregroundStyle(FashColors.textSecondary)
                }
                Text(L10n.orderDetailMeetupCheckInNote)
                    .font(FashTypography.bodySmall)
                    .foregroundStyle(FashColors.textSecondary)
                if !appt.locationUrl.isEmpty, let url = URL(string: appt.locationUrl) {
                    Link(destination: url) {
                        Label(L10n.orderDetailMeetupOpenMaps, systemImage: "arrow.up.right.square")
                            .font(FashTypography.labelLarge)
                            .foregroundStyle(FashColors.brandPrimary)
                    }
                }
                let reminder = appt.reminderEnabled
                    ? L10n.orderDetailMeetupReminderOn(appt.reminderOffsetMinutes)
                    : L10n.orderDetailMeetupReminderOff
                Text(reminder)
                    .font(FashTypography.bodySmall)
                    .foregroundStyle(FashColors.textSecondary)
                if !appt.createdAt.isEmpty || !appt.updatedAt.isEmpty || !appt.reminderSentAt.isEmpty {
                    Text(L10n.orderDetailMeetupActivityTitle)
                        .font(FashTypography.labelMedium.weight(.semibold))
                        .padding(.top, 4)
                    if !appt.createdAt.isEmpty {
                        Text(L10n.orderDetailMeetupCreated(OrderFormatting.formatShortDate(appt.createdAt)))
                            .font(FashTypography.bodySmall)
                            .foregroundStyle(FashColors.textSecondary)
                    }
                    if !appt.reminderSentAt.isEmpty {
                        Text(L10n.orderDetailMeetupReminderSent(OrderFormatting.formatShortDate(appt.reminderSentAt)))
                            .font(FashTypography.bodySmall)
                            .foregroundStyle(FashColors.textSecondary)
                    }
                    if !appt.updatedAt.isEmpty {
                        Text(L10n.orderDetailMeetupUpdated(OrderFormatting.formatShortDate(appt.updatedAt)))
                            .font(FashTypography.bodySmall)
                            .foregroundStyle(FashColors.textSecondary)
                    }
                }
            }
        )
    }

    static func meetingGraceSection(
        detail: OrderDetailPayload,
        role: OrderViewerRole,
        busy: OrderDetailBusyAction,
        onCheckIn: @escaping () -> Void,
        onNoShow: @escaping () -> Void,
        onAckCash: @escaping () -> Void
    ) -> some View {
        guard let grace = detail.meetingGrace else { return AnyView(EmptyView()) }
        let isBuyer = role == .buyer
        let showCheckIn = grace.viewerShouldShowCheckIn(isBuyer: isBuyer, appointment: detail.meetingAppointment)
        return AnyView(
            sectionCard {
                Text(L10n.orderDetailMeetingGraceTitle)
                    .font(FashTypography.titleSmall.weight(.semibold))
                if !grace.checkInHint.isEmpty {
                    Text(grace.checkInHint)
                        .font(FashTypography.bodySmall)
                        .foregroundStyle(FashColors.textSecondary)
                }
                if !grace.buyerCheckedInAt.isEmpty {
                    Text(L10n.orderDetailGraceBuyerChecked(OrderFormatting.formatShortDate(grace.buyerCheckedInAt)))
                        .font(FashTypography.bodySmall)
                }
                if !grace.sellerCheckedInAt.isEmpty {
                    Text(L10n.orderDetailGraceSellerChecked(OrderFormatting.formatShortDate(grace.sellerCheckedInAt)))
                        .font(FashTypography.bodySmall)
                }
                if grace.sosUnlocked {
                    Text(L10n.orderDetailGraceSosUnlocked)
                        .font(FashTypography.bodySmall.weight(.semibold))
                        .foregroundStyle(FashColors.brandPrimary)
                }
                if showCheckIn {
                    Button(action: onCheckIn) {
                        HStack {
                            if busy == .checkIn { ProgressView().scaleEffect(0.85) }
                            Text(L10n.orderDetailCheckInCta)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(FashColors.brandPrimary)
                    .disabled(busy != .none)
                }
                if detail.canAcknowledgeOfflineCash, role == .seller {
                    Button(action: onAckCash) {
                        HStack {
                            if busy == .acknowledgeCash { ProgressView().scaleEffect(0.85) }
                            Text(L10n.orderDetailAckOfflineCash)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(busy != .none)
                }
                if grace.canReportNoShow {
                    Button(L10n.orderDetailReportNoShowCta, action: onNoShow)
                        .font(FashTypography.labelLarge)
                        .foregroundStyle(FashColors.brandPrimary)
                        .disabled(busy != .none)
                }
                if grace.phase.isEmpty == false {
                    Text(L10n.orderDetailMeetingGraceSyncHint)
                        .font(FashTypography.labelSmall)
                        .foregroundStyle(FashColors.textSecondary)
                }
            }
        )
    }

    static func buyerShippingCard(detail: OrderDetailPayload) -> some View {
        guard !detail.shippingAddressFormatted.isEmpty || !detail.recipientName.isEmpty else {
            return AnyView(EmptyView())
        }
        return AnyView(
            sectionCard {
                Text(L10n.orderDetailShippingAddressTitle)
                    .font(FashTypography.titleSmall.weight(.semibold))
                if !detail.recipientName.isEmpty {
                    Text(detail.recipientName.uppercased())
                        .font(FashTypography.titleSmall.weight(.bold))
                }
                if !detail.recipientPhone.isEmpty {
                    Text(detail.recipientPhone)
                        .font(FashTypography.bodyMedium)
                }
                if !detail.shippingAddressFormatted.isEmpty {
                    Text(detail.shippingAddressFormatted)
                        .font(FashTypography.bodyMedium)
                        .foregroundStyle(FashColors.textSecondary)
                }
            }
        )
    }

    static func trackingCard(detail: OrderDetailPayload) -> some View {
        guard !detail.trackingNumber.isEmpty || !detail.carrier.isEmpty else { return AnyView(EmptyView()) }
        return AnyView(
            sectionCard {
                Text(L10n.orderDetailTracking)
                    .font(FashTypography.labelSmall)
                    .foregroundStyle(FashColors.textSecondary)
                Text(detail.carrier.isEmpty ? "—" : detail.carrier)
                    .font(FashTypography.bodyMedium.weight(.semibold))
                Text(detail.trackingNumber.isEmpty ? L10n.orderDetailTrackingEmpty : detail.trackingNumber)
                    .font(FashTypography.bodySmall)
                    .foregroundStyle(FashColors.brandPrimary)
                if !detail.trackingStatusSummary.isEmpty {
                    Text(detail.trackingStatusSummary)
                        .font(FashTypography.bodySmall)
                        .foregroundStyle(FashColors.textSecondary)
                }
            }
        )
    }

    static func buyerReviewSection(detail: OrderDetailPayload, role: OrderViewerRole) -> some View {
        guard let review = detail.buyerReview else { return AnyView(EmptyView()) }
        let heading: String = {
            switch role {
            case .buyer: return L10n.orderDetailBuyerReviewHeadingBuyer
            case .seller: return L10n.orderDetailBuyerReviewHeadingSeller
            case .viewer: return L10n.orderDetailBuyerReviewHeadingViewer
            }
        }()
        return AnyView(
            sectionCard {
                Text(heading)
                    .font(FashTypography.labelSmall)
                    .foregroundStyle(FashColors.textSecondary)
                HStack(spacing: 2) {
                    ForEach(0..<5, id: \.self) { i in
                        Image(systemName: i < review.rating ? "star.fill" : "star")
                            .foregroundStyle(i < review.rating ? FashColors.brandPrimary : FashColors.textSecondary.opacity(0.4))
                    }
                }
                Text(review.comment.isEmpty ? L10n.orderDetailBuyerReviewNoComment : review.comment)
                    .font(FashTypography.bodyMedium)
                    .foregroundStyle(FashColors.textSecondary)
                if !review.createdAt.isEmpty {
                    Text(L10n.orderDetailBuyerReviewSubmittedAt(OrderFormatting.formatShortDate(review.createdAt)))
                        .font(FashTypography.bodySmall)
                        .foregroundStyle(FashColors.textSecondary)
                }
            }
        )
    }
}
