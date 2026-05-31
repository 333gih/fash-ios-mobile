import SwiftUI

struct NotificationPreferencesScreen: View {
    @Environment(AppDependencies.self) private var deps
    @Bindable var viewModel: NotificationPreferencesViewModel
    var onDismiss: () -> Void = {}

    var body: some View {
        OverlayScreenHost(title: L10n.notificationPreferencesTitle, onDismiss: onDismiss) {
            Group {
                if viewModel.isLoading && viewModel.prefs == nil {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let prefs = viewModel.prefs {
                    preferencesForm(prefs)
                }
            }
        }
        .task {
            await viewModel.load(deps: deps)
        }
        .overlay(alignment: .topTrailing) {
            if viewModel.isSaving {
                ProgressView()
                    .padding(.top, 12)
                    .padding(.trailing, 16)
            }
        }
    }

    @ViewBuilder
    private func preferencesForm(_ prefs: NotificationPreferences) -> some View {
        List {
            Section {
                Text(L10n.notificationPreferencesSubtitle)
                    .font(FashTypography.bodySmall)
                    .foregroundStyle(FashColors.textSecondary)
                    .listRowBackground(Color.clear)
            }
            Section {
                Toggle(L10n.notificationPreferencesRecommendationPush, isOn: pushBinding)
                    .disabled(viewModel.isSaving)
                Toggle(L10n.notificationPreferencesRecommendationEmail, isOn: emailBinding)
                    .disabled(viewModel.isSaving)
            }
            Section {
                Toggle(L10n.notificationPreferencesQuietHoursEnabled, isOn: quietHoursBinding)
                    .disabled(viewModel.isSaving)
                if prefs.quietHoursStart != nil, prefs.quietHoursEnd != nil {
                    hourPicker(
                        L10n.notificationPreferencesQuietHoursStart,
                        selection: quietStartBinding
                    )
                    hourPicker(
                        L10n.notificationPreferencesQuietHoursEnd,
                        selection: quietEndBinding
                    )
                }
            } header: {
                Text(L10n.notificationPreferencesQuietHours)
            } footer: {
                Text(L10n.notificationPreferencesQuietHoursHint)
            }
            if let msg = viewModel.eventMessage {
                Section {
                    Text(msg)
                        .font(FashTypography.bodySmall)
                        .foregroundStyle(FashColors.error)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var pushBinding: Binding<Bool> {
        Binding(
            get: { viewModel.prefs?.recommendationPushEnabled ?? true },
            set: { newValue in
                Task { await viewModel.onRecommendationPushChanged(newValue, deps: deps) }
            }
        )
    }

    private var emailBinding: Binding<Bool> {
        Binding(
            get: { viewModel.prefs?.recommendationEmailEnabled ?? true },
            set: { newValue in
                Task { await viewModel.onRecommendationEmailChanged(newValue, deps: deps) }
            }
        )
    }

    private var quietHoursBinding: Binding<Bool> {
        Binding(
            get: {
                guard let prefs = viewModel.prefs else { return false }
                return prefs.quietHoursStart != nil && prefs.quietHoursEnd != nil
            },
            set: { newValue in
                Task { await viewModel.onQuietHoursEnabledChanged(newValue, deps: deps) }
            }
        )
    }

    private var quietStartBinding: Binding<Int> {
        Binding(
            get: { viewModel.prefs?.quietHoursStart ?? 22 },
            set: { newValue in
                Task { await viewModel.onQuietHoursStartChanged(newValue, deps: deps) }
            }
        )
    }

    private var quietEndBinding: Binding<Int> {
        Binding(
            get: { viewModel.prefs?.quietHoursEnd ?? 8 },
            set: { newValue in
                Task { await viewModel.onQuietHoursEndChanged(newValue, deps: deps) }
            }
        )
    }

    private func hourPicker(_ label: String, selection: Binding<Int>) -> some View {
        Picker(label, selection: selection) {
            ForEach(0..<24, id: \.self) { hour in
                Text(formatHour(hour)).tag(hour)
            }
        }
        .disabled(viewModel.isSaving)
    }

    private func formatHour(_ hour: Int) -> String {
        String(format: "%02d:00", min(23, max(0, hour)))
    }
}
