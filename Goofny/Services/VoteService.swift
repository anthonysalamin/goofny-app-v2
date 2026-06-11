import Foundation
import Supabase

struct VoteService {
    private var client: SupabaseClient { SupabaseManager.shared.client }

    /// Casts a vote via the `cast_vote` RPC.
    /// Safe against duplicates (DB unique constraint + ON CONFLICT DO NOTHING).
    /// Returns the pet's new vote count.
    @discardableResult
    func vote(petID: UUID) async throws -> Int {
        let response: Int = try await client
            .rpc("cast_vote", params: ["p_pet_id": petID])
            .execute()
            .value
        return response
    }

    /// IDs of all pets the user has already voted for.
    func votedPetIDs(voterID: UUID) async throws -> Set<UUID> {
        struct Row: Decodable {
            let petId: UUID
            enum CodingKeys: String, CodingKey { case petId = "pet_id" }
        }
        let rows: [Row] = try await client
            .from("votes")
            .select("pet_id")
            .eq("voter_id", value: voterID)
            .execute()
            .value
        return Set(rows.map(\.petId))
    }
}
