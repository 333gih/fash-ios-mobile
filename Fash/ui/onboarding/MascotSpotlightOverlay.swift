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

private enum CoachStackLayout {
    case verticalMascotFirst
    case verticalCaptionFirst
    case horizontalMascotFirst
}

private struct MascotCoachPlacement {
    let stackCenter: CGPoint
    let stackHalfWidth: CGFloat
    let stackHalfHeight: CGFloat
    let direction: MascotPointDirection
    let flipHorizontal: Bool
    let layout: CoachStackLayout
    let captionMaxWidth: CGFloat
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
    private let controlsReserve: CGFloat = 132
    private let topSafe: CGFloat = 56
    private let stackSpacing: CGFloat = 8
    private let captionHeightEstimate: CGFloat = 104

    var body: some View {
        GeometryReader { overlayProxy in
            let overlayGlobal = overlayProxy.frame(in: .global)
            let overlaySize = overlayProxy.size
            let globalHole = anchor.flatMap { anchorFrames[$0] }
            let localHole = globalHole.map { global in
                global.insetForSpotlight(padding: holePadding)
                    .offsetBy(dx: -overlayGlobal.minX, dy: -overlayGlobal.minY)
            }
            let captionMaxWidth = min(overlaySize.width - 40, 300)
            let verticalStackHeight = mascotSize + stackSpacing + captionHeightEstimate
            let horizontalStackWidth = mascotSize + stackSpacing + captionMaxWidth
            let placement = coachPlacement(
                hole: localHole,
                overlaySize: overlaySize,
                captionMaxWidth: captionMaxWidth,
                verticalStackHeight: verticalStackHeight,
                horizontalStackWidth: horizontalStackWidth
            )

            ZStack {
                spotlightLayer(hole: holeReady ? localHole : nil)

                if let placement {
                    coachStackLayer(placement: placement)
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
    private func coachStackLayer(placement: MascotCoachPlacement) -> some View {
        let originX = max(placement.stackCenter.x - placement.stackHalfWidth, 8)
        let originY = max(placement.stackCenter.y - placement.stackHalfHeight, topSafe)

        coachStack(
            direction: placement.direction,
            flipHorizontal: placement.flipHorizontal,
            layout: placement.layout,
            captionMaxWidth: placement.captionMaxWidth
        )
        .position(
            x: originX + placement.stackHalfWidth,
            y: originY + placement.stackHalfHeight
        )
    }

    @ViewBuilder
    private func coachStack(
        direction: MascotPointDirection,
        flipHorizontal: Bool,
        layout: CoachStackLayout,
        captionMaxWidth: CGFloat
    ) -> some View {
        switch layout {
        case .verticalMascotFirst:
            VStack(spacing: stackSpacing) {
                FashMascotGuideImage(
                    name: direction.assetName,
                    size: mascotSize,
                    flipHorizontal: flipHorizontal
                )
                captionBubble(maxWidth: captionMaxWidth)
            }
        case .verticalCaptionFirst:
            VStack(spacing: stackSpacing) {
                captionBubble(maxWidth: captionMaxWidth)
                FashMascotGuideImage(
                    name: direction.assetName,
                    size: mascotSize,
                    flipHorizontal: flipHorizontal
                )
            }
        case .horizontalMascotFirst:
            HStack(spacing: stackSpacing) {
                FashMascotGuideImage(
                    name: direction.assetName,
                    size: mascotSize,
                    flipHorizontal: flipHorizontal
                )
                captionBubble(maxWidth: captionMaxWidth)
            }
        }
    }

    @ViewBuilder
    private func introCoachLayer(overlaySize: CGSize) -> some View {
        let centerY = overlaySize.height * 0.30
        VStack(spacing: 12) {
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

    private func coachPlacement(
        hole: CGRect?,
        overlaySize: CGSize,
        captionMaxWidth: CGFloat,
        verticalStackHeight: CGFloat,
        horizontalStackWidth: CGFloat
    ) -> MascotCoachPlacement? {
        guard let hole else { return nil }

        let contentBottom = overlaySize.height - controlsReserve
        let spaceAbove = hole.minY - topSafe
        let spaceBelow = contentBottom - hole.maxY
        let spaceLeft = hole.minX
        let spaceRight = overlaySize.width - hole.maxX

        let halfVertical = verticalStackHeight / 2
        let halfHorizontal = horizontalStackWidth / 2
        let verticalHalfWidth = max(captionMaxWidth / 2, mascotSize / 2)

        let canPlaceBelow = spaceBelow >= verticalStackHeight + mascotGap
        let canPlaceAbove = spaceAbove >= verticalStackHeight + mascotGap

        if canPlaceBelow, spaceBelow >= spaceAbove {
            let stackCenterY = min(hole.maxY + mascotGap + halfVertical, contentBottom - halfVertical)
            let stackCenterX = hole.midX.clamped(
                verticalHalfWidth + 12,
                overlaySize.width - verticalHalfWidth - 12
            )
            return MascotCoachPlacement(
                stackCenter: CGPoint(x: stackCenterX, y: stackCenterY),
                stackHalfWidth: verticalHalfWidth,
                stackHalfHeight: halfVertical,
                direction: .up,
                flipHorizontal: false,
                layout: .verticalMascotFirst,
                captionMaxWidth: captionMaxWidth
            )
        }

        if canPlaceAbove {
            let stackCenterY = max(hole.minY - mascotGap - halfVertical, topSafe + halfVertical)
            let stackCenterX = hole.midX.clamped(
                verticalHalfWidth + 12,
                overlaySize.width - verticalHalfWidth - 12
            )
            return MascotCoachPlacement(
                stackCenter: CGPoint(x: stackCenterX, y: stackCenterY),
                stackHalfWidth: verticalHalfWidth,
                stackHalfHeight: halfVertical,
                direction: .down,
                flipHorizontal: false,
                layout: .verticalCaptionFirst,
                captionMaxWidth: captionMaxWidth
            )
        }

        let canPlaceRight = spaceRight >= horizontalStackWidth + mascotGap
        let canPlaceLeft = spaceLeft >= horizontalStackWidth + mascotGap

        if canPlaceRight, spaceRight >= spaceLeft {
            let stackCenterX = min(hole.maxX + mascotGap + halfHorizontal, overlaySize.width - halfHorizontal - 12)
            let stackCenterY = hole.midY.clamped(halfVertical + topSafe, contentBottom - halfVertical)
            return MascotCoachPlacement(
                stackCenter: CGPoint(x: stackCenterX, y: stackCenterY),
                stackHalfWidth: halfHorizontal,
                stackHalfHeight: mascotSize / 2,
                direction: .left,
                flipHorizontal: true,
                layout: .horizontalMascotFirst,
                captionMaxWidth: captionMaxWidth
            )
        }

        if canPlaceLeft {
            let stackCenterX = max(hole.minX - mascotGap - halfHorizontal, halfHorizontal + 12)
            let stackCenterY = hole.midY.clamped(halfVertical + topSafe, contentBottom - halfVertical)
            return MascotCoachPlacement(
                stackCenter: CGPoint(x: stackCenterX, y: stackCenterY),
                stackHalfWidth: halfHorizontal,
                stackHalfHeight: mascotSize / 2,
                direction: .left,
                flipHorizontal: false,
                layout: .horizontalMascotFirst,
                captionMaxWidth: captionMaxWidth
            )
        }

        let fallbackY = max(topSafe + halfVertical, contentBottom - halfVertical)
        let fallbackX = hole.midX.clamped(
            verticalHalfWidth + 12,
            overlaySize.width - verticalHalfWidth - 12
        )
        return MascotCoachPlacement(
            stackCenter: CGPoint(x: fallbackX, y: fallbackY),
            stackHalfWidth: verticalHalfWidth,
            stackHalfHeight: halfVertical,
            direction: .up,
            flipHorizontal: false,
            layout: .verticalMascotFirst,
            captionMaxWidth: captionMaxWidth
        )
    }
}

private extension CGRect {
    func insetForSpotlight(padding: CGFloat) -> CGRect {
        insetBy(dx: -padding, dy: -padding)
    }
}

private extension CGFloat {
    func clamped(_ lower: CGFloat, _ upper: CGFloat) -> CGFloat {
        min(max(self, lower), upper)
    }
}
