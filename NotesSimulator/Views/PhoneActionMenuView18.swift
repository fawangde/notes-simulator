import SwiftUI

/// iOS 18 号码长按 / 点击菜单（参考真机截图：预览泡 + 分组操作菜单）
struct PhoneActionMenuView18: View {
    let phone: String
    let windowAnchor: CGRect
    let presentation: PhoneMenuPresentation
    let tuning: Notes18TuningSettings
    let onMessage: () -> Void
    let onCopy: () -> Void
    let onDismiss: () -> Void

    @EnvironmentObject private var app: AppState

    private struct MenuRowAnimState {
        var opacity: Double = 0
        var offsetY: CGFloat = PhoneMenu1718Layout.Animation.menuRowEnterOffsetY
    }

    @State private var isDismissing = false
    @State private var didCompleteDismiss = false

    @State private var bubbleLeft: CGFloat = 0
    @State private var bubbleTop: CGFloat = 0

    /// 号码+小白底同步缩放：1.0 正文 → 1.2 为小白底 100%
    @State private var morphUnitScale: CGFloat = 1
    @State private var basePillShellScale: CGFloat = 0.15
    @State private var pill100ShellScale: CGFloat = 0.22

    /// 预览泡壳 scale（在 pill100 之上继续放大到全预览）
    @State private var shellScale: CGFloat = 1
    @State private var shellBgOpacity: Double = 1

    @State private var menuLeft: CGFloat = 0
    @State private var menuTop: CGFloat = 0
    @State private var menuWidth: CGFloat = PhoneMenu1718Layout.Design.menuWidth
    @State private var menuHeight: CGFloat = PhoneMenu1718Layout.Design.menuHeight
    @State private var menuGrowUp = false
    @State private var menuOpacity: Double = 0
    @State private var menuScale: CGFloat = PhoneMenu1718Layout.Animation.previewEnterScaleFrom
    @State private var menuRowStates: [MenuRowAnimState] = Array(
        repeating: MenuRowAnimState(),
        count: PhoneMenu18Layout.Design.menuActionRowCount
    )

    private var menuLayoutTuning: Notes1718TuningSettings { tuning.bridgedTo1718() }

    @State private var metrics = PhoneMenu18Layout.metrics(
        in: UIScreen.main.bounds.size,
        safeTop: 0,
        safeBottom: 0,
        tuning: Notes18TuningSettings.default.bridgedTo1718()
    )
    @State private var overlayScreenHeight: CGFloat = UIScreen.main.bounds.height
    @State private var overlaySafeTop: CGFloat = 0
    @State private var overlaySafeBottom: CGFloat = 0
    @State private var resolvedAnchor: CGRect = .zero

    private var tokens: NotesStyle18Tokens.PhoneMenu.Type { NotesStyle18Tokens.PhoneMenu.self }
    private var anim: PhoneMenu1718Layout.Animation.Type { PhoneMenu1718Layout.Animation.self }

    private var previewPhoneFont: Font {
        .system(size: CGFloat(tuning.previewPhoneFontSize), weight: .semibold)
    }

    private var morphPhoneFont: Font {
        .system(size: CGFloat(tuning.phoneFontSize), weight: .regular)
    }

    private var formattedDialString: String {
        PhoneUtilities.formatSpacedMobile(phone)
    }

    private var morphUnitAnimation: Animation {
        .easeOut(duration: anim.morphUnitScaleDuration)
    }

    private var previewEnterSpring: Animation {
        .spring(response: anim.previewEnterResponse, dampingFraction: anim.previewEnterDamping)
    }

    private var previewExitSpring: Animation {
        .spring(response: anim.previewExitResponse, dampingFraction: anim.previewExitDamping)
    }

    private var pill150ShellScale: CGFloat {
        pill100ShellScale * anim.dismissYellowStartPillMultiplier
    }

    /// 入场：壳到 80% 全预览时渐显头像+预览号码
    private var enterPreviewBlend: CGFloat {
        let start = anim.morphToPreviewScaleThreshold
        guard shellScale > start else { return 0 }
        guard shellScale < 1 else { return 1 }
        return (shellScale - start) / (1 - start)
    }

