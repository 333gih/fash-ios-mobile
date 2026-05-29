import SwiftUI

/// Bottom hint card — Android [PostFlowNoticeCard] / [PostStepScrollWithBottomNotice].
struct PostFlowNoticeCard: View {
    @Environment(\.fashSpacing) private var spacing
    let text: String
    var title: String? = nil

    private var lines: [String] {
        let split = text.split(separator: "\n").map { String($0).trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        return split.isEmpty ? [text.trimmingCharacters(in: .whitespaces)] : split
    }

    var body: some View {
        HStack(alignment: .top, spacing: spacing.spacing3) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(FashColors.brandPrimary.opacity(0.58))
                .frame(width: 3, height: 68)
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(FashColors.brandPrimary)
                    Text(title ?? L10n.postNoticeTitle)
                        .font(FashTypography.labelLarge.weight(.semibold))
                        .foregroundStyle(FashColors.textPrimary)
                }
                ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                    Text("• \(line)")
                        .font(FashTypography.bodySmall)
                        .foregroundStyle(FashColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(spacing.spacing4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FashColors.surfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: spacing.radiusCard, style: .continuous))
    }
}

/// Scroll content with optional bottom notice for a post step.
struct PostStepScrollContent<Content: View>: View {
    @Environment(\.fashSpacing) private var spacing
    var bottomNotice: String? = nil
    @ViewBuilder let content: () -> Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: spacing.spacing4) {
                content()
                if let bottomNotice, !bottomNotice.isEmpty {
                    PostFlowNoticeCard(text: bottomNotice)
                }
            }
            .padding(.horizontal, spacing.editorialStart)
            .padding(.bottom, spacing.spacing6)
        }
    }
}
