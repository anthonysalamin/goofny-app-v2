import Foundation
import Supabase

struct StorageService {
    private var client: SupabaseClient { SupabaseManager.shared.client }

    /// Uploads pet avatar JPEG data to `pet-avatars/{userID}/{uuid}.jpg`
    /// and returns its public URL.
    func uploadAvatar(data: Data, userID: UUID) async throws -> String {
        // Lowercased to match the RLS policy: auth.uid()::text is lowercase,
        // while Swift's UUID.uuidString is uppercase.
        let path = "\(userID.uuidString.lowercased())/\(UUID().uuidString.lowercased()).jpg"
        try await client.storage
            .from(AppConfig.avatarBucket)
            .upload(path, data: data, options: FileOptions(contentType: "image/jpeg"))
        let url = try client.storage
            .from(AppConfig.avatarBucket)
            .getPublicURL(path: path)
        return url.absoluteString
    }
}
