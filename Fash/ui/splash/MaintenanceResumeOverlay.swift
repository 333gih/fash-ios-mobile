import SwiftUI

struct MaintenanceResumePresentation: Equatable {
    let moment: String
    let releaseNotesTitle: String?
    let releaseNotes: String?
    let updatedAtToken: String

    var isWarningCleared: Bool { moment == "warning_cleared" }
    var isBackOnline: Bool { moment == "back_online" }

    var noteLines: [String] {
        guard let raw = releaseNotes?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
            return []
        }
        return raw
            .split(whereSeparator: \.isNewline)
            .map { line in
                var s = String(line).trimmingCharacters(in: .whitespaces)
                while s.hasPrefix("-") || s.hasPrefix("•") || s.hasPrefix("*") {
                    s.removeFirst()
                    s = s.trimmingCharacters(in: .whitespaces)
                }
                return s
            }
            .filter { !$0.isEmpty }
    }
}

/// Lightweight chip when admin cancels the countdown — app stays usable underneath.
struct MaintenanceResumeOverlay: View {
    let presentation: MaintenanceResumePresentation
    let onDismiss: () -> Void

    @State private var appeared = false

    var body: some View {
        VStack {
            Spacer()
            HStack(spacing: 12) {
                MaintenanceMascotImage(maxWidth: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.maintenanceResumeWarningTitle)
                        .font(.subheadline.weight(.semibold))
                    Text(L10n.maintenanceResumeWarningBody)
                        .font(.caption)
                        .foregroundStyle(FashColors.textSecondary)
                }
                Spacer(minLength: 0)
                Button(L10n.maintenanceResumeCtaContinue) { onDismiss() }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(FashColors.brandPrimary)
            }
            .padding(14)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(FashColors.brandPrimary.opacity(0.25), lineWidth: 1)
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
            .offset(y: appeared ? 0 : 80)
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
                appeared = true
            }
            Task {
                try? await Task.sleep(for: .seconds(4))
                onDismiss()
            }
        }
    }
}
