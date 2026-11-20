import Foundation
import UserNotifications
import UIKit

final class NotificationManager {
    static let shared = NotificationManager()
    private let center = UNUserNotificationCenter.current()

    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

    func isAuthorized() async -> Bool {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral: return true
        default: return false
        }
    }

    func schedule(_ reminder: ReminderItem) {
        let content = UNMutableNotificationContent()
        content.title = reminder.type.pushTitle
        content.body = "Time to add a new measurement!"
        content.sound = .default
        let calendar = Calendar.current
        var components = DateComponents()
        components.hour = calendar.component(.hour, from: reminder.time)
        components.minute = calendar.component(.minute, from: reminder.time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: reminder.id.uuidString, content: content, trigger: trigger)
        center.removePendingNotificationRequests(withIdentifiers: [reminder.id.uuidString])
        center.add(request)
    }

    func cancel(_ reminder: ReminderItem) {
        center.removePendingNotificationRequests(withIdentifiers: [reminder.id.uuidString])
    }

    func pendingCount() async -> Int {
        await center.pendingNotificationRequests().count
    }

    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
