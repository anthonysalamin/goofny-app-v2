import Foundation
import SwiftUI
import PhotosUI

/// Backs both Add Pet and Edit Pet screens.
@MainActor
final class PetFormViewModel: ObservableObject {
    // Form fields
    @Published var name = ""
    @Published var species: Species = .dog {
        didSet {
            if oldValue != species {
                breed = ""
                // Pending vaccines are species-specific (e.g. DHPP is dog-only)
                pendingVaccinations = []
            }
        }
    }
    @Published var sex: Sex = .male
    @Published var breed = ""
    @Published var birthDate: Date = Calendar.current.date(byAdding: .year, value: -1, to: .now) ?? .now
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

    // Health records (edit mode — already persisted)
    @Published var vaccinations: [Vaccination] = []
    @Published var conditions: [MedicalCondition] = []

    // Health records (create mode — held locally, inserted after the pet is created)
    @Published var pendingVaccinations: [PendingVaccination] = []
    @Published var pendingConditions: [PendingCondition] = []

    // State
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var didSave = false

    private let petService = PetService()
    private let storageService = StorageService()
    private(set) var editingPet: Pet?

    var isEditing: Bool { editingPet != nil }

    /// Age in whole years derived from the birth date.
    var age: Int {
        max(Calendar.current.dateComponents([.year], from: birthDate, to: .now).year ?? 0, 0)
    }

    /// Human-readable list of required fields that are still empty.
    var missingFields: [String] {
        var missing: [String] = []
        if avatarData == nil && existingAvatarURL == nil { missing.append("photo") }
        if name.trimmingCharacters(in: .whitespaces).isEmpty { missing.append("name") }
        if breed.isEmpty { missing.append("breed") }
        if city.trimmingCharacters(in: .whitespaces).isEmpty { missing.append("city") }
        return missing
    }

    var isValid: Bool { missingFields.isEmpty }

    init(pet: Pet? = nil) {
        if let pet {
            editingPet = pet
            name = pet.name
            species = pet.species
            sex = pet.sex
            breed = pet.breed
            // Use the stored birth date; for old rows approximate from the age field
            birthDate = pet.birthDateValue
                ?? Calendar.current.date(byAdding: .year, value: -pet.age, to: .now)
                ?? .now
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
        let missing = missingFields
        guard missing.isEmpty else {
            errorMessage = "Missing required field\(missing.count == 1 ? "" : "s"): \(missing.joined(separator: ", "))."
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
                birthDate: Vaccination.dayFormatter.string(from: birthDate),
                country: country,
                city: city.trimmingCharacters(in: .whitespaces),
                avatarUrl: avatarURL,
                notes: notes.isEmpty ? nil : notes
            )

            if let pet = editingPet {
                try await petService.updatePet(id: pet.id, payload: payload)
            } else {
                let newPet = try await petService.createPet(payload)

                // Persist health records collected during creation
                for pending in pendingVaccinations {
                    let saved = try await petService.addVaccination(
                        VaccinationPayload(
                            petId: newPet.id,
                            vaccineName: pending.vaccineName,
                            vaccinationDate: Vaccination.dayFormatter.string(from: pending.date),
                            protectionMonths: pending.protectionMonths,
                            reminderEnabled: pending.reminderEnabled
                        )
                    )
                    if pending.reminderEnabled {
                        await NotificationService().scheduleRenewalReminders(for: saved, petName: newPet.name)
                    }
                }
                for pending in pendingConditions {
                    try await petService.addMedicalCondition(
                        MedicalConditionPayload(
                            petId: newPet.id,
                            conditionName: pending.name,
                            notes: pending.notes.isEmpty ? nil : pending.notes
                        )
                    )
                }
                pendingVaccinations = []
                pendingConditions = []
            }
            didSave = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: Health records

    /// Insert or update a vaccine record, then (re)schedule renewal reminders.
    func saveVaccination(
        existing: Vaccination?,
        vaccineName: String,
        date: Date,
        protectionMonths: Int,
        reminderEnabled: Bool
    ) async {
        guard let pet = editingPet else { return }
        let payload = VaccinationPayload(
            petId: pet.id,
            vaccineName: vaccineName,
            vaccinationDate: Vaccination.dayFormatter.string(from: date),
            protectionMonths: protectionMonths,
            reminderEnabled: reminderEnabled
        )
        do {
            let saved: Vaccination
            if let existing {
                try await petService.updateVaccination(id: existing.id, payload: payload)
                saved = Vaccination(
                    id: existing.id,
                    petId: pet.id,
                    vaccineName: vaccineName,
                    vaccinationDate: payload.vaccinationDate,
                    protectionMonths: protectionMonths,
                    reminderEnabled: reminderEnabled
                )
            } else {
                saved = try await petService.addVaccination(payload)
            }
            await NotificationService().scheduleRenewalReminders(for: saved, petName: pet.name)
            await loadHealthRecords()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteVaccination(_ vaccination: Vaccination) async {
        do {
            try await petService.deleteVaccination(id: vaccination.id)
            await NotificationService().cancelReminders(for: vaccination.id)
            await loadHealthRecords()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addCondition(name: String, notes: String) async {
        guard let pet = editingPet, !name.isEmpty else { return }
        do {
            try await petService.addMedicalCondition(
                MedicalConditionPayload(petId: pet.id, conditionName: name, notes: notes.isEmpty ? nil : notes)
            )
            await loadHealthRecords()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteCondition(_ condition: MedicalCondition) async {
        do {
            try await petService.deleteMedicalCondition(id: condition.id)
            await loadHealthRecords()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: Pending health records (create mode)

    func addPendingVaccination(name: String, date: Date, protectionMonths: Int, reminderEnabled: Bool) {
        pendingVaccinations.append(
            PendingVaccination(vaccineName: name, date: date,
                               protectionMonths: protectionMonths, reminderEnabled: reminderEnabled)
        )
    }

    func removePendingVaccination(_ pending: PendingVaccination) {
        pendingVaccinations.removeAll { $0.id == pending.id }
    }

    func addPendingCondition(name: String, notes: String) {
        guard !name.isEmpty else { return }
        pendingConditions.append(PendingCondition(name: name, notes: notes))
    }

    func removePendingCondition(_ pending: PendingCondition) {
        pendingConditions.removeAll { $0.id == pending.id }
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

/// Vaccine entered while creating a pet (not yet persisted).
struct PendingVaccination: Identifiable, Hashable {
    let id = UUID()
    var vaccineName: String
    var date: Date
    var protectionMonths: Int
    var reminderEnabled: Bool

    /// Adapter so `VaccinationRow` can render pending entries too.
    var displayRow: Vaccination {
        Vaccination(
            id: id,
            petId: id,
            vaccineName: vaccineName,
            vaccinationDate: Vaccination.dayFormatter.string(from: date),
            protectionMonths: protectionMonths,
            reminderEnabled: reminderEnabled
        )
    }
}

/// Medical condition entered while creating a pet (not yet persisted).
struct PendingCondition: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var notes: String
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
