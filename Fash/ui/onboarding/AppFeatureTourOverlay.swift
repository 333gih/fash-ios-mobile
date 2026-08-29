import SwiftUI

/// Spotlight tour over main shell anchors — Android [AppFeatureTourOverlay].
struct AppFeatureTourOverlay: View {
    let currentStep: AppTourStep
    var anchorFrames: [FeatureTourAnchor: CGRect] = [:]
    var onStepChange: (AppTourStep) -> Void
    var onSkip: () -> Void
    var onFinish: () -> Void

    private var steps: [AppTourStep] { AppTourStep.allCases }

    var body: some View {
        MascotSpotlightOverlay(
            title: currentStep.title,
            bodyText: currentStep.body,
            anchor: currentStep.anchor,
            anchorFrames: anchorFrames,
            stepIndex: currentStep.rawValue,
            stepCount: steps.count,
            showBack: currentStep != .intro,
            isLast: currentStep == steps.last,
            onBack: {
                if let prev = AppTourStep(rawValue: currentStep.rawValue - 1) {
                    onStepChange(prev)
                }
            },
            onNext: {
                if currentStep == steps.last {
                    onFinish()
                } else if let next = AppTourStep(rawValue: currentStep.rawValue + 1) {
                    onStepChange(next)
                }
            },
            onSkip: onSkip
        )
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
