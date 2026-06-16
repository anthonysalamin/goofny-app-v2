import SwiftUI

// MARK: - Form state

/// Holds all mutable state for the vaccine form.
/// Using @Observable lets SwiftUI re-render only the section that changed a property,
/// so typing in the vet/clinic fields doesn't force the Picker or DatePicker to re-render.
@Observable
private final class VaccineFormState {
    var selectedVaccineID: String?
    var customVaccine: VaccineInfo?
    var dateGiven: Date = .now
    /// Captured once so the DatePicker range stays stable across re-renders.
    let maxDate: Date = .now
    var protectionDurationMonths: Int = 12
    var isCustomDuration = false
    var vetName = ""
    var clinicName = ""
    var clinicLocation = ""
    var batchNumber = ""
    var notes = ""
    var reminderEnabled = false
    var isSaving = false
    var errorMessage: String?
}

// MARK: - View

/// Add or edit a vaccine record for a pet.
/// The vaccine list adapts to the pet's species (dog / cat).
struct VaccineFormView: View {
    let species: Species
    let existing: Vaccination?
    let onSave: (VaccinationFormData) async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var formState = VaccineFormState()

    private var catalog: [VaccineInfo] { VaccineCatalog.list(for: species) }
    private var isEditing: Bool { existing != nil }

    private var selectedVaccine: VaccineInfo? {
        guard let id = formState.selectedVaccineID else { return nil }
        return catalog.first { $0.id == id } ?? formState.customVaccine
    }

    var body: some View {
        @Bindable var state = formState
        NavigationStack {
            Form {
                VaccinePickerSection(formState: formState, species: species, catalog: catalog)
                if selectedVaccine != nil {
                    VaccineDateSection(formState: formState)
                    VaccineDurationSection(formState: formState, catalog: catalog)
                    VetClinicSection(formState: formState)
                    VaccineNotesSection(formState: formState)
                    VaccineReminderSection(formState: formState)
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
                        if formState.isSaving { ProgressView() } else { Text("Save").bold() }
                    }
                    .disabled(selectedVaccine == nil || formState.isSaving)
                }
            }
            .toast(message: $state.errorMessage)
            .onAppear(perform: prefill)
        }
        .presentationDetents([.large])
    }

    private func prefill() {
        guard let existing else { return }
        if let match = VaccineCatalog.info(name: existing.vaccineType, species: species) {
            formState.selectedVaccineID = match.id
        } else {
            formState.customVaccine = VaccineInfo(
                name: existing.vaccineType,
                defaultMonths: existing.protectionDurationMonths,
                durationNote: nil,
                description: existing.description(for: species) ?? "Vaccine record for \(existing.vaccineType).",
                diseasesCovered: existing.diseaseCovered
            )
            formState.selectedVaccineID = existing.vaccineType
        }
        formState.dateGiven = existing.date ?? .now
        formState.protectionDurationMonths = existing.protectionDurationMonths
        formState.isCustomDuration = existing.protectionDurationMonths != selectedVaccine?.defaultMonths
        formState.vetName = existing.vetName ?? ""
        formState.clinicName = existing.clinicName ?? ""
        formState.clinicLocation = existing.clinicLocation ?? ""
        formState.batchNumber = existing.batchNumber ?? ""
        formState.notes = existing.notes ?? ""
        formState.reminderEnabled = existing.reminderEnabled
    }

    private func save() async {
        guard let vaccine = selectedVaccine else { return }
        formState.isSaving = true
        defer { formState.isSaving = false }

        if formState.reminderEnabled {
            let granted = await NotificationService().requestPermission()
            if !granted {
                formState.errorMessage = "Notifications are disabled for Goofny. Enable them in Settings to get renewal reminders."
            }
        }

        await onSave(VaccinationFormData(
            vaccineType: vaccine.name,
            diseaseCovered: vaccine.diseasesCovered,
            dateGiven: formState.dateGiven,
            protectionDurationMonths: formState.protectionDurationMonths,
            vetName: formState.vetName,
            clinicName: formState.clinicName,
            clinicLocation: formState.clinicLocation,
            batchNumber: formState.batchNumber,
            notes: formState.notes,
            reminderEnabled: formState.reminderEnabled
        ))
        dismiss()
    }
}

// MARK: - Section subviews

private struct VaccinePickerSection: View {
    @Bindable var formState: VaccineFormState
    let species: Species
    let catalog: [VaccineInfo]

    private var selectedVaccine: VaccineInfo? {
        guard let id = formState.selectedVaccineID else { return nil }
        return catalog.first { $0.id == id } ?? formState.customVaccine
    }

