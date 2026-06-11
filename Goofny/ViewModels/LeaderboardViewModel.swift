import Foundation

@MainActor
final class LeaderboardViewModel: ObservableObject {
    enum Scope: String, CaseIterable, Identifiable {
        case global = "Global"
        case country = "By Country"
        var id: String { rawValue }
    }

    @Published var scope: Scope = .global
    @Published var species: Species = .dog
    @Published var country: String = Locale.current.region?.identifier ?? "US"
    @Published var pets: [Pet] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let petService = PetService()

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            var filters = FeedFilters.none
            filters.species = species
            if scope == .country { filters.country = country }
            pets = try await petService.fetchFeed(filters: filters, sort: .mostVoted, page: 0, pageSize: 100)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Rank shown in the list: global or per-country depending on scope.
    func displayRank(for pet: Pet) -> Int? {
        scope == .global ? pet.globalRank : pet.countryRank
    }
}
