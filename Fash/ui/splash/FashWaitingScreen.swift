import SwiftUI

private let splashAccent = Color(hex: 0xF04D63)
private let longWaitFeedbackDelayNs: UInt64 = 2_500_000_000
private let thumbCornerRadius: CGFloat = 28

/// Full-bleed waiting / splash — parity with Android [FashWaitingScreen].
struct FashWaitingScreen: View {
    /// Third dot active (final onboarding step), matching Android default.
    var activeDotIndex: Int = 2

    @State private var showLongWaitFeedback = false

    private let background = FashColorTokens.Dark.screen
    private let onSurface = FashColorTokens.Dark.textPrimary
    private let onSurfaceMuted = FashColorTokens.Dark.textSecondary
    private let outlineVariant = FashColorTokens.Dark.outlineMuted

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let motion = WaitingScreenMotion(time: timeline.date.timeIntervalSinceReferenceDate)
            GeometryReader { geo in
                let safeTop = geo.safeAreaInsets.top
                let safeBottom = geo.safeAreaInsets.bottom
                ZStack {
                    background.ignoresSafeArea()

                    watermark(geo: geo, motion: motion)

                    splashCornerThumb(
                        width: 96,
                        height: 148,
                        cropAlignment: .topLeading
                    )
                    .padding(.leading, 22)
                    .padding(.top, 20 + safeTop)
                    .offset(motion.topCornerOffset)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                    splashCornerThumb(
                        width: 152,
                        height: 104,
                        cropAlignment: .bottomTrailing
                    )
                    .padding(.trailing, 18)
                    .padding(.bottom, 108 + safeBottom)
                    .offset(motion.bottomCornerOffset)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)

                    WaitingScreenCenterEditorial()
                        .scaleEffect(motion.centerBreathScale)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

                    VStack(spacing: 0) {
                        Spacer(minLength: 0)
                        longWaitFeedback
                        genZFooter
                            .padding(.horizontal, 20)
                        stepDots(motion: motion)
                            .padding(.top, 20)
                            .padding(.bottom, max(20, safeBottom))
                    }
                }
            }
        }
        .ignoresSafeArea()
        .task {
            try? await Task.sleep(nanoseconds: longWaitFeedbackDelayNs)
            withAnimation(.easeOut(duration: 0.42)) {
                showLongWaitFeedback = true
            }
        }
    }

    // MARK: - Watermark

    private func watermark(geo: GeometryProxy, motion: WaitingScreenMotion) -> some View {
        let fontSize = min(geo.size.height * 0.16, 132)
        let driftY = geo.size.height * 0.08 + geo.size.height * 0.05 * motion.watermarkDrift
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

    // MARK: - Corner thumbs

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

    // MARK: - Footer

    @ViewBuilder
    private var longWaitFeedback: some View {
        if showLongWaitFeedback {
            VStack(spacing: 10) {
                ProgressView()
                    .progressViewStyle(.linear)
                    .tint(splashAccent)
                    .frame(width: 168)
                    .accessibilityLabel(L10n.waitingScreenStillLoadingCd)
                Text(L10n.waitingScreenStillLoading)
                    .font(FashTypography.bodySmall.weight(.medium))
                    .foregroundStyle(onSurfaceMuted)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            .transition(.opacity.combined(with: .move(edge: .bottom)))
        }
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

    private func stepDots(motion: WaitingScreenMotion) -> some View {
        let active = min(max(activeDotIndex, 0), 2)
        return HStack(spacing: 10) {
            ForEach(0..<3, id: \.self) { index in
                let isActive = index == active
                let waveAngle = motion.dotWavePhase * 2 * Double.pi
                let stagger = Double(index) * 2 * Double.pi / 3
                let yOffset = CGFloat(sin(waveAngle + stagger) * 5)
                Circle()
                    .fill(isActive ? splashAccent : outlineVariant.opacity(0.45))
                    .frame(width: isActive ? 10 : 8, height: isActive ? 10 : 8)
                    .scaleEffect(isActive ? motion.activeDotPulseScale : 1)
                    .offset(y: yOffset)
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Motion (Android infinite transitions)

private struct WaitingScreenMotion {
    let watermarkDrift: CGFloat
    let topCornerOffset: CGSize
    let bottomCornerOffset: CGSize
    let dotWavePhase: CGFloat
    let activeDotPulseScale: CGFloat
    let centerBreathScale: CGFloat

    init(time: TimeInterval) {
        watermarkDrift = CGFloat(sin(time * 2 * .pi / 12))

        let cornerPhase = time.truncatingRemainder(dividingBy: 14) / 14
        let cornerAngle = cornerPhase * 2 * Double.pi
        topCornerOffset = CGSize(
            width: CGFloat(sin(cornerAngle) * 5),
            height: CGFloat(cos(cornerAngle * 0.65) * 6)
        )
        bottomCornerOffset = CGSize(
            width: CGFloat(cos(cornerAngle * 1.1) * 6),
            height: CGFloat(sin(cornerAngle * 0.85) * 5)
        )

        dotWavePhase = CGFloat(time.truncatingRemainder(dividingBy: 1.4) / 1.4)

        let pulsePhase = time.truncatingRemainder(dividingBy: 1.1) / 1.1
        activeDotPulseScale = CGFloat(0.96 + 0.1 * sin(pulsePhase * 2 * .pi))

        centerBreathScale = CGFloat(1 + 0.012 * sin(time * 2 * .pi / 2.6))
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
