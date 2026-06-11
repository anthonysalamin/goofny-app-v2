import SwiftUI

struct LeaderboardView: View {
    @StateObject private var viewModel = LeaderboardViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                controls

                if viewModel.isLoading && viewModel.pets.isEmpty {
                    ProgressView("Loading rankings…").frame(maxHeight: .infinity)
                } else if viewModel.pets.isEmpty {
                    EmptyStateView(
                        icon: "trophy",
                        title: "No rankings yet",
                        message: "Once pets receive votes, they'll appear here."
                    )
                    Spacer()
                } else {
                    leaderboardList
                }
            }
            .navigationTitle("Leaderboard")
            .navigationDestination(for: Pet.self) { pet in
                PetDetailView(viewModel: PetDetailViewModel(pet: pet))
            }
            .task { await viewModel.load() }
            .refreshable { await viewModel.load() }
        }
    }

    private var controls: some View {
        VStack(spacing: 10) {
            Picker("Scope", selection: $viewModel.scope) {
                ForEach(LeaderboardViewModel.Scope.allCases) { scope in
                    Text(scope.rawValue).tag(scope)
                }
            }
            .pickerStyle(.segmented)

            Picker("Species", selection: $viewModel.species) {
                ForEach(Species.allCases) { species in
                    Text("\(species.emoji) \(species.label)s").tag(species)
                }
            }
            .pickerStyle(.segmented)

            if viewModel.scope == .country {
                Picker("Country", selection: $viewModel.country) {
                    ForEach(Country.all, id: \.code) { country in
                        Text("\(Country.flag(for: country.code)) \(country.name)").tag(country.code)
                    }
                }
                .pickerStyle(.menu)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
        .onChange(of: viewModel.scope) { _, _ in Task { await viewModel.load() } }
        .onChange(of: viewModel.species) { _, _ in Task { await viewModel.load() } }
        .onChange(of: viewModel.country) { _, _ in Task { await viewModel.load() } }
    }

    private var leaderboardList: some View {
        List(viewModel.pets) { pet in
            NavigationLink(value: pet) {
                HStack(spacing: 12) {
                    rankView(for: pet)
                    PetAvatarView(urlString: pet.avatarUrl, size: 52, cornerRadius: 12)
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(pet.name).font(.headline)
                            if let title = pet.title { TitleBadge(title: title) }
                        }
                        Text("\(pet.breed) · \(pet.countryFlag) \(pet.countryName)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
                    VStack(spacing: 2) {
                        Image(systemName: "heart.fill").foregroundStyle(.pink).font(.caption)
                        Text("\(pet.votesCount)")
                            .font(.subheadline.bold().monospacedDigit())
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .listStyle(.plain)
    }

    private func rankView(for pet: Pet) -> some View {
        let rank = viewModel.displayRank(for: pet) ?? 0
        return Group {
            switch rank {
            case 1: Text("🥇")
            case 2: Text("🥈")
            case 3: Text("🥉")
            default:
                Text("#\(rank)")
                    .font(.subheadline.bold().monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 36)
    }
}
