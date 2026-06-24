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
            static let fontSize: CGFloat = 29
            static let weight: Font.Weight = .bold
            /// 标题混色：label 占比越低越灰
            static let labelBlendFraction: CGFloat = 0
            static let secondaryBlendFraction: CGFloat = 0.40
            static let tertiaryBlendFraction: CGFloat = 0.44
            static let quaternaryBlendFraction: CGFloat = 0.16
            /// 标题右内边距 = 左内边距 × 此比例
            static let trailingLeadingRatio: CGFloat = 1.5
            static let contentInset: CGFloat = 16
            static let gapToBody: CGFloat = 24

            static var minLineHeight: CGFloat {
                let font = UIFont.systemFont(ofSize: fontSize, weight: .bold)
                return ceil(font.lineHeight)
            }
        }

        enum PrimaryText {
            /// 正文 / 导航图标等主色：label 占比越低越灰
            static let labelBlendFraction: CGFloat = 0.64
            static let secondaryBlendFraction: CGFloat = 0.28
            static let tertiaryBlendFraction: CGFloat = 0.08
            static let quaternaryBlendFraction: CGFloat = 0
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
            /// 按钮底缘距 Home 条（原 12，减 10 → 整体下移 10pt）
            static let bottomSafeGap: CGFloat = 2
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
        /// 与正文号码首行左缘对齐（= phoneLeadingDigitSpacing × 号码字宽）
        static var titlePhoneAlignedLeadingInset: CGFloat {
            oneDigitWidth(for: PhoneLink.fontSize) * PhoneUtilities.phoneLeadingDigitSpacing
        }
        static var titlePhoneAlignedTrailingInset: CGFloat {
            titlePhoneAlignedLeadingInset * Official.Title.trailingLeadingRatio
        }
        static var titleMinLineHeight: CGFloat { Official.Title.minLineHeight }
    }

    /// iOS 26 备忘录正文阅读进度条（系统滚动条风格，仅滑块、不可拖拽）
    enum ReadingProgress {
        static let thumbWidth: CGFloat = 3
        static let thumbMinHeight: CGFloat = 48
        static let thumbMaxHeight: CGFloat = 72
        static let trailingInset: CGFloat = 2.5
        static let verticalInset: CGFloat = 8
        static let autoHideDelay: TimeInterval = 1.2
        static let revealFadeDuration: TimeInterval = 0.2
        static let hideFadeDuration: TimeInterval = 0.35
        static let thumbColor = Color.primary.opacity(0.36)

        /// 与系统滚动条一致：滑块长度随可见比例缩短，并限制在 min/max 之间
        static func thumbHeight(
            trackHeight: CGFloat,
            viewportHeight: CGFloat,
            contentHeight: CGFloat
        ) -> CGFloat {
            guard contentHeight > viewportHeight, viewportHeight > 0, trackHeight > 0 else {
                return thumbMaxHeight
            }
            let visibleRatio = viewportHeight / contentHeight
            let proportional = trackHeight * visibleRatio
            return min(max(proportional, thumbMinHeight), thumbMaxHeight)
        }
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
    static var label: Color { Color(uiColor: labelUI) }
    static var labelUI: UIColor {
        blendedLabelUI(
            labelMix: NotesDesignTokens.Official.PrimaryText.labelBlendFraction,
            secondaryMix: NotesDesignTokens.Official.PrimaryText.secondaryBlendFraction,
            tertiaryMix: NotesDesignTokens.Official.PrimaryText.tertiaryBlendFraction,
            quaternaryMix: NotesDesignTokens.Official.PrimaryText.quaternaryBlendFraction
        )
    }
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

    static func blendedLabelUI(
        labelMix: CGFloat,
        secondaryMix: CGFloat,
        tertiaryMix: CGFloat,
        quaternaryMix: CGFloat
    ) -> UIColor {
        UIColor { traits in
            let label = UIColor.label.resolvedColor(with: traits)
            let secondary = UIColor.secondaryLabel.resolvedColor(with: traits)
            let tertiary = UIColor.tertiaryLabel.resolvedColor(with: traits)
            let quaternary = UIColor.quaternaryLabel.resolvedColor(with: traits)
            func components(of color: UIColor) -> (CGFloat, CGFloat, CGFloat, CGFloat) {
                var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
                color.getRed(&r, green: &g, blue: &b, alpha: &a)
                return (r, g, b, a)
            }
            let (lr, lg, lb, la) = components(of: label)
            let (sr, sg, sb, _) = components(of: secondary)
            let (tr, tg, tb, _) = components(of: tertiary)
            let (qr, qg, qb, _) = components(of: quaternary)
            return UIColor(
                red: lr * labelMix + sr * secondaryMix + tr * tertiaryMix + qr * quaternaryMix,
                green: lg * labelMix + sg * secondaryMix + tg * tertiaryMix + qg * quaternaryMix,
                blue: lb * labelMix + sb * secondaryMix + tb * tertiaryMix + qb * quaternaryMix,
                alpha: la
            )
        }
    }
}

/// 备忘录自动识别号码/数据链接色（真机金黄下划线；非 UIColor.link 默认蓝）
enum NotesDetectedLinkColor {
    /// #EAB109 · RGB 234, 177, 9
    static let uiColor = UIColor(red: 234 / 255, green: 177 / 255, blue: 9 / 255, alpha: 1)
    static let color = Color(uiColor: uiColor)
}
