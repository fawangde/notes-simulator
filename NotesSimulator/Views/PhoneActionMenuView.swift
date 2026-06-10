import SwiftUI
import UIKit

/// 偏上：菜单在号码下方，号码原位放大；偏下：菜单在号码上方；中间：号码下跳至弹窗下方
private enum PhoneMenuLayout { case top, middle, bottom }

private struct PhoneMenuLayoutMetrics {
    let layout: PhoneMenuLayout
    let menuOriginY: CGFloat
    let menuLeading: CGFloat
    let bubbleX: CGFloat
    let bubbleY: CGFloat
}

struct PhoneActionMenuView: View {

    let phone: String
    let anchor: CGRect
    let onMessage: () -> Void
    let onCopy: () -> Void
    let onDismiss: () -> Void

    @State private var bubbleScale: CGFloat = 0.91
    @State private var bubbleOpacity: Double = 0
    @State private var bubbleLiftY: CGFloat = 0
    @State private var bubbleDisplayY: CGFloat = 0
    @State private var overlayOpacity: Double = 0
    @State private var menuScale: CGFloat = 0.84
    @State private var menuOffsetY: CGFloat = 14
    @State private var menuOpacity: Double = 0
    @State private var activeLayout: PhoneMenuLayout = .top

    private var bubbleDigitWidth: CGFloat {
        NotesDesignTokens.oneDigitWidth(for: NotesDesignTokens.PreviewBubble.fontSize)
    }

    private var bubbleLeftExtend: CGFloat {
        bubbleDigitWidth * PhoneUtilities.previewBubbleLeftExtendDigits
    }

    private var bubbleShiftRight: CGFloat {
        bubbleDigitWidth * PhoneUtilities.previewBubbleShiftRightDigits
    }

    private var bubbleNumberShiftLeft: CGFloat {
        bubbleDigitWidth * PhoneUtilities.previewBubbleNumberShiftLeftDigits
    }

    private var bubbleRightExtend: CGFloat {
        bubbleDigitWidth * PhoneUtilities.previewBubbleRightExtendDigits - bubbleNumberShiftLeft
    }

    /// 菜单行图标相对顶部号码左缘再右移 1 个字宽
    private var menuIconLeadingExtra: CGFloat {
        NotesDesignTokens.oneDigitWidth(for: NotesDesignTokens.MenuLayout.headerFontSize)
    }

    private var bubblePhoneUIFont: UIFont {
        UIFont.systemFont(ofSize: NotesDesignTokens.PreviewBubble.fontSize, weight: .regular)
    }

    private var bubblePhoneTextWidth: CGFloat {
        (phone as NSString).size(withAttributes: [.font: bubblePhoneUIFont]).width
    }

    private var bubbleWidth: CGFloat {
        guard anchor != .zero else { return 0 }
        return bubbleLeftExtend + bubblePhoneTextWidth + bubbleRightExtend
    }

