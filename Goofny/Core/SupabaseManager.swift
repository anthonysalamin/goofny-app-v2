import Foundation
import Supabase

/// Single shared Supabase client for the whole app.
final class SupabaseManager {
    static let shared = SupabaseManager()

    let client: SupabaseClient

    private init() {
        client = SupabaseClient(
            supabaseURL: AppConfig.supabaseURL,
            supabaseKey: AppConfig.supabaseKey,
            options: SupabaseClientOptions(
                auth: SupabaseClientOptions.AuthOptions(
                    // Opt in to the new (correct) behavior: the locally stored session
                    // is emitted as the initial session even if expired/invalid.
                    // We check `session.isExpired` in AuthViewModel accordingly.
                    // See https://github.com/supabase/supabase-swift/pull/822
                    emitLocalSessionAsInitialSession: true
                )
            )
        )
    }
}
