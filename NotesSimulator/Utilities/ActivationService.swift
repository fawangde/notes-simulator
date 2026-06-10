import FirebaseDatabase
import Foundation

enum ActivationError: LocalizedError {
    case invalidCodeFormat
    case codeNotFound
    case alreadyUsed
    case expired
    case noClicksRemaining
    case missingClickCount
    case deviceMismatch
    case permissionDenied
    case firebaseUnavailable
    case networkUnavailable
    case firebaseUnreachable

    case missingUsedField

    var errorDescription: String? {
        switch self {
        case .invalidCodeFormat:
            return "激活码须为 5、6、7 位（按天）或 8 位（按次数），仅含英文字母或数字"
        case .codeNotFound:
            let db = FirebaseDatabaseConfig.databaseURLString ?? "（未读取到 DATABASE_URL）"
            return """
            在 Realtime Database 里找不到这个激活码。

            请确认：
            1. 打开的是 Realtime Database（不是 Firestore）
            2. 路径是 activationCodes/你的码
            3. 字段 used 为 boolean 的 false
            4. App 连接的数据库：
            \(db)
            """
        case .alreadyUsed:
            return "激活码已使用，无法再次激活或转给他人"
        case .expired:
            return "激活已过期"
        case .noClicksRemaining:
            return "模拟次数已用完，请重新激活"
        case .missingClickCount:
            return "8 位激活码缺少 clickCount 字段，请在 Realtime Database 中补充"
        case .missingUsedField:
            return """
            激活码节点存在，但缺少 used 字段（boolean）。

            请把字段名改为 used（不是 sued），值设为 false。
            路径：activationCodes/你的码/used = false
            """
        case .deviceMismatch:
            return "当前设备与激活记录不匹配"
        case .permissionDenied:
            return "Realtime Database 拒绝访问，请在 Firebase 控制台 → Realtime Database → 规则 中发布 firebase/database.rules"
        case .firebaseUnavailable:
            return "Firebase 未配置，请添加含 DATABASE_URL 的 GoogleService-Info.plist"
        case .networkUnavailable:
            return "当前无网络，请先打开 Wi-Fi 或蜂窝移动网络"
        case .firebaseUnreachable:
            return "无法连接 Realtime Database，请检查网络后重试"
        }
    }
}

@MainActor
final class ActivationService {
    static let shared = ActivationService()

    private let codesPath = "activationCodes"

    private var root: DatabaseReference? {
        FirebaseDatabaseConfig.reference()
    }

    private init() {}

    func deviceId() -> String {
        DeviceIdentity.id
    }

    func activate(code rawCode: String) async throws -> ActivationOutcome {
        let code = ActivationFormatting.normalizedCode(rawCode)
        guard let mode = ActivationFormatting.inferredMode(for: code) else {
            throw ActivationError.invalidCodeFormat
        }
        guard root != nil else { throw ActivationError.firebaseUnavailable }

        guard NetworkMonitor.shared.isConnected else {
            throw ActivationError.networkUnavailable
        }
        guard await FirebaseReachability.canReachDatabase() else {
            throw ActivationError.firebaseUnreachable
        }

        let deviceId = deviceId()
        let ref = codeRef(code)
        let now = Date()
        let data = try await fetchCodeData(at: ref)
        try Self.requireUnusedCode(in: data)

        switch mode {
        case .time:
            guard let duration = ActivationFormatting.duration(for: code) else {
                throw ActivationError.invalidCodeFormat
            }
            let expiresAt = now.addingTimeInterval(duration)
            try await updateValues(
                at: ref,
                [
                    "used": true,
                    "mode": ActivationMode.time.rawValue,
                    "deviceId": deviceId,
                    "activatedAt": Self.timestamp(now),
                    "expiresAt": Self.timestamp(expiresAt),
                    "codeLength": code.count,
                ]
            )
            return ActivationOutcome(mode: .time, expiresAt: expiresAt, remainingClicks: nil)

        case .clicks:
            guard let clickCount = RTDBValue.int(from: data["clickCount"]), clickCount > 0 else {
                throw ActivationError.missingClickCount
            }
            try await updateValues(
                at: ref,
                [
                    "used": true,
                    "mode": ActivationMode.clicks.rawValue,
                    "deviceId": deviceId,
                    "activatedAt": Self.timestamp(now),
                    "remainingClicks": clickCount,
                    "codeLength": code.count,
                ]
            )
            return ActivationOutcome(mode: .clicks, expiresAt: nil, remainingClicks: clickCount)
        }
    }

