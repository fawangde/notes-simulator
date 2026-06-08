import UIKit

final class NotesAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        DispatchQueue.main.async {
            if url.scheme == "notesimulator" {
                NotificationCenter.default.post(name: .noteImportRequested, object: nil)
            } else {
                NotificationCenter.default.post(name: .noteImportFileOpened, object: url)
            }
        }
        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        NotificationCenter.default.post(name: .noteImportRequested, object: nil)
    }
}

extension Notification.Name {
    static let noteImportFileOpened = Notification.Name("noteImportFileOpened")
    static let noteImportRequested = Notification.Name("noteImportRequested")
}
