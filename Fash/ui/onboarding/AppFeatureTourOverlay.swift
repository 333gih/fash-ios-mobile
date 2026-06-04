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
        Canvas { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.black.opacity(0.58)))
            if let hole {
                let rounded = Path(roundedRect: hole, cornerSize: CGSize(width: holeCorner, height: holeCorner))
                context.blendMode = .clear
                context.fill(rounded, with: .color(.white))
                context.blendMode = .normal
                context.stroke(
                    rounded,
                    with: .color(FashColors.brandPrimary),
                    lineWidth: 2.5
                )
            }
        }
        .compositingGroup()
    }

    @ViewBuilder
    private func tourCard(hole: CGRect?, overlayHeight: CGFloat) -> some View {
        let steps = AppTourStep.allCases
        let index = currentStep.rawValue
        let total = steps.count
        let progress = CGFloat(index + 1) / CGFloat(max(total, 1))
        let placeBelow = cardPlacesBelow(hole: hole, overlayHeight: overlayHeight)

        VStack {
            if !placeBelow { Spacer(minLength: 0) }
            cardContent(progress: progress, steps: steps)
                .padding(.horizontal, 20)
                .padding(.vertical, currentStep == .intro ? 0 : 28)
            if placeBelow { Spacer(minLength: 0) }
        }
        .padding(.bottom, placeBelow ? 24 : 0)
        .padding(.top, placeBelow ? 0 : 24)
    }

    private func cardPlacesBelow(hole: CGRect?, overlayHeight: CGFloat) -> Bool {
        if currentStep == .intro { return false }
        guard let hole else { return true }
        return hole.midY < overlayHeight * 0.42
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
