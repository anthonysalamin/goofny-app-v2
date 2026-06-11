import SwiftUI
import Supabase

@main
struct GoofnyApp: App {
    @StateObject private var auth = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(auth)
                .onOpenURL { url in
                    // Handles OAuth (Google / Facebook) deep-link callbacks: goofny://auth-callback
                    SupabaseManager.shared.client.auth.handle(url)
                }
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var auth: AuthViewModel

    var body: some View {
        Group {
            switch auth.state {
            case .loading:
                ProgressView("Loading…")
            case .signedOut:
                AuthFlowView()
            case .signedIn:
                MainTabView()
            }
        }
        .task { await auth.observeAuthState() }
    }
}
