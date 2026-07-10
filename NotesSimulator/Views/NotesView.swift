import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct NotesView: View {
    @EnvironmentObject private var app: AppState
    @State private var showTextImporter = false
    @State private var showTuningPanel = false
    @State private var rootFrameGlobal: CGRect = .zero
    @State private var frozenWindowAnchor: CGRect = .zero
    @State private var frozenMenuAnchor: CGRect = .zero
    @State private var bottomSafeInset: CGFloat = 0
    @State private var transitionProgress: CGFloat = 0
    var body: some View {
        ZStack {
            if app.usesLegacyNotesShell, app.showIMessage {
                Color.black
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            notesLayer

            if app.showPhoneMenu, let phone = app.selectedPhone {
                if let shell = app.legacyNotesShell {
                    Group {
                        switch shell {
                        case .ios17:
                            PhoneActionMenuView17(
                                phone: phone,
                                windowAnchor: frozenWindowAnchor,
                                presentation: app.phoneMenuPresentation,
                                tuning: app.notes17Tuning,
                                onMessage: openIMessage,
                                onCopy: {
                                    UIPasteboard.general.string = phone
                                    app.showPhoneMenu = false
                                },
                                onDismiss: {
                                    app.phoneMenuBackdropStrength = 0
                                    app.showPhoneMenu = false
                                }
                            )
                        case .ios18:
                            PhoneActionMenuView18(
                                phone: phone,
                                windowAnchor: frozenWindowAnchor,
                                presentation: app.phoneMenuPresentation,
                                tuning: app.notes18Tuning,
                                onMessage: openIMessage,
                                onCopy: {
                                    UIPasteboard.general.string = phone
                                    app.showPhoneMenu = false
                                },
                                onDismiss: {
                                    app.phoneMenuBackdropStrength = 0
                                    app.showPhoneMenu = false
                                }
                            )
                        }
                    }
                    .transition(.opacity)
                    .zIndex(20)
                } else {
                    PhoneActionMenuView(
                        phone: phone,
                        anchor: frozenMenuAnchor,
                        presentation: app.phoneMenuPresentation,
                        onMessage: openIMessage,
                        onCopy: {
                            UIPasteboard.general.string = phone
                            app.showPhoneMenu = false
                        },
                        onDismiss: { app.showPhoneMenu = false }
                    )
                    .zIndex(20)
                }
            }

            imessageOverlay
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(
            app.usesLegacyNotesShell
                ? .easeOut(duration: (app.legacyNotesShell?.messagesPresentDuration ?? IMessage1718DesignTokens.messagesPresentDuration))
                : imessageTransitionAnimation,
            value: app.showIMessage
        )
        .animation(
            app.usesLegacyNotesShell ? nil : .spring(response: 0.48, dampingFraction: 0.82),
            value: app.showPhoneMenu
        )
        .onAppear {
            if !app.showIMessage {
                transitionProgress = 0
                app.phoneMenuBackdropStrength = 0
            }
        }
        .alert("请先激活 App", isPresented: $app.showActivationRequiredAlert) {
            Button("好", role: .cancel) {}
        }
        .onChange(of: app.isActivated) { active in
            if !active {
                app.showPhoneMenu = false
                app.showIMessage = false
                transitionProgress = 0
                if app.activationMode == .clicks {
                    app.leaveNotesToSettings()
                }
            }
        }
        .background {
            if !app.usesLegacyNotesShell {
                notesPaperBackground
                    .ignoresSafeArea()
            }
        }
        .background(
            GeometryReader { proxy in
                Color.clear
                    .onAppear { rootFrameGlobal = proxy.frame(in: .global) }
                    .onChange(of: proxy.size) { _ in
                        rootFrameGlobal = proxy.frame(in: .global)
                    }
            }
        )
    }

    @ViewBuilder
    /// iOS 17–18 信息页：与 iOS 26 相同 `.transition(.move(edge: .bottom))` 整页一体上滑。
    /// 禁止 progress offset / scroll 冻结 / 预估键盘（内部 scroll 与 26 同算法，仅 token 不同）。
    private var imessageOverlay: some View {
        if app.showIMessage {
            if let shell = app.legacyNotesShell {
                switch shell {
                case .ios17:
                    NewIMessageView17(onClose: closeIMessage)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .ignoresSafeArea()
                        .transition(.move(edge: .bottom))
                        .zIndex(30)
                case .ios18:
                    NewIMessageView18(onClose: closeIMessage)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .ignoresSafeArea()
                        .transition(.move(edge: .bottom))
                        .zIndex(30)
                }
            } else {
                NewIMessageView(onClose: closeIMessage)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
                    .transition(.move(edge: .bottom))
                    .zIndex(30)
            }
        }
    }

    /// iOS 26：点「信息」后整体压暗（原逻辑）
    private var notesLayer: some View {
        Group {
            switch app.legacyNotesShell {
            case .ios17:
                notesLayerLegacy(.ios17)
            case .ios18:
                notesLayerLegacy(.ios18)
            case nil:
                notesLayerIOS26
            }
        }
    }

    private var notesLayerIOS26: some View {
        notesContent
            .blur(radius: longPressNotesBlurRadius)
            .background {
                notesPaperBackground
                    .ignoresSafeArea()
            }
            .overlay {
                if app.showIMessage {
                    Color.black
                        .opacity(IMessageDesignTokens.composeBackdropDimOpacity)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                }
            }
            .allowsHitTesting(!app.showIMessage)
            .animation(imessageTransitionAnimation, value: app.showIMessage)
    }

    /// iOS 17 / 18：固定屏高一体板 + compositingGroup，再 uniform scale
    private func notesLayerLegacy(_ shell: LegacyNotesShell) -> some View {
        GeometryReader { geo in
            let safeTop = resolvedStatusBarTop(fallback: geo.safeAreaInsets.top)
            let safeBottom = resolvedHomeIndicatorBottom(fallback: geo.safeAreaInsets.bottom)

            legacyFullScreenCard(
                shell: shell,
                width: geo.size.width,
                height: geo.size.height,
                safeTop: safeTop,
                safeBottom: safeBottom
            )
            .frame(width: geo.size.width, height: geo.size.height)
            .onAppear { bottomSafeInset = safeBottom }
            .onChange(of: geo.safeAreaInsets.bottom) { bottomSafeInset = $0 }
        }
        .ignoresSafeArea()
        .allowsHitTesting(transitionProgress < 0.01)
        .sheet(isPresented: $showTuningPanel) {
            switch shell {
            case .ios17:
                Notes17TuningPanel(settings: $app.notes17Tuning)
            case .ios18:
                Notes18TuningPanel(settings: $app.notes18Tuning)
            }
        }
        .fileImporter(
            isPresented: $showTextImporter,
            allowedContentTypes: [.plainText, .text, .data],
            allowsMultipleSelection: false
        ) { result in
            guard case .success(let urls) = result, let url = urls.first else { return }
            app.importTextFile(from: url)
        }
    }

    private func legacyFullScreenCard(
        shell: LegacyNotesShell,
        width: CGFloat,
        height: CGFloat,
        safeTop: CGFloat,
        safeBottom: CGFloat
    ) -> some View {
        let navH = NotesDesignTokens.Layout.navBarHeight
        let chromeBelow = shell.chromeBelowNav

        return ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                Color.clear.frame(height: safeTop)
                Color.clear.frame(height: shell.unifiedNavExtraDownShift)

                classicNavBar(shell: shell)
                    .padding(.horizontal, NotesDesignTokens.Official.Nav.horizontalMargin)
                    .frame(height: navH)

                Color.clear
                    .frame(height: chromeBelow)
                    .frame(maxWidth: .infinity)

                NotesReadingProgressAttachment(
                    trackStyle: .ios1718(safeBottom: safeBottom)
                ) {
                    ScrollView(showsIndicators: false) {
                        legacyScrollBody(shell: shell)
                            .trackNotesReadingScrollContent()
                            .padding(.bottom, 8 + legacyToolbarScrollReserve(shell: shell, safeBottom: safeBottom))
                    }
                }
            }

            legacyBottomToolbarOverlay(shell: shell, safeBottom: safeBottom)
        }
        .frame(width: width, height: height, alignment: .top)
        .background {
            shell.paperColor(app: app)
                .frame(width: width, height: height)
        }
        .blur(radius: longPressNotesBlurRadius(shell: shell))
        .animation(
            app.phoneMenuBackdropStrength > 0 && app.phoneMenuBackdropStrength < 1
                ? nil
                : .easeOut(duration: PhoneMenu1718Layout.Animation.overlayEnterDuration),
            value: app.phoneMenuBackdropStrength
        )
        .overlay {
            legacyBackdropDimOverlay(shell: shell)
        }
        .compositingGroup()
        .modifier(
            Notes1718FromViewModalLayer(
                progress: transitionProgress,
                screenWidth: width,
                screenHeight: height,
                safeTop: safeTop
            )
        )
    }

    private func legacyToolbarScrollReserve(shell: LegacyNotesShell, safeBottom: CGFloat) -> CGFloat {
        let barH = NotesDesignTokens.Layout.bottomToolbarHeight
        return shell.chromeAboveToolbar
            + barH
            + safeBottom
            + shell.unifiedBottomPlateExtraDownShift
    }

    private func legacyBottomToolbarOverlay(shell: LegacyNotesShell, safeBottom: CGFloat) -> some View {
        let barH = NotesDesignTokens.Layout.bottomToolbarHeight
        let chromeAbove = shell.chromeAboveToolbar
        let plateDown = shell.unifiedBottomPlateExtraDownShift
        let iconBandHeight = chromeAbove + barH

        return ZStack(alignment: .bottom) {
            GeometryReader { proxy in
                let homeIndicator = max(proxy.safeAreaInsets.bottom, safeBottom)
                let plateHeight = iconBandHeight + homeIndicator + plateDown

                shell.paperColor(app: app)
                    .frame(maxWidth: .infinity)
                    .frame(height: plateHeight)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
            .ignoresSafeArea(edges: .bottom)

            ZStack {
                classicBottomBarIcons(shell: shell)
                    .padding(.horizontal, NotesDesignTokens.Official.Nav.horizontalMargin)
            }
            .frame(height: iconBandHeight)
            .padding(.bottom, safeBottom)
        }
        .frame(height: iconBandHeight + plateDown)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func legacyBackdropDimOverlay(shell: LegacyNotesShell) -> some View {
        let amount = legacyBackdropDimAmount(shell: shell)
        if amount > 0.001 {
            Color.black
                .opacity(amount)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
    }

    private func legacyBackdropDimAmount(shell: LegacyNotesShell) -> CGFloat {
        guard app.usesLegacyNotesShell, app.showIMessage || transitionProgress > 0.001 else {
            return 0
        }
        let p = min(max(transitionProgress, 0), 1)
        return p * (1 - shell.fromViewEndAlpha)
    }

    private func legacyScrollBody(shell: LegacyNotesShell) -> some View {
        let bridgedTuning = shell.bridged1718Tuning(app: app)
        return VStack(alignment: .leading, spacing: 0) {
            Text(NoteDateFormatting.string(from: app.noteHeaderDisplayDate))
                .font(NotesDesignTokens.Layout.dateFont)
                .foregroundStyle(IOSTheme.labelSecondary)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 10)

            ZStack(alignment: .topLeading) {
                if app.noteTitle.isEmpty {
                    Text("标题")
                        .font(IOSTheme.titleFont)
                        .foregroundStyle(IOSTheme.labelTertiary)
                        .allowsHitTesting(false)
                }
                NotesTitleEditor(
                    text: $app.noteTitle,
                    usesIOS1718Style: true,
                    tuning1718: bridgedTuning
                )
                .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, NotesDesignTokens.Layout.titlePhoneAlignedLeadingInset)
            .padding(.trailing, NotesDesignTokens.Layout.titlePhoneAlignedTrailingInset)
            .padding(.bottom, NotesDesignTokens.Layout.titleToBodyGap)

            NotesBodyEditor(
                text: $app.noteBody,
                hiddenPhone: hiddenPhoneForMenu,
                usesIOS1718Style: true,
                tuning1718: bridgedTuning
            ) { phone, windowRect, presentation in
                guard app.canUseSimulationFeatures else {
                    app.presentActivationRequired()
                    return
                }
                app.selectedPhone = phone
                app.phoneMenuPresentation = presentation
                app.phoneMenuAnchor = windowRect
                frozenWindowAnchor = windowRect
                frozenMenuAnchor = localAnchor(windowRect)
                withAnimation(.spring(response: 0.48, dampingFraction: 0.82)) {
                    app.showPhoneMenu = true
                }
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, NotesDesignTokens.Layout.contentInset)
        .padding(.top, 6)
    }

    private var notesPaperBackground: some View {
        IOSTheme.notesPaper
    }

    private var imessageTransitionAnimation: Animation {
        app.showIMessage
            ? .linear(duration: IMessageDesignTokens.presentLinearDuration)
            : .spring(
                response: IMessageDesignTokens.dismissSpringResponse,
                dampingFraction: IMessageDesignTokens.dismissSpringDamping
            )
    }

    private func resolvedScreenHeight() -> CGFloat {
        max(keyWindow?.bounds.height ?? 0, UIScreen.main.bounds.height)
    }

    private func localAnchor(_ windowRect: CGRect) -> CGRect {
        guard rootFrameGlobal != .zero, windowRect != .zero else { return .zero }
        return CGRect(
            x: windowRect.minX - rootFrameGlobal.minX,
            y: windowRect.minY - rootFrameGlobal.minY,
            width: windowRect.width,
            height: windowRect.height
        )
    }

    private var notesContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                if !app.usesLegacyNotesShell {
                    Text(NoteDateFormatting.string(from: app.noteHeaderDisplayDate))
                        .font(NotesDesignTokens.Layout.dateFont)
                        .foregroundStyle(IOSTheme.labelSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 10)
                }

                ZStack(alignment: .topLeading) {
                    if app.noteTitle.isEmpty {
                        Text("标题")
                            .font(IOSTheme.titleFont)
                            .foregroundStyle(IOSTheme.labelTertiary)
                            .allowsHitTesting(false)
                    }
                    NotesTitleEditor(
                        text: $app.noteTitle,
                        usesIOS1718Style: false,
                        tuning26: app.notes26Tuning
                    )
                    .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, NotesDesignTokens.Layout.titlePhoneAlignedLeadingInset)
                .padding(.trailing, NotesDesignTokens.Layout.titlePhoneAlignedTrailingInset)
                .padding(.bottom, NotesDesignTokens.Layout.titleToBodyGap)

                NotesBodyEditor(
                    text: $app.noteBody,
                    hiddenPhone: hiddenPhoneForMenu,
                    menuAnimatedPhone: menuBodyAnimatedPhone,
                    phoneMenuBodyDismissSignal: app.phoneMenuBodyDismissSignal,
                    usesIOS1718Style: false,
                    tuning26: app.notes26Tuning
                ) { phone, windowRect, presentation in
                    guard app.canUseSimulationFeatures else {
                        app.presentActivationRequired()
                        return
                    }
                    app.selectedPhone = phone
                    app.phoneMenuPresentation = presentation
                    app.phoneMenuAnchor = windowRect
                    frozenWindowAnchor = windowRect
                    frozenMenuAnchor = localAnchor(windowRect)
                    withAnimation(.spring(response: 0.48, dampingFraction: 0.82)) {
                        app.showPhoneMenu = true
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, NotesDesignTokens.Layout.contentInset)
            .padding(.top, 6)
            .padding(.bottom, 8 + bottomToolbarReserve)
            .trackNotesReadingScrollContent()
        }
        .overlay(alignment: .top) {
            if !app.usesLegacyNotesShell {
                NotesTopGlassFade()
                    .allowsHitTesting(false)
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            navBar
                .zIndex(1)
        }
        .overlay(alignment: .bottom) {
            bottomBar
                .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .notesReadingProgressIndicatorIfNeeded(true, trackStyle: .ios26)
        .sheet(isPresented: $showTuningPanel) {
            Notes26TuningPanel(settings: $app.notes26Tuning)
        }
        .background {
            GeometryReader { geo in
                Color.clear
                    .onAppear { bottomSafeInset = geo.safeAreaInsets.bottom }
                    .onChange(of: geo.safeAreaInsets.bottom) {
                        bottomSafeInset = $0
                    }
            }
        }
        .fileImporter(
            isPresented: $showTextImporter,
            allowedContentTypes: [.plainText, .text, .data],
            allowsMultipleSelection: false
        ) { result in
            guard case .success(let urls) = result, let url = urls.first else { return }
            app.importTextFile(from: url)
        }
    }

    private var hiddenPhoneForMenu: String? {
        guard app.showPhoneMenu, let phone = app.selectedPhone else { return nil }
        if app.usesLegacyNotesShell {
            if app.phoneMenuPresentation == .longPress { return phone }
            return nil
        }
        // iOS 26：长按保留正文号码（分身动画）；轻点仍隐藏
        if app.phoneMenuPresentation == .longPress { return nil }
        return phone
    }

    /// iOS 26 长按：正文号码缩放动画目标
    private var menuBodyAnimatedPhone: String? {
        guard !app.usesLegacyNotesShell,
              app.showPhoneMenu,
              app.phoneMenuPresentation == .longPress,
              let phone = app.selectedPhone else { return nil }
        return phone
    }

    /// 长按时糊正文/顶栏/底栏，纸面背景保持清晰（仅 legacy 17/18）
    private func longPressNotesBlurRadius(shell: LegacyNotesShell) -> CGFloat {
        guard app.showPhoneMenu, app.phoneMenuPresentation == .longPress else { return 0 }
        return shell.longPressTextBlurRadius(app: app) * CGFloat(app.phoneMenuBackdropStrength)
    }

    private var longPressNotesBlurRadius: CGFloat { 0 }

    /// 为底栏预留滚动空间（底栏 overlay 固定屏幕底部，不随键盘上移）
    private var bottomToolbarReserve: CGFloat {
        let barH = NotesDesignTokens.Layout.bottomToolbarHeight
        let gap = NotesDesignTokens.Official.Toolbar.bottomSafeGap
        return barH + gap + bottomSafeInset
    }

    private var navBar: some View {
        modernNavBar
            .padding(.horizontal, NotesDesignTokens.Official.Nav.horizontalMargin)
            .frame(height: NotesDesignTokens.Layout.navBarHeight)
            .frame(maxWidth: .infinity)
    }

    private var modernNavBar: some View {
        HStack(alignment: .center) {
            NotesGlassCircleButton(
                systemName: NotesDesignTokens.Official.Nav.backIcon,
                weight: NotesDesignTokens.Official.Nav.iconWeight
            ) {
                app.leaveNotesToSettings()
                closeIMessage()
            }

            Spacer(minLength: 0)

            NotesGlassCapsuleGroup(
                icons: [
                    NotesDesignTokens.Official.Nav.shareIcon,
                    NotesDesignTokens.Official.Nav.moreIcon,
                ],
                weight: NotesDesignTokens.Official.Nav.iconWeight,
                onTap: { index in
                    if index == 0 {
                        showTextImporter = true
                    } else if index == 1 {
                        KeyboardDismiss.resign()
                    }
                }
            )
        }
    }

    private func classicNavBar(shell: LegacyNotesShell) -> some View {
        let accent = shell == .ios17 ? NotesStyle17Tokens.iconColor : NotesStyle18Tokens.iconColor
        return HStack(alignment: .center, spacing: 0) {
            NotesClassicBackButton(iconColor: accent) {
                app.leaveNotesToSettings()
                closeIMessage()
            }

            Spacer(minLength: 0)

            HStack(spacing: shell.navTrailingSpacing) {
                NotesClassicIconButton(systemName: shell.navTrailingIcons[0], iconColor: accent) {
                    showTextImporter = true
                }
                NotesClassicIconButton(systemName: shell.navTrailingIcons[1], iconColor: accent) {
                    KeyboardDismiss.resign()
                }
            }
        }
    }

    private var bottomBar: some View {
        modernBottomBar
            .padding(.horizontal, NotesDesignTokens.Official.Nav.horizontalMargin)
            .padding(.bottom, NotesDesignTokens.Official.Toolbar.bottomSafeGap)
            .frame(height: NotesDesignTokens.Layout.bottomToolbarHeight)
            .frame(maxWidth: .infinity)
    }

    private var modernBottomBar: some View {
        HStack(alignment: .center) {
            NotesGlassCapsuleGroup(
                icons: [
                    NotesDesignTokens.Official.Toolbar.checklistIcon,
                    NotesDesignTokens.Official.Toolbar.attachmentIcon,
                    NotesDesignTokens.Official.Toolbar.markupIcon,
                ],
                iconSize: NotesDesignTokens.Official.Toolbar.iconSize,
                weight: NotesDesignTokens.Official.Toolbar.iconWeight,
                onTap: { index in
                    if index == 0 {
                        showTuningPanel = true
                    }
                }
            )

            Spacer(minLength: 0)

            NotesGlassCircleButton(
                systemName: NotesDesignTokens.Official.Toolbar.composeIcon,
                iconSize: NotesDesignTokens.Official.Toolbar.iconSize,
                weight: NotesDesignTokens.Official.Toolbar.iconWeight
            ) {}
        }
    }

    private func classicBottomBarIcons(shell: LegacyNotesShell) -> some View {
        let accent = shell == .ios17 ? NotesStyle17Tokens.iconColor : NotesStyle18Tokens.iconColor
        return HStack(spacing: 0) {
            NotesClassicIconButton(
                systemName: shell.toolbarChecklistIcon,
                iconSize: shell.toolbarIconSize,
                iconColor: accent
            ) {
                showTuningPanel = true
            }

            Spacer(minLength: 0)

            NotesClassicIconButton(
                systemName: shell.toolbarCameraIcon,
                iconSize: shell.toolbarIconSize,
                iconColor: accent
            ) {}

            Spacer(minLength: 0)

            NotesClassicIconButton(
                systemName: shell.toolbarMarkupIcon,
                iconSize: shell.toolbarIconSize,
                iconColor: accent
            ) {}

            Spacer(minLength: 0)

            NotesClassicIconButton(
                systemName: shell.toolbarComposeIcon,
                iconSize: shell.toolbarIconSize,
                iconColor: accent
            ) {}
        }
    }

    /// safeAreaInset 内 GeometryReader 的 top inset 常为 0，改读 keyWindow（与 NewIMessageView 一致）
    private func resolvedStatusBarTop(fallback: CGFloat) -> CGFloat {
        let windowTop = keyWindow?.safeAreaInsets.top ?? 0
        return max(fallback, windowTop)
    }

    private func resolvedHomeIndicatorBottom(fallback: CGFloat) -> CGFloat {
        let windowBottom = keyWindow?.safeAreaInsets.bottom ?? 0
        return max(fallback, windowBottom)
    }

    private var keyWindow: UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }
    }

    /// 1718 打开信息：菜单淡出 → 备忘录缩小 + 信息页一体上滑（并行，各自动画 token）
    private func openIMessage() {
        guard app.canUseSimulationFeatures else {
            app.presentActivationRequired()
            return
        }
        if let shell = app.legacyNotesShell {
            ComposeThread1718PinWarmup.refresh(app: app)
            withAnimation(.easeIn(duration: shell.phoneMenuFadeOutDuration)) {
                app.showPhoneMenu = false
                app.phoneMenuBackdropStrength = 0
            }
            withAnimation(.easeOut(duration: shell.systemModalDuration)) {
                transitionProgress = 1
            }
            withAnimation(.easeOut(duration: shell.messagesPresentDuration)) {
                app.showIMessage = true
            }
        } else {
            app.showPhoneMenu = false
            app.showIMessage = true
        }
    }

    private func closeIMessage() {
        if let shell = app.legacyNotesShell {
            withAnimation(.easeOut(duration: shell.messagesDismissDuration)) {
                app.showIMessage = false
            }
            withAnimation(.easeOut(duration: shell.fromViewDismissDuration)) {
                transitionProgress = 0
            }
        } else {
            app.showIMessage = false
        }
    }
}
