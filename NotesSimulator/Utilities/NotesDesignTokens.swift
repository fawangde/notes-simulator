import SwiftUI
import UIKit

/// iOS 26.2 备忘录设计规范
/// - `Official`：HIG / SF Symbols / 开发者文档可查的固定 pt、图标名、语义色名
/// - 颜色与玻璃透光：一律走 `NotesSemanticColor` / SwiftUI `Material`，不写死 HEX 与 α
enum NotesDesignTokens {
    enum Theme: String, CaseIterable {
        case yellow
        case white
        case dark
    }

    // MARK: - ✅ 官方公开固定参数（HIG / SF Symbols）

    enum Official {
        enum Nav {
            static let barHeight: CGFloat = 52
            static let buttonSize: CGFloat = 44
            static let buttonCornerRadius: CGFloat = 22
            static let horizontalMargin: CGFloat = 16
            static let backIcon = "chevron.left"
            static let shareIcon = "square.and.arrow.up"
            static let moreIcon = "ellipsis"
            static let iconSize: CGFloat = 19
            static let iconWeight: Font.Weight = .medium
            static let dateRowHeight: CGFloat = 34
        }

        enum Title {
            static let fontSize: CGFloat = 32
            static let weight: Font.Weight = .bold
            static let contentInset: CGFloat = 16
            static let gapToBody: CGFloat = 24
        }

        enum Body {
            static let fontSize: CGFloat = 19
            static let weight: UIFont.Weight = .medium
            // FROZEN — 号码列表行高/段间距已定型，勿改
            /// 单行号码占用高度（pt）
            static let phoneListRowHeight: CGFloat = 22
            /// 两行号码之间的段间距（pt）
            static let phoneListParagraphSpacing: CGFloat = 7
        }

        enum Toolbar {
            static let height: CGFloat = 58
            static let bottomSafeGap: CGFloat = 12
            static let buttonSize: CGFloat = 44
            static let iconSize: CGFloat = 21
            static let iconWeight: Font.Weight = .medium
            static let checklistIcon = "checklist"
            static let attachmentIcon = "paperclip"
            static let markupIcon = "pencil.tip.crop.circle"
            static let composeIcon = "square.and.pencil"
        }

        /// Apple Materials 文档公示的材质名（透光率由系统运行时计算）
        enum MaterialName {
            static let navButton = Material.bar          // 工具栏材质，浅色下更偏白；透光仍由系统计算
            static let topFade = UIBlurEffect.Style.systemChromeMaterial
            static let toolbarPanel = Material.bar
            static let phoneMenu = Material.thin
            static let overlay = UIBlurEffect.Style.systemMaterial
        }
    }

    // MARK: - 布局别名（兼容现有引用）

    enum Layout {
        static let contentInset = Official.Title.contentInset
        static let navBarHeight = Official.Nav.barHeight
        static let bottomToolbarHeight = Official.Toolbar.height
        static let toolbarButtonSize = Official.Toolbar.buttonSize
        static let toolbarCapsuleRadius = Official.Nav.buttonCornerRadius
        static let cardRadius = Official.Nav.buttonCornerRadius
        static let titleFont = Font.system(size: Official.Title.fontSize, weight: Official.Title.weight)
        static let dateFont = Font.system(size: 15, weight: .regular)
        static let titleToBodyGap = Official.Title.gapToBody
    }

    // MARK: - 长按菜单（尺寸为模拟交互布局，面板材质走系统 Material）

    enum PhoneMenu {
        static let width: CGFloat = 263
        static let height: CGFloat = 560
        static let cornerRadius: CGFloat = 28
        static let horizontalMargin: CGFloat = 16
        static let headerHeight: CGFloat = 56
        static let rowHeight: CGFloat = 58
        static let groupDividerHeight: CGFloat = 2
        static let contentInsetH: CGFloat = 14
        static let headerFont = Font.system(size: 20, weight: .semibold)
        static let titleFont = Font.system(size: 17, weight: .regular)
        static let subtitleFont = Font.system(size: 13, weight: .light)
        static let iconSize: CGFloat = 19
        static let iconGap: CGFloat = 10
        static let chevronSize: CGFloat = 16
        static let bottomSafeThreshold: CGFloat = 120
        static let topSafeThreshold: CGFloat = 80
        static let menuGap: CGFloat = 15
        static let overlayDim: CGFloat = 0.34
    }

