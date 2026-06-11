import Foundation
import Supabase

/// Subscribes to Postgres changes on `pets` so vote counts update live.
final class RealtimeService {
    private var client: SupabaseClient { SupabaseManager.shared.client }
    private var channel: RealtimeChannelV2?
    private var task: Task<Void, Never>?

    /// Calls `onPetUpdated` whenever a pet row changes (e.g. votes_count).
    func subscribeToPetUpdates(onPetUpdated: @escaping @MainActor (UUID, Int) -> Void) async {
        let channel = client.channel("public:pets")
        let updates = channel.postgresChange(UpdateAction.self, schema: "public", table: "pets")

        await channel.subscribe()
        self.channel = channel

        task = Task {
            for await update in updates {
                guard
                    let idString = update.record["id"]?.stringValue,
                    let id = UUID(uuidString: idString),
                    let votes = update.record["votes_count"]?.intValue
                else { continue }
                await onPetUpdated(id, votes)
            }
        }
    }

    func unsubscribe() async {
        task?.cancel()
        task = nil
        if let channel {
            await channel.unsubscribe()
        }
        channel = nil
    }
}
