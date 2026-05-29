import SwiftUI
import UIKit

struct InviteFriendsScreen: View {
    @Environment(\.fashSpacing) private var spacing
    @Environment(AppDependencies.self) private var deps
    var onDismiss: () -> Void

    @State private var referralToken: String?
    @State private var referrerUsername: String = ""
    @State private var showCopiedToast = false

    private var httpsInviteUrl: String {
        InviteDeepLinks.publicInviteHttpsURL(
            referrerUsername: referrerUsername.isEmpty ? nil : referrerUsername,
            referralToken: referralToken
        )
    }

    private var shareBody: String {
        L10n.inviteShareBodyFormat(httpsInviteUrl, Self.appStoreURL)
    }

    var body: some View {
        FashScreenScaffold(title: L10n.inviteScreenTitle, showBack: true, onBack: onDismiss) {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        heroCard
                        Text(L10n.inviteBenefitsSectionTitle)
                            .font(FashTypography.titleMedium.weight(.semibold))
                            .foregroundStyle(FashColors.textPrimary)
                        benefitRow(
                            icon: "star",
                            title: L10n.inviteBenefitPriorityTitle,
                            body: L10n.inviteBenefitPriorityBody
                        )
                        benefitRow(
                            icon: "gift",
                            title: L10n.inviteBenefitPromosTitle,
                            body: L10n.inviteBenefitPromosBody
                        )
                        benefitRow(
                            icon: "person.3",
                            title: L10n.inviteBenefitCircleTitle,
                            body: L10n.inviteBenefitCircleBody
                        )
                        Button(action: shareInvite) {
                            Label(L10n.inviteCtaShare, systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(FashFilledButtonStyle())
                        Button(action: copyInvite) {
                            Label(L10n.inviteCtaCopy, systemImage: "doc.on.doc")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(FashOutlinedBrandButtonStyle())
                        Text(L10n.inviteFinePrint)
                            .font(FashTypography.bodySmall)
                            .foregroundStyle(FashColors.textSecondary)
                            .padding(.top, 4)
                    }
                    .padding(.horizontal, spacing.editorialStart)
                    .padding(.vertical, 12)
                }
                if showCopiedToast {
                    Text(L10n.inviteCopied)
                        .font(FashTypography.labelMedium)
                        .foregroundStyle(FashColors.onBrandPrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(FashColors.brandPrimary)
                        .clipShape(Capsule())
                        .padding(.bottom, 24)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .background(FashColors.screen)
            .animation(.easeInOut(duration: 0.2), value: showCopiedToast)
        }
        .task { await loadReferralContext() }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.inviteScreenHeroKicker)
                .font(FashTypography.labelLarge)
                .foregroundStyle(FashColors.textSecondary)
            Text(L10n.inviteScreenHeroTitle)
                .font(FashTypography.headlineSmall.weight(.bold))
                .foregroundStyle(FashColors.textPrimary)
            Text(L10n.inviteScreenHeroBody)
                .font(FashTypography.bodyMedium)
                .foregroundStyle(FashColors.textPrimary.opacity(0.92))
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [
                    FashColors.brandPrimary.opacity(0.22),
                    FashColors.surfaceContainerHigh.opacity(0.55),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func benefitRow(icon: String, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(FashColors.brandPrimary)
                .frame(width: 28, height: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(FashTypography.titleSmall.weight(.semibold))
                    .foregroundStyle(FashColors.textPrimary)
                Text(body)
                    .font(FashTypography.bodySmall)
                    .foregroundStyle(FashColors.textSecondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FashColors.surfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func loadReferralContext() async {
        async let token = deps.userRepository.getReferralInviteTokenOrNull()
        async let profile = deps.userRepository.getMeProfile()
        referralToken = await token
        if case .success(let me) = await profile {
            referrerUsername = me.username.trimmingCharacters(in: .whitespaces)
        }
    }

    private func copyInvite() {
        UIPasteboard.general.string = shareBody
        showCopiedToast = true
        Task {
            try? await Task.sleep(for: .seconds(2))
            showCopiedToast = false
        }
    }

    private func shareInvite() {
        FashActivityShare.present(activityItems: [L10n.inviteShareSubject, shareBody]) { completed in
            FashActivityShare.showSuccessIfNeeded(completed, message: L10n.shareInviteSuccess, deps: deps)
        }
    }

    private static var appStoreURL: String {
        "https://apps.apple.com/lookup?bundleId=\(BuildConfig.bundleId)"
    }
}
