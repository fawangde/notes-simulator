import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct NotesView: View {
    @EnvironmentObject private var app: AppState
    @State private var showTextImporter = false
    @State private var rootFrameGlobal: CGRect = .zero
    @State private var frozenMenuAnchor: CGRect = .zero
    @State private var noteDisplayedDate = Date()
    var body: some View {
        ZStack {
            notesLayer

            if app.showPhoneMenu, let phone = app.selectedPhone {
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

            if app.showIMessage {
                NewIMessageView(onClose: closeIMessage)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
                    .transition(.move(edge: .bottom))
                    .zIndex(30)
            }
        }
        .animation(imessageTransitionAnimation, value: app.showIMessage)
        .animation(.spring(response: 0.48, dampingFraction: 0.82), value: app.showPhoneMenu)
        .alert("请先激活 App", isPresented: $app.showActivationRequiredAlert) {
            Button("好", role: .cancel) {}
        }
        .onChange(of: app.isActivated) { active in
            if !active {
                app.showPhoneMenu = false
                app.showIMessage = false
                if app.activationMode == .clicks {
                    app.leaveNotesToSettings()
                }
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

    /// 备忘录主页：点「信息」后整体压暗，关闭信息页恢复（压暗不放在撰写页内，避免随底板滑动）
    private var notesLayer: some View {
        notesContent
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

    private var notesPaperBackground: some View {
        Group {
            if app.notesStyleIOS1718 {
                NotesStyle1718Tokens.paperBackground
            } else {
                IOSTheme.notesPaper
            }
        }
    }

    /// 上弹匀速；下收保持原弹簧
    private var imessageTransitionAnimation: Animation {
        app.showIMessage
            ? .linear(duration: IMessageDesignTokens.presentLinearDuration)
            : .spring(
                response: IMessageDesignTokens.dismissSpringResponse,
                dampingFraction: IMessageDesignTokens.dismissSpringDamping
            )
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
                        usesIOS1718Style: app.notesStyleIOS1718
                    )
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, NotesDesignTokens.Layout.titlePhoneAlignedLeadingInset)
                .padding(.trailing, NotesDesignTokens.Layout.titlePhoneAlignedTrailingInset)
                .padding(.bottom, NotesDesignTokens.Layout.titleToBodyGap)

                NotesBodyEditor(
                    text: $app.noteBody,
                    hiddenPhone: app.showPhoneMenu ? app.selectedPhone : nil
                ) { phone, windowRect in
                    guard app.canUseSimulationFeatures else {
                        app.presentActivationRequired()
                        return
                    }
                    app.selectedPhone = phone
                    app.phoneMenuAnchor = windowRect
                    frozenMenuAnchor = localAnchor(windowRect)
                    withAnimation(.spring(response: 0.48, dampingFraction: 0.82)) {
                        app.showPhoneMenu = true
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, NotesDesignTokens.Layout.contentInset)
            .padding(.top, 6)
            .padding(.bottom, 8)
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
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomBar
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

    private func touchNoteDate() {
        noteDisplayedDate = Date()
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
                // 底板贴屏幕最顶；下缘到导航栏下方 chromeBelow（与底栏对称）
                let plateHeight = safeTop + navH + chromeBelow

                NotesStyle1718Tokens.paperBackground
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
                .background(NotesStyle1718Tokens.paperBackground)
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
                weight: NotesDesignTokens.Official.Toolbar.iconWeight
            )

            Spacer(minLength: 0)

            NotesGlassCircleButton(
                systemName: NotesDesignTokens.Official.Toolbar.composeIcon,
                iconSize: NotesDesignTokens.Official.Toolbar.iconSize,
                weight: NotesDesignTokens.Official.Toolbar.iconWeight
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
                // 底板贴屏幕最底；上缘仅到图标上方 chromeAbove，不随图标 offset
                let plateHeight = chromeAbove + barH + down + homeIndicator

                NotesStyle1718Tokens.paperBackground
                    .frame(maxWidth: .infinity)
                    .frame(height: plateHeight)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
            .ignoresSafeArea(edges: .bottom)

            HStack(alignment: .center) {
                HStack(spacing: NotesStyle1718Tokens.toolbarSpacing) {
                    NotesClassicIconButton(
                        systemName: NotesStyle1718Tokens.toolbarChecklistIcon,
                        iconSize: NotesStyle1718Tokens.toolbarIconSize
                    ) {}
                    NotesClassicIconButton(
                        systemName: NotesStyle1718Tokens.toolbarCameraIcon,
                        iconSize: NotesStyle1718Tokens.toolbarIconSize
                    ) {}
                    NotesClassicIconButton(
                        systemName: NotesStyle1718Tokens.toolbarMarkupIcon,
                        iconSize: NotesStyle1718Tokens.toolbarIconSize
                    ) {}
                }

                Spacer(minLength: 0)

                NotesClassicIconButton(
                    systemName: NotesStyle1718Tokens.toolbarComposeIcon,
                    iconSize: NotesStyle1718Tokens.toolbarIconSize
                ) {}
            }
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

    private var keyWindow: UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }
    }

    private func openIMessage() {
        guard app.canUseSimulationFeatures else {
            app.presentActivationRequired()
            return
        }
        app.showPhoneMenu = false
        app.showIMessage = true
    }

    private func closeIMessage() {
        app.showIMessage = false
    }
}
