import SwiftUI

private let splashAccent = Color(hex: 0xF04D63)
private let thumbCornerRadius: CGFloat = 28

/// Full-bleed waiting / splash — branded editorial only (no determinate progress bar).
struct FashWaitingScreen: View {
    /// Third dot active (final onboarding step), matching Android default.
    var activeDotIndex: Int = 2

    private let background = FashColorTokens.Dark.screen
    private let onSurface = FashColorTokens.Dark.textPrimary
    private let onSurfaceMuted = FashColorTokens.Dark.textSecondary
    private let outlineVariant = FashColorTokens.Dark.outlineMuted

    // GPU-driven animation state — replaced TimelineView(30fps) with withAnimation → CAAnimation
    @State private var watermarkDrift: CGFloat = -1
    @State private var topCornerX: CGFloat = -5
    @State private var topCornerY: CGFloat = 6
    @State private var bottomCornerX: CGFloat = 6
    @State private var bottomCornerY: CGFloat = -5
    @State private var breathScale: CGFloat = 0.988
    @State private var dotPulse: CGFloat = 0.96
    // Staggered dot offsets — animated independently with phase offsets
    @State private var dot0Y: CGFloat = -5
    @State private var dot1Y: CGFloat = 0
    @State private var dot2Y: CGFloat = 5
    @State private var didStartAnimations = false

    var body: some View {
        GeometryReader { geo in
            let safeTop = geo.safeAreaInsets.top
            let safeBottom = geo.safeAreaInsets.bottom
            ZStack {
                background.ignoresSafeArea()

                watermark(geo: geo)

                splashCornerThumb(
                    width: 96,
                    height: 148,
                    cropAlignment: .topLeading
                )
                .padding(.leading, 22)
                .padding(.top, 20 + safeTop)
                .offset(x: topCornerX, y: topCornerY)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                splashCornerThumb(
                    width: 152,
                    height: 104,
                    cropAlignment: .bottomTrailing
                )
                .padding(.trailing, 18)
                .padding(.bottom, 108 + safeBottom)
                .offset(x: bottomCornerX, y: bottomCornerY)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)

                WaitingScreenCenterEditorial()
                    .scaleEffect(breathScale)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    genZFooter
                        .padding(.horizontal, 20)
                    stepDots
                        .padding(.top, 20)
                        .padding(.bottom, max(20, safeBottom))
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            guard !didStartAnimations else { return }
            didStartAnimations = true
            startAnimations()
        }
    }

