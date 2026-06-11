import Foundation
import Supabase

struct PetService {
    private var client: SupabaseClient { SupabaseManager.shared.client }

    // MARK: Feed

    /// Fetch pets from the ranked/trending views with filters, search and sort.
    func fetchFeed(filters: FeedFilters, sort: FeedSort, page: Int = 0, pageSize: Int = 20) async throws -> [Pet] {
        let table = sort == .trending ? "trending_pets" : "ranked_pets"
        var query = client.from(table).select()

        if let species = filters.species { query = query.eq("species", value: species.rawValue) }
        if let country = filters.country { query = query.eq("country", value: country) }
        if let sex = filters.sex { query = query.eq("sex", value: sex.rawValue) }
        if !filters.city.isEmpty { query = query.ilike("city", pattern: "%\(filters.city)%") }
        if !filters.breed.isEmpty { query = query.ilike("breed", pattern: "%\(filters.breed)%") }
        if !filters.searchText.isEmpty { query = query.ilike("name", pattern: "%\(filters.searchText)%") }

        let ordered = switch sort {
        case .newest: query.order("created_at", ascending: false)
        case .mostVoted: query.order("votes_count", ascending: false)
        case .trending: query.order("recent_votes", ascending: false)
        }

        let from = page * pageSize
        return try await ordered
            .range(from: from, to: from + pageSize - 1)
            .execute()
            .value
    }

    func fetchPet(id: UUID) async throws -> Pet {
        try await client
            .from("ranked_pets")
            .select()
            .eq("id", value: id)
            .single()
            .execute()
            .value
    }

    func fetchMyPets(ownerID: UUID) async throws -> [Pet] {
        try await client
            .from("ranked_pets")
            .select()
            .eq("owner_id", value: ownerID)
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    // MARK: CRUD

    @discardableResult
    func createPet(_ payload: PetPayload) async throws -> Pet {
        try await client
            .from("pets")
            .insert(payload)
            .select()
            .single()
            .execute()
            .value
    }

    func updatePet(id: UUID, payload: PetPayload) async throws {
        try await client
            .from("pets")
            .update(payload)
            .eq("id", value: id)
            .execute()
    }

    func deletePet(id: UUID) async throws {
        try await client
            .from("pets")
            .delete()
            .eq("id", value: id)
            .execute()
    }

    // MARK: Health records

    func fetchVaccinations(petID: UUID) async throws -> [Vaccination] {
        try await client
            .from("vaccinations")
            .select()
            .eq("pet_id", value: petID)
            .order("vaccination_date", ascending: false)
            .execute()
            .value
    }

    @discardableResult
    func addVaccination(_ payload: VaccinationPayload) async throws -> Vaccination {
        try await client
            .from("vaccinations")
            .insert(payload)
            .select()
            .single()
            .execute()
            .value
    }

    func updateVaccination(id: UUID, payload: VaccinationPayload) async throws {
        try await client
            .from("vaccinations")
            .update(payload)
            .eq("id", value: id)
            .execute()
    }

    func deleteVaccination(id: UUID) async throws {
        try await client.from("vaccinations").delete().eq("id", value: id).execute()
    }

    func fetchMedicalConditions(petID: UUID) async throws -> [MedicalCondition] {
        try await client
            .from("medical_conditions")
            .select()
            .eq("pet_id", value: petID)
            .execute()
            .value
    }

    func addMedicalCondition(_ payload: MedicalConditionPayload) async throws {
        try await client.from("medical_conditions").insert(payload).execute()
    }

    func deleteMedicalCondition(id: UUID) async throws {
        try await client.from("medical_conditions").delete().eq("id", value: id).execute()
    }
}
