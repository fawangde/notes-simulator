import FirebaseCore
import UIKit

final class NotesAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseBootstrap.configureIfNeeded()
        _ = FirebaseDatabaseConfig.database()
        return true
    }

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
    static let converterImportDidFinish = Notification.Name("converterImportDidFinish")
}
