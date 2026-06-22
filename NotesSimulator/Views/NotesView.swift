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
    @State private var noteDisplayedDate = Date()
    @State private var bottomSafeInset: CGFloat = 0
    @State private var transitionProgress: CGFloat = 0
    @State private var notesScrollOffsetY: CGFloat = 0
    @State private var notesScrollContentHeight: CGFloat = 0
    @State private var notesScrollViewportHeight: CGFloat = 0
    @State private var notesScrollIndicatorVisible = false
    @State private var notesScrollIndicatorHideTask: Task<Void, Never>?
    var body: some View {
        ZStack {
            if app.notesStyleIOS1718, app.showIMessage {
                Color.black
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            notesLayer

            if app.showPhoneMenu, let phone = app.selectedPhone {
                if app.notesStyleIOS1718 {
                    PhoneActionMenuView1718(
                        phone: phone,
                        windowAnchor: frozenWindowAnchor,
                        presentation: app.phoneMenuPresentation,
                        tuning: app.notes1718Tuning,
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
                    .transition(.opacity)
                    .zIndex(20)
                } else {
                    PhoneActionMenuView(
                        phone: phone,
                        anchor: frozenMenuAnchor,
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
            app.notesStyleIOS1718
                ? .easeOut(duration: IMessage1718DesignTokens.messagesPresentDuration)
                : imessageTransitionAnimation,
            value: app.showIMessage
        )
        .animation(
            app.notesStyleIOS1718 ? nil : .spring(response: 0.48, dampingFraction: 0.82),
            value: app.showPhoneMenu
        )
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
            if !app.notesStyleIOS1718 {
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
        if app.notesStyleIOS1718 {
            if app.showIMessage {
                NewIMessageView1718(onClose: closeIMessage)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
                    .transition(.move(edge: .bottom))
                    .zIndex(30)
            }
        } else if app.showIMessage {
            NewIMessageView(onClose: closeIMessage)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
                .transition(.move(edge: .bottom))
                .zIndex(30)
        }
    }

    /// iOS 26：点「信息」后整体压暗（原逻辑）
    private var notesLayer: some View {
        Group {
            if app.notesStyleIOS1718 {
                notesLayer1718
            } else {
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

    /// iOS 17–18：固定屏高一体板 + compositingGroup，再 uniform scale
    private var notesLayer1718: some View {
        GeometryReader { geo in
            let safeTop = resolvedStatusBarTop(fallback: geo.safeAreaInsets.top)
            let safeBottom = resolvedHomeIndicatorBottom(fallback: geo.safeAreaInsets.bottom)

            notes1718FullScreenCard(
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
            if app.notesStyleIOS1718 {
                Notes1718TuningPanel(settings: $app.notes1718Tuning)
            } else {
                Notes26TuningPanel(settings: $app.notes26Tuning)
            }
        }
        .onAppear { noteDisplayedDate = Date() }
        .onChange(of: app.noteTitle) { _ in touchNoteDate() }
        .onChange(of: app.noteBody) { _ in touchNoteDate() }
        .fileImporter(
            isPresented: $showTextImporter,
            allowedContentTypes: [.plainText, .text, .data],
            allowsMultipleSelection: false
        ) { result in
            guard case .success(let urls) = result, let url = urls.first else { return }
            app.importTextFile(from: url)
        }
    }

    private func notes1718FullScreenCard(
        width: CGFloat,
        height: CGFloat,
        safeTop: CGFloat,
        safeBottom: CGFloat
    ) -> some View {
        let navH = NotesDesignTokens.Layout.navBarHeight
        let chromeBelow = NotesStyle1718Tokens.chromeBelowNav

        return ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                Color.clear.frame(height: safeTop)
                Color.clear.frame(height: NotesStyle1718Tokens.unifiedNavExtraDownShift)

                classicNavBar
                    .padding(.horizontal, NotesDesignTokens.Official.Nav.horizontalMargin)
                    .frame(height: navH)

                Color.clear
                    .frame(height: chromeBelow)
                    .frame(maxWidth: .infinity)

                ScrollView(showsIndicators: false) {
                    notes1718ScrollBody
                        .trackNotesScrollContentMetrics()
                        .padding(.bottom, 8 + notes1718ToolbarScrollReserve(safeBottom: safeBottom))
                }
                .trackNotesScrollMetrics(
                    offsetY: $notesScrollOffsetY,
                    contentHeight: $notesScrollContentHeight,
                    viewportHeight: $notesScrollViewportHeight
                )
                .onChange(of: notesScrollOffsetY) { _ in
                    noteScrollIndicatorDidScroll()
                }
                .onChange(of: notesScrollContentHeight) { _ in
                    if !showsNotesScrollProgress {
                        hideNotesScrollIndicatorImmediately()
                    }
                }
                .onChange(of: notesScrollViewportHeight) { _ in
                    if !showsNotesScrollProgress {
                        hideNotesScrollIndicatorImmediately()
                    }
                }
            }

            notes1718BottomToolbarOverlay(safeBottom: safeBottom)
        }
        .frame(width: width, height: height, alignment: .top)
        .background {
            paper1718
                .frame(width: width, height: height)
        }
        .blur(radius: longPressNotesBlurRadius)
        .animation(
            app.phoneMenuBackdropStrength > 0 && app.phoneMenuBackdropStrength < 1
                ? nil
                : .easeOut(duration: PhoneMenu1718Layout.Animation.overlayEnterDuration),
            value: app.phoneMenuBackdropStrength
        )
        .overlay {
            notes1718BackdropDimOverlay
        }
        .overlay(alignment: .trailing) {
            notesReadingProgressOverlay1718(
                cardHeight: height,
                safeTop: safeTop,
                safeBottom: safeBottom
            )
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

    private func notes1718ToolbarScrollReserve(safeBottom: CGFloat) -> CGFloat {
        let barH = NotesDesignTokens.Layout.bottomToolbarHeight
        let chromeAbove = NotesStyle1718Tokens.chromeAboveToolbar
        return chromeAbove
            + barH
            + safeBottom
            + NotesStyle1718Tokens.unifiedBottomPlateExtraDownShift
    }

    /// 1718 一体板底栏：与 classicBottomBar 同结构的可见纸底板 + 按键居中
    private func notes1718BottomToolbarOverlay(safeBottom: CGFloat) -> some View {
        let barH = NotesDesignTokens.Layout.bottomToolbarHeight
        let chromeAbove = NotesStyle1718Tokens.chromeAboveToolbar
        let plateDown = NotesStyle1718Tokens.unifiedBottomPlateExtraDownShift
        let iconBandHeight = chromeAbove + barH

        return ZStack(alignment: .bottom) {
            GeometryReader { proxy in
                let homeIndicator = max(proxy.safeAreaInsets.bottom, safeBottom)
                let plateHeight = iconBandHeight + homeIndicator + plateDown

                paper1718
                    .frame(maxWidth: .infinity)
                    .frame(height: plateHeight)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
            .ignoresSafeArea(edges: .bottom)

            ZStack {
                classicBottomBarIcons
                    .padding(.horizontal, NotesDesignTokens.Official.Nav.horizontalMargin)
            }
            .frame(height: iconBandHeight)
            .padding(.bottom, safeBottom)
        }
        .frame(height: iconBandHeight + plateDown)
        .frame(maxWidth: .infinity)
    }

    /// 与 iOS 26 composeBackdropDim 同思路：黑色遮罩压暗，避免 ignoresSafeArea 顶/底栏不吃 opacity 叠出亮层
    @ViewBuilder
    private var notes1718BackdropDimOverlay: some View {
        let amount = notes1718BackdropDimAmount
        if amount > 0.001 {
            Color.black
                .opacity(amount)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
    }

    private var notes1718BackdropDimAmount: CGFloat {
        guard app.notesStyleIOS1718, app.showIMessage || transitionProgress > 0.001 else {
            return 0
        }
        let p = min(max(transitionProgress, 0), 1)
        return p * (1 - IMessage1718DesignTokens.fromViewEndAlpha)
    }

    private var notes1718ScrollBody: some View {
        VStack(alignment: .leading, spacing: 0) {
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
                    tuning1718: app.notes1718Tuning
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
                tuning1718: app.notes1718Tuning
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
        Group {
            if app.notesStyleIOS1718 {
                app.notes1718Tuning.paperBackgroundColor()
            } else {
                IOSTheme.notesPaper
            }
        }
    }

    private var paper1718: Color {
        app.notes1718Tuning.paperBackgroundColor()
    }

    /// 1718：打开/关闭信息页动画（easeOut，时长见 messagesPresentDuration）
    private var imessageTransitionAnimation: Animation {
        if app.notesStyleIOS1718 {
            return app.showIMessage
                ? .easeOut(duration: IMessage1718DesignTokens.messagesPresentDuration)
                : .easeOut(duration: IMessage1718DesignTokens.messagesDismissDuration)
        }
        return app.showIMessage
            ? .linear(duration: IMessageDesignTokens.presentLinearDuration)
            : .spring(
                response: IMessageDesignTokens.dismissSpringResponse,
                dampingFraction: IMessageDesignTokens.dismissSpringDamping
            )
    }

    private var notes1718FromViewOpenAnimation: Animation {
        .easeOut(duration: IMessage1718DesignTokens.systemModalDuration)
    }

    private var notes1718FromViewCloseAnimation: Animation {
        .easeOut(duration: IMessage1718DesignTokens.fromViewDismissDuration)
    }

    private var notes1718MessagesOpenAnimation: Animation {
        .easeOut(duration: IMessage1718DesignTokens.messagesPresentDuration)
    }

    private var notes1718MessagesCloseAnimation: Animation {
        .easeOut(duration: IMessage1718DesignTokens.messagesDismissDuration)
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
                if !app.notesStyleIOS1718 {
                    Text(NoteDateFormatting.string(from: noteDisplayedDate))
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
                        usesIOS1718Style: app.notesStyleIOS1718,
                        tuning1718: app.notes1718Tuning,
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
                    usesIOS1718Style: app.notesStyleIOS1718,
                    tuning1718: app.notes1718Tuning,
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
            .trackNotesScrollContentMetrics()
        }
        .trackNotesScrollMetrics(
            offsetY: $notesScrollOffsetY,
            contentHeight: $notesScrollContentHeight,
            viewportHeight: $notesScrollViewportHeight
        )
        .onChange(of: notesScrollOffsetY) { _ in
            noteScrollIndicatorDidScroll()
        }
        .onChange(of: notesScrollContentHeight) { _ in
            if !showsNotesScrollProgress {
                hideNotesScrollIndicatorImmediately()
            }
        }
        .onChange(of: notesScrollViewportHeight) { _ in
            if !showsNotesScrollProgress {
                hideNotesScrollIndicatorImmediately()
            }
        }
        .overlay(alignment: .top) {
            if !app.notesStyleIOS1718 {
                NotesTopGlassFade()
                    .allowsHitTesting(false)
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            navBar
        }
        .overlay(alignment: .bottom) {
            bottomBar
                .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .overlay(alignment: .trailing) {
            notesReadingProgressOverlay
        }
        .sheet(isPresented: $showTuningPanel) {
            if app.notesStyleIOS1718 {
                Notes1718TuningPanel(settings: $app.notes1718Tuning)
            } else {
                Notes26TuningPanel(settings: $app.notes26Tuning)
            }
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
        .onAppear {
            noteDisplayedDate = Date()
        }
        .onChange(of: app.noteTitle) { _ in touchNoteDate() }
        .onChange(of: app.noteBody) { _ in touchNoteDate() }
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
        if app.notesStyleIOS1718, app.phoneMenuPresentation == .longPress {
            return phone
        }
        if app.notesStyleIOS1718 { return nil }
        return phone
    }

    /// 长按时糊正文/顶栏/底栏，纸面背景保持清晰
    private var longPressNotesBlurRadius: CGFloat {
        guard app.notesStyleIOS1718,
              app.showPhoneMenu,
              app.phoneMenuPresentation == .longPress else { return 0 }
        return CGFloat(app.notes1718Tuning.longPressTextBlurRadius) * CGFloat(app.phoneMenuBackdropStrength)
    }

    private func touchNoteDate() {
        noteDisplayedDate = Date()
    }

    private var notesScrollProgress: CGFloat {
        let maxScroll = max(notesScrollContentHeight - notesScrollViewportHeight, 1)
        return min(max(notesScrollOffsetY / maxScroll, 0), 1)
    }

    private var showsNotesScrollProgress: Bool {
        notesScrollViewportHeight > 0
            && notesScrollContentHeight > notesScrollViewportHeight + 1
    }

    @ViewBuilder
    private var notesReadingProgressOverlay: some View {
        if showsNotesScrollProgress {
            GeometryReader { geo in
                let bounds = NotesReadingProgressTrackBounds.ios26(
                    safeAreaInsets: geo.safeAreaInsets,
                    containerHeight: geo.size.height
                )

                NotesReadingProgressOverlay(
                    progress: notesScrollProgress,
                    trackHeight: bounds.height,
                    viewportHeight: notesScrollViewportHeight,
                    contentHeight: notesScrollContentHeight,
                    isVisible: notesScrollIndicatorVisible
                )
                .padding(.top, bounds.top)
                .padding(.bottom, bounds.bottom)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            }
        }
    }

    @ViewBuilder
    private func notesReadingProgressOverlay1718(
        cardHeight: CGFloat,
        safeTop: CGFloat,
        safeBottom: CGFloat
    ) -> some View {
        if showsNotesScrollProgress {
            let bounds = NotesReadingProgressTrackBounds.ios1718(
                safeTop: safeTop,
                safeBottom: safeBottom,
                containerHeight: cardHeight
            )

            NotesReadingProgressOverlay(
                progress: notesScrollProgress,
                trackHeight: bounds.height,
                viewportHeight: notesScrollViewportHeight,
                contentHeight: notesScrollContentHeight,
                isVisible: notesScrollIndicatorVisible
            )
            .padding(.top, bounds.top)
            .padding(.bottom, bounds.bottom)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        }
    }

    private func noteScrollIndicatorDidScroll() {
        guard showsNotesScrollProgress else { return }
        notesScrollIndicatorHideTask?.cancel()

        if !notesScrollIndicatorVisible {
            withAnimation(.easeOut(duration: NotesDesignTokens.ReadingProgress.revealFadeDuration)) {
                notesScrollIndicatorVisible = true
            }
        }

        let delay = NotesDesignTokens.ReadingProgress.autoHideDelay
        notesScrollIndicatorHideTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: NotesDesignTokens.ReadingProgress.hideFadeDuration)) {
                notesScrollIndicatorVisible = false
            }
        }
    }

    private func hideNotesScrollIndicatorImmediately() {
        notesScrollIndicatorHideTask?.cancel()
        notesScrollIndicatorHideTask = nil
        notesScrollIndicatorVisible = false
    }

    /// 为底栏预留滚动空间（底栏 overlay 固定屏幕底部，不随键盘上移）
    private var bottomToolbarReserve: CGFloat {
        let barH = NotesDesignTokens.Layout.bottomToolbarHeight
        let gap = NotesDesignTokens.Official.Toolbar.bottomSafeGap
        if app.notesStyleIOS1718 {
            return barH
                + NotesStyle1718Tokens.toolbarExtraDownShift
                + NotesStyle1718Tokens.chromeAboveToolbar
                + gap
                + bottomSafeInset
        }
        return barH + gap + bottomSafeInset
    }

    private var navBar: some View {
        Group {
            if app.notesStyleIOS1718 {
                classicTopBar
            } else {
                modernNavBar
                    .padding(.horizontal, NotesDesignTokens.Official.Nav.horizontalMargin)
                    .frame(height: NotesDesignTokens.Layout.navBarHeight)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var classicTopBar: some View {
        let navH = NotesDesignTokens.Layout.navBarHeight
        let chromeBelow = NotesStyle1718Tokens.chromeBelowNav

        return ZStack(alignment: .top) {
            GeometryReader { proxy in
                let safeTop = resolvedStatusBarTop(fallback: proxy.safeAreaInsets.top)
                let plateHeight = safeTop + navH + chromeBelow

                paper1718
                    .frame(maxWidth: .infinity)
                    .frame(height: plateHeight)
                    .offset(y: -safeTop)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .ignoresSafeArea(edges: .top)

            classicNavBar
                .padding(.horizontal, NotesDesignTokens.Official.Nav.horizontalMargin)
                .frame(height: navH)
                .frame(maxWidth: .infinity)
        }
        .frame(height: navH + chromeBelow)
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

    private var classicNavBar: some View {
        HStack(alignment: .center, spacing: 0) {
            NotesClassicBackButton {
                app.leaveNotesToSettings()
                closeIMessage()
            }

            Spacer(minLength: 0)

            HStack(spacing: NotesStyle1718Tokens.navTrailingSpacing) {
                NotesClassicIconButton(systemName: NotesStyle1718Tokens.navTrailingIcons[0]) {
                    showTextImporter = true
                }
                NotesClassicIconButton(systemName: NotesStyle1718Tokens.navTrailingIcons[1]) {
                    KeyboardDismiss.resign()
                }
            }
        }
    }

    private var bottomBar: some View {
        Group {
            if app.notesStyleIOS1718 {
                classicBottomBar
            } else {
                modernBottomBar
                    .padding(.horizontal, NotesDesignTokens.Official.Nav.horizontalMargin)
                    .padding(.bottom, NotesDesignTokens.Official.Toolbar.bottomSafeGap)
                    .frame(height: NotesDesignTokens.Layout.bottomToolbarHeight)
                    .frame(maxWidth: .infinity)
            }
        }
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

    private var classicBottomBarIcons: some View {
        HStack(spacing: 0) {
            NotesClassicIconButton(
                systemName: NotesStyle1718Tokens.toolbarChecklistIcon,
                iconSize: NotesStyle1718Tokens.toolbarIconSize
            ) {
                showTuningPanel = true
            }

            Spacer(minLength: 0)

            NotesClassicIconButton(
                systemName: NotesStyle1718Tokens.toolbarCameraIcon,
                iconSize: NotesStyle1718Tokens.toolbarIconSize
            ) {}

            Spacer(minLength: 0)

            NotesClassicIconButton(
                systemName: NotesStyle1718Tokens.toolbarMarkupIcon,
                iconSize: NotesStyle1718Tokens.toolbarIconSize
            ) {}

            Spacer(minLength: 0)

            NotesClassicIconButton(
                systemName: NotesStyle1718Tokens.toolbarComposeIcon,
                iconSize: NotesStyle1718Tokens.toolbarIconSize
            ) {}
        }
    }

    private var classicBottomBar: some View {
        let down = NotesStyle1718Tokens.toolbarExtraDownShift
        let bottomGap = NotesDesignTokens.Official.Toolbar.bottomSafeGap
        let barH = NotesDesignTokens.Layout.bottomToolbarHeight
        let chromeAbove = NotesStyle1718Tokens.chromeAboveToolbar

        return ZStack(alignment: .bottom) {
            GeometryReader { proxy in
                let homeIndicator = proxy.safeAreaInsets.bottom
                let plateHeight = chromeAbove + barH + down + homeIndicator

                paper1718
                    .frame(maxWidth: .infinity)
                    .frame(height: plateHeight)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
            .ignoresSafeArea(edges: .bottom)

            classicBottomBarIcons
                .padding(.horizontal, NotesDesignTokens.Official.Nav.horizontalMargin)
                .padding(.bottom, bottomGap)
                .offset(y: down)
        }
        .frame(height: barH + down)
        .frame(maxWidth: .infinity)
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
        if app.notesStyleIOS1718 {
            ComposeThread1718PinWarmup.refresh(app: app)
            withAnimation(.easeIn(duration: IMessage1718DesignTokens.phoneMenuFadeOutDuration)) {
                app.showPhoneMenu = false
                app.phoneMenuBackdropStrength = 0
            }
            withAnimation(notes1718FromViewOpenAnimation) {
                transitionProgress = 1
            }
            withAnimation(notes1718MessagesOpenAnimation) {
                app.showIMessage = true
            }
        } else {
            app.showPhoneMenu = false
            app.showIMessage = true
        }
    }

    private func closeIMessage() {
        if app.notesStyleIOS1718 {
            withAnimation(notes1718MessagesCloseAnimation) {
                app.showIMessage = false
            }
            withAnimation(notes1718FromViewCloseAnimation) {
                transitionProgress = 0
            }
        } else {
            app.showIMessage = false
        }
    }
}
