import SwiftUI

struct ExploreCategoryStrip: View {
    @Environment(\.fashSpacing) private var spacing
    let roots: [CategoryTreeNode]
    var selectedId: String?
    var onSelect: (CategoryTreeNode?) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: spacing.spacing2) {
                categoryChip(title: L10n.exploreCategoryAll, selected: selectedId == nil) {
                    onSelect(nil)
                }
                ForEach(roots, id: \.id) { node in
                    categoryChip(title: node.name, selected: selectedId == node.id) {
                        onSelect(node)
                    }
                }
            }
            .padding(.horizontal, spacing.editorialStart)
            .padding(.vertical, spacing.spacing2)
        }
    }

    private func categoryChip(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(FashTypography.labelMedium.weight(selected ? .semibold : .regular))
                .foregroundStyle(selected ? FashColors.brandPrimary : FashColors.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(selected ? FashColors.brandPrimary.opacity(0.12) : FashColors.surfaceContainerLow)
                .clipShape(Capsule())
                .overlay {
                    if selected {
                        Capsule().strokeBorder(FashColors.brandPrimary.opacity(0.35), lineWidth: 1)
                    }
                }
        }
        .buttonStyle(.plain)
    }
}
