import SwiftUI

private let listingPickerPageSize = 30

struct SellerListingPickerSheet: View {
    @Environment(AppDependencies.self) private var deps
    @Environment(\.fashSpacing) private var spacing

    let selectedId: String
    var onDismiss: () -> Void
    var onSelect: (ListingFeedItem) -> Void

    @State private var query = ""
    @State private var listings: [ListingFeedItem] = []
    @State private var loading = true
    @State private var loadingMore = false
    @State private var offset = 0
    @State private var hasMore = true

    private var filtered: [ListingFeedItem] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return listings }
        return listings.filter {
            $0.title.lowercased().contains(q) || $0.id.lowercased().contains(q)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                SellerPackageFilledField(
                    label: L10n.sellerPackagesToolsSearchListings,
                    text: $query
                )
                Group {
                    if loading {
                        ProgressView()
                            .tint(FashColors.brandPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 160)
                    } else if filtered.isEmpty {
                        Text(L10n.sellerPackagesToolsNoListings)
                            .font(FashTypography.bodyMedium)
                            .foregroundStyle(FashColors.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(filtered) { item in
                                    listingRow(item)
                                        .onAppear {
                                            if item.id == filtered.last?.id {
                                                Task { await loadPage(reset: false) }
                                            }
                                        }
                                }
                                if loadingMore {
                                    ProgressView()
                                        .tint(FashColors.brandPrimary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                }
                            }
                        }
                        .frame(height: 360)
                    }
                }
            }
            .padding(.horizontal, spacing.editorialStart)
            .padding(.bottom, 24)
            .background(FashColors.screen)
            .navigationTitle(L10n.sellerPackagesToolsPickListing)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.createListingCloseCd, action: onDismiss)
                }
            }
            .task { await loadPage(reset: true) }
        }
        .presentationDetents([.medium, .large])
    }

    private func listingRow(_ item: ListingFeedItem) -> some View {
        let selected = item.id == selectedId
        return Button {
            onSelect(item)
            onDismiss()
        } label: {
            HStack(spacing: 12) {
                Color.clear
                    .frame(width: 56, height: 56)
                    .overlay {
                        FashAsyncImage(url: item.coverImageUrl, contentMode: .fill)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(FashColors.surfaceContainerHigh)
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title.isEmpty ? item.id : item.title)
                        .font(FashTypography.bodyMedium.weight(.semibold))
                        .foregroundStyle(FashColors.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    if let status = item.listingStatus, !status.isEmpty {
                        Text(status)
                            .font(FashTypography.labelSmall)
                            .foregroundStyle(FashColors.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if selected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(FashColors.brandPrimary)
                }
            }
            .padding(10)
            .background(FashColors.surface)
            .overlay(
                RoundedRectangle(cornerRadius: spacing.radiusSoftMin, style: .continuous)
                    .stroke(
                        selected ? FashColors.brandPrimary : FashColors.outlineMuted.opacity(0.5),
                        lineWidth: selected ? 2 : 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: spacing.radiusSoftMin, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func loadPage(reset: Bool) async {
        if reset {
            loading = true
            offset = 0
            hasMore = true
        } else {
            guard !loadingMore, hasMore else { return }
            loadingMore = true
        }
        let nextOffset = reset ? 0 : offset
        let active = await deps.listingRepository.getMyListings(
            status: "active",
            limit: listingPickerPageSize,
            offset: nextOffset
        )
        var result = active
        if reset, case .success(let page) = active, page.isEmpty {
            result = await deps.listingRepository.getMyListings(
                status: nil,
                limit: listingPickerPageSize,
                offset: nextOffset
            )
        }
        await MainActor.run {
            if reset { loading = false } else { loadingMore = false }
            if case .success(let page) = result {
                hasMore = page.count >= listingPickerPageSize
                listings = reset ? page : listings + page
                offset = reset ? page.count : offset + page.count
            }
        }
    }
}
