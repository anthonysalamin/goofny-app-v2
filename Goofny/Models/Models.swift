import Foundation

// MARK: - Enums

enum Species: String, Codable, CaseIterable, Identifiable {
    case dog, cat
    var id: String { rawValue }
    var label: String { self == .dog ? "Dog" : "Cat" }
    var emoji: String { self == .dog ? "🐶" : "🐱" }
}

enum Sex: String, Codable, CaseIterable, Identifiable {
    case male, female
    var id: String { rawValue }
    var label: String { self == .male ? "Male" : "Female" }
    var symbol: String { self == .male ? "♂" : "♀" }
}

// MARK: - Profile

struct Profile: Codable, Identifiable, Hashable {
    let id: UUID
    var email: String
    var displayName: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, email
        case displayName = "display_name"
        case createdAt = "created_at"
    }
}

// MARK: - Pet
// Decodes rows from `pets`, `ranked_pets` and `trending_pets`.

struct Pet: Codable, Identifiable, Hashable {
    let id: UUID
    let ownerId: UUID
    var name: String
    var species: Species
    var sex: Sex
    var breed: String
    var age: Int
    var country: String        // ISO 3166-1 alpha-2 (e.g. "CH")
    var city: String
    var avatarUrl: String?
    var notes: String?
    var votesCount: Int
    let createdAt: Date
    // Ranking fields (present on ranked_pets / trending_pets views)
    var globalRank: Int?
    var countryRank: Int?
    var title: String?
    var recentVotes: Int?

    enum CodingKeys: String, CodingKey {
        case id, name, species, sex, breed, age, country, city, notes, title
        case ownerId = "owner_id"
        case avatarUrl = "avatar_url"
        case votesCount = "votes_count"
        case createdAt = "created_at"
        case globalRank = "global_rank"
        case countryRank = "country_rank"
        case recentVotes = "recent_votes"
    }

    var countryFlag: String { Country.flag(for: country) }
    var countryName: String { Country.name(for: country) }
    var isCrowned: Bool { title != nil }
    var crownEmoji: String? {
        guard let title else { return nil }
        return title == "King" ? "👑" : "💎"
    }
}

/// Payload for inserting/updating a pet.
struct PetPayload: Codable {
    var ownerId: UUID
    var name: String
    var species: String
    var sex: String
    var breed: String
    var age: Int
    var country: String
    var city: String
    var avatarUrl: String?
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case name, species, sex, breed, age, country, city, notes
        case ownerId = "owner_id"
        case avatarUrl = "avatar_url"
    }
}

// MARK: - Vaccination

struct Vaccination: Codable, Identifiable, Hashable {
    let id: UUID
    let petId: UUID
    var vaccineName: String
    var vaccinationDate: Date

    enum CodingKeys: String, CodingKey {
        case id
        case petId = "pet_id"
        case vaccineName = "vaccine_name"
        case vaccinationDate = "vaccination_date"
    }
}

struct VaccinationPayload: Codable {
    var petId: UUID
    var vaccineName: String
    var vaccinationDate: Date

    enum CodingKeys: String, CodingKey {
        case petId = "pet_id"
        case vaccineName = "vaccine_name"
        case vaccinationDate = "vaccination_date"
    }
}

// MARK: - Medical Condition

struct MedicalCondition: Codable, Identifiable, Hashable {
    let id: UUID
    let petId: UUID
    var conditionName: String
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case id, notes
        case petId = "pet_id"
        case conditionName = "condition_name"
    }
}

struct MedicalConditionPayload: Codable {
    var petId: UUID
    var conditionName: String
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case notes
        case petId = "pet_id"
        case conditionName = "condition_name"
    }
}

// MARK: - Vote

struct Vote: Codable, Identifiable, Hashable {
    let id: UUID
    let voterId: UUID
    let petId: UUID
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case voterId = "voter_id"
        case petId = "pet_id"
        case createdAt = "created_at"
    }
}

// MARK: - Feed sorting & filters

enum FeedSort: String, CaseIterable, Identifiable {
    case newest = "Newest"
    case mostVoted = "Most Voted"
    case trending = "Trending"
    var id: String { rawValue }
}

struct FeedFilters: Equatable {
    var species: Species?
    var country: String?
    var city: String = ""
    var breed: String = ""
    var sex: Sex?
    var searchText: String = ""

    var isActive: Bool {
        species != nil || country != nil || !city.isEmpty || !breed.isEmpty || sex != nil
    }

    static let none = FeedFilters()
}
