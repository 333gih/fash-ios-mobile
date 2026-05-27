import SwiftUI
import UIKit

private let homeSearchExpandCycleMs = 11_000.0

/// Home header faux search field — width controlled by parent (expand/collapse). Tap opens Explore.
struct FashHomeHeaderSearchField: View {
    let onClick: () -> Void
    var width: CGFloat
    var animateHint: Bool = true
    var contentReveal: CGFloat = 1
    var placeholder: String = L10n.homeHeaderSearchPlaceholder

    var body: some View {
        if width <= 0 {
            EmptyView()
        } else {
            Button(action: onClick) {
                fieldBody
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.searchLabel)
        }
    }

    private var fieldBody: some View {
        let reveal = min(max(contentReveal, 0), 1)
        let showPlaceholder = reveal > 0.32

        return TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate * 1000
            let borderPulse = animateHint
                ? 0.22 + 0.30 * (0.5 + 0.5 * sin(t / 1800 * .pi * 2))
                : 0.32
            let shimmer = animateHint ? homeSearchShimmer(at: t) : -0.35
            let borderAlpha = borderPulse * max(reveal, 0.35)
            let shimmerActive = animateHint && reveal > 0.85

            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(FashColors.surfaceVariant.opacity(0.38 + 0.12 * reveal))
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(FashColors.brandPrimary.opacity(borderAlpha), lineWidth: 1)
                if shimmerActive {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [.clear, FashColors.brandPrimary.opacity(0.07), .clear],
                                startPoint: UnitPoint(x: shimmer - 0.25, y: 0.5),
                                endPoint: UnitPoint(x: shimmer + 0.25, y: 0.5)
                            )
                        )
                        .allowsHitTesting(false)
                }
                if showPlaceholder {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 20))
                            .foregroundStyle(FashColors.brandPrimary)
                        Text(placeholder)
                            .font(FashTypography.bodyMedium.weight(.medium))
                            .foregroundStyle(FashColors.textSecondary.opacity(0.82))
                            .lineLimit(1)
                            .opacity(Double((reveal - 0.32) / 0.68))
                    }
                    .padding(.horizontal, 12)
                } else {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 20))
                        .foregroundStyle(FashColors.brandPrimary)
                }
            }
            .frame(width: width, height: 40)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: .black.opacity(animateHint && reveal > 0.9 ? 0.06 : 0), radius: 1, y: 1)
        }
    }

    private func homeSearchShimmer(at ms: Double) -> CGFloat {
        let cycle = 5600.0
        let phase = ms.truncatingRemainder(dividingBy: cycle)
        if phase < 3800 { return -0.35 }
        let t = (phase - 3800) / 1400
        return CGFloat(-0.35 + 1.7 * min(max(t, 0), 1))
    }
}

/// Progress 0 = collapsed icon, 1 = expanded field (~11s cycle).
func rememberHomeSearchExpandProgress(animate: Bool, date: Date) -> CGFloat {
    guard animate else { return 0 }
    let ms = date.timeIntervalSinceReferenceDate * 1000
    let phase = ms.truncatingRemainder(dividingBy: homeSearchExpandCycleMs)
    if phase < 3600 { return 0 }
    if phase < 4400 { return CGFloat((phase - 3600) / 800) }
    if phase < 8000 { return 1 }
    if phase < 8700 { return CGFloat(1 - (phase - 8000) / 700) }
    return 0
}

/// Collapsed search icon with a short pulse before expand.
struct FashHomeCollapsedSearchIcon: View {
    let onClick: () -> Void
    var animateHint: Bool = true

    var body: some View {
        Button(action: onClick) {
            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                let attention = animateHint
                    ? homeSearchIconAttention(at: timeline.date.timeIntervalSinceReferenceDate * 1000)
                    : 0
                let scale = 1 + attention * 0.16
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 24))
                    .foregroundStyle(attention > 0.5 ? FashColors.brandPrimary : FashColors.textPrimary)
                    .scaleEffect(scale)
                    .frame(width: 48, height: 48)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.searchLabel)
    }

    private func homeSearchIconAttention(at ms: Double) -> CGFloat {
        let phase = ms.truncatingRemainder(dividingBy: homeSearchExpandCycleMs)
        if phase < 3200 || phase > 3950 { return 0 }
        if phase < 3550 { return CGFloat((phase - 3200) / 350) }
        return CGFloat(1 - (phase - 3550) / 400)
    }
}
