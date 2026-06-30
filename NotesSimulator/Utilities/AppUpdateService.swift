import Foundation
import UIKit

struct RemoteAppVersion: Decodable {
    let version: String?
    let latestBuild: Int
    let minBuild: Int?
    let releaseNotes: String
    let installURL: String
}

struct AppUpdateOffer: Equatable {
    let latestBuild: Int
    let releaseNotes: String
    let installURL: URL
    let isForced: Bool
}

enum AppUpdateStore {
    private static let dismissedBuildKey = "appUpdateDismissedBuild"

    static var dismissedBuild: Int {
        get { UserDefaults.standard.integer(forKey: dismissedBuildKey) }
        set { UserDefaults.standard.set(newValue, forKey: dismissedBuildKey) }
    }
}

@MainActor
enum AppUpdateService {
    private static let versionURL = URL(string: "https://fawangde.github.io/notes-simulator/version.json")!

    static var localBuild: Int {
        let raw = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
        return Int(raw ?? "") ?? 0
    }

    static func checkForUpdate() async -> AppUpdateOffer? {
        guard NetworkMonitor.shared.isConnected else { return nil }

        let remote: RemoteAppVersion
        do {
            remote = try await fetchRemoteVersion()
        } catch {
            return nil
        }

        let local = localBuild
        guard local > 0, remote.latestBuild > local else { return nil }

        let minBuild = remote.minBuild ?? remote.latestBuild
        let isForced = local < minBuild
        if !isForced, AppUpdateStore.dismissedBuild >= remote.latestBuild {
            return nil
        }

        guard let installURL = URL(string: remote.installURL.trimmingCharacters(in: .whitespacesAndNewlines)),
              installURL.scheme?.hasPrefix("http") == true else {
            return nil
        }

        let notes = remote.releaseNotes.trimmingCharacters(in: .whitespacesAndNewlines)
        let versionPrefix = remote.version.map { "v\($0) · Build \(remote.latestBuild)\n\n" } ?? "Build \(remote.latestBuild)\n\n"

        return AppUpdateOffer(
            latestBuild: remote.latestBuild,
            releaseNotes: versionPrefix + (notes.isEmpty ? "发现新版本，请前往安装页更新。" : notes),
            installURL: installURL,
            isForced: isForced
        )
    }

    static func dismissUpdate(latestBuild: Int) {
        AppUpdateStore.dismissedBuild = latestBuild
    }

    static func openInstallPage(_ url: URL) {
        UIApplication.shared.open(url)
    }

    private static func fetchRemoteVersion() async throws -> RemoteAppVersion {
        var request = URLRequest(url: versionURL)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 12

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200 ... 299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(RemoteAppVersion.self, from: data)
    }
}

@MainActor
final class AppUpdateController: ObservableObject {
    static let shared = AppUpdateController()

    @Published var offer: AppUpdateOffer?

    private init() {}

    func checkNow() async {
        offer = await AppUpdateService.checkForUpdate()
    }

    func dismissCurrentOffer() {
        guard let offer else { return }
        AppUpdateService.dismissUpdate(latestBuild: offer.latestBuild)
        self.offer = nil
    }

    func openInstallPage() {
        guard let url = offer?.installURL else { return }
        AppUpdateService.openInstallPage(url)
    }
}
