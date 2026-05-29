import SwiftUI

// MARK: - Teaser content

private enum ExploreFilterTeaserContent {
    static var rotatingLines: [String] {
        [
            L10n.exploreFilterTeaserLineSizing,
            L10n.exploreFilterTeaserLineArea,
            L10n.exploreFilterTeaserLineStyle,
            L10n.exploreFilterTeaserLinePrice,
            L10n.exploreFilterTeaserLineCategory,
        ]
    }

    static var marqueeChips: [String] {
        [
            L10n.exploreFilterTeaserSizing,
            L10n.exploreFilterTeaserArea,
            L10n.exploreFilterTeaserCategory,
            L10n.exploreFilterTeaserStyle,
            L10n.exploreFilterTeaserBrand,
            L10n.exploreFilterTeaserPrice,
        ]
    }
}

// MARK: - Icon pulse (idle)

struct ExploreFilterIconPulse<Content: View>: View {
    let active: Bool
    @ViewBuilder var content: () -> Content

    var body: some View {
        if active {
            content()
        } else {
            TimelineView(.animation(minimumInterval: 1.1, paused: false)) { context in
                let phase = context.date.timeIntervalSinceReferenceDate
                let t = (sin(phase * 2 * .pi / 1.1) + 1) / 2
                let scale = 1 + 0.07 * t
                let alpha = 0.88 + 0.12 * t
                content()
                    .scaleEffect(scale)
                    .opacity(alpha)
            }
        }
    }
}

// MARK: - Rotating CTA line

struct ExploreFilterTeaserRotatingLine: View {
    var compact: Bool = false

    @State private var lineIndex = 0

    private var lines: [String] { ExploreFilterTeaserContent.rotatingLines }

    var body: some View {
        Group {
            if #available(iOS 17.0, *) {
                AnimatedContent(targetState: lineIndex) { index in
                    lineText(lines[index % max(lines.count, 1)])
                } transition: { _ in
                    .asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    )
                }
            } else {
                lineText(lines.isEmpty ? "" : lines[lineIndex % lines.count])
            }
        }
        .frame(maxWidth: .infinity, minHeight: compact ? 20 : 24, alignment: .leading)
        .task(id: lines.count) {
            guard lines.count > 1 else { return }
            let delayNs: UInt64 = compact ? 2_800_000_000 : 3_200_000_000
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: delayNs)
                lineIndex = (lineIndex + 1) % lines.count
            }
        }
    }

    private func lineText(_ text: String) -> some View {
        Text(text)
            .font((compact ? FashTypography.bodyMedium : FashTypography.bodyMedium).weight(compact ? .medium : .semibold))
            .foregroundStyle(FashColors.textPrimary)
            .lineLimit(1)
            .truncationMode(.tail)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Marquee chips

struct ExploreFilterTeaserMarquee: View {
    var body: some View {
        let separator = L10n.exploreFilterTeaserSeparator
        let marqueeText = ExploreFilterTeaserContent.marqueeChips.joined(separator: separator)

        FashMarqueeText(
            text: marqueeText,
            font: FashTypography.labelMedium,
            fontWeight: .medium,
            color: FashColors.brandPrimary,
            lineHeight: 20,
            initialDelayMs: 600,
            repeatDelayMs: 800,
            velocity: 32
        )
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
        .background(FashColors.brandPrimary.opacity(0.07))
        .clipShape(Capsule())
    }
}

// MARK: - Idle teaser block

struct ExploreFilterIdleTeaser: View {
    var compact: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 4 : 6) {
            ExploreFilterTeaserRotatingLine(compact: compact)
                .padding(.top, compact ? 0 : 2)
            if !compact {
                ExploreFilterTeaserMarquee()
            }
            Text(L10n.exploreFilterTeaserTap)
                .font(FashTypography.bodySmall)
                .foregroundStyle(FashColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
