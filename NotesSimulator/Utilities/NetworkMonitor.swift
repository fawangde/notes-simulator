import Combine
import Foundation
import Network

@MainActor
final class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()

    @Published private(set) var isConnected = true

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    private init() {
        isConnected = monitor.currentPath.status == .satisfied
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }
}

enum NetworkPromptStore {
    private static let key = "ActivationNetworkPromptShown.v1"

    static var hasShownPrompt: Bool {
        UserDefaults.standard.bool(forKey: key)
    }

    static func markPromptShown() {
        UserDefaults.standard.set(true, forKey: key)
    }
}
