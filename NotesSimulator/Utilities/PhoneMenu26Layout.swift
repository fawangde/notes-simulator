import CoreGraphics
import UIKit

/// iOS 26 号码长按菜单：菜单安全区夹紧 + 预览泡位移选向（不改面板尺寸与动画语义）
enum PhoneMenu26Layout {
    enum Style {
        /// 菜单在号码下方，预览泡原位放大
        case top
        /// 菜单在号码上方，预览泡原位
        case bottom
        /// 菜单在号码上方，预览泡下跳至菜单下方
        case middle
    }

    enum Design {
        /// 菜单顶缘：状态栏 safe area 下缘再下移（顶栏按键顶缘附近）
        static let menuBoundsTopBelowSafeArea: CGFloat = 20
        /// 菜单底缘：底栏按键底缘再上移
        static let menuBoundsBottomRaise: CGFloat = 20
    }

    struct VerticalPlacement {
        let style: Style
        let menuOriginY: CGFloat
        let bubbleY: CGFloat
    }

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

    static func menuToolbarBounds(
        screenHeight: CGFloat,
        safeTop: CGFloat,
        safeBottom: CGFloat
    ) -> (menuTopMin: CGFloat, menuBottomMax: CGFloat) {
        let bottomGap = NotesDesignTokens.Official.Toolbar.bottomSafeGap
        let menuTopMin = safeTop + Design.menuBoundsTopBelowSafeArea
        let bottomButtonBottom = screenHeight - safeBottom - bottomGap
        let menuBottomMax = bottomButtonBottom - Design.menuBoundsBottomRaise
        return (menuTopMin, menuBottomMax)
    }

    /// 先夹紧菜单，预览泡随动；在「预览在上 / 预览下跳」间选位移更小者
    static func verticalPlacement(
        anchor: CGRect,
        screenHeight: CGFloat,
        safeTop: CGFloat,
        safeBottom: CGFloat,
        menuHeight: CGFloat,
        gap: CGFloat,
        bubbleHeight: CGFloat
    ) -> VerticalPlacement {
        let bounds = menuToolbarBounds(
            screenHeight: screenHeight,
            safeTop: safeTop,
            safeBottom: safeBottom
        )
        let menuTopMin = bounds.menuTopMin
        let menuTopMax = bounds.menuBottomMax - menuHeight
        let baseBubbleY = anchor.maxY - bubbleHeight

        func clampMenuTop(_ ideal: CGFloat) -> CGFloat {
            if menuTopMax < menuTopMin {
                return menuTopMin
            }
            return min(max(ideal, menuTopMin), menuTopMax)
        }

        let topMenuY = clampMenuTop(anchor.maxY + gap)
        let topBubbleY = topMenuY - gap - bubbleHeight
        let topShift = abs(topBubbleY - baseBubbleY)

        let aboveMenuY = clampMenuTop(anchor.minY - gap - menuHeight)
        let jumpedBubbleY = aboveMenuY + menuHeight + gap
        let aboveShift = abs(jumpedBubbleY - baseBubbleY)

        if topShift <= aboveShift {
            return VerticalPlacement(
                style: .top,
                menuOriginY: topMenuY,
                bubbleY: topBubbleY
            )
        }

        let style: Style = abs(jumpedBubbleY - baseBubbleY) < 1 ? .bottom : .middle
        return VerticalPlacement(
            style: style,
            menuOriginY: aboveMenuY,
            bubbleY: style == .bottom ? baseBubbleY : jumpedBubbleY
        )
    }
}
