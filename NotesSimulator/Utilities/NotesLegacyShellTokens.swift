import SwiftUI

extension LegacyNotesShell {
    var chromeBelowNav: CGFloat {
        switch self {
        case .ios17: NotesStyle17Tokens.chromeBelowNav
        case .ios18: NotesStyle18Tokens.chromeBelowNav
        }
    }

    var unifiedNavExtraDownShift: CGFloat {
        switch self {
        case .ios17: NotesStyle17Tokens.unifiedNavExtraDownShift
        case .ios18: NotesStyle18Tokens.unifiedNavExtraDownShift
        }
    }

    var chromeAboveToolbar: CGFloat {
        switch self {
        case .ios17: NotesStyle17Tokens.chromeAboveToolbar
        case .ios18: NotesStyle18Tokens.chromeAboveToolbar
        }
    }

    var unifiedBottomPlateExtraDownShift: CGFloat {
        switch self {
        case .ios17: NotesStyle17Tokens.unifiedBottomPlateExtraDownShift
        case .ios18: NotesStyle18Tokens.unifiedBottomPlateExtraDownShift
        }
    }

    var toolbarExtraDownShift: CGFloat {
        switch self {
        case .ios17: NotesStyle17Tokens.toolbarExtraDownShift
        case .ios18: NotesStyle18Tokens.toolbarExtraDownShift
        }
    }

    var navTrailingSpacing: CGFloat {
        switch self {
        case .ios17: NotesStyle17Tokens.navTrailingSpacing
        case .ios18: NotesStyle18Tokens.navTrailingSpacing
        }
    }

    var navTrailingIcons: [String] {
        switch self {
        case .ios17: NotesStyle17Tokens.navTrailingIcons
        case .ios18: NotesStyle18Tokens.navTrailingIcons
        }
    }

    var toolbarChecklistIcon: String {
        switch self {
        case .ios17: NotesStyle17Tokens.toolbarChecklistIcon
        case .ios18: NotesStyle18Tokens.toolbarChecklistIcon
        }
    }

    var toolbarCameraIcon: String {
        switch self {
        case .ios17: NotesStyle17Tokens.toolbarCameraIcon
        case .ios18: NotesStyle18Tokens.toolbarCameraIcon
        }
    }

    var toolbarMarkupIcon: String {
        switch self {
        case .ios17: NotesStyle17Tokens.toolbarMarkupIcon
        case .ios18: NotesStyle18Tokens.toolbarMarkupIcon
        }
    }

    var toolbarComposeIcon: String {
        switch self {
        case .ios17: NotesStyle17Tokens.toolbarComposeIcon
        case .ios18: NotesStyle18Tokens.toolbarComposeIcon
        }
    }

    var toolbarIconSize: CGFloat {
        switch self {
        case .ios17: NotesStyle17Tokens.toolbarIconSize
        case .ios18: NotesStyle18Tokens.toolbarIconSize
        }
    }

    var messagesPresentDuration: TimeInterval {
        switch self {
        case .ios17: IMessage17DesignTokens.messagesPresentDuration
        case .ios18: IMessage18DesignTokens.messagesPresentDuration
        }
    }

    var messagesDismissDuration: TimeInterval {
        switch self {
        case .ios17: IMessage17DesignTokens.messagesDismissDuration
        case .ios18: IMessage18DesignTokens.messagesDismissDuration
        }
    }

    var systemModalDuration: TimeInterval {
        switch self {
        case .ios17: IMessage17DesignTokens.systemModalDuration
        case .ios18: IMessage18DesignTokens.systemModalDuration
        }
    }

    var fromViewDismissDuration: TimeInterval {
        switch self {
        case .ios17: IMessage17DesignTokens.fromViewDismissDuration
        case .ios18: IMessage18DesignTokens.fromViewDismissDuration
        }
    }

    var fromViewEndAlpha: CGFloat {
        switch self {
        case .ios17: IMessage17DesignTokens.fromViewEndAlpha
        case .ios18: IMessage18DesignTokens.fromViewEndAlpha
        }
    }

    var phoneMenuFadeOutDuration: TimeInterval {
        switch self {
        case .ios17: IMessage17DesignTokens.phoneMenuFadeOutDuration
        case .ios18: IMessage18DesignTokens.phoneMenuFadeOutDuration
        }
    }

    @MainActor
    func paperColor(app: AppState) -> Color {
        switch self {
        case .ios17: app.notes17Tuning.paperBackgroundColor()
        case .ios18: app.notes18Tuning.paperBackgroundColor()
        }
    }

    @MainActor
    func bridged1718Tuning(app: AppState) -> Notes1718TuningSettings {
        switch self {
        case .ios17: app.notes17Tuning.bridgedTo1718()
        case .ios18: app.notes18Tuning.bridgedTo1718()
        }
    }

    @MainActor
    func longPressTextBlurRadius(app: AppState) -> CGFloat {
        switch self {
        case .ios17: CGFloat(app.notes17Tuning.longPressTextBlurRadius)
        case .ios18: CGFloat(app.notes18Tuning.longPressTextBlurRadius)
        }
    }
}

extension Notes17TuningSettings {
    func bridgedTo1718() -> Notes1718TuningSettings {
        guard let data = try? JSONEncoder().encode(self),
              let decoded = try? JSONDecoder().decode(Notes1718TuningSettings.self, from: data) else {
            return .default
        }
        return decoded
    }

    static func bridgedFrom1718(_ source: Notes1718TuningSettings) -> Notes17TuningSettings {
        guard let data = try? JSONEncoder().encode(source),
              let decoded = try? JSONDecoder().decode(Notes17TuningSettings.self, from: data) else {
            return .default
        }
        return decoded
    }
}

extension Notes18TuningSettings {
    func bridgedTo1718() -> Notes1718TuningSettings {
        guard let data = try? JSONEncoder().encode(self),
              let decoded = try? JSONDecoder().decode(Notes1718TuningSettings.self, from: data) else {
            return .default
        }
        return decoded
    }

    static func bridgedFrom1718(_ source: Notes1718TuningSettings) -> Notes18TuningSettings {
        guard let data = try? JSONEncoder().encode(source),
              let decoded = try? JSONDecoder().decode(Notes18TuningSettings.self, from: data) else {
            return .default
        }
        return decoded
    }
}