    func decrementRemainingClicks(code: String, boundUID: String, to newValue: Int) async throws {
        guard newValue >= 0 else { throw ActivationError.noClicksRemaining }
        guard root != nil else { throw ActivationError.firebaseUnavailable }
        let deviceId = deviceId()
        guard deviceId == boundUID else { throw ActivationError.deviceMismatch }

        let ref = codeRef(code)
        let data = try await fetchCodeData(at: ref)
        guard data["deviceId"] as? String == deviceId else {
            throw ActivationError.deviceMismatch
        }
        guard data["mode"] as? String == ActivationMode.clicks.rawValue else {
            throw ActivationError.codeNotFound
        }
        let current = RTDBValue.int(from: data["remainingClicks"]) ?? 0
        guard current == newValue + 1 else {
            throw ActivationError.noClicksRemaining
        }
        try await updateValues(at: ref, ["remainingClicks": newValue])
    }

    func verifyActivation(
        code: String,
        boundUID: String,
        mode: ActivationMode,
        expiresAt: Date?,
        remainingClicks: Int?
    ) async throws -> ActivationOutcome {
        guard root != nil else { throw ActivationError.firebaseUnavailable }
        guard deviceId() == boundUID else { throw ActivationError.deviceMismatch }

        let data = try await fetchCodeData(at: codeRef(code))
        guard RTDBValue.bool(from: data["used"]) == true else {
            throw ActivationError.codeNotFound
        }
        guard data["deviceId"] as? String == boundUID else {
            throw ActivationError.deviceMismatch
        }

        switch mode {
        case .time:
            guard let expiresAt, expiresAt > Date() else { throw ActivationError.expired }
            if let remoteExpiry = Self.date(from: data["expiresAt"]), remoteExpiry <= Date() {
                throw ActivationError.expired
            }
            return ActivationOutcome(mode: .time, expiresAt: expiresAt, remainingClicks: nil)

        case .clicks:
            let remoteClicks = RTDBValue.int(from: data["remainingClicks"]) ?? 0
            let localClicks = remainingClicks ?? remoteClicks
            let synced = min(localClicks, remoteClicks)
            guard synced > 0 else { throw ActivationError.noClicksRemaining }
            return ActivationOutcome(mode: .clicks, expiresAt: nil, remainingClicks: synced)
        }
    }

    private func codeRef(_ code: String) -> DatabaseReference {
        root!.child(codesPath).child(code)
    }

    private func fetchCodeData(at ref: DatabaseReference) async throws -> [String: Any] {
        try await withCheckedThrowingContinuation { continuation in
            ref.getData { error, snapshot in
                if let error {
                    continuation.resume(throwing: Self.mapFirebaseError(error))
                    return
                }
                guard let snapshot, snapshot.exists() else {
                    continuation.resume(throwing: ActivationError.codeNotFound)
                    return
                }
                guard let dict = Self.dictionary(from: snapshot.value) else {
                    continuation.resume(throwing: ActivationError.codeNotFound)
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
        if let dict = value as? [String: Any] {
            return dict
        }
        if let dict = value as? [String: NSObject] {
            return dict.reduce(into: [String: Any]()) { result, entry in
                result[entry.key] = entry.value
            }
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

    private static func requireUnusedCode(in data: [String: Any]) throws {
        if data["used"] == nil {
            if data["sued"] != nil {
                throw ActivationError.missingUsedField
            }
            throw ActivationError.missingUsedField
        }
        if RTDBValue.bool(from: data["used"]) == true {
            throw ActivationError.alreadyUsed
        }
    }

    private static func mapFirebaseError(_ error: Error) -> Error {
        let ns = error as NSError
        let message = ns.localizedDescription.lowercased()
        if ns.domain == "com.firebase",
           message.contains("permission") || message.contains("denied") || ns.code == 1 {
            return ActivationError.permissionDenied
        }
        return error
    }

    private static func timestamp(_ date: Date) -> Double {
        date.timeIntervalSince1970 * 1000
    }

    private static func date(from value: Any?) -> Date? {
        guard let ms = RTDBValue.double(from: value) else { return nil }
        return Date(timeIntervalSince1970: ms / 1000)
    }
}