    var body: some View {
        Section("\(species.emoji) \(species.label) vaccine") {
            Picker("Vaccine type", selection: $formState.selectedVaccineID) {
                Text("Select a vaccine").tag(String?.none)
                ForEach(catalog) { vaccine in
                    Text(vaccine.name).tag(Optional(vaccine.id))
                }
            }
            .onChange(of: formState.selectedVaccineID) { _, _ in
                if let selectedVaccine, !formState.isCustomDuration {
                    formState.protectionDurationMonths = selectedVaccine.defaultMonths
                }
            }

            if let vaccine = selectedVaccine {
                Text(vaccine.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if !vaccine.diseasesCovered.isEmpty {
                    LabeledContent("Protects against") {
                        Text(vaccine.diseasesCovered.joined(separator: ", "))
                            .multilineTextAlignment(.trailing)
                    }
                    .font(.caption)
                }

                if let note = vaccine.durationNote {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }
}

private struct VaccineDateSection: View {
    @Bindable var formState: VaccineFormState

    var body: some View {
        Section("Date given") {
            DatePicker(
                "Date given",
                selection: $formState.dateGiven,
                in: ...formState.maxDate,
                displayedComponents: .date
            )
        }
    }
}

private struct VaccineDurationSection: View {
    @Bindable var formState: VaccineFormState
    let catalog: [VaccineInfo]

    private var selectedVaccine: VaccineInfo? {
        guard let id = formState.selectedVaccineID else { return nil }
        return catalog.first { $0.id == id } ?? formState.customVaccine
    }

    private var nextDueDate: Date {
        Calendar.current.date(byAdding: .month, value: formState.protectionDurationMonths, to: formState.dateGiven) ?? formState.dateGiven
    }

    var body: some View {
        Section {
            Toggle("Custom duration", isOn: $formState.isCustomDuration.animation())
                .onChange(of: formState.isCustomDuration) { _, custom in
                    if !custom, let vaccine = selectedVaccine {
                        formState.protectionDurationMonths = vaccine.defaultMonths
                    }
                }

            if formState.isCustomDuration {
                Stepper(value: $formState.protectionDurationMonths, in: 1...120) {
                    LabeledContent("Protection duration", value: VaccineInfo.durationLabel(months: formState.protectionDurationMonths))
                }
            } else {
                LabeledContent("Protection duration (default)", value: VaccineInfo.durationLabel(months: formState.protectionDurationMonths))
            }

            LabeledContent("Next due date", value: nextDueDate.formatted(date: .abbreviated, time: .omitted))
                .foregroundStyle(nextDueDate < .now ? .red : .primary)
        } header: {
            Text("Protection")
        } footer: {
            if let vaccine = selectedVaccine {
                Text("Default for \(vaccine.name): \(vaccine.defaultDurationLabel). Turn on custom duration to change it (for example, if your vet gave a different schedule).")
            }
        }
    }
}

private struct VetClinicSection: View {
    @Bindable var formState: VaccineFormState

    var body: some View {
        Section("Vet & clinic") {
            TextField("Vet name", text: $formState.vetName)
            TextField("Clinic name", text: $formState.clinicName)
            TextField("Clinic location", text: $formState.clinicLocation)
            TextField("Batch number", text: $formState.batchNumber)
        }
    }
}

private struct VaccineNotesSection: View {
    @Bindable var formState: VaccineFormState

    var body: some View {
        Section("Notes") {
            TextField("Anything else to remember", text: $formState.notes, axis: .vertical)
                .lineLimit(3...6)
        }
    }
}

private struct VaccineReminderSection: View {
    @Bindable var formState: VaccineFormState

    var body: some View {
        Section {
            Toggle("Notify me when renewal is due", isOn: $formState.reminderEnabled)
        } footer: {
            Text("You'll get a notification 14 days before the due date and on the day itself.")
        }
    }
}

// MARK: - Vaccination row (shared by the pet form and detail screen)

struct VaccinationRow: View {
    let species: Species
    let vaccination: Vaccination

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(vaccination.vaccineType)
                        .font(.subheadline.bold())
                    if vaccination.reminderEnabled {
                        Image(systemName: "bell.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                }

                if let description = vaccination.description(for: species) {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let diseases = vaccination.diseasesLabel {
                    Text("Protects against: \(diseases)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Text("Given \(vaccination.displayDate) · protects \(VaccineInfo.durationLabel(months: vaccination.protectionDurationMonths))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                if let vetClinic = vaccination.vetClinicLabel {
                    Text(vetClinic)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                if let batch = vaccination.batchNumber, !batch.isEmpty {
                    Text("Batch: \(batch)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                if let notes = vaccination.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if let due = vaccination.nextDueDate {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(vaccination.isOverdue ? "Overdue" : "Due")
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
