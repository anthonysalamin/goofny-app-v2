import Foundation

enum AppConfig {
    /// Supabase project: GOOFNY V2 (ap-southeast-1, Singapore)
    static let supabaseURL = URL(string: "https://mfvrhacaqtizpdkqxpfm.supabase.co")!

    /// Publishable (anon) key — safe to ship in the client. RLS protects the data.
    static let supabaseKey = "sb_publishable_0GjW_41bA3Qr9m9Reb1JkA_H_RNrU0L"

    /// Deep-link used for OAuth callbacks. Must match the URL scheme in Info.plist
    /// and the Redirect URL configured in Supabase Auth settings.
    static let authRedirectURL = URL(string: "goofny://auth-callback")!

    static let avatarBucket = "pet-avatars"

    static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }
}
