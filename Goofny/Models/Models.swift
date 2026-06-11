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
    var birthDate: String?     // "yyyy-MM-dd" (Postgres date)
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
        case birthDate = "birth_date"
        case votesCount = "votes_count"
        case createdAt = "created_at"
        case globalRank = "global_rank"
        case countryRank = "country_rank"
        case recentVotes = "recent_votes"
    }

    var birthDateValue: Date? {
        birthDate.flatMap { Vaccination.dayFormatter.date(from: $0) }
    }

    /// Age in years — computed from birth date when available, else the stored value.
    var displayAge: Int {
        if let birth = birthDateValue {
            return Calendar.current.dateComponents([.year], from: birth, to: .now).year ?? age
        }
        return age
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
    var birthDate: String?     // "yyyy-MM-dd"
    var country: String
    var city: String
    var avatarUrl: String?
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case name, species, sex, breed, age, country, city, notes
        case ownerId = "owner_id"
        case birthDate = "birth_date"
        case avatarUrl = "avatar_url"
    }
}

// MARK: - Vaccination

struct Vaccination: Codable, Identifiable, Hashable {
    let id: UUID
    let petId: UUID
    var vaccineName: String
    /// Postgres `date` column — transported as "yyyy-MM-dd".
    /// (A Swift `Date` can't be decoded from a plain date string.)
    var vaccinationDate: String
    /// How long the vaccine protects, in months (default from catalog, user-overridable).
    var protectionMonths: Int
    /// Whether the user wants a renewal notification.
    var reminderEnabled: Bool

    var date: Date? { Self.dayFormatter.date(from: vaccinationDate) }
    var displayDate: String {
        date?.formatted(date: .abbreviated, time: .omitted) ?? vaccinationDate
    }

    /// vaccine date + protection duration
    var nextDueDate: Date? {
        guard let date else { return nil }
        return Calendar.current.date(byAdding: .month, value: protectionMonths, to: date)
    }

    var isOverdue: Bool {
        guard let due = nextDueDate else { return false }
        return due < .now
    }

    /// Due within the next 30 days
    var isDueSoon: Bool {
        guard let due = nextDueDate, !isOverdue else { return false }
        return due < Calendar.current.date(byAdding: .day, value: 30, to: .now)!
    }

    static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()

    enum CodingKeys: String, CodingKey {
        case id
        case petId = "pet_id"
        case vaccineName = "vaccine_name"
        case vaccinationDate = "vaccination_date"
        case protectionMonths = "protection_months"
        case reminderEnabled = "reminder_enabled"
    }
}

struct VaccinationPayload: Codable {
    var petId: UUID
    var vaccineName: String
    var vaccinationDate: String   // "yyyy-MM-dd"
    var protectionMonths: Int
    var reminderEnabled: Bool

    enum CodingKeys: String, CodingKey {
        case petId = "pet_id"
        case vaccineName = "vaccine_name"
        case vaccinationDate = "vaccination_date"
        case protectionMonths = "protection_months"
        case reminderEnabled = "reminder_enabled"
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
