import SwiftUI
import UIKit

/// iOS 18 备忘录外观（reference 目测 + 用户定稿参数）
enum NotesStyle18Tokens {
    static var iconColor: Color { NotesDetectedLinkColor.color }

    static let navBackTitle = "备忘录"
    static let navBackIcon = "chevron.left"
    static let navTrailingIcons = [
        "square.and.arrow.up",
        "ellipsis.circle",
    ]

    static let toolbarChecklistIcon = "checklist"
    static let toolbarCameraIcon = "paperclip"
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
    /// 18 一体板：顶栏相对 safeTop 再下移
    static let unifiedNavExtraDownShift: CGFloat = 4
    /// 18 一体板：底栏相对 classic 再上移
    static let unifiedToolbarUpShift: CGFloat = 4
    /// 18 一体板：底栏整块底板再下移
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
        /// iOS 18 菜单：标题 / 右侧图标 / chevron（比 tuning 灰化后的 label 更黑）
        static var menuEmphasisUIColor: UIColor {
            UIColor { traits in
                traits.userInterfaceStyle == .dark ? UIColor.label : UIColor.black
            }
        }
        static var menuEmphasisColor: Color { Color(uiColor: menuEmphasisUIColor) }
        /// 操作菜单底板：略透明，可隐约透出底下金黄号码
        static let menuPanelBackgroundOpacity: CGFloat = 0.88
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

/// iOS 18 号码菜单：参考真机截图（双行副标题 + chevron 展开项 + 9 行操作）
enum PhoneMenu18Layout {
    enum Design {
        static let menuActionRowCount = 9
        static let menuWidthReduction: CGFloat = 20
        static let twoLineRowHeight: CGFloat = 62
        static let singleLineRowHeight: CGFloat = 44
        static let menuTitleFontSize: CGFloat = 17
        static let menuSubtitleFontSize: CGFloat = 14
        /// 8pt 分组带内灰色线透明度
        static let sectionSeparatorOpacity: CGFloat = 0.66
        /// 标题 / 副标题 / chevron 相对菜单左内边距再右移
        static let textContentLeadingExtra: CGFloat = 10
        /// chevron 行：符号在标题左缘外，不挤占标题列对齐
        static let chevronLeadingOffset: CGFloat = 16
        /// 分组灰色分割线（信息|›呼叫、›视频|添加到通讯录）：8pt 高，独立于行高之外
        static let sectionSeparatorHeight: CGFloat = 8
        static let sectionSeparatorCount = 2
        /// 菜单顶缘：状态栏 safe area 下缘再下移（顶栏可点按键顶缘，非导航底板）
        static let menuBoundsTopBelowSafeArea: CGFloat = 20
        /// 菜单底缘：底栏按键底缘再上移
        static let menuBoundsBottomRaise: CGFloat = 20

        static var menuHeight: CGFloat {
            let divider = PhoneMenu1718Layout.Design.menuDividerHeight
            let hairlineDividers = CGFloat(menuActionRowCount - 1 - sectionSeparatorCount)
            return 3 * twoLineRowHeight
                + 6 * singleLineRowHeight
                + hairlineDividers * divider
                + CGFloat(sectionSeparatorCount) * sectionSeparatorHeight
        }
    }

    static func metrics(
        in screen: CGSize,
        safeTop: CGFloat,
        safeBottom: CGFloat,
        tuning: Notes1718TuningSettings = .default
    ) -> PhoneMenu1718Layout.Metrics {
        let base = PhoneMenu1718Layout.metrics(
            in: screen,
            safeTop: safeTop,
            safeBottom: safeBottom,
            tuning: tuning
        )
        return PhoneMenu1718Layout.Metrics(
            leftMargin: base.leftMargin,
            previewSize: base.previewSize,
            menuSize: CGSize(
                width: max(base.menuSize.width - Design.menuWidthReduction, 220),
                height: Design.menuHeight
            ),
            previewMenuGap: base.previewMenuGap,
            numberToPreviewGap: base.numberToPreviewGap,
            tapMenuGap: base.tapMenuGap,
            menuRowHighlightCornerRadius: base.menuRowHighlightCornerRadius,
            minContentTop: base.minContentTop,
            maxContentBottom: base.maxContentBottom,
            previewCornerRadius: base.previewCornerRadius,
            menuCornerRadius: base.menuCornerRadius,
            avatarSize: base.avatarSize,
            avatarSpacing: base.avatarSpacing,
            previewPadH: base.previewPadH,
            previewContentShiftLeft: base.previewContentShiftLeft,
            previewContentScale: base.previewContentScale,
            previewSideMarginExtra: base.previewSideMarginExtra,
            previewFontSize: base.previewFontSize,
            menuContentInsetH: base.menuContentInsetH,
            menuIconSize: base.menuIconSize,
            menuTitleSize: base.menuTitleSize,
            menuSubtitleSize: base.menuSubtitleSize,
            menuHeaderPhoneFontSize: base.menuHeaderPhoneFontSize,
            rowHeight: base.rowHeight,
            headerHeight: base.headerHeight,
            dividerHeight: base.dividerHeight,
            previewShadowOpacity: base.previewShadowOpacity,
            previewShadowRadius: base.previewShadowRadius,
            previewShadowY: base.previewShadowY,
            menuShadowOpacity: base.menuShadowOpacity,
            menuShadowRadius: base.menuShadowRadius,
            menuShadowY: base.menuShadowY
        )
    }

