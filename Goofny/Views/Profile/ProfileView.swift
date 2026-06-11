import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @StateObject private var viewModel = MyPetsViewModel()
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    header
                    statsRow
                    if !viewModel.titles.isEmpty { titlesSection }
                    myPetsSection
                }
                .padding()
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .navigationDestination(for: Pet.self) { pet in
                PetDetailView(viewModel: PetDetailViewModel(pet: pet))
            }
            .task {
                if let id = auth.userID { await viewModel.load(ownerID: id) }
            }
            .refreshable {
                if let id = auth.userID { await viewModel.load(ownerID: id) }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(.orange.gradient)
            Text(auth.profile?.displayName ?? "Pet Lover")
                .font(.title2.bold())
            Text(auth.profile?.email ?? "")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            stat(value: "\(viewModel.pets.count)", label: "Pets")
            stat(value: "\(viewModel.totalVotes)", label: "Total Votes")
            stat(value: viewModel.bestRank.map { "#\($0)" } ?? "—", label: "Best Rank")
        }
    }

    private func stat(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.title3.bold().monospacedDigit())
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var titlesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Royal Titles 👑").font(.headline)
            ForEach(viewModel.titles) { pet in
                HStack {
                    PetAvatarView(urlString: pet.avatarUrl, size: 40, cornerRadius: 10)
                    Text(pet.name).font(.subheadline.bold())
                    Spacer()
                    if let title = pet.title {
                        Text("\(title) of \(pet.countryName) \(pet.countryFlag)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.yellow.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var myPetsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("My Pets").font(.headline)

            if viewModel.pets.isEmpty && !viewModel.isLoading {
                EmptyStateView(
                    icon: "plus.circle",
                    title: "No pets yet",
                    message: "Add your first pet from the Add Pet tab!"
                )
            }

            ForEach(viewModel.pets) { pet in
                NavigationLink(value: pet) {
                    HStack(spacing: 12) {
                        PetAvatarView(urlString: pet.avatarUrl, size: 56, cornerRadius: 14)
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(pet.name).font(.subheadline.bold())
                                if let title = pet.title { TitleBadge(title: title) }
                            }
                            Text(pet.breed).font(.caption).foregroundStyle(.secondary)
                            HStack(spacing: 10) {
                                Label("\(pet.votesCount)", systemImage: "heart.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.pink)
                                if let rank = pet.countryRank {
                                    Text("#\(rank) in \(pet.countryName)")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(12)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
            }
        }
    }
}
