import Foundation

enum FirebaseReachability {
    static var databaseURL: URL? {
        guard let urlString = FirebaseDatabaseConfig.databaseURLString,
              let parsed = URL(string: urlString) else {
            return nil
        }
        return parsed
    }

    /// 检测当前网络能否访问 Realtime Database
    static func canReachDatabase(timeout: TimeInterval = 8) async -> Bool {
        guard let base = databaseURL else { return false }
        let probe = base.appendingPathComponent(".json")
        var request = URLRequest(url: probe)
        request.httpMethod = "GET"
        request.timeoutInterval = timeout
        request.cachePolicy = .reloadIgnoringLocalCacheData
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { return false }
            return (200 ... 499).contains(http.statusCode)
        } catch {
            return false
        }
    }
}
