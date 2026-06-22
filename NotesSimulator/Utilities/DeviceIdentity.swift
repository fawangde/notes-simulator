import Foundation
import Security

/// 每台设备唯一 ID，存 Keychain，卸载重装后仍保留（除非抹掉设备数据）。
enum DeviceIdentity {
    private static let service = "com.notesimulator.app.device"
    private static let account = "activationDeviceId"

    static var id: String {
        if let existing = readKeychain() {
            return existing
        }
        let newId = UUID().uuidString
        saveKeychain(newId)
        return newId
    }

    /// 硬件 UDID（仅用于本机免激活白名单；Ad Hoc 分发场景）
    static var hardwareUDID: String? {
        readMobileGestaltString(key: "UniqueDeviceID")
    }

    private static func readMobileGestaltString(key: String) -> String? {
        guard let handle = dlopen("/usr/lib/libMobileGestalt.dylib", RTLD_NOW) else { return nil }
        defer { dlclose(handle) }
        guard let symbol = dlsym(handle, "MGCopyAnswer") else { return nil }
        typealias MGCopyAnswerFn = @convention(c) (CFString) -> Unmanaged<CFTypeRef>?
        let copyAnswer = unsafeBitCast(symbol, to: MGCopyAnswerFn.self)
        guard let value = copyAnswer(key as CFString)?.takeRetainedValue() else { return nil }
        if let string = value as? String { return string }
        if let data = value as? Data { return String(data: data, encoding: .utf8) }
        return nil
    }

    static func normalizedHardwareUDID(_ raw: String) -> String {
        raw.uppercased().unicodeScalars
            .filter { Character($0).isHexDigit }
            .map(String.init)
            .joined()
    }

    private static func readKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess,
              let data = item as? Data,
              let value = String(data: data, encoding: .utf8),
              !value.isEmpty else {
            return nil
        }
        return value
    }

    private static func saveKeychain(_ value: String) {
        guard let data = value.data(using: .utf8) else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
}
