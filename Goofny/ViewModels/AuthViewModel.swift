import Foundation
import Supabase

@MainActor
final class AuthViewModel: ObservableObject {
    enum AuthState { case loading, signedOut, signedIn }

    @Published var state: AuthState = .loading
    @Published var profile: Profile?
    @Published var errorMessage: String?
    @Published var infoMessage: String?
    @Published var isBusy = false

    private let service = AuthService()

    var userID: UUID? { service.currentUserID }

    /// Streams Supabase auth state changes for the app's lifetime.
    func observeAuthState() async {
        for await (event, session) in SupabaseManager.shared.client.auth.authStateChanges {
            switch event {
            case .initialSession:
                // With `emitLocalSessionAsInitialSession: true`, the locally stored
                // session is emitted even if expired — so validate it here.
                // If it's expired, the client refreshes it and emits .tokenRefreshed.
                if let session, !session.isExpired {
                    state = .signedIn
                    await loadProfile()
                } else {
                    state = .signedOut
                }
            case .signedIn, .tokenRefreshed:
                if session != nil {
                    state = .signedIn
                    await loadProfile()
                } else {
                    state = .signedOut
                }
            case .signedOut, .userDeleted:
                state = .signedOut
                profile = nil
            default:
                break
            }
        }
    }

    func loadProfile() async {
        guard let id = service.currentUserID else { return }
        profile = try? await service.fetchProfile(userID: id)
    }

    // MARK: Actions

    func signIn(email: String, password: String) async {
        await run { try await self.service.signIn(email: email, password: password) }
    }

    func signUp(email: String, password: String, displayName: String) async {
        await run {
            try await self.service.signUp(email: email, password: password, displayName: displayName)
            // If email confirmation is enabled, no session exists yet.
            // With autoconfirm (dev), a session is created and the app signs in automatically.
            if self.service.currentUserID == nil {
                self.infoMessage = "Check your inbox to confirm your email."
            }
        }
    }

    func resetPassword(email: String) async {
        await run {
            try await self.service.resetPassword(email: email)
            self.infoMessage = "Password reset email sent."
        }
    }

    func signInWithGoogle() async {
        await run { try await self.service.signInWithGoogle() }
    }

    func signInWithFacebook() async {
        await run { try await self.service.signInWithFacebook() }
    }

    func signOut() async {
        await run { try await self.service.signOut() }
    }

    func updateDisplayName(_ name: String) async {
        guard let id = service.currentUserID else { return }
        await run {
            try await self.service.updateDisplayName(name, userID: id)
            await self.loadProfile()
        }
    }

    // MARK: Helpers

    private func run(_ block: @escaping () async throws -> Void) async {
        isBusy = true
        errorMessage = nil
        defer { isBusy = false }
        do {
            try await block()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
