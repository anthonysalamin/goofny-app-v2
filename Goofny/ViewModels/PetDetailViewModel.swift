import Foundation

@MainActor
final class PetDetailViewModel: ObservableObject {
    @Published var pet: Pet
    @Published var vaccinations: [Vaccination] = []
    @Published var conditions: [MedicalCondition] = []
    @Published var hasVoted = false
    @Published var isVoting = false
    @Published var errorMessage: String?

    private let petService = PetService()
    private let voteService = VoteService()

    init(pet: Pet) {
        self.pet = pet
    }

    func load(userID: UUID?) async {
        async let freshPet = try? petService.fetchPet(id: pet.id)
        async let vax = try? petService.fetchVaccinations(petID: pet.id)
        async let meds = try? petService.fetchMedicalConditions(petID: pet.id)

        if let fresh = await freshPet { pet = fresh }
        vaccinations = await vax ?? []
        conditions = await meds ?? []

        if let userID {
            let voted = (try? await voteService.votedPetIDs(voterID: userID)) ?? []
            hasVoted = voted.contains(pet.id)
        }
    }

    func vote() async {
        guard !hasVoted else { return }
        isVoting = true
        defer { isVoting = false }
        do {
            let count = try await voteService.vote(petID: pet.id)
            pet.votesCount = count
            hasVoted = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
