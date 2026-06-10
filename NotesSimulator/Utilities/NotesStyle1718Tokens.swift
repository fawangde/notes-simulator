import SwiftUI
import UIKit

/// iOS 17–18 备忘录外观（reference 目测 + 用户定稿参数）
enum NotesStyle1718Tokens {
    static var iconColor: Color { NotesDetectedLinkColor.color }

    static let navBackTitle = "备忘录"
    static let navBackIcon = "chevron.left"
    static let navTrailingIcons = [
        "square.and.arrow.up",
        "ellipsis.circle",
    ]

    static let toolbarChecklistIcon = "checklist"
    static let toolbarCameraIcon = "camera"
    /// 标记：系统自带圆圈符号（不是外描圈）
    static let toolbarMarkupIcon = "pencil.tip.crop.circle"
    static let toolbarComposeIcon = "square.and.pencil"

    static let navIconSize: CGFloat = 22
    static let toolbarIconSize: CGFloat = 24
    static let navBackFont = Font.system(size: 17, weight: .regular)
    static let navTrailingSpacing: CGFloat = 24
    static let toolbarSpacing: CGFloat = 28

    /// 顶栏下缘再向下延伸的实心挡板区（与底栏 chromeAboveToolbar 对称）
    static let chromeBelowNav: CGFloat = 10
    /// 底栏上缘再向上延伸的实心挡板区（完全盖住图标下方并超出）
    static let chromeAboveToolbar: CGFloat = 10
    /// 底栏图标整体再下移
    static let toolbarExtraDownShift: CGFloat = 10

    /// 与备忘录主背景同一颜色（底板不得有色差）
    static var paperBackground: Color {
        paperColor
    }

    static let paperColor = Color(uiColor: paperUIColor)
    static let paperUIColor = UIColor(red: 1, green: 252 / 255, blue: 245 / 255, alpha: 1)

    static var titleUIColor: UIColor { IOSTheme.titleLabelUI }
    static var titleColor: Color { IOSTheme.titleLabel }
}
