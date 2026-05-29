import SwiftUI

/// Pill selector for post flow — Android [PostSelectablePill].
struct PostSelectablePill: View {
    let text: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(FashTypography.labelLarge)
                .foregroundStyle(selected ? FashColors.readableOnBrandPrimary : FashColors.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(selected ? FashColors.brandPrimary : FashColors.surfaceContainerLow)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

/// Full-width selectable row — Android [PostSelectableListRow].
struct PostSelectableListRow: View {
    @Environment(\.fashSpacing) private var spacing
    let text: String
    var subtitle: String? = nil
    var leadingEmoji: String? = nil
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                leadingAvatar
                VStack(alignment: .leading, spacing: 2) {
                    Text(text)
                        .font(FashTypography.bodyLarge)
                        .foregroundStyle(FashColors.textPrimary)
                        .multilineTextAlignment(.leading)
                    if let subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(FashTypography.bodySmall)
                            .foregroundStyle(FashColors.textSecondary)
                    }
                }
                Spacer(minLength: 0)
                Image(systemName: selected ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(selected ? FashColors.brandPrimary : FashColors.textSecondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(selected ? FashColors.brandPrimary.opacity(0.12) : FashColors.surfaceContainerLow)
            .clipShape(RoundedRectangle(cornerRadius: spacing.radiusCard, style: .continuous))
            .overlay {
                if selected {
                    RoundedRectangle(cornerRadius: spacing.radiusCard, style: .continuous)
                        .stroke(FashColors.brandPrimary.opacity(0.85), lineWidth: 1.5)
                }
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var leadingAvatar: some View {
        let fill = selected ? FashColors.brandPrimary.opacity(0.12) : FashColors.surfaceContainerLow
        ZStack {
            Circle()
                .fill(fill)
                .frame(width: 40, height: 40)
            if let leadingEmoji, !leadingEmoji.isEmpty {
                Text(leadingEmoji)
                    .font(FashTypography.titleMedium)
            } else {
                Text(listLeadingInitial(text))
                    .font(FashTypography.titleSmall.weight(.semibold))
                    .foregroundStyle(selected ? FashColors.brandPrimary : FashColors.textSecondary)
            }
        }
    }
}

private func listLeadingInitial(_ text: String) -> String {
    let t = text.trimmingCharacters(in: .whitespaces)
    guard let c = t.first else { return "?" }
    return String(c).uppercased()
}

/// Outlined field styling for post steps.
struct PostListingOutlinedField: View {
    @Environment(\.fashSpacing) private var spacing
    let label: String
    @Binding var text: String
    var axis: Axis = .horizontal
    var lineLimit: ClosedRange<Int>? = nil
    var keyboard: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(FashTypography.labelLarge)
                .foregroundStyle(FashColors.textSecondary)
            Group {
                if axis == .vertical {
                    TextField(label, text: $text, axis: .vertical)
                        .lineLimit(lineLimit ?? 3...6)
                } else {
                    TextField(label, text: $text)
                }
            }
            .keyboardType(keyboard)
            .padding(spacing.spacing3)
            .background(PostListingColors.fieldSurface)
            .clipShape(RoundedRectangle(cornerRadius: spacing.radiusSoftMin, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: spacing.radiusSoftMin, style: .continuous)
                    .stroke(FashColors.outlineMuted.opacity(0.45), lineWidth: 1)
            }
        }
    }
}

/// Wrapping grid of pills — used across post steps.
struct FlowPillsGrid<Content: View>: View {
    @ViewBuilder let content: () -> Content
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 88), spacing: 8)], alignment: .leading, spacing: 8) {
            content()
        }
    }
}

struct PostListingVndPriceField: View {
    @Environment(\.fashSpacing) private var spacing
    let label: String
    @Binding var digits: String

    private var preview: String? {
        guard let amount = Int64(digits.filter(\.isNumber)), amount > 0 else { return nil }
        return FeedPriceFormat.format(amount)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            PostListingOutlinedField(label: label, text: $digits, keyboard: .numberPad)
            if let preview {
                Text(L10n.postPriceVndPreview(preview))
                    .font(FashTypography.bodySmall)
                    .foregroundStyle(FashColors.brandPrimary)
            }
        }
    }
}
