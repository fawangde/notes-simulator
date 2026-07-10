import FirebaseDatabase
import Foundation

enum PCSessionError: LocalizedError {
    case notActivated
    case networkUnavailable
    case firebaseUnavailable
    case sessionNotFound
    case sessionExpired
    case sessionAlreadyUsed
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .notActivated:
            return "请先在设置页激活备忘录 App"
        case .networkUnavailable:
            return "当前无网络，请连接 Wi-Fi 或蜂窝数据"
        case .firebaseUnavailable:
            return "Firebase 未配置"
        case .sessionNotFound:
            return "二维码已失效，请在 PC 上重新点击激活"
        case .sessionExpired:
            return "二维码已过期，请在 PC 上重新点击激活"
        case .sessionAlreadyUsed:
            return "该二维码已被使用"
        case .permissionDenied:
            return "授权失败，请确认 Firebase 已发布 pcSessions 规则"
        }
    }
}

/// PC 扫码授权：只读写 pcSessions，不修改 activationCodes 与本地激活状态。
@MainActor
final class PCSessionService {
    static let shared = PCSessionService()

    private let sessionsPath = "pcSessions"

    private var root: DatabaseReference? {
        FirebaseDatabaseConfig.reference()
    }

    private init() {}

    func authorize(sessionId rawSessionId: String, app: AppState) async throws {
        let sessionId = rawSessionId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !sessionId.isEmpty else { throw PCSessionError.sessionNotFound }

        if DevelopmentFlags.bypassActivation {
            try await writeBypassAuthorization(sessionId: sessionId)
            return
        }

        guard app.isActivated else { throw PCSessionError.notActivated }
        guard NetworkMonitor.shared.isConnected else { throw PCSessionError.networkUnavailable }
        guard root != nil else { throw PCSessionError.firebaseUnavailable }
        guard await FirebaseReachability.canReachDatabase() else {
            throw PCSessionError.networkUnavailable
        }

        await app.syncActivationIfNeeded()
        guard app.isActivated else { throw PCSessionError.notActivated }

        guard let code = app.activationCode,
              let deviceId = app.activationBoundUID,
              let mode = app.activationMode else {
            throw PCSessionError.notActivated
        }

        let ref = sessionRef(sessionId)
        let data = try await fetchSession(at: ref)
        guard data["status"] as? String == "pending" else {
            if data["status"] as? String == "authorized" {
                throw PCSessionError.sessionAlreadyUsed
            }
            throw PCSessionError.sessionNotFound
        }

        let sessionExpiresMs = RTDBValue.double(from: data["sessionExpiresAt"]) ?? 0
        if sessionExpiresMs > 0, Date().timeIntervalSince1970 * 1000 > sessionExpiresMs {
            throw PCSessionError.sessionExpired
        }

        let now = Date()
        var payload: [String: Any] = [
            "status": "authorized",
            "activationCode": code,
            "deviceId": deviceId,
            "mode": mode.rawValue,
            "authorizedAt": now.timeIntervalSince1970 * 1000,
        ]

        switch mode {
        case .time:
            guard let expiresAt = app.activationExpiresAt else { throw PCSessionError.notActivated }
            payload["expiresAt"] = expiresAt.timeIntervalSince1970 * 1000
            payload["expireTime"] = expiresAt.timeIntervalSince1970
        case .clicks:
            payload["appActivated"] = true
        }

        try await updateValues(at: ref, payload)
    }

    private func writeBypassAuthorization(sessionId: String) async throws {
        guard root != nil else { throw PCSessionError.firebaseUnavailable }
        let ref = sessionRef(sessionId)
        let data = try await fetchSession(at: ref)
        guard data["status"] as? String == "pending" else {
            throw PCSessionError.sessionNotFound
        }
        let now = Date()
        let expires = now.addingTimeInterval(86400)
        try await updateValues(
            at: ref,
            [
                "status": "authorized",
                "activationCode": "DEVBYPASS",
                "deviceId": DeviceIdentity.id,
                "mode": ActivationMode.time.rawValue,
                "authorizedAt": now.timeIntervalSince1970 * 1000,
                "expiresAt": expires.timeIntervalSince1970 * 1000,
                "expireTime": expires.timeIntervalSince1970,
            ]
        )
    }

    private func sessionRef(_ sessionId: String) -> DatabaseReference {
        root!.child(sessionsPath).child(sessionId)
    }

    private func fetchSession(at ref: DatabaseReference) async throws -> [String: Any] {
        try await withCheckedThrowingContinuation { continuation in
            ref.getData { error, snapshot in
                if let error {
                    continuation.resume(throwing: Self.mapFirebaseError(error))
                    return
                }
                guard let snapshot, snapshot.exists(),
                      let dict = Self.dictionary(from: snapshot.value) else {
                    continuation.resume(throwing: PCSessionError.sessionNotFound)
                    return
                }
                continuation.resume(returning: dict)
            }
        }
    }

    private func updateValues(at ref: DatabaseReference, _ values: [String: Any]) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            ref.updateChildValues(values) { error, _ in
                if let error {
                    continuation.resume(throwing: Self.mapFirebaseError(error))
                } else {
                    continuation.resume()
                }
            }
        }
    }

    private static func dictionary(from value: Any?) -> [String: Any]? {
        if let dict = value as? [String: Any] { return dict }
        if let dict = value as? [String: NSObject] {
            return dict.reduce(into: [String: Any]()) { $0[$1.key] = $1.value }
        }
        if let dict = value as? NSDictionary {
            var result: [String: Any] = [:]
            for case let key as String in dict.allKeys {
                result[key] = dict[key]
            }
            return result
        }
        return nil
    }

    private static func mapFirebaseError(_ error: Error) -> Error {
        let ns = error as NSError
        let message = ns.localizedDescription.lowercased()
        if ns.domain == "com.firebase",
           message.contains("permission") || message.contains("denied") || ns.code == 1 {
            return PCSessionError.permissionDenied
        }
        return error
    }
}

enum PCSessionLinkParser {
    static func sessionId(from raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let url = URL(string: trimmed),
           url.scheme == "notesimulator",
           url.host == "pair",
           let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
           let session = items.first(where: { $0.name == "s" })?.value,
           !session.isEmpty {
            return session
        }

        if trimmed.range(of: "^[0-9a-fA-F]{32}$", options: .regularExpression) != nil {
            return trimmed
        }
        return nil
    }
}
