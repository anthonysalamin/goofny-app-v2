import Foundation
import SwiftUI
import PhotosUI

/// Backs both Add Pet and Edit Pet screens.
@MainActor
final class PetFormViewModel: ObservableObject {
    // Form fields
    @Published var name = ""
    @Published var species: Species = .dog { didSet { if oldValue != species { breed = "" } } }
    @Published var sex: Sex = .male
    @Published var breed = ""
    @Published var age = 1
    @Published var country: String = Locale.current.region?.identifier ?? "US"
    @Published var city = ""
    @Published var notes = ""

    // Avatar
    @Published var photoItem: PhotosPickerItem? {
        didSet { Task { await loadPhoto() } }
    }
    @Published var avatarImage: Image?
    private var avatarData: Data?
    private var existingAvatarURL: String?

    // Health records (edit mode only)
    @Published var vaccinations: [Vaccination] = []
    @Published var conditions: [MedicalCondition] = []

    // State
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var didSave = false

    private let petService = PetService()
    private let storageService = StorageService()
    private(set) var editingPet: Pet?

    var isEditing: Bool { editingPet != nil }

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && !breed.isEmpty
            && !city.trimmingCharacters(in: .whitespaces).isEmpty
            && (avatarData != nil || existingAvatarURL != nil)
    }

    init(pet: Pet? = nil) {
        if let pet {
            editingPet = pet
            name = pet.name
            species = pet.species
            sex = pet.sex
            breed = pet.breed
            age = pet.age
            country = pet.country
            city = pet.city
            notes = pet.notes ?? ""
            existingAvatarURL = pet.avatarUrl
        }
    }

    func loadHealthRecords() async {
        guard let pet = editingPet else { return }
        vaccinations = (try? await petService.fetchVaccinations(petID: pet.id)) ?? []
        conditions = (try? await petService.fetchMedicalConditions(petID: pet.id)) ?? []
    }

    private func loadPhoto() async {
        guard let item = photoItem else { return }
        guard let data = try? await item.loadTransferable(type: Data.self),
              let uiImage = UIImage(data: data) else { return }
        // Resize + compress before upload
        let resized = uiImage.resized(maxDimension: 1024)
        avatarData = resized.jpegData(compressionQuality: 0.8)
        avatarImage = Image(uiImage: resized)
    }

    // MARK: Save

    func save(ownerID: UUID) async {
        guard isValid else {
            errorMessage = "Please fill in all required fields and add a photo."
            return
        }
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            var avatarURL = existingAvatarURL
            if let data = avatarData {
                avatarURL = try await storageService.uploadAvatar(data: data, userID: ownerID)
            }

            let payload = PetPayload(
                ownerId: ownerID,
                name: name.trimmingCharacters(in: .whitespaces),
                species: species.rawValue,
                sex: sex.rawValue,
                breed: breed,
                age: age,
                country: country,
                city: city.trimmingCharacters(in: .whitespaces),
                avatarUrl: avatarURL,
                notes: notes.isEmpty ? nil : notes
            )

            if let pet = editingPet {
                try await petService.updatePet(id: pet.id, payload: payload)
            } else {
                try await petService.createPet(payload)
            }
            didSave = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: Health records

    func addVaccination(name: String, date: Date) async {
        guard let pet = editingPet, !name.isEmpty else { return }
        try? await petService.addVaccination(
            VaccinationPayload(petId: pet.id, vaccineName: name, vaccinationDate: date)
        )
        await loadHealthRecords()
    }

    func deleteVaccination(_ vaccination: Vaccination) async {
        try? await petService.deleteVaccination(id: vaccination.id)
        await loadHealthRecords()
    }

    func addCondition(name: String, notes: String) async {
        guard let pet = editingPet, !name.isEmpty else { return }
        try? await petService.addMedicalCondition(
            MedicalConditionPayload(petId: pet.id, conditionName: name, notes: notes.isEmpty ? nil : notes)
        )
        await loadHealthRecords()
    }

    func deleteCondition(_ condition: MedicalCondition) async {
        try? await petService.deleteMedicalCondition(id: condition.id)
        await loadHealthRecords()
    }

    func deletePet() async -> Bool {
        guard let pet = editingPet else { return false }
        do {
            try await petService.deletePet(id: pet.id)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}

extension UIImage {
    func resized(maxDimension: CGFloat) -> UIImage {
        let largest = max(size.width, size.height)
        guard largest > maxDimension else { return self }
        let scale = maxDimension / largest
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in draw(in: CGRect(origin: .zero, size: newSize)) }
    }
}
