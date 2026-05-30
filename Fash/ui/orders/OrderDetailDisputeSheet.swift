import PhotosUI
import SwiftUI

/// Open dispute / submit evidence — parity with Android `OrderDetailScreen` dispute dialogs.
struct OrderDetailDisputeSheet: View {
    @Environment(\.fashSpacing) private var spacing
    @Environment(AppDependencies.self) private var deps

    let isEvidence: Bool
    @Binding var description: String
    @Binding var photoUrls: [String]
    let busy: OrderDetailBusyAction
    let onDismiss: () -> Void
    let onSubmit: () async -> Bool

    @State private var pickerItem: PhotosPickerItem?
    @State private var isUploadingPhoto = false

    private var title: String {
        isEvidence ? L10n.orderDetailDisputeDialogTitleEvidence : L10n.orderDetailDisputeDialogTitleOpen
    }

    private var submitBusy: Bool {
        busy == (isEvidence ? .submitEvidence : .openDispute)
    }

    private var formIdle: Bool {
        busy == .none && !isUploadingPhoto
    }

    private var canSubmit: Bool {
        !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && formIdle
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: spacing.spacing3) {
                    Text(L10n.orderDetailDisputeDescriptionLabel)
                        .font(FashTypography.labelMedium)
                        .foregroundStyle(FashColors.textSecondary)
                    TextField("", text: $description, axis: .vertical)
                        .lineLimit(3...8)
                        .padding(12)
                        .background(FashColors.surfaceContainerLow)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .disabled(!formIdle)

                    PhotosPicker(selection: $pickerItem, matching: .images) {
                        HStack {
                            if isUploadingPhoto {
                                ProgressView().scaleEffect(0.85)
                            }
                            Text(L10n.orderDetailDisputeAddPhoto(photoUrls.count))
                                .font(FashTypography.labelLarge.weight(.medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(FashColors.outlineMuted.opacity(0.55), lineWidth: 1)
                        )
                    }
                    .disabled(!formIdle || photoUrls.count >= 10)
                    .onChange(of: pickerItem) { _, item in
                        guard let item else { return }
                        pickerItem = nil
                        Task { await addPhoto(from: item) }
                    }

                    if !photoUrls.isEmpty {
                        disputePhotoGrid
                    }
                }
                .padding(spacing.editorialStart)
                .padding(.vertical, spacing.spacing2)
            }
            .background(FashColors.screen)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.createListingCancel, action: onDismiss)
                        .disabled(submitBusy)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            if await onSubmit() { onDismiss() }
                        }
                    } label: {
                        if submitBusy {
                            ProgressView().scaleEffect(0.85)
                        } else {
                            Text(L10n.orderDetailDisputeSubmit)
                        }
                    }
                    .disabled(!canSubmit)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var disputePhotoGrid: some View {
        let columns = [GridItem(.adaptive(minimum: 72), spacing: 8)]
        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(Array(photoUrls.enumerated()), id: \.offset) { index, url in
                ZStack(alignment: .topTrailing) {
                    FashAsyncImage(
                        url: FeedImageUrl.resolveListingImageUrlOrNil(url),
                        contentMode: .fill
                    )
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    Button {
                        photoUrls.remove(at: index)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(FashColors.textPrimary)
                            .background(Circle().fill(FashColors.surfaceContainerHighest))
                    }
                    .offset(x: 6, y: -6)
                    .disabled(!formIdle)
                }
            }
        }
    }

    private func addPhoto(from item: PhotosPickerItem) async {
        guard photoUrls.count < 10 else {
            deps.showSnackbar(L10n.orderDetailDisputePhotoLimit)
            return
        }
        guard let data = try? await item.loadTransferable(type: Data.self), !data.isEmpty else { return }
        isUploadingPhoto = true
        defer { isUploadingPhoto = false }
        let prefix = isEvidence ? "evidence" : "dispute"
        let filename = "\(prefix)_\(Int(Date().timeIntervalSince1970 * 1000)).jpg"
        switch await deps.listingRepository.uploadListingImage(bytes: data, filename: filename, mimeType: "image/jpeg") {
        case .success(let upload):
            let url = upload.url
            photoUrls.append(url)
        case .failure(let error):
            let msg = FashErrorPresentation.userMessage(for: error)
            deps.showSnackbar(msg.isEmpty ? L10n.createListingUploadError : msg)
        }
    }
}
