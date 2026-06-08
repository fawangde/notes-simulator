import SwiftUI
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
                IOSTheme.notesPaper
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
                Text(NoteDateFormatting.string(from: noteDisplayedDate))
                    .font(NotesDesignTokens.Layout.dateFont)
                    .foregroundStyle(IOSTheme.labelSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 10)

                ZStack(alignment: .topLeading) {
                    if app.noteTitle.isEmpty {
                        Text("标题")
                            .font(IOSTheme.titleFont)
                            .foregroundStyle(IOSTheme.labelTertiary)
                    }
                    TextField("", text: $app.noteTitle, axis: .vertical)
                        .font(IOSTheme.titleFont)
                        .foregroundStyle(IOSTheme.labelPrimary)
                }
                .padding(.bottom, NotesDesignTokens.Layout.titleToBodyGap)

                NotesBodyEditor(
                    text: $app.noteBody,
                    hiddenPhone: app.showPhoneMenu ? app.selectedPhone : nil
                ) { phone, windowRect in
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
            NotesTopGlassFade()
                .allowsHitTesting(false)
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
        HStack(alignment: .center) {
            NotesGlassCircleButton(
                systemName: NotesDesignTokens.Official.Nav.backIcon,
                weight: NotesDesignTokens.Official.Nav.iconWeight
            ) {
                app.screen = .home
                app.showPhoneMenu = false
                app.showIMessage = false
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
        .padding(.horizontal, NotesDesignTokens.Official.Nav.horizontalMargin)
        .frame(height: NotesDesignTokens.Layout.navBarHeight)
        .frame(maxWidth: .infinity)
    }

    private var bottomBar: some View {
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
        .padding(.horizontal, NotesDesignTokens.Official.Nav.horizontalMargin)
        .padding(.bottom, NotesDesignTokens.Official.Toolbar.bottomSafeGap)
        .frame(height: NotesDesignTokens.Layout.bottomToolbarHeight)
        .frame(maxWidth: .infinity)
    }

    private func openIMessage() {
        app.showPhoneMenu = false
        app.showIMessage = true
    }

    private func closeIMessage() {
        app.showIMessage = false
    }
}
