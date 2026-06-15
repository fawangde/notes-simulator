import FirebaseCore
import Foundation

/// 保证任何 Firebase API 调用前已完成 configure（SwiftUI 下 AppState 可能早于 AppDelegate）
enum FirebaseBootstrap {
    private static let lock = NSLock()
    private static var didConfigure = false

    static func configureIfNeeded() {
        lock.lock()
        defer { lock.unlock() }
        guard !didConfigure else { return }
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        didConfigure = FirebaseApp.app() != nil
    }
}
