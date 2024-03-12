import UserNotifications

class NotificationManager {
    static func scheduleNotification(title: String, body: String, delay: Double) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        let requestIdentifier = UUID().uuidString
        let request = UNNotificationRequest(identifier: requestIdentifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            } else {
                print("Notification scheduled!")
            }
        }
    }

    static func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.sound])
    }
}
