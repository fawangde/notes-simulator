import UIKit

/// 信息页气泡文字样式（26 / 1718 共用）
struct ComposeBubbleTuningSettings: Codable, Equatable {
    var fontSize: Double = 17

    static let `default` = ComposeBubbleTuningSettings()

    func bubbleFontUI() -> UIFont {
        UIFont.systemFont(ofSize: CGFloat(fontSize), weight: .regular)
    }
}

enum ComposeBubbleTuningStore {
    private static let key = "ComposeBubbleTuning.v1"

    static func load() -> ComposeBubbleTuningSettings {
        guard let data = UserDefaults.standard.data(forKey: key),
              let settings = try? JSONDecoder().decode(ComposeBubbleTuningSettings.self, from: data) else {
            return .default
        }
        return settings
    }

    static func save(_ settings: ComposeBubbleTuningSettings) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
