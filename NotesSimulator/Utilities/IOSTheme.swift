import SwiftUI
import UIKit

enum IOSTheme {
    static var noteTheme: NotesDesignTokens.Theme = .white

    /// 页面底色：systemBackground 略压暗 3%
    private static let notesPaperDimFactor: CGFloat = 0.97

    static var notesPaper: Color {
        Color(uiColor: notesPaperUI)
    }

    static var notesPaperUI: UIColor {
        UIColor { traits in
            let base = UIColor.systemBackground.resolvedColor(with: traits)
            var red: CGFloat = 0
            var green: CGFloat = 0
            var blue: CGFloat = 0
            var alpha: CGFloat = 0
            guard base.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
                return base
            }
            return UIColor(
                red: red * notesPaperDimFactor,
                green: green * notesPaperDimFactor,
                blue: blue * notesPaperDimFactor,
                alpha: alpha
            )
        }
    }

    static var labelPrimary: Color { NotesSemanticColor.label }
    static var labelPrimaryUI: UIColor { NotesSemanticColor.labelUI }
    static var titleLabel: Color { Color(uiColor: titleLabelUI) }
    static var titleLabelUI: UIColor {
        NotesSemanticColor.blendedLabelUI(
            labelMix: NotesDesignTokens.Official.Title.labelBlendFraction,
            secondaryMix: NotesDesignTokens.Official.Title.secondaryBlendFraction,
            tertiaryMix: NotesDesignTokens.Official.Title.tertiaryBlendFraction,
            quaternaryMix: NotesDesignTokens.Official.Title.quaternaryBlendFraction
        )
    }
    static var labelSecondary: Color { NotesSemanticColor.secondaryLabel }
    static var labelTertiary: Color { NotesSemanticColor.tertiaryLabel }

    /// 号码链接：备忘录检测数据金黄（UIColor.link 在备忘录外常为蓝）
    static var phoneLink: Color { NotesDetectedLinkColor.color }
    static var phoneLinkUI: UIColor { NotesDetectedLinkColor.uiColor }
    static var phonePreviewText: Color { NotesDetectedLinkColor.color }

    static var navIcon: Color { NotesSemanticColor.label }
    static var toolbarIcon: Color { NotesSemanticColor.label }
    static var menuIcon: Color { NotesSemanticColor.label }
    static var menuDivider: Color { NotesSemanticColor.separator }

    static let titleFont = NotesDesignTokens.Layout.titleFont

    private static let bodyMetrics = UIFontMetrics(forTextStyle: .body)

    private static var bodyBaseFont: UIFont {
        UIFont.systemFont(
            ofSize: NotesDesignTokens.Official.Body.fontSize,
            weight: NotesDesignTokens.Official.Body.weight
        )
    }

    /// 正文 / 号码：基准 19pt，随系统「显示与亮度 → 文字大小」缩放
    static func bodyUIFont(compatibleWith traitCollection: UITraitCollection) -> UIFont {
        bodyMetrics.scaledFont(for: bodyBaseFont, compatibleWith: traitCollection)
    }

    static func scaledUIFont(
        baseSize: CGFloat,
        weight: UIFont.Weight = .regular,
        compatibleWith traitCollection: UITraitCollection
    ) -> UIFont {
        let base = UIFont.systemFont(ofSize: baseSize, weight: weight)
        return bodyMetrics.scaledFont(for: base, compatibleWith: traitCollection)
    }

    /// 号码字号可单独调节，仍随系统文字大小缩放
    static func phoneUIFont(
        baseSize: CGFloat,
        compatibleWith traitCollection: UITraitCollection
    ) -> UIFont {
        scaledUIFont(baseSize: baseSize, compatibleWith: traitCollection)
    }

    /// 单行号码段落高度
    static func phoneLineParagraphStyle(for font: UIFont) -> NSParagraphStyle {
        let scale = font.pointSize / NotesDesignTokens.Official.Body.fontSize
        let rowHeight = NotesDesignTokens.Official.Body.phoneListRowHeight * scale
        let style = NSMutableParagraphStyle()
        style.minimumLineHeight = rowHeight
        style.maximumLineHeight = rowHeight
        style.lineBreakMode = .byWordWrapping
        return style.copy() as! NSParagraphStyle
    }

    static func bodyParagraphStyle(for font: UIFont) -> NSParagraphStyle {
        phoneLineParagraphStyle(for: font)
    }

    static let imessageBG = Color(uiColor: .systemGroupedBackground)
    static let keyboardBG = Color(uiColor: .systemGray4)
    static let bubbleBlue = Color(uiColor: .systemBlue)
}
