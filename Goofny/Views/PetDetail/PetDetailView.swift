import SwiftUI

struct PetDetailView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: PetDetailViewModel
    @State private var showEdit = false

    private var pet: Pet { viewModel.pet }
    private var isOwner: Bool { auth.userID == pet.ownerId }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                hero
                statsRow
                infoSection
                // Health records & notes are private — owner only
                if isOwner {
                    if !viewModel.vaccinations.isEmpty { vaccinationSection }
                    if !viewModel.conditions.isEmpty { conditionsSection }
                    if let notes = pet.notes, !notes.isEmpty { notesSection(notes) }
                }
            }
            .padding()
        }
        .navigationTitle(pet.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isOwner {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Edit") { showEdit = true }
                }
            }
        }
        .sheet(isPresented: $showEdit, onDismiss: {
            // Re-fetch so edits (breed, country, city, photo, …) show immediately
            Task { await viewModel.load(userID: auth.userID) }
        }) {
            NavigationStack {
                PetFormView(
                    viewModel: PetFormViewModel(pet: pet),
                    onDeleted: { dismiss() }   // pet is gone — pop back to the list
                )
            }
        }
        .task { await viewModel.load(userID: auth.userID) }
        .alert("Oops", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: Sections

    private var hero: some View {
        VStack(spacing: 12) {
            PetAvatarView(urlString: pet.avatarUrl, size: 220, cornerRadius: 28)

            HStack(spacing: 8) {
                Text(pet.name).font(.title.bold())
                if let title = pet.title { TitleBadge(title: title) }
            }

            Text("\(pet.species.emoji) \(pet.breed) · \(pet.sex.symbol) \(pet.sex.label) · \(pet.displayAge) yr\(pet.displayAge == 1 ? "" : "s")")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("\(pet.countryFlag) \(pet.city), \(pet.countryName)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if !isOwner {
                voteButton
            }
        }
    }

    private var voteButton: some View {
        Button {
            Task { await viewModel.vote() }
        } label: {
            HStack {
                if viewModel.isVoting {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: viewModel.hasVoted ? "heart.fill" : "heart")
                }
                Text(viewModel.hasVoted ? "Voted!" : "Vote for \(pet.name)")
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }
        .buttonStyle(.borderedProminent)
        .tint(viewModel.hasVoted ? .gray : .pink)
        .disabled(viewModel.hasVoted || viewModel.isVoting)
        .padding(.top, 4)
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            statCard(value: "\(pet.votesCount)", label: "Votes", icon: "heart.fill", color: .pink)
            if let rank = pet.countryRank {
                statCard(value: "#\(rank)", label: pet.countryName, icon: "flag.fill", color: .blue)
            }
            if let rank = pet.globalRank {
                statCard(value: "#\(rank)", label: "Global", icon: "globe", color: .green)
            }
        }
    }

    private func statCard(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon).foregroundStyle(color)
            Text(value).font(.title3.bold().monospacedDigit())
            Text(label).font(.caption).foregroundStyle(.secondary).lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("About")
            infoRow("Species", "\(pet.species.emoji) \(pet.species.label)")
            infoRow("Breed", pet.breed)
            infoRow("Sex", "\(pet.sex.symbol) \(pet.sex.label)")
            infoRow("Age", "\(pet.displayAge) year\(pet.displayAge == 1 ? "" : "s")")
            if let birthday = pet.birthDateValue {
                infoRow("Birthday", birthday.formatted(date: .abbreviated, time: .omitted))
            }
            infoRow("Country", "\(pet.countryFlag) \(pet.countryName)")
            infoRow("City", pet.city)
            infoRow("Member since", pet.createdAt.formatted(date: .abbreviated, time: .omitted))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var vaccinationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("Vaccinations 💉")
            ForEach(viewModel.vaccinations) { vaccination in
                VaccinationRow(vaccination: vaccination)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var conditionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("Medical Conditions 🏥")
            ForEach(viewModel.conditions) { condition in
                VStack(alignment: .leading, spacing: 2) {
                    Text(condition.conditionName).font(.subheadline.bold())
                    if let notes = condition.notes {
                        Text(notes).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func notesSection(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("Notes 📝")
            Text(notes).font(.subheadline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title).font(.headline)
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value)
        }
        .font(.subheadline)
    }
}