    /// 退场：150% 小白底 → 100% 预览内容淡出
    private var dismissPreviewBlend: CGFloat {
        let s = shellScale
        if s >= pill150ShellScale { return 1 }
        if s <= pill100ShellScale { return 0 }
        return (s - pill100ShellScale) / (pill150ShellScale - pill100ShellScale)
    }

    private var previewRowOpacity: Double {
        if isDismissing { return Double(dismissPreviewBlend) }
        return Double(enterPreviewBlend)
    }

    /// 退场：150%→100% 小白底，黄字由淡到实
    private var dismissYellowOpacity: Double {
        let s = shellScale
        if s > pill150ShellScale { return 0 }
        if s <= pill100ShellScale { return 1 }
        return Double((pill150ShellScale - s) / (pill150ShellScale - pill100ShellScale))
    }

    private var morphTextOpacity: Double {
        if isDismissing { return dismissYellowOpacity }
        if enterPreviewBlend >= 1 { return 0 }
        if enterPreviewBlend <= 0 { return 1 }
        return Double(1 - enterPreviewBlend)
    }

    /// 退场：号码 scale 随壳 scale 连续变化，一次 spring 缩回正文
    private var resolvedMorphUnitScale: CGFloat {
        guard isDismissing else { return morphUnitScale }
        let span = pill100ShellScale - basePillShellScale
        guard span > 0.001 else { return 1 }
        if shellScale >= pill100ShellScale { return anim.morphPillTextScaleAt100 }
        let t = min(max((shellScale - basePillShellScale) / span, 0), 1)
        return 1 + t * (anim.morphPillTextScaleAt100 - 1)
    }

    /// 退场尾段：压暗/模糊随号码 scale 从 1.2→1.01 同步恢复
    private var dismissBackdropStrength: Double {
        let scale = resolvedMorphUnitScale
        let lo = anim.morphPillVanishScaleThreshold
        let hi = anim.morphPillTextScaleAt100
        if scale <= lo { return 0 }
        if scale >= hi { return 1 }
        return Double((scale - lo) / (hi - lo))
    }

    /// 退场：号码 ≤1.01× 时小白底立即消失（不再渐隐）
    private var resolvedShellBgOpacity: Double {
        guard isDismissing else { return shellBgOpacity }
        if resolvedMorphUnitScale <= anim.morphPillVanishScaleThreshold { return 0 }
        return shellBgOpacity
    }

    private var cornerBlend: CGFloat {
        isDismissing ? (1 - dismissPreviewBlend) : enterPreviewBlend
    }

    private var morphPillHeight: CGFloat {
        resolvedAnchor.height + anim.phoneTextPad * 2
    }

    private var previewCornerRadius: CGFloat {
        let pillCorner = morphPillHeight / 2
        let full = metrics.previewCornerRadius
        let visual = pillCorner * (1 - cornerBlend) + full * cornerBlend
        return min(visual / max(shellScale, 0.08), metrics.previewSize.height / 2)
    }

    private var phoneAnchorInBubble: CGPoint {
        CGPoint(
            x: resolvedAnchor.minX - bubbleLeft,
            y: resolvedAnchor.maxY - bubbleTop
        )
    }