    private func startAnimations() {
        // Watermark slow drift — 12s period, autoReverse
        withAnimation(.linear(duration: 12).repeatForever(autoreverses: true)) {
            watermarkDrift = 1
        }
        // Corner float — approximate sin/cos lissajous with independent autoReverse axes
        withAnimation(.easeInOut(duration: 7).repeatForever(autoreverses: true)) {
            topCornerX = 5
        }
        withAnimation(.easeInOut(duration: 10.75).repeatForever(autoreverses: true)) {
            topCornerY = -6
        }
        withAnimation(.easeInOut(duration: 6.4).repeatForever(autoreverses: true)) {
            bottomCornerX = -6
        }
        withAnimation(.easeInOut(duration: 8.2).repeatForever(autoreverses: true)) {
            bottomCornerY = 5
        }
        // Center breath
        withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) {
            breathScale = 1.012
        }
        // Active dot pulse
        withAnimation(.linear(duration: 1.1).repeatForever(autoreverses: true)) {
            dotPulse = 1.06
        }
        // Staggered dot wave — three independent animations with 1/3 period phase offset
        withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
            dot0Y = 5
        }
        Task {
            try? await Task.sleep(for: .seconds(1.4 / 3))
            withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                dot1Y = 5
            }
            try? await Task.sleep(for: .seconds(1.4 / 3))
            withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                dot2Y = 5
            }
        }
    }

    private func watermark(geo: GeometryProxy) -> some View {
        let fontSize = min(geo.size.height * 0.16, 132)
        let driftY = geo.size.height * 0.08 + geo.size.height * 0.05 * watermarkDrift
        return Text(L10n.splashWordmark)
            .font(.custom("BeVietnamPro-Bold", size: fontSize))
            .tracking(-2)
            .foregroundStyle(onSurface.opacity(0.08))
            .rotationEffect(.degrees(-90))
            .frame(height: geo.size.height * 0.72)
            .offset(x: geo.size.width * 0.12, y: driftY)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .allowsHitTesting(false)
    }

    private func splashCornerThumb(
        width: CGFloat,
        height: CGFloat,
        cropAlignment: Alignment
    ) -> some View {
        FashLoginHeroTrenchIllustration()
            .saturation(0)
            .frame(width: width, height: height, alignment: cropAlignment)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: thumbCornerRadius, style: .continuous))
            .allowsHitTesting(false)
    }

    private var genZFooter: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(outlineVariant.opacity(0.55))
                .frame(width: 48, height: 1)
            Text(L10n.splashFooterGenZ)
                .font(.custom("BeVietnamPro-Medium", size: 11))
                .tracking(1.6)
                .foregroundStyle(onSurfaceMuted)
                .padding(.horizontal, 4)
                .background(background)
            Rectangle()
                .fill(outlineVariant.opacity(0.55))
                .frame(maxWidth: .infinity, maxHeight: 1)
        }
    }

    private var stepDots: some View {
        let active = min(max(activeDotIndex, 0), 2)
        let dotYOffsets: [CGFloat] = [dot0Y, dot1Y, dot2Y]
        return HStack(spacing: 10) {
            ForEach(0..<3, id: \.self) { index in
                let isActive = index == active
                Circle()
                    .fill(isActive ? splashAccent : outlineVariant.opacity(0.45))
                    .frame(width: isActive ? 10 : 8, height: isActive ? 10 : 8)
                    .scaleEffect(isActive ? dotPulse : 1)
                    .offset(y: dotYOffsets[index])
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Staggered center copy

private struct WaitingScreenCenterEditorial: View {
    @State private var showEyebrow = false
    @State private var showHeadline = false
    @State private var showAccentTrack = false
    @State private var showBody = false
    @State private var showMantra = false
    @State private var accentPulseAlpha: CGFloat = 0.55

    private let onSurface = FashColorTokens.Dark.textPrimary
    private let onSurfaceMuted = FashColorTokens.Dark.textSecondary

    var body: some View {
        VStack(spacing: 0) {
            if showEyebrow {
                Text(L10n.waitingScreenEyebrow)
                    .font(FashTypography.labelLarge.weight(.medium))
                    .tracking(1.2)
                    .foregroundStyle(onSurfaceMuted.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
            Spacer().frame(height: 12)

            if showHeadline {
                Text(L10n.waitingScreenHeadline)
                    .font(FashTypography.headlineSmall.weight(.bold))
                    .italic()
                    .foregroundStyle(onSurface)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
            Spacer().frame(height: 10)

            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            FashColors.brandPrimary.opacity(accentPulseAlpha),
                            splashAccent.opacity(0.85 * accentPulseAlpha),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: showAccentTrack ? 72 : 0, height: 4)
                .animation(.spring(response: 0.55, dampingFraction: 0.72), value: showAccentTrack)
            Spacer().frame(height: 14)

            if showBody {
                Text(L10n.waitingScreenLine2)
                    .font(FashTypography.bodyLarge)
                    .foregroundStyle(onSurfaceMuted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
            Spacer().frame(height: 10)

            if showMantra {
                Text(L10n.waitingScreenLine3)
                    .font(FashTypography.titleMedium.weight(.semibold))
                    .tracking(0.3)
                    .foregroundStyle(FashColors.brandPrimary)
                    .multilineTextAlignment(.center)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .padding(.horizontal, 28)
        .task {
            await runStaggeredEntrance()
        }
        .onAppear {
            startAccentPulse()
        }
    }

    private func runStaggeredEntrance() async {
        try? await Task.sleep(nanoseconds: 120_000_000)
        withAnimation(.easeOut(duration: 0.42)) { showEyebrow = true }
        try? await Task.sleep(nanoseconds: 180_000_000)
        withAnimation(.easeOut(duration: 0.48)) { showHeadline = true }
        try? await Task.sleep(nanoseconds: 120_000_000)
        showAccentTrack = true
        try? await Task.sleep(nanoseconds: 160_000_000)
        withAnimation(.easeOut(duration: 0.42)) { showBody = true }
        try? await Task.sleep(nanoseconds: 140_000_000)
        withAnimation(.easeOut(duration: 0.40)) { showMantra = true }
    }

    private func startAccentPulse() {
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
            accentPulseAlpha = 1
        }
    }
}
