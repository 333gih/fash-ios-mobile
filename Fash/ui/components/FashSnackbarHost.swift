import SwiftUI

enum FashSnackbarKind {
    case error
    case success
    case info
}

func inferFashSnackbarKind(message: String) -> FashSnackbarKind {
    let m = message.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    if m.isEmpty { return .info }
    let errorHints = [
        "http ", "failed", "failure", "error", "lỗi", "thất bại", "invalid", "denied",
        "required", "conflict", "not found", "không thể", "không thành công", "permission",
        "server error", "bad request", "authentication", "unauthorized", "forbidden",
        "timeout", "hết hạn", "từ chối",
    ]
    if errorHints.contains(where: { m.contains($0) }) { return .error }
    let successHints = [
        "success", "thành công", "đã lưu", "đã thêm", "đã gỡ", "đã gửi", "đã cập nhật", "đã chia sẻ",
        "đã theo dõi", "saved", "sent", "added", "removed", "following", "available again",
        "có thể mua lại", "yêu thích", "mong muốn", "wishlist",
    ]
    if successHints.contains(where: { m.contains($0) }) { return .success }
    return .info
}

/// Bottom transient message — Android [FashSnackbarHost].
struct FashSnackbarHost: View {
    let message: String
    var onDismiss: () -> Void = {}

    private var kind: FashSnackbarKind { inferFashSnackbarKind(message: message) }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(accentColor)
                .frame(width: 4, height: 44)
            Image(systemName: iconName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(accentColor)
                .frame(width: 36, height: 36)
                .background(iconBackground)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            Text(message)
                .font(FashTypography.bodyMedium.weight(.medium))
                .foregroundStyle(FashColors.textPrimary)
                .lineLimit(4)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(FashColors.textSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(FashColors.surfaceContainerHighest)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(FashColors.outlineMuted.opacity(0.48), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.12), radius: 10, y: 4)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private var accentColor: Color {
        switch kind {
        case .error: return FashColors.error
        case .success: return FashColors.brandPrimary
        case .info: return FashColors.textSecondary
        }
    }

    private var iconBackground: Color {
        switch kind {
        case .error: return FashColors.error.opacity(0.12)
        case .success: return FashColors.brandPrimary.opacity(0.14)
        case .info: return FashColors.surfaceContainer
        }
    }

    private var iconName: String {
        switch kind {
        case .error: return "exclamationmark.circle"
        case .success: return "checkmark.circle.fill"
        case .info: return "info.circle"
        }
    }
}
