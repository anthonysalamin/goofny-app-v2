import Foundation

@MainActor
final class FeedViewModel: ObservableObject {
    @Published var pets: [Pet] = []
    @Published var filters = FeedFilters.none
    @Published var sort: FeedSort = .newest
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var errorMessage: String?
    @Published var votedPetIDs: Set<UUID> = []

    private let petService = PetService()
    private let voteService = VoteService()
    private let realtime = RealtimeService()

    private var page = 0
    private let pageSize = 20
    private var reachedEnd = false
    private var searchDebounce: Task<Void, Never>?

    // MARK: Loading

    func initialLoad(userID: UUID?) async {
        await reload()
        if let userID {
            votedPetIDs = (try? await voteService.votedPetIDs(voterID: userID)) ?? []
        }
        await realtime.subscribeToPetUpdates { [weak self] petID, votes in
            self?.applyLiveVoteCount(petID: petID, votes: votes)
        }
    }

    func reload() async {
        isLoading = true
        errorMessage = nil
        page = 0
        reachedEnd = false
        defer { isLoading = false }
        do {
            pets = try await petService.fetchFeed(filters: filters, sort: sort, page: 0, pageSize: pageSize)
            reachedEnd = pets.count < pageSize
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadMoreIfNeeded(current pet: Pet) async {
        guard !isLoadingMore, !reachedEnd, pet.id == pets.last?.id else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        do {
            page += 1
            let next = try await petService.fetchFeed(filters: filters, sort: sort, page: page, pageSize: pageSize)
            pets.append(contentsOf: next)
            reachedEnd = next.count < pageSize
        } catch {
            page -= 1
        }
    }

    // MARK: Search / filters

    func searchTextChanged(_ text: String) {
        filters.searchText = text
        searchDebounce?.cancel()
        searchDebounce = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else { return }
            await self?.reload()
        }
    }

    func applyFilters(_ newFilters: FeedFilters) async {
        filters = newFilters
        await reload()
    }

    func changeSort(_ newSort: FeedSort) async {
        sort = newSort
        await reload()
    }

    // MARK: Voting

    func hasVoted(for pet: Pet) -> Bool { votedPetIDs.contains(pet.id) }

    func vote(for pet: Pet) async {
        guard !hasVoted(for: pet) else { return }
        // Optimistic update
        votedPetIDs.insert(pet.id)
        applyLiveVoteCount(petID: pet.id, votes: pet.votesCount + 1)
        do {
            let count = try await voteService.vote(petID: pet.id)
            applyLiveVoteCount(petID: pet.id, votes: count)
        } catch {
            votedPetIDs.remove(pet.id)
            applyLiveVoteCount(petID: pet.id, votes: pet.votesCount)
            errorMessage = error.localizedDescription
        }
    }

    private func applyLiveVoteCount(petID: UUID, votes: Int) {
        if let index = pets.firstIndex(where: { $0.id == petID }) {
            pets[index].votesCount = votes
        }
    }

    deinit {
        let realtime = self.realtime
        Task { await realtime.unsubscribe() }
    }
}
