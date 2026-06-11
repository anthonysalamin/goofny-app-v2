import Foundation
import Supabase

enum AuthError: LocalizedError {
    case notSignedIn
    var errorDescription: String? { "You must be signed in." }
}

struct AuthService {
    private var client: SupabaseClient { SupabaseManager.shared.client }

    var currentUserID: UUID? { client.auth.currentSession?.user.id }

    func currentSession() async -> Session? {
        try? await client.auth.session
    }

    // MARK: Email / Password

    func signUp(email: String, password: String, displayName: String) async throws {
        try await client.auth.signUp(
            email: email,
            password: password,
            data: ["display_name": .string(displayName)]
        )
    }

    func signIn(email: String, password: String) async throws {
        try await client.auth.signIn(email: email, password: password)
    }

    func resetPassword(email: String) async throws {
        try await client.auth.resetPasswordForEmail(email, redirectTo: AppConfig.authRedirectURL)
    }

    // MARK: OAuth (Google / Facebook via Supabase)

    func signInWithGoogle() async throws {
        try await client.auth.signInWithOAuth(provider: .google, redirectTo: AppConfig.authRedirectURL)
    }

    func signInWithFacebook() async throws {
        try await client.auth.signInWithOAuth(provider: .facebook, redirectTo: AppConfig.authRedirectURL)
    }

    // MARK: Session

    func signOut() async throws {
        try await client.auth.signOut()
    }

    // MARK: Profile

    func fetchProfile(userID: UUID) async throws -> Profile {
        try await client
            .from("profiles")
            .select()
            .eq("id", value: userID)
            .single()
            .execute()
            .value
    }

    func updateDisplayName(_ name: String, userID: UUID) async throws {
        try await client
            .from("profiles")
            .update(["display_name": name])
            .eq("id", value: userID)
            .execute()
    }
}
