import SwiftUI

/// Lightweight non-blocking milestone toast — appears from the bottom, auto-dismisses after 3.5s.
///
/// Use for meaningful but non-critical milestone moments: profile completion, first save, first listing.
/// Never block user interaction; always auto-dismiss.
struct FashMilestoneToast: View {
    @Environment(\.fashSpacing) private var spacing

    let icon: String
    let message: String
    var onDismiss: () -> Void = {}

    var body: some View {
        Button(action: onDismiss) {
            HStack(spacing: spacing.spacing3) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(FashColors.brandPrimary)
                Text(message)
                    .font(FashTypography.bodyMedium.weight(.semibold))
                    .foregroundStyle(FashColors.textPrimary)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, spacing.editorialStart)
            .padding(.vertical, spacing.spacing3)
            .background(FashColors.surfaceContainerHighest)
            .clipShape(FashShapes.medium)
            .fashAmbientShadow(radius: 12, opacity: 0.1)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, spacing.editorialStart)
    }
}

// MARK: - View Modifier

extension View {
    /// Attaches a milestone toast overlay above the bottom safe area.
    ///
    /// Pass a `Binding<Bool>` — set to `true` to show, the modifier auto-resets it after 3.5 s.
    func fashMilestoneToast(
        isPresented: Binding<Bool>,
        icon: String,
        message: String
    ) -> some View {
        self.overlay(alignment: .bottom) {
            if isPresented.wrappedValue {
                FashMilestoneToast(icon: icon, message: message) {
                    withAnimation(FashMotion.overlay) {
                        isPresented.wrappedValue = false
                    }
                }
                .padding(.bottom, 12)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .onAppear {
                    Task {
                        try? await Task.sleep(nanoseconds: 3_500_000_000)
                        withAnimation(FashMotion.overlay) {
                            isPresented.wrappedValue = false
                        }
                    }
                }
            }
        }
        .animation(FashMotion.overlay, value: isPresented.wrappedValue)
    }
}