    enum PreviewBubble {
        static let height: CGFloat = 45
        static let padH: CGFloat = 12
        static let cornerRadius: CGFloat = 12
        static let fontSize: CGFloat = 20
        static let longPressDelay: TimeInterval = 0.5
        static let menuDelay: TimeInterval = 0.12
        static let phoneBubbleExtraShiftX: CGFloat = 0
        static let bgColor = Color(
            red: 1,
            green: 1,
            blue: 1,
            opacity: 112 / 255
        )
        static let borderColor = Color.white
    }

    enum PhoneLink {
        static let fontSize: CGFloat = 19
        static let uiColor = NotesDetectedLinkColor.uiColor
        static let color = NotesDetectedLinkColor.color
    }

    enum MenuGlass {
        static let blur: Double = 0.98
        static let translucency: Double = 0.95
        static let refractionTop: Double = 0.39
        static let refractionMid: Double = 0.18
        static let specularStrength: Double = 0.65
        static let innerShadow: Double = 0.06
        static let tintColor = Color(red: 248 / 255, green: 248 / 255, blue: 250 / 255, opacity: 212 / 255)
        static let borderColor = Color.white.opacity(80 / 255)
        static let frostCover: Double = max(0.04, min(0.98, 1.0 - translucency))
    }

    enum MenuLayout {
        static let width: CGFloat = 254
        static let height: CGFloat = 560
        static let cornerRadius: CGFloat = 34
        static let rowHeight: CGFloat = 58
        static let headerHeight: CGFloat = 56
        static let gap: CGFloat = 15
        static let contentInsetH: CGFloat = 14
        static let headerFontSize: CGFloat = 18
        static let rowTitleFontSize: CGFloat = 15
        static let rowSubtitleFontSize: CGFloat = 13
        static let iconSize: CGFloat = 18
        static let chevronSize: CGFloat = 16
    }

    static func oneDigitWidth(for fontSize: CGFloat) -> CGFloat {
        let font = UIFont.systemFont(ofSize: fontSize, weight: .regular)
        return ceil(("0" as NSString).size(withAttributes: [.font: font]).width)
    }

    enum Spring {
        static let peek = (response: 0.26, damping: 0.73)
        static let menuShow = (response: 0.33, damping: 0.67)
        static let menuHide = (response: 0.23, damping: 0.81)
        static let overlay = (response: 0.22, damping: 1.0)
    }
}

/// 系统语义色 — 色值与对比度由 UIKit 按壁纸 / 深色模式 /「降低透明度」动态解析
enum NotesSemanticColor {
    static var label: Color { Color(uiColor: .label) }
    static var labelUI: UIColor { .label }
    static var secondaryLabel: Color { Color(uiColor: .secondaryLabel) }
    static var secondaryLabelUI: UIColor { .secondaryLabel }
    static var tertiaryLabel: Color { Color(uiColor: .tertiaryLabel) }
    static var tertiaryLabelUI: UIColor { .tertiaryLabel }
    static var link: Color { Color(uiColor: .link) }
    static var linkUI: UIColor { .link }
    static var separator: Color { Color(uiColor: .separator) }
    static var separatorUI: UIColor { .separator }
    static var systemBackground: Color { Color(uiColor: .systemBackground) }
    static var systemBackgroundUI: UIColor { .systemBackground }
    static var quaternaryFill: Color { Color(uiColor: .quaternarySystemFill) }
    static var quaternaryFillUI: UIColor { .quaternarySystemFill }
}

/// 备忘录自动识别号码/数据链接色（真机金黄下划线；非 UIColor.link 默认蓝）
enum NotesDetectedLinkColor {
    /// 备忘录号码金黄（偏暖黄，真机采样向）
    static let uiColor = UIColor(red: 245 / 255, green: 188 / 255, blue: 8 / 255, alpha: 1)
    static let color = Color(red: 245 / 255, green: 188 / 255, blue: 8 / 255)
}