    private var previewContentInset: CGFloat {
        metrics.previewPadH - metrics.previewContentShiftLeft
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                LongPressBackdrop18(
                    overlayOpacity: app.phoneMenuBackdropStrength,
                    dimOpacity: tuning.longPressOverlayDim
                )

                Color.clear
                    .contentShape(Rectangle())
                    .ignoresSafeArea()
                    .onTapGesture { dismissAll() }

                if resolvedAnchor != .zero {
                    scaledShellCluster
                    morphTextLayer
                }

                menuCard
                    .frame(width: menuWidth, height: menuHeight)
                    .scaleEffect(menuScale, anchor: menuScaleAnchor())
                    .offset(x: menuLeft, y: menuTop)
                    .opacity(menuOpacity)
            }
            .onAppear {
                resolvedAnchor = PhoneMenu1718Layout.anchorInOverlay(
                    windowAnchor,
                    overlayGlobalFrame: geo.frame(in: .global)
                )
                let insets = PhoneMenu18Layout.resolvedSafeInsets(
                    fallbackTop: geo.safeAreaInsets.top,
                    fallbackBottom: geo.safeAreaInsets.bottom
                )
                metrics = PhoneMenu18Layout.metrics(
                    in: geo.size,
                    safeTop: insets.top,
                    safeBottom: insets.bottom,
                    tuning: menuLayoutTuning
                )
                let screenH = geo.size.height
                let safeTop = insets.top
                let safeBottom = insets.bottom
                overlayScreenHeight = screenH
                overlaySafeTop = safeTop
                overlaySafeBottom = safeBottom
                resetRowStates()
                didCompleteDismiss = false
                // 同帧内 @State 尚未提交，placement 须直接用 geo 的 safe area
                runShowAnimation(screenHeight: screenH, safeTop: safeTop, safeBottom: safeBottom)
            }
            .onChange(of: shellScale) { _ in
                syncDismissBackdropOnly()
            }
            .onChange(of: tuning) { _ in
                let insets = PhoneMenu18Layout.resolvedSafeInsets(
                    fallbackTop: geo.safeAreaInsets.top,
                    fallbackBottom: geo.safeAreaInsets.bottom
                )
                metrics = PhoneMenu18Layout.metrics(
                    in: geo.size,
                    safeTop: insets.top,
                    safeBottom: insets.bottom,
                    tuning: menuLayoutTuning
                )
                overlayScreenHeight = geo.size.height
                overlaySafeTop = insets.top
                overlaySafeBottom = insets.bottom
            }
        }
        .ignoresSafeArea()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var scaledShellCluster: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: previewCornerRadius, style: .continuous)
                .fill(tuning.previewBubbleFillColor())
                .opacity(resolvedShellBgOpacity)
                .shadow(
                    color: .black.opacity(metrics.previewShadowOpacity * Double(cornerBlend) * resolvedShellBgOpacity),
                    radius: metrics.previewShadowRadius * cornerBlend,
                    y: metrics.previewShadowY * cornerBlend
                )

            previewRowContent
                .opacity(previewRowOpacity)
        }
        .frame(width: metrics.previewSize.width, height: metrics.previewSize.height)
        .scaleEffect(shellScale, anchor: shellScaleAnchor(in: metrics))
        .offset(x: bubbleLeft, y: bubbleTop)
    }

    /// 黄字与小白底同步 scale（1→1.2），锚点为号码左下角
    private var morphTextLayer: some View {
        Text(phone)
            .font(morphPhoneFont)
            .foregroundStyle(NotesDetectedLinkColor.color)
            .underline(true, color: NotesDetectedLinkColor.color)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .scaleEffect(resolvedMorphUnitScale, anchor: .bottomLeading)
            .offset(x: resolvedAnchor.minX, y: resolvedAnchor.minY)
            .opacity(morphTextOpacity)
            .allowsHitTesting(false)
    }

    /// 预览泡：头像+号码紧挨（5pt），整体靠左且上下居中
    private var previewRowContent: some View {
        HStack(spacing: anim.previewAvatarPhoneSpacing) {
            ContactPlaceholderAvatar1718(size: metrics.avatarSize, tuning: menuLayoutTuning)
                .frame(width: metrics.avatarSize, height: metrics.avatarSize)

            Text(formattedDialString)
                .font(previewPhoneFont)
                .foregroundStyle(Color(uiColor: tuning.previewPhoneUIColor()))
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
        .fixedSize(horizontal: true, vertical: false)
        .padding(.leading, previewContentInset)
        .frame(
            width: metrics.previewSize.width,
            height: metrics.previewSize.height,
            alignment: .init(horizontal: .leading, vertical: .center)
        )
    }

    private func shellScaleAnchor(in metrics: PhoneMenu1718Layout.Metrics) -> UnitPoint {
        guard metrics.previewSize.width > 0, metrics.previewSize.height > 0 else {
            return .bottomLeading
        }
        let pt = phoneAnchorInBubble
        return UnitPoint(
            x: min(max(pt.x / metrics.previewSize.width, 0), 1),
            y: min(max(pt.y / metrics.previewSize.height, 0), 1)
        )
    }

    private func menuScaleAnchor() -> UnitPoint {
        guard menuWidth > 0, menuHeight > 0 else { return .bottomLeading }
        return UnitPoint(
            x: min(max((resolvedAnchor.minX - menuLeft) / menuWidth, 0), 1),
            y: min(max((resolvedAnchor.maxY - menuTop) / menuHeight, 0), 1)
        )
    }

    private var menuRowLabelColor: Color {
        NotesStyle18Tokens.PhoneMenu.menuEmphasisColor
    }

    private var menuRowIconColor: Color {
        NotesStyle18Tokens.PhoneMenu.menuEmphasisColor
    }

    private func menuTitleText(_ title: String) -> some View {
        Text(title)
            .font(.system(size: PhoneMenu18Layout.Design.menuTitleFontSize, weight: .regular))
            .foregroundStyle(menuRowLabelColor)
    }

    private func menuTitleColumn(title: String, subtitle: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            menuTitleText(title)
            if let subtitle {
                Text(subtitle)
                    .font(.system(size: PhoneMenu18Layout.Design.menuSubtitleFontSize, weight: .regular))
                    .foregroundStyle(Color(uiColor: .secondaryLabel))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, PhoneMenu18Layout.Design.textContentLeadingExtra)
    }

    private func menuChevronGlyph() -> some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(menuRowLabelColor)
            .offset(x: -PhoneMenu18Layout.Design.chevronLeadingOffset)
    }

    private func menuChevronTitleBlock(title: String) -> some View {
        ZStack(alignment: .leading) {
            menuTitleText(title)
            menuChevronGlyph()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, PhoneMenu18Layout.Design.textContentLeadingExtra)
    }

    private func menuTrailingIcon(_ icon: String) -> some View {
        Image(systemName: icon)
            .font(.system(size: metrics.menuIconSize, weight: .regular))
            .symbolRenderingMode(.monochrome)
            .foregroundStyle(menuRowIconColor)
    }

    private var menuCard: some View {
        VStack(spacing: 0) {
            animatedTwoLineMenuRow(
                index: 0,
                icon: "phone",
                title: "呼叫",
                subtitle: app.phoneMenuCallSubtitle,
                action: onDismiss
            )
            menuSeparator
            animatedTwoLineMenuRow(
                index: 1,
                icon: "video",
                title: "视频",
                subtitle: "微信",
                action: onDismiss
            )
            menuSeparator
            animatedTwoLineMenuRow(
                index: 2,
                icon: "message",
                title: "信息",
                subtitle: "信息",
                action: onMessage
            )
            menuSectionSeparator
            animatedChevronMenuRow(index: 3, icon: "phone", title: "呼叫", action: onDismiss)
            menuSeparator
            animatedChevronMenuRow(index: 4, icon: "video", title: "视频", action: onDismiss)
            menuSectionSeparator
            animatedMenuRow(index: 5, icon: "person.crop.circle.badge.plus", title: "添加到通讯录", action: onDismiss)
            menuSeparator
            animatedMenuRow(index: 6, icon: "doc.on.doc", title: "拷贝", action: onCopy)
            menuSeparator
            animatedMenuRow(index: 7, icon: "pencil", title: "编辑链接", action: onDismiss)
            menuSeparator
            animatedMenuRow(index: 8, icon: "trash", title: "移除链接", action: onDismiss)
        }
        .background {
            MenuPanelSolidBackground18(
                cornerRadius: metrics.menuCornerRadius,
                fill: tuning.menuPanelTintColor()
                    .opacity(NotesStyle18Tokens.PhoneMenu.menuPanelBackgroundOpacity),
                shadowOpacity: metrics.menuShadowOpacity,
                shadowRadius: metrics.menuShadowRadius,
                shadowY: metrics.menuShadowY
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: metrics.menuCornerRadius, style: .continuous))
    }

    private var menuSeparator: some View {
        Rectangle()
            .fill(Color(uiColor: .separator))
            .frame(height: metrics.dividerHeight)
    }

    private var menuSectionSeparator: some View {
        Rectangle()
            .fill(
                Color(uiColor: .separator)
                    .opacity(PhoneMenu18Layout.Design.sectionSeparatorOpacity)
            )
            .frame(height: PhoneMenu18Layout.Design.sectionSeparatorHeight)
    }

    private func animatedTwoLineMenuRow(
        index: Int,
        icon: String,
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        menuTwoLineRow(icon: icon, title: title, subtitle: subtitle, action: action)
            .opacity(menuRowStates[index].opacity)
            .offset(y: menuRowStates[index].offsetY)
    }

    private func animatedChevronMenuRow(
        index: Int,
        icon: String,
        title: String,
        action: @escaping () -> Void
    ) -> some View {
        menuChevronRow(icon: icon, title: title, action: action)
            .opacity(menuRowStates[index].opacity)
            .offset(y: menuRowStates[index].offsetY)
    }

    private func animatedMenuRow(
        index: Int,
        icon: String,
        title: String,
        action: @escaping () -> Void
    ) -> some View {
        menuRow(icon: icon, title: title, action: action)
            .opacity(menuRowStates[index].opacity)
            .offset(y: menuRowStates[index].offsetY)
    }

    private func menuTwoLineRow(
        icon: String,
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                menuTitleColumn(title: title, subtitle: subtitle)
                menuTrailingIcon(icon)
            }
            .padding(.horizontal, metrics.menuContentInsetH)
            .frame(height: PhoneMenu18Layout.Design.twoLineRowHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(MenuRowButtonStyle18(cornerRadius: metrics.menuRowHighlightCornerRadius))
    }

    private func menuChevronRow(
        icon: String,
        title: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                menuChevronTitleBlock(title: title)
                menuTrailingIcon(icon)
            }
            .padding(.horizontal, metrics.menuContentInsetH)
            .frame(height: PhoneMenu18Layout.Design.singleLineRowHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(MenuRowButtonStyle18(cornerRadius: metrics.menuRowHighlightCornerRadius))
    }

    private func menuRow(
        icon: String,
        title: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                menuTitleColumn(title: title)
                menuTrailingIcon(icon)
            }
            .padding(.horizontal, metrics.menuContentInsetH)
            .frame(height: PhoneMenu18Layout.Design.singleLineRowHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(MenuRowButtonStyle18(cornerRadius: metrics.menuRowHighlightCornerRadius))
    }

    // MARK: - Animation

    private func resetRowStates() {
        menuRowStates = Array(
            repeating: MenuRowAnimState(),
            count: PhoneMenu18Layout.Design.menuActionRowCount
        )
    }

    /// 正文 1.0x 号码+padding 对应壳 scale
    private func computedBasePillShellScale(in metrics: PhoneMenu1718Layout.Metrics) -> CGFloat {
        guard metrics.previewSize.width > 0, metrics.previewSize.height > 0 else { return 0.15 }
        let padH = anim.phoneTextPad - anim.morphSettleBackHorizontal
        let padV = anim.phoneTextPad
        let pillW = resolvedAnchor.width + padH * 2
        let pillH = resolvedAnchor.height + padV * 2
        let wRatio = pillW / metrics.previewSize.width
        let hRatio = pillH / metrics.previewSize.height
        return min(max(max(wRatio, hRatio), 0.06), 0.95)
    }

    private func initialMenuScale(in metrics: PhoneMenu1718Layout.Metrics) -> CGFloat {
        guard menuWidth > 0, menuHeight > 0 else {
            return anim.previewEnterScaleFrom
        }
        let pad = anim.phoneTextPad
        let wRatio = (resolvedAnchor.width + pad * 2) / menuWidth
        let hRatio = (resolvedAnchor.height + pad * 2) / menuHeight
        return min(max(max(wRatio, hRatio), 0.08), anim.previewEnterScaleFrom)
    }

    private func runShowAnimation(
        screenHeight: CGFloat? = nil,
        safeTop: CGFloat? = nil,
        safeBottom: CGFloat? = nil
    ) {
        runLongPressShow(
            screenHeight: screenHeight,
            safeTop: safeTop,
            safeBottom: safeBottom
        )
    }

    private func runLongPressShow(
        screenHeight: CGFloat? = nil,
        safeTop: CGFloat? = nil,
        safeBottom: CGFloat? = nil
    ) {
        let final = PhoneMenu18Layout.placement(
            anchor: resolvedAnchor,
            metrics: metrics,
            screenHeight: screenHeight ?? overlayScreenHeight,
            safeTop: safeTop ?? overlaySafeTop,
            safeBottom: safeBottom ?? overlaySafeBottom
        )
        let spring = previewEnterSpring
        let basePill = computedBasePillShellScale(in: metrics)
        let pill100 = basePill * anim.morphPillTextScaleAt100

        bubbleLeft = final.previewFrame.minX
        bubbleTop = final.previewFrame.minY
        menuLeft = final.menuFrame.minX
        menuTop = final.menuFrame.minY
        menuWidth = final.menuFrame.width
        menuHeight = final.menuFrame.height
        menuGrowUp = final.menuGrowUp

        basePillShellScale = basePill
        pill100ShellScale = pill100
        isDismissing = false
        morphUnitScale = 1
        shellScale = basePill
        shellBgOpacity = 1
        menuOpacity = 0
        menuScale = anim.previewEnterScaleFrom
        resetRowStates()
        app.phoneMenuBackdropStrength = 0

        withAnimation(.easeOut(duration: anim.overlayEnterDuration)) {
            app.phoneMenuBackdropStrength = 1
        }

        withAnimation(morphUnitAnimation) {
            morphUnitScale = anim.morphPillTextScaleAt100
            shellScale = pill100
        }

        let springStart = anim.morphUnitScaleDuration - anim.morphToPreviewSpringOverlap
        DispatchQueue.main.asyncAfter(deadline: .now() + springStart) {
            withAnimation(spring) {
                shellScale = 1
                menuOpacity = 1
                menuScale = 1
            }

            for index in menuRowStates.indices {
                let delay = Double(index) * anim.menuRowEnterDelayStep
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(spring) {
                        menuRowStates[index].opacity = 1
                        menuRowStates[index].offsetY = 0
                    }
                }
            }
        }
    }

    /// 退场：仅同步压暗/模糊；小白底在 ≤1.01× 时由 resolvedShellBgOpacity 立即消失
    private func syncDismissBackdropOnly() {
        guard isDismissing else { return }
        app.phoneMenuBackdropStrength = dismissBackdropStrength
    }

    private func dismissAll() {
        let exitSpring = previewExitSpring
        let menuExitScale = initialMenuScale(in: metrics)
        isDismissing = true
        didCompleteDismiss = false
        shellBgOpacity = 1
        morphUnitScale = anim.morphPillTextScaleAt100

        for (reverseIndex, rowIndex) in menuRowStates.indices.reversed().enumerated() {
            let delay = Double(reverseIndex) * anim.menuRowExitDelayStep
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeIn(duration: anim.menuRowExitDuration)) {
                    menuRowStates[rowIndex].opacity = 0
                    menuRowStates[rowIndex].offsetY = anim.menuRowExitOffsetY
                }
            }
        }

        withAnimation(exitSpring) {
            shellScale = basePillShellScale
            menuOpacity = 0
            menuScale = menuExitScale
        }

        syncDismissBackdropOnly()

        // spring 跑完后再 onDismiss，保留 1.01×→1.0× 号码回缩动画
        let total = anim.previewExitResponse * 0.92 + 0.02
        DispatchQueue.main.asyncAfter(deadline: .now() + total) {
            guard !didCompleteDismiss else { return }
            didCompleteDismiss = true
            app.phoneMenuBackdropStrength = 0
            onDismiss()
        }
    }
}

private struct LongPressBackdrop18: View {
    var overlayOpacity: Double
    var dimOpacity: Double

    var body: some View {
        Color.black
            .opacity(overlayOpacity * dimOpacity)
            .ignoresSafeArea()
            .allowsHitTesting(false)
    }
}

private struct MenuRowButtonStyle18: ButtonStyle {
    var cornerRadius: CGFloat

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        configuration.isPressed
                            ? NotesStyle18Tokens.PhoneMenu.rowHighlightFill
                            : Color.clear
                    )
                    .padding(.horizontal, 8)
            )
    }
}

private struct MenuPanelSolidBackground18: View {
    var cornerRadius: CGFloat
    var fill: Color
    var shadowOpacity: Double
    var shadowRadius: CGFloat
    var shadowY: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(fill)
            .shadow(color: .black.opacity(shadowOpacity), radius: shadowRadius, y: shadowY)
    }
}