    var body: some View {
        GeometryReader { geo in
            let metrics = layoutMetrics(in: geo.size, safeTop: geo.safeAreaInsets.top)

            let dimAmount = NotesDesignTokens.PhoneMenu.overlayDim

            ZStack(alignment: .topLeading) {
                Color.black
                    .opacity(overlayOpacity * dimAmount)
                    .ignoresSafeArea()
                    .animation(.easeOut(duration: 0.18), value: dimAmount)
                    .onTapGesture { dismissAll() }

                if anchor != .zero {
                    previewBubble
                        .scaleEffect(bubbleScale, anchor: scaleAnchor(for: metrics.layout))
                        .offset(x: metrics.bubbleX, y: bubbleDisplayY + bubbleLiftY)
                        .opacity(bubbleOpacity)
                }

                menuCard
                    .frame(width: NotesDesignTokens.MenuLayout.width, height: NotesDesignTokens.MenuLayout.height)
                    .scaleEffect(menuScale, anchor: menuScaleAnchor(for: metrics.layout))
                    .offset(x: metrics.menuLeading, y: metrics.menuOriginY + menuOffsetY)
                    .opacity(menuOpacity)
            }
            .onAppear { runShowAnimation(metrics: metrics) }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func scaleAnchor(for layout: PhoneMenuLayout) -> UnitPoint {
        switch layout {
        case .top: return UnitPoint(x: 0, y: 1)
        case .bottom, .middle: return UnitPoint(x: 0, y: 0)
        }
    }

    private func menuScaleAnchor(for layout: PhoneMenuLayout) -> UnitPoint {
        switch layout {
        case .top: return UnitPoint(x: 0.5, y: 0)
        case .bottom, .middle: return UnitPoint(x: 0.5, y: 1)
        }
    }

    private func layoutMetrics(in screen: CGSize, safeTop: CGFloat) -> PhoneMenuLayoutMetrics {
        let menuH = NotesDesignTokens.MenuLayout.height
        let gap = NotesDesignTokens.MenuLayout.gap
        let bottomDist = screen.height - anchor.maxY
        let topDist = anchor.minY - safeTop
        let bubbleH = NotesDesignTokens.PreviewBubble.height
        let anchorBubbleY = anchor.maxY - bubbleH

        let bubbleX = anchor.minX - bubbleLeftExtend + bubbleShiftRight + NotesDesignTokens.PreviewBubble.phoneBubbleExtraShiftX
        /// 菜单左边框与预览泡左边框对齐（整体右移 2 字宽）
        let leading = min(bubbleX, screen.width - NotesDesignTokens.MenuLayout.width - 8)

        if bottomDist < NotesDesignTokens.PhoneMenu.bottomSafeThreshold {
            let menuY = max(anchor.minY - gap - menuH, safeTop + 8)
            return PhoneMenuLayoutMetrics(
                layout: .bottom,
                menuOriginY: menuY,
                menuLeading: leading,
                bubbleX: bubbleX,
                bubbleY: anchorBubbleY
            )
        }

        if topDist < NotesDesignTokens.PhoneMenu.topSafeThreshold {
            return PhoneMenuLayoutMetrics(
                layout: .top,
                menuOriginY: anchor.maxY + gap,
                menuLeading: leading,
                bubbleX: bubbleX,
                bubbleY: anchorBubbleY
            )
        }

        let menuY = max(safeTop + 8, anchor.minY - gap - menuH)
        let jumpedBubbleY = menuY + menuH + gap
        return PhoneMenuLayoutMetrics(
            layout: .middle,
            menuOriginY: menuY,
            menuLeading: leading,
            bubbleX: bubbleX,
            bubbleY: jumpedBubbleY
        )
    }

    private var previewBubble: some View {
        HStack(spacing: 0) {
            Color.clear.frame(width: bubbleLeftExtend)
            Text(phone)
                .font(Font(bubblePhoneUIFont))
                .foregroundStyle(NotesDesignTokens.PhoneLink.color)
                .underline(true, color: NotesDesignTokens.PhoneLink.color)
                .lineLimit(1)
                .fixedSize()
                .offset(x: -bubbleNumberShiftLeft)
            Color.clear.frame(width: bubbleRightExtend)
        }
        .frame(width: bubbleWidth, height: NotesDesignTokens.PreviewBubble.height, alignment: .center)
        .background {
            PreviewBubbleGlassBackground(
                cornerRadius: NotesDesignTokens.PreviewBubble.cornerRadius,
                tint: NotesDesignTokens.PreviewBubble.bgColor,
                border: NotesDesignTokens.PreviewBubble.borderColor
            )
        }
        .allowsHitTesting(false)
    }

    private var menuCard: some View {
        VStack(spacing: 0) {
            Text(phone)
                .font(.system(size: NotesDesignTokens.MenuLayout.headerFontSize, weight: .semibold))
                .foregroundStyle(IOSTheme.labelPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, NotesDesignTokens.MenuLayout.contentInsetH + menuIconLeadingExtra)
                .padding(.trailing, NotesDesignTokens.MenuLayout.contentInsetH)
                .frame(height: NotesDesignTokens.MenuLayout.headerHeight)

            menuContentDivider

            MenuActionRow(
                icon: "phone", title: "呼叫", subtitle: "电话 (副号)",
                rowHeight: NotesDesignTokens.MenuLayout.rowHeight, contentInsetH: NotesDesignTokens.MenuLayout.contentInsetH,
                iconLeadingExtra: menuIconLeadingExtra,
                titleFontSize: NotesDesignTokens.MenuLayout.rowTitleFontSize, subtitleFontSize: NotesDesignTokens.MenuLayout.rowSubtitleFontSize,
                iconSize: NotesDesignTokens.MenuLayout.iconSize, chevronSize: NotesDesignTokens.MenuLayout.chevronSize,
                action: onDismiss
            )
            MenuActionRow(
                icon: "video", title: "视频", subtitle: "微信",
                rowHeight: NotesDesignTokens.MenuLayout.rowHeight, contentInsetH: NotesDesignTokens.MenuLayout.contentInsetH,
                iconLeadingExtra: menuIconLeadingExtra,
                titleFontSize: NotesDesignTokens.MenuLayout.rowTitleFontSize, subtitleFontSize: NotesDesignTokens.MenuLayout.rowSubtitleFontSize,
                iconSize: NotesDesignTokens.MenuLayout.iconSize, chevronSize: NotesDesignTokens.MenuLayout.chevronSize,
                action: onDismiss
            )
            MenuActionRow(
                icon: "message", title: "信息", subtitle: "信息",
                rowHeight: NotesDesignTokens.MenuLayout.rowHeight, contentInsetH: NotesDesignTokens.MenuLayout.contentInsetH,
                iconLeadingExtra: menuIconLeadingExtra,
                titleFontSize: NotesDesignTokens.MenuLayout.rowTitleFontSize, subtitleFontSize: NotesDesignTokens.MenuLayout.rowSubtitleFontSize,
                iconSize: NotesDesignTokens.MenuLayout.iconSize, chevronSize: NotesDesignTokens.MenuLayout.chevronSize,
                action: onMessage
            )

            groupDivider

            MenuActionRow(
                icon: "phone", title: "呼叫", showsChevron: true,
                rowHeight: NotesDesignTokens.MenuLayout.rowHeight, contentInsetH: NotesDesignTokens.MenuLayout.contentInsetH,
                iconLeadingExtra: menuIconLeadingExtra,
                titleFontSize: NotesDesignTokens.MenuLayout.rowTitleFontSize, subtitleFontSize: NotesDesignTokens.MenuLayout.rowSubtitleFontSize,
                iconSize: NotesDesignTokens.MenuLayout.iconSize, chevronSize: NotesDesignTokens.MenuLayout.chevronSize,
                action: onDismiss
            )
            MenuActionRow(
                icon: "video", title: "视频", showsChevron: true,
                rowHeight: NotesDesignTokens.MenuLayout.rowHeight, contentInsetH: NotesDesignTokens.MenuLayout.contentInsetH,
                iconLeadingExtra: menuIconLeadingExtra,
                titleFontSize: NotesDesignTokens.MenuLayout.rowTitleFontSize, subtitleFontSize: NotesDesignTokens.MenuLayout.rowSubtitleFontSize,
                iconSize: NotesDesignTokens.MenuLayout.iconSize, chevronSize: NotesDesignTokens.MenuLayout.chevronSize,
                action: onDismiss
            )

            groupDivider

            MenuActionRow(
                icon: "person.crop.circle.badge.plus", title: "添加到通讯录",
                rowHeight: NotesDesignTokens.MenuLayout.rowHeight, contentInsetH: NotesDesignTokens.MenuLayout.contentInsetH,
                iconLeadingExtra: menuIconLeadingExtra,
                titleFontSize: NotesDesignTokens.MenuLayout.rowTitleFontSize, subtitleFontSize: NotesDesignTokens.MenuLayout.rowSubtitleFontSize,
                iconSize: NotesDesignTokens.MenuLayout.iconSize, chevronSize: NotesDesignTokens.MenuLayout.chevronSize,
                action: onDismiss
            )

            groupDivider

            MenuActionRow(
                icon: "doc.on.doc", title: "拷贝",
                rowHeight: NotesDesignTokens.MenuLayout.rowHeight, contentInsetH: NotesDesignTokens.MenuLayout.contentInsetH,
                iconLeadingExtra: menuIconLeadingExtra,
                titleFontSize: NotesDesignTokens.MenuLayout.rowTitleFontSize, subtitleFontSize: NotesDesignTokens.MenuLayout.rowSubtitleFontSize,
                iconSize: NotesDesignTokens.MenuLayout.iconSize, chevronSize: NotesDesignTokens.MenuLayout.chevronSize,
                action: onCopy
            )
            MenuActionRow(
                icon: "pencil", title: "编辑链接",
                rowHeight: NotesDesignTokens.MenuLayout.rowHeight, contentInsetH: NotesDesignTokens.MenuLayout.contentInsetH,
                iconLeadingExtra: menuIconLeadingExtra,
                titleFontSize: NotesDesignTokens.MenuLayout.rowTitleFontSize, subtitleFontSize: NotesDesignTokens.MenuLayout.rowSubtitleFontSize,
                iconSize: NotesDesignTokens.MenuLayout.iconSize, chevronSize: NotesDesignTokens.MenuLayout.chevronSize,
                action: onDismiss
            )
        }
        .background {
            MenuPanelGlassBackground(
                cornerRadius: NotesDesignTokens.MenuLayout.cornerRadius,
                tint: NotesDesignTokens.MenuGlass.tintColor,
                border: NotesDesignTokens.MenuGlass.borderColor,
                blur: NotesDesignTokens.MenuGlass.blur,
                translucency: NotesDesignTokens.MenuGlass.translucency,
                refractionTop: NotesDesignTokens.MenuGlass.refractionTop,
                refractionMid: NotesDesignTokens.MenuGlass.refractionMid,
                specularStrength: NotesDesignTokens.MenuGlass.specularStrength,
                innerShadow: NotesDesignTokens.MenuGlass.innerShadow
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: NotesDesignTokens.MenuLayout.cornerRadius, style: .continuous))
    }

    private var menuContentDivider: some View {
        Rectangle()
            .fill(NotesSemanticColor.separator)
            .frame(height: 1 / UIScreen.main.scale)
            .padding(.leading, NotesDesignTokens.MenuLayout.contentInsetH)
            .padding(.trailing, NotesDesignTokens.MenuLayout.contentInsetH)
    }

    private var groupDivider: some View {
        menuContentDivider
    }

    private func runShowAnimation(metrics: PhoneMenuLayoutMetrics) {
        let anchorBubbleY = anchor.maxY - NotesDesignTokens.PreviewBubble.height
        activeLayout = metrics.layout

        bubbleScale = 0.91
        bubbleOpacity = 0
        bubbleLiftY = metrics.layout == .top ? 6 : -6
        bubbleDisplayY = metrics.layout == .middle ? anchorBubbleY : metrics.bubbleY
        overlayOpacity = 0
        menuScale = 0.84
        menuOffsetY = metrics.layout == .top ? 14 : -14
        menuOpacity = 0

        withAnimation(.spring(
            response: NotesDesignTokens.Spring.peek.response,
            dampingFraction: NotesDesignTokens.Spring.peek.damping
        )) {
            bubbleScale = 1.04
            bubbleOpacity = 1
            bubbleLiftY = 0
            overlayOpacity = 1
            if metrics.layout == .middle {
                bubbleDisplayY = metrics.bubbleY
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.13) {
            withAnimation(.spring(response: 0.14, dampingFraction: 0.72)) {
                bubbleScale = 1.0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + NotesDesignTokens.PreviewBubble.menuDelay) {
            withAnimation(.spring(
                response: NotesDesignTokens.Spring.menuShow.response,
                dampingFraction: NotesDesignTokens.Spring.menuShow.damping
            )) {
                menuScale = 1.0
                menuOffsetY = 0
                menuOpacity = 1
            }
        }
    }

    private func dismissAll() {
        if activeLayout == .middle {
            let anchorBubbleY = anchor.maxY - NotesDesignTokens.PreviewBubble.height
            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                bubbleDisplayY = anchorBubbleY
            }
        }

        withAnimation(.spring(
            response: NotesDesignTokens.Spring.menuHide.response,
            dampingFraction: NotesDesignTokens.Spring.menuHide.damping
        )) {
            menuScale = 0.87
            menuOpacity = 0
            menuOffsetY = 7
            bubbleScale = 0.92
            bubbleOpacity = 0
            overlayOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.23) {
            onDismiss()
        }
    }
}

private struct MenuActionRow: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    var showsChevron: Bool = false
    var rowHeight: CGFloat
    var contentInsetH: CGFloat
    var iconLeadingExtra: CGFloat = 0
    var titleFontSize: CGFloat
    var subtitleFontSize: CGFloat
    var iconSize: CGFloat
    var chevronSize: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: NotesDesignTokens.PhoneMenu.iconGap) {
                Image(systemName: icon)
                    .font(.system(size: iconSize, weight: .light))
                    .foregroundStyle(IOSTheme.menuIcon)
                    .frame(width: iconSize + 3, height: iconSize + 3)

                if let subtitle {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.system(size: titleFontSize, weight: .regular))
                            .foregroundStyle(IOSTheme.labelPrimary)
                        Text(subtitle)
                            .font(.system(size: subtitleFontSize, weight: .light))
                            .foregroundStyle(IOSTheme.labelSecondary)
                    }
                } else {
                    Text(title)
                        .font(.system(size: titleFontSize, weight: .regular))
                        .foregroundStyle(IOSTheme.labelPrimary)
                }

                Spacer(minLength: 0)

                if showsChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: chevronSize, weight: .semibold))
                        .foregroundStyle(IOSTheme.labelPrimary.opacity(0.72))
                        .padding(.trailing, 4)
                }
            }
            .padding(.leading, contentInsetH + iconLeadingExtra)
            .padding(.trailing, contentInsetH)
            .frame(height: rowHeight)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(MenuRowPressStyle())
    }
}

private struct MenuRowPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? NotesSemanticColor.quaternaryFill : Color.clear)
    }
}
