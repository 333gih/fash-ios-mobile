import SwiftUI

enum MascotPointDirection {
    case up
    case down
    case left

    var assetName: String {
        switch self {
        case .up: return "FashMascotPointUp"
        case .down: return "FashMascotPointDown"
        case .left: return "FashMascotPointLeft"
        }
    }
}

private struct MascotCoachPlacement {
    let mascotCenter: CGPoint
    let direction: MascotPointDirection
    let flipHorizontal: Bool
    let captionCenter: CGPoint
}

/// Dimmed scrim + spotlight hole + mascot pointing at the target + compact caption (no dialog card).
struct MascotSpotlightOverlay: View {
    let title: String
    let bodyText: String
    var anchor: FeatureTourAnchor?
    var anchorFrames: [FeatureTourAnchor: CGRect] = [:]
    var stepIndex: Int = 0
    var stepCount: Int = 1
    var showBack: Bool = false
    var isLast: Bool = false
    var onBack: () -> Void = {}
    var onNext: () -> Void = {}
    var onSkip: () -> Void = {}

    @State private var holeReady = false

    private let holePadding: CGFloat = 10
    private let holeCorner: CGFloat = 18
    private let mascotSize: CGFloat = 72
    private let mascotGap: CGFloat = 14

    var body: some View {
        GeometryReader { overlayProxy in
            let overlayGlobal = overlayProxy.frame(in: .global)
            let overlaySize = overlayProxy.size
            let globalHole = anchor.flatMap { anchorFrames[$0] }
            let localHole = globalHole.map { global in
                global.insetForSpotlight(padding: holePadding)
                    .offsetBy(dx: -overlayGlobal.minX, dy: -overlayGlobal.minY)
            }
            let placement = coachPlacement(hole: localHole, overlaySize: overlaySize)

            ZStack {
                spotlightLayer(hole: holeReady ? localHole : nil)

                if let placement {
                    mascotCoachLayer(placement: placement, overlaySize: overlaySize)
                } else {
                    introCoachLayer(overlaySize: overlaySize)
                }

                controlsBar
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .ignoresSafeArea()
        .accessibilityAddTraits(.isModal)
        .onChange(of: anchor) { _, _ in
            holeReady = anchor == nil
            guard anchor != nil else { return }
            holeReady = false
            Task {
                try? await Task.sleep(for: .milliseconds(48))
                holeReady = true
            }
        }
        .onAppear {
            holeReady = anchor == nil
            if anchor != nil {
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
            Color.black.opacity(0.62)
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
    private func mascotCoachLayer(placement: MascotCoachPlacement, overlaySize: CGSize) -> some View {
        FashMascotGuideImage(
            name: placement.direction.assetName,
            size: mascotSize,
            flipHorizontal: placement.flipHorizontal
        )
        .position(placement.mascotCenter)

        captionBubble(maxWidth: min(overlaySize.width - 40, 300))
            .position(placement.captionCenter)
    }

    @ViewBuilder
    private func introCoachLayer(overlaySize: CGSize) -> some View {
        let centerY = overlaySize.height * 0.38
        VStack(spacing: 16) {
            FashMascotGuideImage(name: MascotPointDirection.up.assetName, size: 88)
            captionBubble(maxWidth: min(overlaySize.width - 48, 320))
        }
        .position(x: overlaySize.width / 2, y: centerY)
    }

    @ViewBuilder
    private func captionBubble(maxWidth: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(FashTypography.titleSmall.weight(.bold))
                .foregroundStyle(FashColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Text(bodyText)
                .font(FashTypography.bodySmall)
                .foregroundStyle(FashColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: maxWidth, alignment: .leading)
        .background(FashColors.surface.opacity(0.96))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.14), radius: 10, y: 4)
    }

    private var controlsBar: some View {
        VStack {
            Spacer()
            HStack(spacing: 12) {
                Button(L10n.appTourSkip, action: onSkip)
                    .font(FashTypography.labelMedium)
                    .foregroundStyle(Color.white.opacity(0.88))

                Spacer(minLength: 0)

                HStack(spacing: 5) {
                    ForEach(0..<max(stepCount, 1), id: \.self) { page in
                        Capsule()
                            .fill(page == stepIndex ? FashColors.brandPrimary : Color.white.opacity(0.35))
                            .frame(width: page == stepIndex ? 16 : 6, height: 6)
                    }
                }

                Spacer(minLength: 0)

                HStack(spacing: 8) {
                    if showBack {
                        Button(L10n.appTourBack, action: onBack)
                            .font(FashTypography.labelMedium.weight(.semibold))
                            .foregroundStyle(Color.white.opacity(0.92))
                    }
                    Button(isLast ? L10n.appTourDone : L10n.appTourNext, action: onNext)
                        .font(FashTypography.labelMedium.weight(.bold))
                        .foregroundStyle(FashColors.brandPrimary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.96))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 20)
            .background(
                LinearGradient(
                    colors: [Color.black.opacity(0.0), Color.black.opacity(0.55)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }

    private func coachPlacement(hole: CGRect?, overlaySize: CGSize) -> MascotCoachPlacement? {
        guard let hole else { return nil }

        let spaceAbove = hole.minY
        let spaceBelow = overlaySize.height - hole.maxY
        let spaceLeft = hole.minX
        let spaceRight = overlaySize.width - hole.maxX

        let captionHeight: CGFloat = 96
        let halfMascot = mascotSize / 2

        if spaceBelow >= mascotSize + mascotGap + 40, spaceBelow >= spaceAbove {
            let mascotY = hole.maxY + mascotGap + halfMascot
            let captionY = min(mascotY + halfMascot + captionHeight / 2 + 8, overlaySize.height - 120)
            return MascotCoachPlacement(
                mascotCenter: CGPoint(x: hole.midX, y: mascotY),
                direction: .up,
                flipHorizontal: false,
                captionCenter: CGPoint(x: hole.midX, y: captionY)
            )
        }

        if spaceAbove >= mascotSize + mascotGap + 40 {
            let mascotY = hole.minY - mascotGap - halfMascot
            let captionY = max(mascotY - halfMascot - captionHeight / 2 - 8, 80)
            return MascotCoachPlacement(
                mascotCenter: CGPoint(x: hole.midX, y: mascotY),
                direction: .down,
                flipHorizontal: false,
                captionCenter: CGPoint(x: hole.midX, y: captionY)
            )
        }

        if spaceRight >= mascotSize + mascotGap + 40, spaceRight >= spaceLeft {
            let mascotX = hole.maxX + mascotGap + halfMascot
            return MascotCoachPlacement(
                mascotCenter: CGPoint(x: mascotX, y: hole.midY),
                direction: .left,
                flipHorizontal: true,
                captionCenter: CGPoint(x: min(mascotX + halfMascot + 130, overlaySize.width - 20), y: hole.midY)
            )
        }

        let mascotX = hole.minX - mascotGap - halfMascot
        return MascotCoachPlacement(
            mascotCenter: CGPoint(x: max(halfMascot + 12, mascotX), y: hole.midY),
            direction: .left,
            flipHorizontal: false,
            captionCenter: CGPoint(x: max(130, mascotX - halfMascot - 10), y: hole.midY)
        )
    }
}

private extension CGRect {
    func insetForSpotlight(padding: CGFloat) -> CGRect {
        insetBy(dx: -padding, dy: -padding)
    }
}
