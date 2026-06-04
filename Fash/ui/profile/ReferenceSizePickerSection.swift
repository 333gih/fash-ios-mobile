import SwiftUI

/// Letter-size chips (XS, S, M, …) + optional custom — Android `ProfileSetupSizingSection` reference row.
struct ReferenceSizePickerSection: View {
    @Binding var referenceSize: String
    let genderPreference: String
    var label: String = L10n.profileSetupReferenceSizeLabel

    @State private var customSizeMode = false

    private var standardSizes: [String] {
        SizingReferenceGuide.standardReferenceSizes(genderPreference: genderPreference)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(FashTypography.labelMedium)
                .foregroundStyle(FashColors.textSecondary)

            FlowLayout(spacing: 8) {
                ForEach(standardSizes, id: \.self) { size in
                    sizeChip(size)
                }
                customChip
            }

            if customSizeMode {
                TextField(
                    "",
                    text: $referenceSize,
                    prompt: Text(L10n.profileSetupReferenceSizeHint).foregroundStyle(FashColors.textSecondary.opacity(0.5))
                )
                .font(FashTypography.bodyMedium)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.characters)
                .onChange(of: referenceSize) { _, newValue in
                    if newValue.count > 40 {
                        referenceSize = String(newValue.prefix(40))
                    }
                }
            }

            if SizingReferenceGuide.lookupSizingGuide(referenceSize: referenceSize, genderPreference: genderPreference) != nil {
                Text(L10n.profileSetupSizingInlineHint)
                    .font(FashTypography.bodySmall)
                    .foregroundStyle(FashColors.textSecondary)
            }
        }
        .onAppear { resetCustomModeFromReference() }
        .onChange(of: genderPreference) { _, _ in resetCustomModeFromReference() }
    }

    private func sizeChip(_ size: String) -> some View {
        let selected = !customSizeMode && referenceSize.caseInsensitiveCompare(size) == .orderedSame
        return Button {
            customSizeMode = false
            referenceSize = size
        } label: {
            Text(size)
                .font(FashTypography.labelSmall.weight(selected ? .semibold : .regular))
                .foregroundStyle(selected ? FashColors.readableOnBrandPrimary : FashColors.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(selected ? FashColors.brandPrimary : FashColors.surfaceContainer)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var customChip: some View {
        Button {
            customSizeMode = true
            if SizingReferenceGuide.isStandardReferenceSize(referenceSize, genderPreference: genderPreference) {
                referenceSize = ""
            }
        } label: {
            Text(L10n.profileSetupReferenceSizeCustom)
                .font(FashTypography.labelSmall.weight(customSizeMode ? .semibold : .regular))
                .foregroundStyle(customSizeMode ? FashColors.readableOnBrandPrimary : FashColors.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(customSizeMode ? FashColors.brandPrimary : FashColors.surfaceContainer)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    /// Align custom-mode with stored value (Android `remember(referenceSize, genderPreference)`).
    private func resetCustomModeFromReference() {
        let trimmed = referenceSize.trimmingCharacters(in: .whitespacesAndNewlines)
        customSizeMode = !trimmed.isEmpty
            && !SizingReferenceGuide.isStandardReferenceSize(trimmed, genderPreference: genderPreference)
        if !customSizeMode,
           SizingReferenceGuide.isStandardReferenceSize(trimmed, genderPreference: genderPreference) {
            referenceSize = trimmed.uppercased()
        }
    }
}
