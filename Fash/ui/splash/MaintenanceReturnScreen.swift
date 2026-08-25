import SwiftUI

/// Full-screen gate after maintenance ends — blocks Home until user continues (Depop/Poshmark-style reopen sheet).
struct MaintenanceReturnScreen: View {
    let presentation: MaintenanceResumePresentation
    let onExplore: () -> Void
    let onHome: () -> Void

    @State private var appeared = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [FashColors.brandPrimary.opacity(0.12), FashColors.screen],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 280)
                .overlay(alignment: .bottom) {
                    MaintenanceMascotImage(maxWidth: 200)
                        .scaleEffect(appeared ? 1 : 0.88)
                        .opacity(appeared ? 1 : 0)
                        .padding(.bottom, 8)
                }

                VStack(spacing: 12) {
                    Text(displayTitle)
                        .font(.title2.weight(.bold))
                        .multilineTextAlignment(.center)
                    Text(L10n.maintenanceReturnApology)
                        .font(.subheadline)
                        .foregroundStyle(FashColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 28)
                .padding(.top, 8)

                notesCard
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                VStack(spacing: 10) {
                    FashPrimaryButton(title: L10n.maintenanceResumeCtaExplore, action: onExplore)
                    Button(L10n.maintenanceReturnCtaHome, action: onHome)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(FashColors.textSecondary)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(FashColors.screen)
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                appeared = true
            }
        }
    }

    @ViewBuilder
    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.maintenanceResumeWhatsNew)
                .font(.caption.weight(.semibold))
                .foregroundStyle(FashColors.textSecondary)
                .textCase(.uppercase)
            ForEach(noteLines, id: \.self) { line in
                HStack(alignment: .top, spacing: 10) {
                    Circle()
                        .fill(FashColors.brandPrimary)
                        .frame(width: 6, height: 6)
                        .padding(.top, 7)
                    Text(line)
                        .font(.subheadline)
                        .foregroundStyle(FashColors.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FashColors.surfaceContainerHigh, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var displayTitle: String {
        if let custom = presentation.releaseNotesTitle?.trimmingCharacters(in: .whitespacesAndNewlines), !custom.isEmpty {
            return custom
        }
        return L10n.maintenanceResumeBackOnlineTitle
    }

    private var noteLines: [String] {
        if !presentation.noteLines.isEmpty { return presentation.noteLines }
        return [
            L10n.maintenanceReturnDefaultNote1,
            L10n.maintenanceReturnDefaultNote2,
            L10n.maintenanceReturnDefaultNote3,
        ]
    }
}
