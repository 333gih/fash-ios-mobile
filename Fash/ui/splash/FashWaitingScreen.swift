import SwiftUI

/// Full-bleed waiting / splash — Android `FashWaitingScreen` (dark editorial canvas).
struct FashWaitingScreen: View {
    @State private var showLongWaitFeedback = false

    private let background = Color(red: 0.07, green: 0.07, blue: 0.08)
    private let onSurface = Color.white
    private let onSurfaceMuted = Color.white.opacity(0.72)

    var body: some View {
        GeometryReader { geo in
            ZStack {
                background.ignoresSafeArea()
                Text(L10n.splashWordmark)
                    .fashBrandMarkStyle(FashBrandTypography.markSplashCenter)
                    .foregroundStyle(onSurface.opacity(0.08))
                    .rotationEffect(.degrees(-90))
                    .offset(x: geo.size.width * 0.22, y: geo.size.height * 0.06)
                VStack(spacing: 0) {
                    Spacer()
                    VStack(spacing: 12) {
                        Text(L10n.waitingScreenEyebrow)
                            .font(FashTypography.labelLarge.weight(.medium))
                            .foregroundStyle(onSurfaceMuted.opacity(0.85))
                            .multilineTextAlignment(.center)
                        Text(L10n.waitingScreenHeadline)
                            .font(FashTypography.headlineSmall.weight(.bold))
                            .italic()
                            .foregroundStyle(onSurface)
                            .multilineTextAlignment(.center)
                        Rectangle()
                            .fill(FashColors.brandPrimary)
                            .frame(width: 72, height: 4)
                            .clipShape(RoundedRectangle(cornerRadius: 2))
                        Text(L10n.waitingScreenLine2)
                            .font(FashTypography.bodyLarge)
                            .foregroundStyle(onSurfaceMuted)
                            .multilineTextAlignment(.center)
                        Text(L10n.waitingScreenLine3)
                            .font(FashTypography.titleMedium.weight(.semibold))
                            .foregroundStyle(FashColors.brandPrimary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 28)
                    Spacer()
                    if showLongWaitFeedback {
                        VStack(spacing: 10) {
                            ProgressView()
                                .tint(FashColors.brandPrimary)
                            Text(L10n.waitingScreenStillLoading)
                                .font(FashTypography.bodySmall.weight(.medium))
                                .foregroundStyle(onSurfaceMuted)
                        }
                        .padding(.bottom, 16)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                    genZFooter
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                }
            }
        }
        .ignoresSafeArea()
        .task {
            try? await Task.sleep(for: .seconds(2.5))
            withAnimation(.easeOut(duration: 0.42)) {
                showLongWaitFeedback = true
            }
        }
    }

    private var genZFooter: some View {
        HStack(spacing: 12) {
            Rectangle().fill(onSurfaceMuted.opacity(0.35)).frame(width: 48, height: 1)
            Text(L10n.splashFooterGenZ)
                .font(FashTypography.labelSmall.weight(.medium))
                .foregroundStyle(onSurfaceMuted)
            Rectangle().fill(onSurfaceMuted.opacity(0.35)).frame(maxWidth: .infinity, maxHeight: 1)
        }
    }
}
