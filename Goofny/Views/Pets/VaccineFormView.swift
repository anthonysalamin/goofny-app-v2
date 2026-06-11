import SwiftUI

/// Add or edit a vaccine record for a pet.
/// The vaccine list adapts to the pet's species (dog / cat).
struct VaccineFormView: View {
    let species: Species
    let existing: Vaccination?
    let onSave: (_ vaccineName: String, _ date: Date, _ protectionMonths: Int, _ reminderEnabled: Bool) async -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var selectedVaccine: VaccineInfo?
    @State private var administeredDate: Date = .now
    @State private var protectionMonths: Int = 12
    @State private var isCustomDuration = false
    @State private var reminderEnabled = false
    @State private var isSaving = false
    @State private var errorMessage: String?

    private var catalog: [VaccineInfo] { VaccineCatalog.list(for: species) }
    private var isEditing: Bool { existing != nil }

    private var nextDueDate: Date {
        Calendar.current.date(byAdding: .month, value: protectionMonths, to: administeredDate) ?? administeredDate
    }

    var body: some View {
        NavigationStack {
            Form {
                vaccineSection
                if selectedVaccine != nil {
                    dateSection
                    durationSection
                    reminderSection
                }
            }
            .navigationTitle(isEditing ? "Edit Vaccine" : "Add Vaccine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await save() }
                    } label: {
                        if isSaving { ProgressView() } else { Text("Save").bold() }
                    }
                    .disabled(selectedVaccine == nil || isSaving)
                }
            }
            .toast(message: $errorMessage)
            .onAppear(perform: prefill)
        }
        .presentationDetents([.large])
    }

    // MARK: Sections

    private var vaccineSection: some View {
        Section("\(species.emoji) \(species.label) vaccine") {
            Picker("Vaccine", selection: $selectedVaccine) {
                Text("Select a vaccine").tag(VaccineInfo?.none)
                ForEach(catalog) { vaccine in
                    Text(vaccine.name).tag(VaccineInfo?.some(vaccine))
                }
            }
            .onChange(of: selectedVaccine) { _, newValue in
                // Pre-fill the default protection duration unless the user customized it
                if let newValue, !isCustomDuration {
                    protectionMonths = newValue.defaultMonths
                }
            }

            if let note = selectedVaccine?.durationNote {
                Text(note)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var dateSection: some View {
        Section("Administered on") {
            DatePicker(
                "Date",
                selection: $administeredDate,
                in: ...Date.now,
                displayedComponents: .date
            )
        }
    }

    private var durationSection: some View {
        Section {
            Toggle("Custom duration", isOn: $isCustomDuration.animation())
                .onChange(of: isCustomDuration) { _, custom in
                    if !custom, let vaccine = selectedVaccine {
                        protectionMonths = vaccine.defaultMonths
                    }
                }

            if isCustomDuration {
                Stepper(value: $protectionMonths, in: 1...120) {
                    LabeledContent("Protection", value: VaccineInfo.durationLabel(months: protectionMonths))
                }
            } else {
                LabeledContent("Protection (default)", value: VaccineInfo.durationLabel(months: protectionMonths))
            }

            LabeledContent("Next renewal", value: nextDueDate.formatted(date: .abbreviated, time: .omitted))
                .foregroundStyle(nextDueDate < .now ? .red : .primary)
        } header: {
            Text("Protection duration")
        } footer: {
            if let vaccine = selectedVaccine {
                Text("Default for \(vaccine.name): \(vaccine.defaultDurationLabel). Enable custom duration to override (e.g. for local regulations).")
            }
        }
    }

    private var reminderSection: some View {
        Section {
            Toggle("Notify me when renewal is due", isOn: $reminderEnabled)
        } footer: {
            Text("You'll get a notification 14 days before the renewal date and on the day itself.")
        }
    }

    // MARK: Logic

    private func prefill() {
        guard let existing else { return }
        selectedVaccine = VaccineCatalog.info(name: existing.vaccineName, species: species)
            ?? VaccineInfo(name: existing.vaccineName, defaultMonths: existing.protectionMonths, durationNote: nil)
        administeredDate = existing.date ?? .now
        protectionMonths = existing.protectionMonths
        isCustomDuration = existing.protectionMonths != selectedVaccine?.defaultMonths
        reminderEnabled = existing.reminderEnabled
    }

    private func save() async {
        guard let vaccine = selectedVaccine else { return }
        isSaving = true
        defer { isSaving = false }

        if reminderEnabled {
            let granted = await NotificationService().requestPermission()
            if !granted {
                errorMessage = "Notifications are disabled for Goofny. Enable them in Settings to get renewal reminders."
            }
        }

        await onSave(vaccine.name, administeredDate, protectionMonths, reminderEnabled)
        dismiss()
    }
}

// MARK: - Vaccination row (shared by the pet form and detail screen)

struct VaccinationRow: View {
    let vaccination: Vaccination

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(vaccination.vaccineName)
                        .font(.subheadline.bold())
                    if vaccination.reminderEnabled {
                        Image(systemName: "bell.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                }
                Text("Given \(vaccination.displayDate) · protects \(VaccineInfo.durationLabel(months: vaccination.protectionMonths))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let due = vaccination.nextDueDate {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(vaccination.isOverdue ? "Overdue" : "Renews")
                        .font(.caption2.bold())
                        .foregroundStyle(statusColor)
                    Text(due.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(statusColor)
                }
            }
        }
    }

    private var statusColor: Color {
        if vaccination.isOverdue { return .red }
        if vaccination.isDueSoon { return .orange }
        return .secondary
    }
}
