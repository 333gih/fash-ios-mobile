import SwiftUI

/// Explore overlay title slot: periodic Y-flip between `FASH.Explore` and a faux search field.
struct ExploreTopBarFlipTitle: View {
    let progress: CGFloat
    let placeholder: String

    private let slotHeight: CGFloat = 48
    private let fieldHeight: CGFloat = 40

    var body: some View {
        ZStack(alignment: .leading) {
            titleFace
                .exploreFlipFace(progress: progress, showsFront: false)
            searchHintFace
                .exploreFlipFace(progress: progress, showsFront: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: slotHeight)
        .clipped()
    }

    private var titleFace: some View {
        FashScreenTitle(suffix: L10n.brandHeaderSuffixExplore)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: slotHeight, alignment: .leading)
    }

    private var searchHintFace: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18))
                .foregroundStyle(FashColors.brandPrimary)
            Text(placeholder)
                .font(FashTypography.bodyMedium.weight(.medium))
                .foregroundStyle(FashColors.textSecondary.opacity(0.82))
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: fieldHeight)
        .background(FashColors.surfaceVariant.opacity(0.38))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(FashColors.brandPrimary.opacity(0.32), lineWidth: 1)
        )
        .frame(height: slotHeight, alignment: .leading)
    }
}

private struct ExploreFlipFaceModifier: ViewModifier {
    let progress: CGFloat
    let showsFront: Bool

    func body(content: Content) -> some View {
        let clamped = min(max(progress, 0), 1)
        let angle = Double(clamped) * 180
        let rotation = showsFront ? angle + 180 : angle
        let visible = showsFront ? clamped > 0.5 : clamped < 0.5

        content
            .rotation3DEffect(.degrees(rotation), axis: (0, 1, 0), perspective: 0.55)
            .opacity(visible ? 1 : 0)
            .allowsHitTesting(visible)
    }
}

private extension View {
    func exploreFlipFace(progress: CGFloat, showsFront: Bool) -> some View {
        modifier(ExploreFlipFaceModifier(progress: progress, showsFront: showsFront))
    }
}

/// 0 = title face, 1 = search hint face (~11s cycle, aligned with Home header rhythm).
func rememberExploreTitleFlipProgress(animate: Bool, date: Date) -> CGFloat {
    guard animate else { return 0 }
    let ms = date.timeIntervalSinceReferenceDate * 1000
    let phase = ms.truncatingRemainder(dividingBy: homeSearchExpandCycleMs)
    if phase < 4000 { return 0 }
    if phase < 4800 { return CGFloat((phase - 4000) / 800) }
    if phase < 8500 { return 1 }
    if phase < 9300 { return CGFloat(1 - (phase - 8500) / 800) }
    return 0
}

/// Trailing search icon visible only while the title face is showing (avoids duplicate affordance).
func exploreTrailingSearchIconOpacity(flipProgress: CGFloat) -> Double {
    let clamped = min(max(flipProgress, 0), 1)
    if clamped < 0.38 { return 1 }
    if clamped > 0.52 { return 0 }
    return Double(1 - (clamped - 0.38) / 0.14)
}
