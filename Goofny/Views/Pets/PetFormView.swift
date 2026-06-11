import SwiftUI
import PhotosUI

/// Add Pet & Edit Pet screen (mode depends on the view model).
struct PetFormView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: PetFormViewModel

    @State private var newVaccineName = ""
    @State private var newVaccineDate = Date()
    @State private var newConditionName = ""
    @State private var newConditionNotes = ""
    @State private var showDeleteConfirm = false

    var body: some View {
        Form {
            photoSection
            basicsSection
            locationSection
            notesSection
            if viewModel.isEditing {
                vaccinationsSection
                conditionsSection
                deleteSection
            }
            if let error = viewModel.errorMessage {
                Text(error).foregroundStyle(.red).font(.footnote)
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
                .disabled(!viewModel.isValid || viewModel.isSaving)
            }
            if viewModel.isEditing {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .task { await viewModel.loadHealthRecords() }
        .onChange(of: viewModel.didSave) { _, saved in
            if saved { dismiss() }
        }
        .alert("Delete \(viewModel.name)?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                Task {
                    if await viewModel.deletePet() { dismiss() }
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

            Picker("Breed", selection: $viewModel.breed) {
                Text("Select a breed").tag("")
                ForEach(Breeds.list(for: viewModel.species), id: \.self) { breed in
                    Text(breed).tag(breed)
                }
            }

            Stepper("Age: \(viewModel.age) year\(viewModel.age == 1 ? "" : "s")", value: $viewModel.age, in: 0...50)
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
            ForEach(viewModel.vaccinations) { vaccination in
                HStack {
                    Text(vaccination.vaccineName)
                    Spacer()
                    Text(vaccination.vaccinationDate.formatted(date: .abbreviated, time: .omitted))
                        .foregroundStyle(.secondary)
                }
                .swipeActions {
                    Button("Delete", role: .destructive) {
                        Task { await viewModel.deleteVaccination(vaccination) }
                    }
                }
            }
            HStack {
                TextField("Vaccine name", text: $newVaccineName)
                DatePicker("", selection: $newVaccineDate, displayedComponents: .date)
                    .labelsHidden()
                Button {
                    Task {
                        await viewModel.addVaccination(name: newVaccineName, date: newVaccineDate)
                        newVaccineName = ""
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
                .disabled(newVaccineName.isEmpty)
            }
        }
    }

    private var conditionsSection: some View {
        Section("Medical Conditions 🏥") {
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
            VStack {
                TextField("Condition name", text: $newConditionName)
                HStack {
                    TextField("Notes (optional)", text: $newConditionNotes)
                    Button {
                        Task {
                            await viewModel.addCondition(name: newConditionName, notes: newConditionNotes)
                            newConditionName = ""
                            newConditionNotes = ""
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
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
