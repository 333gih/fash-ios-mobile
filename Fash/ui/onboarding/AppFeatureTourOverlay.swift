import SwiftUI

/// Spotlight tour over main shell anchors — Android [AppFeatureTourOverlay].
struct AppFeatureTourOverlay: View {
    let currentStep: AppTourStep
    var anchorFrames: [FeatureTourAnchor: CGRect] = [:]
    var onStepChange: (AppTourStep) -> Void
    var onSkip: () -> Void
    var onFinish: () -> Void

    @State private var holeReady = false

    private let holePadding: CGFloat = 10
    private let holeCorner: CGFloat = 18

    var body: some View {
        GeometryReader { overlayProxy in
            let anchor = currentStep.anchor
            let globalHole = anchor.flatMap { anchorFrames[$0] }
            let overlayGlobal = overlayProxy.frame(in: .global)
            let localHole = globalHole.map { global in
                global.insetForFeatureTour(padding: holePadding)
                    .offsetBy(dx: -overlayGlobal.minX, dy: -overlayGlobal.minY)
            }

            ZStack {
                spotlightLayer(hole: holeReady ? localHole : nil)
                tourCard(hole: localHole, overlayHeight: overlayProxy.size.height)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .ignoresSafeArea()
        .accessibilityAddTraits(.isModal)
        .onChange(of: currentStep) { _, _ in
            holeReady = false
            Task {
                try? await Task.sleep(for: .milliseconds(48))
                holeReady = true
            }
        }
        .onAppear {
            holeReady = currentStep.anchor == nil
            if currentStep.anchor != nil {
                Task {
                    try? await Task.sleep(for: .milliseconds(48))
                    holeReady = true
                }
            }
        }
    }

    @ViewBuilder
    private func spotlightLayer(hole: CGRect?) -> some View {
        ZStack {
            Color.black.opacity(0.58)
            if let hole {
                RoundedRectangle(cornerRadius: holeCorner, style: .continuous)
                    .frame(width: hole.width, height: hole.height)
                    .position(x: hole.midX, y: hole.midY)
                    .blendMode(.destinationOut)
            }
        }
        .compositingGroup()
        .overlay {
            if let hole {
                RoundedRectangle(cornerRadius: holeCorner, style: .continuous)
                    .stroke(FashColors.brandPrimary, lineWidth: 2.5)
                    .frame(width: hole.width, height: hole.height)
                    .position(x: hole.midX, y: hole.midY)
            }
        }
    }

    @ViewBuilder
    private func tourCard(hole: CGRect?, overlayHeight: CGFloat) -> some View {
        let steps = AppTourStep.allCases
        let index = currentStep.rawValue
        let total = steps.count
        let progress = CGFloat(index + 1) / CGFloat(max(total, 1))

        if currentStep == .intro {
            VStack {
                Spacer(minLength: 0)
                cardContent(progress: progress, steps: steps)
                    .padding(.horizontal, 20)
                Spacer(minLength: 0)
            }
            return
        }

        let cardAtTop = cardAlignsToTop(hole: hole, overlayHeight: overlayHeight)
        let bottomNavClearance = currentStep.isBottomNavAnchor
            ? MainNavBottomBar.contentHeight + 28
            : 24

        VStack {
            if !cardAtTop { Spacer(minLength: 0) }
            cardContent(progress: progress, steps: steps)
                .padding(.horizontal, 20)
                .padding(.vertical, 28)
            if cardAtTop { Spacer(minLength: 0) }
        }
        .padding(.top, cardAtTop ? 24 : 0)
        .padding(.bottom, cardAtTop ? bottomNavClearance : 24)
    }

    /// Hole near bottom → card at top (Android verticalBias 0.18); hole near top → card at bottom (0.82).
    private func cardAlignsToTop(hole: CGRect?, overlayHeight: CGFloat) -> Bool {
        guard let hole else { return false }
        return hole.midY >= overlayHeight * 0.42
    }

    private func cardContent(progress: CGFloat, steps: [AppTourStep]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(L10n.appTourChip)
                    .font(FashTypography.labelSmall.weight(.semibold))
                    .foregroundStyle(FashColors.brandPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(FashColors.brandPrimary.opacity(0.12))
                    .clipShape(Capsule())
                Spacer()
                Button(L10n.appTourSkip, action: onSkip)
                    .font(FashTypography.labelLarge)
                    .foregroundStyle(FashColors.brandPrimary)
            }
            ProgressView(value: progress)
                .tint(FashColors.brandPrimary)
            Text(currentStep.title)
                .font(FashTypography.titleMedium.weight(.bold))
                .foregroundStyle(FashColors.textPrimary)
            Text(currentStep.body)
                .font(FashTypography.bodyMedium)
                .foregroundStyle(FashColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            HStack {
                if currentStep != .intro {
                    Button(L10n.appTourBack) {
                        if let prev = AppTourStep(rawValue: currentStep.rawValue - 1) {
                            onStepChange(prev)
                        }
                    }
                    .font(FashTypography.labelLarge)
                    .foregroundStyle(FashColors.brandPrimary)
                }
                Spacer()
                Button(currentStep == steps.last ? L10n.appTourDone : L10n.appTourNext) {
                    if currentStep == steps.last {
                        onFinish()
                    } else if let next = AppTourStep(rawValue: currentStep.rawValue + 1) {
                        onStepChange(next)
                    }
                }
                .font(FashTypography.labelLarge.weight(.semibold))
                .foregroundStyle(FashColors.brandPrimary)
            }
        }
        .padding(20)
        .frame(maxWidth: 400)
        .frame(maxWidth: .infinity)
        .background(FashColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 16, y: 8)
    }
}

private extension CGRect {
    func insetForFeatureTour(padding: CGFloat) -> CGRect {
        insetBy(dx: -padding, dy: -padding)
    }
}

#Preview {
    FashTheme {
        AppFeatureTourOverlay(
            currentStep: .navHome,
            anchorFrames: [:],
            onStepChange: { _ in },
            onSkip: {},
            onFinish: {}
        )
    }
}