    /// ignoresSafeArea 覆盖层内 geo.safeAreaInsets 常为 0，回退 keyWindow
    static func resolvedSafeInsets(
        fallbackTop: CGFloat,
        fallbackBottom: CGFloat
    ) -> (top: CGFloat, bottom: CGFloat) {
        let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }
        let windowTop = window?.safeAreaInsets.top ?? 0
        let windowBottom = window?.safeAreaInsets.bottom ?? 0
        return (max(fallbackTop, windowTop), max(fallbackBottom, windowBottom))
    }

    /// 菜单栏可占用垂直范围：顶缘 = 状态栏下约 20pt；底缘 = 底栏按键底缘再上移 20pt
    static func menuToolbarBounds(
        screenHeight: CGFloat,
        safeTop: CGFloat,
        safeBottom: CGFloat
    ) -> (menuTopMin: CGFloat, menuBottomMax: CGFloat) {
        let barH = NotesDesignTokens.Layout.bottomToolbarHeight
        let chromeAbove = NotesStyle18Tokens.chromeAboveToolbar
        let toolbarButton = NotesDesignTokens.Official.Toolbar.buttonSize
        let iconBandHeight = chromeAbove + barH

        let menuTopMin = safeTop + Design.menuBoundsTopBelowSafeArea
        let bottomButtonBottom = screenHeight - safeBottom - iconBandHeight / 2 + toolbarButton / 2
        let menuBottomMax = bottomButtonBottom - Design.menuBoundsBottomRaise
        return (menuTopMin, menuBottomMax)
    }

    private struct PlacementCandidate {
        let bubbleTop: CGFloat
        let menuTop: CGFloat
        let menuGrowUp: Bool
        let shift: CGFloat
    }

    /// 菜单先夹入安全区，预览泡随动；在安全区内选预览泡垂直位移更小的一侧
    static func placement(
        anchor: CGRect,
        metrics: PhoneMenu1718Layout.Metrics,
        screenHeight: CGFloat,
        safeTop: CGFloat,
        safeBottom: CGFloat
    ) -> PhoneMenu1718Layout.Placement {
        let previewW = metrics.previewSize.width
        let previewH = metrics.previewSize.height
        let menuW = metrics.menuSize.width
        let menuH = metrics.menuSize.height
        let gap = metrics.previewMenuGap
        let previewLeft = metrics.leftMargin + metrics.previewSideMarginExtra
        let menuLeft = previewLeft

        let bounds = menuToolbarBounds(
            screenHeight: screenHeight,
            safeTop: safeTop,
            safeBottom: safeBottom
        )
        let menuTopMin = bounds.menuTopMin
        let menuBottomMax = bounds.menuBottomMax
        let menuTopMax = menuBottomMax - menuH

        let baseBubbleTop = anchor.midY - previewH / 2

        func clampMenuTop(_ ideal: CGFloat) -> CGFloat {
            if menuTopMax < menuTopMin {
                return menuTopMin
            }
            return min(max(ideal, menuTopMin), menuTopMax)
        }

        func candidatePreviewAboveMenu() -> PlacementCandidate {
            let menuTop = clampMenuTop(baseBubbleTop + previewH + gap)
            let bubbleTop = menuTop - previewH - gap

            return PlacementCandidate(
                bubbleTop: bubbleTop,
                menuTop: menuTop,
                menuGrowUp: false,
                shift: abs(bubbleTop - baseBubbleTop)
            )
        }

        func candidatePreviewBelowMenu() -> PlacementCandidate {
            let menuTop = clampMenuTop(baseBubbleTop - gap - menuH)
            let bubbleTop = menuTop + menuH + gap

            return PlacementCandidate(
                bubbleTop: bubbleTop,
                menuTop: menuTop,
                menuGrowUp: true,
                shift: abs(bubbleTop - baseBubbleTop)
            )
        }

        let previewAbove = candidatePreviewAboveMenu()
        let previewBelow = candidatePreviewBelowMenu()
        let chosen = previewAbove.shift <= previewBelow.shift ? previewAbove : previewBelow

        let textStart = previewLeft + metrics.previewPadH - metrics.previewContentShiftLeft
            + metrics.avatarSize + metrics.avatarSpacing
        let phoneLeadingSpacer = max(0, anchor.minX - textStart)

        return PhoneMenu1718Layout.Placement(
            previewFrame: CGRect(
                x: previewLeft,
                y: chosen.bubbleTop,
                width: previewW,
                height: previewH
            ),
            menuFrame: CGRect(x: menuLeft, y: chosen.menuTop, width: menuW, height: menuH),
            menuGrowUp: chosen.menuGrowUp,
            phoneLeadingSpacer: phoneLeadingSpacer
        )
    }
}
