import SwiftUI

struct HomeFeedView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @StateObject private var viewModel = FeedViewModel()
    @State private var showFilters = false
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.pets.isEmpty {
                    ProgressView("Fetching cuties…")
                        .frame(maxHeight: .infinity)
                } else if viewModel.pets.isEmpty {
                    EmptyStateView(
                        icon: "pawprint",
                        title: "No pets found",
                        message: viewModel.filters.isActive
                            ? "Try adjusting your filters."
                            : "Be the first to add a pet!"
                    )
                } else {
                    feedList
                }
            }
            .navigationTitle("Goofny")
            .searchable(text: $searchText, prompt: "Search by pet name")
            .onChange(of: searchText) { _, newValue in
                viewModel.searchTextChanged(newValue)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showFilters = true
                    } label: {
                        Image(systemName: viewModel.filters.isActive
                              ? "line.3.horizontal.decrease.circle.fill"
                              : "line.3.horizontal.decrease.circle")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    sortMenu
                }
            }
            .sheet(isPresented: $showFilters) {
                FilterSheetView(filters: viewModel.filters) { newFilters in
                    Task { await viewModel.applyFilters(newFilters) }
                }
            }
            .refreshable { await viewModel.reload() }
            .task { await viewModel.initialLoad(userID: auth.userID) }
            .alert("Oops", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    private var feedList: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                ForEach(viewModel.pets) { pet in
                    NavigationLink(value: pet) {
                        PetCardView(
                            pet: pet,
                            hasVoted: viewModel.hasVoted(for: pet)
                        ) {
                            Task { await viewModel.vote(for: pet) }
                        }
                    }
                    .buttonStyle(.plain)
                    .task { await viewModel.loadMoreIfNeeded(current: pet) }
                }
                if viewModel.isLoadingMore {
                    ProgressView().padding()
                }
            }
            .padding(.horizontal)
        }
        .navigationDestination(for: Pet.self) { pet in
            PetDetailView(viewModel: PetDetailViewModel(pet: pet))
        }
    }

    private var sortMenu: some View {
        Menu {
            ForEach(FeedSort.allCases) { sort in
                Button {
                    Task { await viewModel.changeSort(sort) }
                } label: {
                    if viewModel.sort == sort {
                        Label(sort.rawValue, systemImage: "checkmark")
                    } else {
                        Text(sort.rawValue)
                    }
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down.circle")
        }
    }
}

// MARK: - Pet card

struct PetCardView: View {
    let pet: Pet
    let hasVoted: Bool
    let onVote: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            PetAvatarView(urlString: pet.avatarUrl, size: 84)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(pet.name).font(.headline)
                    if let title = pet.title { TitleBadge(title: title) }
                }
                Text("\(pet.species.emoji) \(pet.breed)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text("\(pet.countryFlag) \(pet.countryName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let rank = pet.countryRank {
                    HStack(spacing: 4) {
                        RankChip(rank: rank)
                        Text("in \(pet.countryName)")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            Spacer()

            VoteButton(votesCount: pet.votesCount, hasVoted: hasVoted, action: onVote)
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
    }
}
