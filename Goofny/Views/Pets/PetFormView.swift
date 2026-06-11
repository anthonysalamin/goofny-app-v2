import SwiftUI
import PhotosUI

/// Add Pet & Edit Pet screen (mode depends on the view model).
struct PetFormView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: PetFormViewModel
    /// Called after a successful save (create or edit).
    var onSaved: (() -> Void)? = nil
    /// Called after the pet was deleted.
    var onDeleted: (() -> Void)? = nil

    /// Single sheet driver — two stacked `.sheet` modifiers inside a Form
    /// section cause immediate-dismiss glitches.
    private enum VaccineSheetMode: Identifiable {
        case add
        case edit(Vaccination)
        var id: String {
            switch self {
            case .add: return "add"
            case .edit(let vaccination): return vaccination.id.uuidString
            }
        }
    }

    @State private var vaccineSheet: VaccineSheetMode?
    @State private var newConditionName = ""
    @State private var newConditionNotes = ""
    @State private var showDeleteConfirm = false

    var body: some View {
        Form {
            photoSection
            basicsSection
            locationSection
            notesSection
            vaccinationsSection
            conditionsSection
            if viewModel.isEditing {
                deleteSection
            }
        }
        .toast(message: $viewModel.errorMessage)
        .sheet(item: $vaccineSheet) { mode in
            switch mode {
            case .add:
                VaccineFormView(species: viewModel.species, existing: nil) { name, date, months, reminder in
                    if viewModel.isEditing {
                        await viewModel.saveVaccination(
                            existing: nil, vaccineName: name, date: date,
                            protectionMonths: months, reminderEnabled: reminder
                        )
                    } else {
                        viewModel.addPendingVaccination(
                            name: name, date: date,
                            protectionMonths: months, reminderEnabled: reminder
                        )
                    }
                }
            case .edit(let vaccination):
                VaccineFormView(species: viewModel.species, existing: vaccination) { name, date, months, reminder in
                    await viewModel.saveVaccination(
                        existing: vaccination, vaccineName: name, date: date,
                        protectionMonths: months, reminderEnabled: reminder
                    )
                }
            }
        }
        .navigationTitle(viewModel.isEditing ? "Edit \(viewModel.name)" : "Add Pet")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    guard let userID = auth.userID else { return }
                    Task { await viewModel.save(ownerID: userID) }
                } label: {
                    if viewModel.isSaving { ProgressView() } else { Text("Save").bold() }
                }
                .disabled(viewModel.isSaving)
            }
            if viewModel.isEditing {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .task { await viewModel.loadHealthRecords() }
        .onChange(of: viewModel.didSave) { _, saved in
            if saved {
                dismiss()
                onSaved?()
            }
        }
        .alert("Delete \(viewModel.name)?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                Task {
                    if await viewModel.deletePet() {
                        dismiss()
                        onDeleted?()
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes the profile and all its votes permanently.")
        }
    }

    // MARK: Sections

    private var photoSection: some View {
        Section("Photo *") {
            HStack {
                Spacer()
                PhotosPicker(selection: $viewModel.photoItem, matching: .images) {
                    if let image = viewModel.avatarImage {
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 140, height: 140)
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                    } else if viewModel.isEditing, let pet = viewModel.editingPet {
                        PetAvatarView(urlString: pet.avatarUrl, size: 140, cornerRadius: 24)
                            .overlay(alignment: .bottomTrailing) { editBadge }
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "camera.fill").font(.title)
                            Text("Choose photo").font(.caption)
                        }
                        .frame(width: 140, height: 140)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                    }
                }
                Spacer()
            }
        }
    }

    private var editBadge: some View {
        Image(systemName: "pencil.circle.fill")
            .font(.title2)
            .foregroundStyle(.white, .orange)
            .offset(x: 6, y: 6)
    }

    private var basicsSection: some View {
        Section("Basics *") {
            TextField("Name", text: $viewModel.name)

            Picker("Species", selection: $viewModel.species) {
                ForEach(Species.allCases) { species in
                    Text("\(species.emoji) \(species.label)").tag(species)
                }
            }
            .pickerStyle(.segmented)

            Picker("Sex", selection: $viewModel.sex) {
                ForEach(Sex.allCases) { sex in
                    Text("\(sex.symbol) \(sex.label)").tag(sex)
                }
            }
            .pickerStyle(.segmented)

            NavigationLink {
                BreedPickerView(species: viewModel.species, selection: $viewModel.breed)
            } label: {
                HStack {
                    Text("Breed")
                    Spacer()
                    Text(viewModel.breed.isEmpty ? "Select a breed" : viewModel.breed)
                        .foregroundStyle(viewModel.breed.isEmpty ? .secondary : .primary)
                }
            }

            DatePicker(
                "Birth date",
                selection: $viewModel.birthDate,
                in: ...Date.now,
                displayedComponents: .date
            )
            LabeledContent("Age", value: "\(viewModel.age) year\(viewModel.age == 1 ? "" : "s")")
        }
    }

    private var locationSection: some View {
        Section("Location *") {
            Picker("Country", selection: $viewModel.country) {
                ForEach(Country.all, id: \.code) { country in
                    Text("\(Country.flag(for: country.code)) \(country.name)").tag(country.code)
                }
            }
            TextField("City", text: $viewModel.city)
        }
    }

    private var notesSection: some View {
        Section("Notes (optional)") {
            TextField("Anything special about your pet?", text: $viewModel.notes, axis: .vertical)
                .lineLimit(3...6)
        }
    }

    private var vaccinationsSection: some View {
        Section("Vaccinations 💉") {
            if viewModel.isEditing {
                ForEach(viewModel.vaccinations) { vaccination in
                    Button {
                        vaccineSheet = .edit(vaccination)
                    } label: {
                        VaccinationRow(vaccination: vaccination)
                    }
                    .buttonStyle(.plain)
                    .swipeActions {
                        Button("Delete", role: .destructive) {
                            Task { await viewModel.deleteVaccination(vaccination) }
                        }
                    }
                }
            } else {
                ForEach(viewModel.pendingVaccinations) { pending in
                    VaccinationRow(vaccination: pending.displayRow)
                        .swipeActions {
                            Button("Delete", role: .destructive) {
                                viewModel.removePendingVaccination(pending)
                            }
                        }
                }
            }

            Button {
                vaccineSheet = .add
            } label: {
                Label("Add vaccine", systemImage: "plus.circle.fill")
                    .foregroundStyle(.orange)
            }
            .buttonStyle(.borderless)
        }
    }

    private var conditionsSection: some View {
        Section("Medical Conditions 🏥") {
            if viewModel.isEditing {
                ForEach(viewModel.conditions) { condition in
                    VStack(alignment: .leading) {
                        Text(condition.conditionName)
                        if let notes = condition.notes {
                            Text(notes).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .swipeActions {
                        Button("Delete", role: .destructive) {
                            Task { await viewModel.deleteCondition(condition) }
                        }
                    }
                }
            } else {
                ForEach(viewModel.pendingConditions) { pending in
                    VStack(alignment: .leading) {
                        Text(pending.name)
                        if !pending.notes.isEmpty {
                            Text(pending.notes).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .swipeActions {
                        Button("Delete", role: .destructive) {
                            viewModel.removePendingCondition(pending)
                        }
                    }
                }
            }

            VStack {
                TextField("Condition name", text: $newConditionName)
                HStack {
                    TextField("Notes (optional)", text: $newConditionNotes)
                    Button {
                        if viewModel.isEditing {
                            Task {
                                await viewModel.addCondition(name: newConditionName, notes: newConditionNotes)
                                newConditionName = ""
                                newConditionNotes = ""
                            }
                        } else {
                            viewModel.addPendingCondition(name: newConditionName, notes: newConditionNotes)
                            newConditionName = ""
                            newConditionNotes = ""
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.orange)
                    }
                    .buttonStyle(.borderless)
                    .disabled(newConditionName.isEmpty)
                }
            }
        }
    }

    private var deleteSection: some View {
        Section {
            Button("Delete Pet", role: .destructive) {
                showDeleteConfirm = true
            }
        }
    }
}
