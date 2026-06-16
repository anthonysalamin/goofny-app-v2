import Foundation
import UserNotifications

/// Schedules local notifications for vaccine renewals.
struct NotificationService {
    private var center: UNUserNotificationCenter { .current() }

    /// Ask once for permission. Returns true if notifications are allowed.
    @discardableResult
    func requestPermission() async -> Bool {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .badge, .sound])) ?? false
        default:
            return false
        }
    }

    /// Schedules two reminders: 14 days before renewal and on the due date.
    func scheduleRenewalReminders(for vaccination: Vaccination, petName: String) async {
        await cancelReminders(for: vaccination.id)
        guard vaccination.reminderEnabled, let dueDate = vaccination.nextDueDate else { return }

        if let soonDate = Calendar.current.date(byAdding: .day, value: -14, to: dueDate), soonDate > .now {
            await schedule(
                id: "vaccine-\(vaccination.id.uuidString)-soon",
                title: "💉 Vaccine renewal coming up",
                body: "\(petName)'s \(vaccination.vaccineType) vaccine is due on \(dueDate.formatted(date: .abbreviated, time: .omitted)).",
                at: soonDate
            )
        }

        if dueDate > .now {
            await schedule(
                id: "vaccine-\(vaccination.id.uuidString)-due",
                title: "💉 Vaccine renewal due",
                body: "\(petName)'s \(vaccination.vaccineType) vaccine is due for renewal today.",
                at: dueDate
            )
        }
    }

    func cancelReminders(for vaccinationID: UUID) async {
        center.removePendingNotificationRequests(withIdentifiers: [
            "vaccine-\(vaccinationID.uuidString)-soon",
            "vaccine-\(vaccinationID.uuidString)-due"
        ])
    }

    private func schedule(id: String, title: String, body: String, at date: Date) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        components.hour = 10 // fire at 10:00 local time

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        try? await center.add(request)
    }
}
