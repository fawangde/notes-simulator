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
    /// 1718 一体板：顶栏相对 safeTop 再下移
    static let unifiedNavExtraDownShift: CGFloat = 4
    /// 1718 一体板：底栏相对 classic 再上移
    static let unifiedToolbarUpShift: CGFloat = 4
    /// 1718 一体板：底栏整块底板再下移
    static let unifiedBottomPlateExtraDownShift: CGFloat = 20
    /// 底栏上缘再向上延伸的实心挡板区（完全盖住图标下方并超出）
    static let chromeAboveToolbar: CGFloat = 10
    /// 底栏图标整体再下移
    static let toolbarExtraDownShift: CGFloat = 10

    /// 备忘录主背景（iOS 16.7 reference：systemGray6）
    static var paperBackground: Color {
        paperColor
    }

    static let paperColor = Color(uiColor: paperUIColor)
    static var paperUIColor: UIColor { UIColor.systemGray6 }

    static var titleUIColor: UIColor { IOSTheme.titleLabelUI }
    static var titleColor: Color { IOSTheme.titleLabel }

    // MARK: - 长按 / 点击号码菜单（iPhone X iOS 16.7.2 reference 见 PhoneMenu1718Layout.Design）

    enum PhoneMenu {
        static let tapFogCornerRadius: CGFloat = 6
        static let tapFogColor = Color.black.opacity(0.28)

        static var menuPanelFill: Color { Color(uiColor: .systemBackground) }
        static var previewFill: Color { Color(uiColor: .systemBackground) }
        static var menuLabelColor: Color { Color(uiColor: .label) }
        static var menuIconColor: Color { Color(uiColor: .secondaryLabel) }
        static var previewLabelColor: Color { Color(uiColor: .label) }
        static var rowHighlightFill: Color { Color(uiColor: .systemGray5) }
        static var phonePressedFill: Color { Color(uiColor: .systemGray5) }

        static let avatarFill = Color(uiColor: UIColor.systemGray4)
        static let avatarSymbolColor = Color.white
        /// person.fill 相对头像直径的比例（K3：58%）
        static let avatarSymbolScale: CGFloat = 0.58

        static let overlayDim: Double = 0.22
        static let tapOverlayDim: Double = 0.22
        static let longPressDelay: TimeInterval = PhoneMenu1718Layout.Animation.longPressDuration

        static let expandDuration: TimeInterval = PhoneMenu1718Layout.Animation.previewEnterDuration
        static let axisExpandDuration: TimeInterval = PhoneMenu1718Layout.Animation.phoneMorphDuration
        static let menuExpandDuration: TimeInterval = PhoneMenu1718Layout.Animation.previewEnterDuration
        static let dismissDuration: TimeInterval = PhoneMenu1718Layout.Animation.previewExitDuration
    }
}
