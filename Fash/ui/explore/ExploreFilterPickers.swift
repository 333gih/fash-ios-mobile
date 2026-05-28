import SwiftUI

/// Searchable multi-select aesthetic tag picker — Android `ExploreAestheticTagPickerSheet`.
struct ExploreAestheticTagPickerSheet: View {
    @Environment(\.fashSpacing) private var spacing
    @Environment(\.dismiss) private var dismiss
    let tags: [CommonAestheticTagDto]
    @Binding var selectedIds: Set<String>
    var onDismiss: () -> Void

    @State private var query = ""

    private var filtered: [CommonAestheticTagDto] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return tags }
        return tags.filter {
            $0.name.lowercased().contains(q)
                || $0.displayName.lowercased().contains(q)
                || $0.displayNameVi.lowercased().contains(q)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if !selectedIds.isEmpty {
                    Section {
                        Button(L10n.exploreFilterAestheticClear, role: .destructive) {
                            selectedIds = []
                        }
                    }
                }
                Section {
                    ForEach(filtered) { tag in
                        let selected = selectedIds.contains(tag.id)
                        Button {
                            if selected { selectedIds.remove(tag.id) }
                            else { selectedIds.insert(tag.id) }
                        } label: {
                            HStack {
                                Text(tag.displayLabel())
                                    .foregroundStyle(FashColors.textPrimary)
                                Spacer()
                                if selected {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(FashColors.brandPrimary)
                                }
                            }
                        }
                    }
                }
            }
            .searchable(text: $query, prompt: L10n.exploreFilterAestheticSearchPlaceholder)
            .navigationTitle(L10n.exploreFilterTeaserStyle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.createListingCloseCd) {
                        onDismiss()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.exploreFilterSheetDone) {
                        onDismiss()
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.fraction(0.85)])
        .presentationDragIndicator(.visible)
    }
}

enum ExploreFilterPickers {}
