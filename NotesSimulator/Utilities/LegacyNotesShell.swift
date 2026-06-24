import Foundation

/// 备忘录 / 信息页 legacy 外壳：iOS 17 与 iOS 18 独立开关，默认关闭时为 iOS 26。
enum LegacyNotesShell: String, Codable, CaseIterable, Identifiable {
    case ios17
    case ios18

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .ios17: return "iOS 17"
        case .ios18: return "iOS 18"
        }
    }
}

extension AppState {
    var legacyNotesShell: LegacyNotesShell? {
        if notesStyleIOS17 { return .ios17 }
        if notesStyleIOS18 { return .ios18 }
        return nil
    }

    var usesLegacyNotesShell: Bool {
        legacyNotesShell != nil
    }

    func activateLegacyNotesShell(_ shell: LegacyNotesShell) {
        switch shell {
        case .ios17:
            notesStyleIOS17 = true
            notesStyleIOS18 = false
        case .ios18:
            notesStyleIOS17 = false
            notesStyleIOS18 = true
        }
    }

    func bridgedLegacyTuningForCompose() -> Notes1718TuningSettings {
        switch legacyNotesShell {
        case .ios17: return notes17Tuning.bridgedTo1718()
        case .ios18: return notes18Tuning.bridgedTo1718()
        case nil: return .default
        }
    }
}
