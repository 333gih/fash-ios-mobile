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

struct MaintenanceResumeOverlay: View {
    let presentation: MaintenanceResumePresentation
    let onDismiss: () -> Void
    let onExplore: () -> Void

    @State private var appeared = false
    @State private var pulse = false

    var body: some View {
        ZStack {
            Color.black.opacity(presentation.isWarningCleared ? 0.28 : 0.46)
                .ignoresSafeArea()
                .onTapGesture {
                    if presentation.isWarningCleared {
                        onDismiss()
                    }
                }

            if presentation.isWarningCleared {
                warningChip
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                backOnlineCard
                    .scaleEffect(appeared ? 1 : 0.92)
                    .opacity(appeared ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
                appeared = true
            }
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                pulse = true
            }
            if presentation.isWarningCleared {
                Task {
                    try? await Task.sleep(for: .seconds(3.5))
                    onDismiss()
                }
            }
        }
    }

    private var warningChip: some View {
        VStack {
            Spacer()
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.green)
                    .symbolEffect(.bounce, value: appeared)
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.maintenanceResumeWarningTitle)
                        .font(.subheadline.weight(.semibold))
                    Text(L10n.maintenanceResumeWarningBody)
                        .font(.caption)
                        .foregroundStyle(FashColors.textSecondary)
                }
                Spacer(minLength: 0)
                Button(L10n.maintenanceResumeCtaContinue) {
                    onDismiss()
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(FashColors.brandPrimary)
            }
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
    }

    private var backOnlineCard: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(FashColors.brandPrimary.opacity(0.14))
                    .frame(width: pulse ? 88 : 76, height: pulse ? 88 : 76)
                Image(systemName: "sparkles")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(FashColors.brandPrimary)
                    .symbolEffect(.pulse, options: .repeating, value: pulse)
            }
            .padding(.top, 28)

            Text(displayTitle)
                .font(.title3.weight(.bold))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.top, 16)

            Text(displayBody)
                .font(.subheadline)
                .foregroundStyle(FashColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.top, 8)

            if !presentation.noteLines.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.maintenanceResumeWhatsNew)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(FashColors.textSecondary)
                        .textCase(.uppercase)
                    ForEach(Array(presentation.noteLines.enumerated()), id: \.offset) { _, line in
                        HStack(alignment: .top, spacing: 8) {
                            Circle()
                                .fill(FashColors.brandPrimary)
                                .frame(width: 6, height: 6)
                                .padding(.top, 6)
                            Text(line)
                                .font(.subheadline)
                                .foregroundStyle(FashColors.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding(16)
                .background(FashColors.surfaceContainerHigh, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }

            Button {
                onExplore()
            } label: {
                Text(L10n.maintenanceResumeCtaExplore)
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(FashColors.brandPrimary)
            .padding(.horizontal, 20)
            .padding(.top, 22)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: 360)
        .background(FashColors.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 24, y: 12)
        .padding(.horizontal, 24)
    }

    private var displayTitle: String {
        if let custom = presentation.releaseNotesTitle?.trimmingCharacters(in: .whitespacesAndNewlines), !custom.isEmpty {
            return custom
        }
        return L10n.maintenanceResumeBackOnlineTitle
    }

    private var displayBody: String {
        if !presentation.noteLines.isEmpty {
            return L10n.maintenanceResumeBackOnlineBodyNotes
        }
        return L10n.maintenanceResumeBackOnlineBody
    }
}
