import SwiftUI

enum AppTab: Hashable {
    case home, leaderboard, addPet, profile
}

struct MainTabView: View {
    @State private var selectedTab: AppTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeFeedView()
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(AppTab.home)

            LeaderboardView()
                .tabItem { Label("Leaderboard", systemImage: "trophy.fill") }
                .tag(AppTab.leaderboard)

            AddPetTabView(selectedTab: $selectedTab)
                .tabItem { Label("Add Pet", systemImage: "plus.circle.fill") }
                .tag(AppTab.addPet)

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.fill") }
                .tag(AppTab.profile)
        }
        .tint(.orange)
    }
}

/// Add Pet tab: after saving, reset the form and jump back to Home.
struct AddPetTabView: View {
    @Binding var selectedTab: AppTab
    @State private var formID = UUID()

    var body: some View {
        NavigationStack {
            PetFormView(viewModel: PetFormViewModel(), onSaved: {
                formID = UUID()          // fresh, empty form for next time
                selectedTab = .home      // back to the feed
            })
            .id(formID)
        }
    }
}
