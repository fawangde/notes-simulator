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

    /// 仅这些错误才应清空本地激活；网络/暂时性失败应保留本地状态
    var shouldClearLocalActivation: Bool {
        switch self {
        case .expired, .noClicksRemaining, .alreadyUsed:
            return true
        case .codeNotFound:
            return true
        case .deviceMismatch:
            return true
        case .invalidCodeFormat, .missingClickCount, .missingUsedField:
            return false
        case .permissionDenied, .firebaseUnavailable, .networkUnavailable, .firebaseUnreachable:
            return false
        }
    }

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

        if RTDBValue.bool(from: data["used"]) == true {
            return try Self.restoreExistingActivation(from: data, code: code, deviceId: deviceId)
        }
        try Self.requireUnusedCode(in: data)

        switch mode {
        case .time:
            guard let duration = ActivationFormatting.duration(for: code) else {
                throw ActivationError.invalidCodeFormat
            }
            let expiresAt = now.addingTimeInterval(duration)
            let nowSec = now.timeIntervalSince1970
            let expireSec = expiresAt.timeIntervalSince1970
            try await updateValues(
                at: ref,
                [
                    "used": true,
                    "mode": ActivationMode.time.rawValue,
                    "deviceId": deviceId,
                    "activatedAt": Self.timestampMillis(now),
                    "expiresAt": Self.timestampMillis(expiresAt),
                    "activateTime": nowSec,
                    "expireTime": expireSec,
                    "codeLength": code.count,
                ]
            )
            return ActivationOutcome(
                mode: .time,
                expiresAt: expiresAt,
                remainingClicks: nil,
                activatedAt: now
            )

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
                    "activatedAt": Self.timestampMillis(now),
                    "activateTime": now.timeIntervalSince1970,
                    "remainingClicks": clickCount,
                    "codeLength": code.count,
                ]
            )
            return ActivationOutcome(
                mode: .clicks,
                expiresAt: nil,
                remainingClicks: clickCount,
                initialClickCount: clickCount,
                activatedAt: now
            )
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

    /// 与 ZG 类似：以 Firebase 记录为准同步；网络失败由调用方保留本地状态
    func syncActivationFromRemote(
        code: String,
        boundUID: String,
        localExpiresAt: Date?,
        localRemainingClicks: Int?
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

        let mode = try Self.resolvedMode(from: data, code: code)

        switch mode {
        case .time:
            let remoteExpiry = Self.expiryDate(from: data)
            let effectiveExpiry = remoteExpiry ?? localExpiresAt
            guard let effectiveExpiry, effectiveExpiry > Date() else {
                throw ActivationError.expired
            }
            return ActivationOutcome(
                mode: .time,
                expiresAt: effectiveExpiry,
                remainingClicks: nil,
                activatedAt: Self.activatedAtDate(from: data)
            )

        case .clicks:
            let remoteClicks = RTDBValue.int(from: data["remainingClicks"]) ?? 0
            guard remoteClicks > 0 else { throw ActivationError.noClicksRemaining }
            let initial = RTDBValue.int(from: data["clickCount"]) ?? remoteClicks
            return ActivationOutcome(
                mode: .clicks,
                expiresAt: nil,
                remainingClicks: remoteClicks,
                initialClickCount: initial,
                activatedAt: Self.activatedAtDate(from: data)
            )
        }
    }

    @available(*, deprecated, message: "Use syncActivationFromRemote")
    func verifyActivation(
        code: String,
        boundUID: String,
        mode: ActivationMode,
        expiresAt: Date?,
        remainingClicks: Int?
    ) async throws -> ActivationOutcome {
        try await syncActivationFromRemote(
            code: code,
            boundUID: boundUID,
            localExpiresAt: expiresAt,
            localRemainingClicks: remainingClicks
        )
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

    /// 本地激活被误清时，同一设备可凭 Firebase 记录恢复
    private static func restoreExistingActivation(
        from data: [String: Any],
        code: String,
        deviceId: String
    ) throws -> ActivationOutcome {
        guard data["deviceId"] as? String == deviceId else {
            throw ActivationError.alreadyUsed
        }
        let mode = try resolvedMode(from: data, code: code)

        switch mode {
        case .time:
            guard let remoteExpiry = expiryDate(from: data), remoteExpiry > Date() else {
                throw ActivationError.expired
            }
            return ActivationOutcome(
                mode: .time,
                expiresAt: remoteExpiry,
                remainingClicks: nil,
                activatedAt: Self.activatedAtDate(from: data)
            )

        case .clicks:
            let remaining = RTDBValue.int(from: data["remainingClicks"]) ?? 0
            guard remaining > 0 else { throw ActivationError.noClicksRemaining }
            let initial = RTDBValue.int(from: data["clickCount"]) ?? remaining
            return ActivationOutcome(
                mode: .clicks,
                expiresAt: nil,
                remainingClicks: remaining,
                initialClickCount: initial,
                activatedAt: Self.activatedAtDate(from: data)
            )
        }
    }

    private static func resolvedMode(from data: [String: Any], code: String) throws -> ActivationMode {
        if let modeRaw = data["mode"] as? String, let mode = ActivationMode(rawValue: modeRaw) {
            return mode
        }
        if let length = RTDBValue.int(from: data["codeLength"]), length == 8 {
            return .clicks
        }
        if let inferred = ActivationFormatting.inferredMode(for: code) {
            return inferred
        }
        throw ActivationError.codeNotFound
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

    private static func timestampMillis(_ date: Date) -> Double {
        date.timeIntervalSince1970 * 1000
    }

    /// 优先读 expireTime（秒，与 ZG 一致），兼容旧字段 expiresAt
    static func expiryDate(from data: [String: Any]) -> Date? {
        if let seconds = RTDBValue.double(from: data["expireTime"]), seconds > 1_000_000_000 {
            return Date(timeIntervalSince1970: seconds)
        }
        return date(from: data["expiresAt"])
    }

    static func activatedAtDate(from data: [String: Any]) -> Date? {
        if let seconds = RTDBValue.double(from: data["activateTime"]), seconds > 1_000_000_000 {
            return Date(timeIntervalSince1970: seconds)
        }
        return date(from: data["activatedAt"])
    }

    /// 兼容 expiresAt：毫秒或秒
    private static func date(from value: Any?) -> Date? {
        guard let raw = RTDBValue.double(from: value) else { return nil }
        if raw > 1_000_000_000_000 {
            return Date(timeIntervalSince1970: raw / 1000)
        }
        if raw > 1_000_000_000 {
            return Date(timeIntervalSince1970: raw)
        }
        return nil
    }
}
