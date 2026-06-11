import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeFeedView()
                .tabItem { Label("Home", systemImage: "house.fill") }

            LeaderboardView()
                .tabItem { Label("Leaderboard", systemImage: "trophy.fill") }

            AddPetTabView()
                .tabItem { Label("Add Pet", systemImage: "plus.circle.fill") }

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.fill") }
        }
        .tint(.orange)
    }
}

/// Wrapper so the Add Pet tab always presents a fresh form.
struct AddPetTabView: View {
    var body: some View {
        NavigationStack {
            PetFormView(viewModel: PetFormViewModel())
        }
    }
}
