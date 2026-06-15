import SwiftUI
import UIKit

/// iOS 26 备忘录文字样式调参
struct Notes26TuningSettings: Codable, Equatable {
    var titleFontSize: Double = 29
    /// 0 = label，1 = secondaryLabel
    var themeTextGrayness: Double = 0.50
    var bodyFontSize: Double = 19
    var phoneFontSize: Double = 19
    /// 0 = PrimaryText 定档灰，1 = 黄纸暖褐墨感
    var bodyYellowWarmth: Double = 0

    static let `default` = Notes26TuningSettings()

    func themeTextUIColor() -> UIColor {
        Self.blendedGrayUIColor(amount: themeTextGrayness)
    }

    func bodyTextUIColor() -> UIColor {
        Self.bodyTextUIColor(warmth: bodyYellowWarmth)
    }

    var bodyPhoneLineHeight: CGFloat {
        CGFloat(22 * bodyFontSize / 19)
    }

    var bodyPhoneParagraphSpacing: CGFloat {
        CGFloat(7 * bodyFontSize / 19)
    }

    static func bodyTextUIColor(warmth: Double) -> UIColor {
        let base = NotesSemanticColor.labelUI
        let warm = UIColor(red: 120 / 255, green: 90 / 255, blue: 40 / 255, alpha: 1)
        return mixUIColor(base, warm, amount: warmth)
    }

    private static func blendedGrayUIColor(amount: Double) -> UIColor {
        let t = CGFloat(min(max(amount, 0), 1))
        return UIColor { traits in
            let label = UIColor.label.resolvedColor(with: traits)
            let secondary = UIColor.secondaryLabel.resolvedColor(with: traits)
            var lr: CGFloat = 0, lg: CGFloat = 0, lb: CGFloat = 0, la: CGFloat = 0
            var sr: CGFloat = 0, sg: CGFloat = 0, sb: CGFloat = 0, sa: CGFloat = 0
            label.getRed(&lr, green: &lg, blue: &lb, alpha: &la)
            secondary.getRed(&sr, green: &sg, blue: &sb, alpha: &sa)
            return UIColor(
                red: lr + (sr - lr) * t,
                green: lg + (sg - lg) * t,
                blue: lb + (sb - lb) * t,
                alpha: la + (sa - la) * t
            )
        }
    }

    private static func mixUIColor(_ a: UIColor, _ b: UIColor, amount: Double) -> UIColor {
        let t = CGFloat(min(max(amount, 0), 1))
        return UIColor { traits in
            let left = a.resolvedColor(with: traits)
            let right = b.resolvedColor(with: traits)
            var lr: CGFloat = 0, lg: CGFloat = 0, lb: CGFloat = 0, la: CGFloat = 0
            var rr: CGFloat = 0, rg: CGFloat = 0, rb: CGFloat = 0, ra: CGFloat = 0
            left.getRed(&lr, green: &lg, blue: &lb, alpha: &la)
            right.getRed(&rr, green: &rg, blue: &rb, alpha: &ra)
            return UIColor(
                red: lr + (rr - lr) * t,
                green: lg + (rg - lg) * t,
                blue: lb + (rb - lb) * t,
                alpha: la + (ra - la) * t
            )
        }
    }
}

enum Notes26TuningStore {
    private static let key = "Notes26Tuning.v1"

    static func load() -> Notes26TuningSettings {
        guard let data = UserDefaults.standard.data(forKey: key),
              let settings = try? JSONDecoder().decode(Notes26TuningSettings.self, from: data) else {
            return .default
        }
        return settings
    }

    static func save(_ settings: Notes26TuningSettings) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
