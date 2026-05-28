import SwiftUI

/// Schedule meetup bottom sheet — Android `MeetingProposalBottomSheet` (simplified).
struct MeetingProposalBottomSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppDependencies.self) private var deps

    let conversationId: String
    let linkedOrderId: String?
    let browseProvinceId: String?
    let browseDistrictId: String?
    let isLoading: Bool
    let onSubmit: (
        _ locationUrl: String,
        _ scheduledAtIso: String,
        _ reminderEnabled: Bool,
        _ reminderOffsetMinutes: Int,
        _ safeZoneId: String?,
        _ safeZoneName: String?
    ) -> Void

    @State private var locationTab = 0
    @State private var locationUrl = ""
    @State private var selectedZoneId: String?
    @State private var selectedZoneName = ""
    @State private var zones: [SafeMeetupZoneDto] = []
    @State private var zonesLoading = true
    @State private var zonesError = false
    @State private var selectedDate = Date()
    @State private var selectedTime = MeetingUi.roundUpToNextSlot()
    @State private var reminderEnabled = true
    @State private var reminderOffset = 60
    @State private var showDatePicker = false

    private var preferVi: Bool { AppLocale.currentTag != AppLocale.tagEN }

    private var canSubmit: Bool {
        let locOk = locationTab == 0 ? selectedZoneId != nil : ChatMapsUrlRules.isLenientMeetingMapsUrl(locationUrl)
        let cal = Calendar.current
        let h = cal.component(.hour, from: selectedTime)
        let m = cal.component(.minute, from: selectedTime)
        return locOk && MeetingUi.isScheduleInFuture(date: selectedDate, hour: h, minute: m)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Picker("", selection: $locationTab) {
                        Text(L10n.safeZoneTabPicker).tag(0)
                        Text(L10n.safeZoneTabManual).tag(1)
                    }
                    .pickerStyle(.segmented)

                    if locationTab == 0 {
                        safeZoneSection
                    } else {
                        TextField(L10n.chatMeetingFieldMapsHint, text: $locationUrl, axis: .vertical)
                            .lineLimit(3...5)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: locationUrl) { _, _ in
                                selectedZoneId = nil
                                selectedZoneName = ""
                            }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(L10n.chatMeetingDatetimeLabel)
                            .font(FashTypography.labelMedium)
                        Button {
                            showDatePicker = true
                        } label: {
                            HStack {
                                Image(systemName: "calendar")
                                Text(dateTimeSummary)
                                    .font(FashTypography.bodyMedium)
                                Spacer()
                            }
                            .padding(12)
                            .background(FashColors.surfaceContainer)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                        DatePicker(L10n.chatMeetingPickTime, selection: $selectedTime, displayedComponents: .hourAndMinute)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(L10n.chatMeetingReminderLabel)
                            .font(FashTypography.labelMedium)
                        HStack {
                            reminderChip(15, L10n.chatMeetingReminder15)
                            reminderChip(30, L10n.chatMeetingReminder30)
                            reminderChip(60, L10n.chatMeetingReminder60)
                        }
                        Toggle(L10n.chatMeetingReminderToggle, isOn: $reminderEnabled)
                            .tint(FashColors.brandPrimary)
                    }

                    FashPrimaryButton(title: L10n.chatMeetingSheetSubmit, isLoading: isLoading, enabled: canSubmit) {
                        submit()
                    }
                }
                .padding(20)
            }
            .navigationTitle(L10n.chatMeetingSheetTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.chatMeetingPickerCancel) { if !isLoading { dismiss() } }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .task { await loadZones() }
        .sheet(isPresented: $showDatePicker) {
            VStack {
                DatePicker(
                    L10n.chatMeetingPickDate,
                    selection: $selectedDate,
                    in: Date()...,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .padding()
                Button(L10n.chatMeetingPickerOk) { showDatePicker = false }
                    .padding()
            }
            .presentationDetents([.medium])
        }
    }

    private var safeZoneSection: some View {
        Group {
            if zonesLoading {
                ProgressView().frame(maxWidth: .infinity).padding()
            } else if zonesError {
                Text(L10n.safeZoneLoadError)
                    .font(FashTypography.bodySmall)
                    .foregroundStyle(FashColors.error)
                Button(L10n.safeZoneRetry) { Task { await loadZones() } }
            } else if zones.isEmpty {
                Text(L10n.safeZoneEmptyHint)
                    .font(FashTypography.bodySmall)
                    .foregroundStyle(FashColors.textSecondary)
            } else {
                ForEach(zones) { zone in
                    let label = zone.displayLabel(preferVi: preferVi)
                    let selected = selectedZoneId == zone.id
                    Button {
                        selectedZoneId = zone.id
                        selectedZoneName = label
                        locationUrl = zone.locationUrl
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(label)
                                    .font(FashTypography.bodyMedium.weight(.semibold))
                                    .foregroundStyle(FashColors.textPrimary)
                                if !zone.addressLine.isEmpty {
                                    Text(zone.addressLine)
                                        .font(FashTypography.labelSmall)
                                        .foregroundStyle(FashColors.textSecondary)
                                }
                            }
                            Spacer()
                            if selected {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(FashColors.brandPrimary)
                            }
                        }
                        .padding(12)
                        .background(selected ? FashColors.brandPrimary.opacity(0.08) : FashColors.surfaceContainer)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var dateTimeSummary: String {
        let cal = Calendar.current
        let h = cal.component(.hour, from: selectedTime)
        let m = cal.component(.minute, from: selectedTime)
        let iso = MeetingUi.buildScheduledAtRfc3339(date: selectedDate, hour: h, minute: m)
        return MeetingUi.formatMeetingWhen(iso, preferVi: preferVi)
    }

    private func reminderChip(_ minutes: Int, _ label: String) -> some View {
        Button {
            reminderOffset = minutes
        } label: {
            Text(label)
                .font(FashTypography.labelSmall)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(reminderOffset == minutes ? FashColors.brandPrimary : FashColors.surfaceContainer)
                .foregroundStyle(reminderOffset == minutes ? FashColors.readableOnBrandPrimary : FashColors.textPrimary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func loadZones() async {
        zonesLoading = true
        zonesError = false
        defer { zonesLoading = false }
        switch await deps.publicCatalogRepository.getSafeMeetupZones(
            provinceId: browseProvinceId,
            districtId: browseDistrictId
        ) {
        case .success(let list):
            zones = list
            if selectedZoneId == nil, let first = list.first {
                selectedZoneId = first.id
                selectedZoneName = first.displayLabel(preferVi: preferVi)
                locationUrl = first.locationUrl
            }
        case .failure:
            zonesError = true
        }
    }

    private func submit() {
        let cal = Calendar.current
        let h = cal.component(.hour, from: selectedTime)
        let m = cal.component(.minute, from: selectedTime)
        let iso = MeetingUi.buildScheduledAtRfc3339(date: selectedDate, hour: h, minute: m)
        let url = locationTab == 0 ? locationUrl : locationUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        onSubmit(
            url,
            iso,
            reminderEnabled,
            reminderOffset,
            locationTab == 0 ? selectedZoneId : nil,
            locationTab == 0 ? selectedZoneName : nil
        )
    }
}
