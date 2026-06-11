import Foundation

@MainActor
final class MyPetsViewModel: ObservableObject {
    @Published var pets: [Pet] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let petService = PetService()

    var totalVotes: Int { pets.reduce(0) { $0 + $1.votesCount } }
    var bestRank: Int? { pets.compactMap(\.countryRank).min() }
    var titles: [Pet] { pets.filter(\.isCrowned) }

    func load(ownerID: UUID) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            pets = try await petService.fetchMyPets(ownerID: ownerID)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
