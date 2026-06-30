import SwiftUI

/// 撰写页：第1层白底（冻结）+ 第2层气泡文案 + 第3层导航/收发件人/底栏 + 系统键盘
struct NewIMessageView: View {
    @EnvironmentObject private var app: AppState
    let onClose: () -> Void

    @State private var composerText = ""
    @State private var composerFocused = true
    @State private var keyboardTopInset: CGFloat = 0
    @State private var showBubbleTuningPanel = false

    private var recipient: String {
        guard let phone = app.selectedPhone else { return "" }
        return PhoneUtilities.formatIMessage(phone)
    }

    private var composeChrome: IOS26ComposeChromeStyle {
        app.ios26ComposeChromeStyle
    }

    private var navTitleText: String {
        composeChrome == .greenSMS ? "新信息" : "新 iMessage 信息"
    }

    private var recipientPhoneColor: Color {
        composeChrome == .greenSMS
            ? IMessageDesignTokens.smsGreenTint
            : IMessageDesignTokens.recipientPhoneTint
    }

    private var recipientCapsuleBackground: Color {
        composeChrome == .greenSMS
            ? IMessageDesignTokens.smsRecipientCapsuleFill
            : IMessageDesignTokens.recipientCapsuleFill
    }

    private var senderLabelColor: Color {
        composeChrome == .greenSMS
            ? IMessageDesignTokens.smsGreenTint
            : IMessageDesignTokens.navTint
    }

    private var senderBadgeForeground: Color {
        composeChrome == .greenSMS
            ? IMessageDesignTokens.smsSenderBadgeTextColor
            : IMessageDesignTokens.senderBadgeTextColor
    }

    private var senderBadgeBackgroundColor: Color {
        composeChrome == .greenSMS
            ? IMessageDesignTokens.smsSenderBadgeBackground
            : IMessageDesignTokens.senderBadgeBackground
    }

    var body: some View {
        GeometryReader { geo in
            let topGap = resolvedTopGap(fallback: geo.safeAreaInsets.top)
            let cornerRadius = IMessageDesignTokens.layer1CornerRadius

            ZStack(alignment: .top) {
                // 第 1 层：顶区透明露出已压暗的备忘录，其下为白底圆角卡片
                VStack(spacing: 0) {
                    Color.clear
                        .frame(height: topGap)
                        .contentShape(Rectangle())
                        .gesture(dismissGesture)

                    IMessageDesignTokens.layer1Background
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipShape(TopRoundedRectangle(radius: cornerRadius))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .ignoresSafeArea(edges: .bottom)

                // 第 2 + 3 层
                VStack(spacing: 0) {
                    Color.clear
                        .frame(height: topGap)
                        .allowsHitTesting(false)

                    composeLayers
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipShape(TopRoundedRectangle(radius: cornerRadius))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                composerBar
                    .zIndex(100)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
        .ignoresSafeArea()
        .onAppear { composerFocused = true }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { note in
            updateKeyboardTopInset(from: note)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            keyboardTopInset = 0
        }
        .onDisappear {
            composerFocused = false
            keyboardTopInset = 0
            KeyboardDismiss.resign()
        }
        .sheet(isPresented: $showBubbleTuningPanel) {
            IOS26ComposeTuningSheet(bubbleTextSettings: $app.composeBubbleTuning)
        }
        .onChange(of: showBubbleTuningPanel) { isOpen in
            if isOpen {
                composerFocused = false
                KeyboardDismiss.resign()
            } else {
                composerFocused = true
            }
        }
    }

    /// ignoresSafeArea 后 GeometryReader 的 safeAreaInsets 常为 0，改读 keyWindow
    private func resolvedTopGap(fallback: CGFloat) -> CGFloat {
        let windowTop = keyWindow?.safeAreaInsets.top ?? 0
        return max(fallback, windowTop, IMessageDesignTokens.layer1TopInset)
    }

    private var composerBar: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
                .allowsHitTesting(false)
            MessagesComposerHost(
                text: $composerText,
                wantsFocus: composerFocused,
                chromeStyle: composeChrome,
                onPlusTap: { showBubbleTuningPanel = true }
            )
            .frame(height: IMessageDesignTokens.layer3ToolbarHeight)
            .padding(.horizontal, 6)
            .offset(
                x: IMessageDesignTokens.layer3ToolbarOffsetX,
                y: IMessageDesignTokens.layer3ToolbarOffsetY + IMessageDesignTokens.layer3KeyboardOffsetY
            )
            .padding(.bottom, composerBottomPadding)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var composeLayers: some View {
        ZStack(alignment: .top) {
            ComposeThreadBackdropHost(
                chromeBottomY: IMessageDesignTokens.addressChromeBottom(
                    showsSenderRow: app.simCardMode == .dual
                ),
                composerBottomReserve: composerBottomReserve,
                dateLine: app.threadDateLine,
                showsIOS264ThreadHeader: app.threadHeaderStyleIOS264,
                isBlankThread: app.isIOS26BlankThreadForSelectedPhone,
                composeChromeStyle: app.ios26ComposeChromeStyle,
                messageText: app.messagePreviewText,
                showsText: app.composeShowsMessageText,
                showsImage: app.composeShowsMessageImage,
                bothContentOrder: app.bothContentOrder,
                image: app.messageDisplayImage,
                senderLineLabel: app.senderLineLabel,
                showsSenderRow: app.simCardMode == .dual,
                bubbleFontSize: CGFloat(app.composeBubbleTuning.fontSize),
                messageLinkUnderlineHidden: app.messageLinkUnderlineHidden
            )
            .id(
                "\(app.mode.rawValue)|\(app.bothContentOrder.rawValue)|"
                    + "\(app.simCardMode.rawValue)|\(app.senderLineLabel)|"
                    + "\(app.messagePreviewText)|\(app.composeShowsMessageText)|"
                    + "\(app.composeShowsMessageImage)|\(app.threadDateLine)|"
                    + "\(app.threadHeaderStyleIOS264)|\(app.isIOS26BlankThreadForSelectedPhone)|"
                    + "\(app.ios26ComposeChromeStyle)"
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            topNavGlassEffect

            composeChromeOverlay
                .allowsHitTesting(false)
        }
        .overlay(alignment: .topTrailing) {
            closeButton
        }
    }

    /// 顶栏：系统玻璃穿透压暗（非镜面截图），底边渐隐
    private var topNavGlassEffect: some View {
        ComposeAddressGlassBackground(
            cornerRadius: 0,
            renderMode: .topPenetrate
        )
        .frame(height: IMessageDesignTokens.topNavGlassHeight)
        .frame(maxWidth: .infinity, alignment: .top)
        .mask(topNavGlassFadeMask)
        .allowsHitTesting(false)
    }

    private var topNavGlassFadeMask: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: .black, location: 0),
                .init(color: .black.opacity(0.98), location: 0.42),
                .init(color: .black.opacity(0.72), location: 0.72),
                .init(color: .black.opacity(0.28), location: 0.9),
                .init(color: .clear, location: 1),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// 导航 + 收发件人（仅展示，不挡聊天区手势）
    private var composeChromeOverlay: some View {
        VStack(spacing: 0) {
            navigationBarTitle
                .offset(
                    x: IMessageDesignTokens.layer3NavOffsetX,
                    y: IMessageDesignTokens.layer3NavOffsetY
                )

            addressSection
                .offset(
                    x: IMessageDesignTokens.layer3AddressOffsetX,
                    y: IMessageDesignTokens.layer3AddressOffsetY
                )
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }

    /// 底栏 + 键盘 +「已送达」距输入框 5pt
    private var composerBottomReserve: CGFloat {
        let toolbarBlock = IMessageDesignTokens.layer3ToolbarHeight
            + IMessageDesignTokens.layer3ToolbarOffsetY
            + IMessageDesignTokens.layer3KeyboardOffsetY
            + 12
        return toolbarBlock
            + composerBottomPadding
            + IMessageDesignTokens.threadDeliveredAboveInput
    }

    private var navigationBarTitle: some View {
        Text(navTitleText)
            .font(IMessageDesignTokens.navTitleFont)
            .foregroundStyle(IOSTheme.labelPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: IMessageDesignTokens.layer3NavHeight)
    }

    private var closeButton: some View {
        Button(action: close) {
            Image(systemName: "xmark")
                .font(.system(size: IMessageDesignTokens.navCloseIconSize, weight: .bold))
                .foregroundStyle(IOSTheme.labelPrimary)
                .frame(
                    width: IMessageDesignTokens.layer3CloseSize,
                    height: IMessageDesignTokens.layer3CloseSize
                )
                .background {
                    ComposeAddressGlassBackground(
                        cornerRadius: IMessageDesignTokens.layer3CloseSize / 2,
                        renderMode: .chromeClose,
                        borderEmphasis: IMessageDesignTokens.chromeCloseBorderEmphasis,
                        showsLiftShadow: true
                    )
                }
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: IMessageDesignTokens.layer3CloseSize / 2,
                        style: .continuous
                    )
                )
        }
        .padding(.top, IMessageDesignTokens.layer3NavOffsetY
            + (IMessageDesignTokens.layer3NavHeight - IMessageDesignTokens.layer3CloseSize) / 2)
        .padding(.trailing, IMessageDesignTokens.layer3CloseTrailingPadding)
        .offset(x: IMessageDesignTokens.layer3CloseOffsetX)
    }

    private var addressSection: some View {
        VStack(spacing: 0) {
            addressRow(centeredVertically: app.simCardMode == .single) {
                Text("收件人：")
                    .font(IMessageDesignTokens.addressLabelFont)
                    .foregroundStyle(IMessageDesignTokens.addressLabelColor)
                Text(recipient)
                    .font(IMessageDesignTokens.addressLabelFont)
                    .foregroundStyle(recipientPhoneColor)
                    .padding(.horizontal, IMessageDesignTokens.recipientCapsuleHPadding)
                    .padding(.vertical, IMessageDesignTokens.recipientCapsuleVPadding)
                    .background(recipientCapsuleBackground)
                    .clipShape(Capsule())
                Spacer(minLength: 0)
            }

            if app.simCardMode == .dual {
                MessagesComposeHairline()
                senderAddressRow
            }
        }
        .background {
            ComposeAddressGlassBackground(
                cornerRadius: IMessageDesignTokens.layer3AddressCardRadius
            )
        }
        .padding(.horizontal, IMessageDesignTokens.layer3AddressCardHPadding)
        .padding(.top, IMessageDesignTokens.layer3AddressCardTop)
        .padding(.bottom, 6)
        .shadow(
            color: .black.opacity(IMessageDesignTokens.addressGlassLiftShadowOpacity),
            radius: IMessageDesignTokens.addressGlassLiftShadowRadius,
            y: IMessageDesignTokens.addressGlassLiftShadowY
        )
    }

    private func addressRow(
        centeredVertically: Bool = false,
        @ViewBuilder content: () -> some View
    ) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, IMessageDesignTokens.addressLeadingInset)
        .padding(.trailing, IMessageDesignTokens.addressLeadingInset)
        .modifier(AddressRowVerticalLayout(centered: centeredVertically))
    }

    private var senderAddressRow: some View {
        HStack(alignment: .center, spacing: 4) {
            Text("发件人：")
                .font(IMessageDesignTokens.addressLabelFont)
                .foregroundStyle(IMessageDesignTokens.addressLabelColor)
            senderBadge
            Text(senderLineLabel)
                .font(IMessageDesignTokens.addressLabelFont)
                .foregroundStyle(senderLabelColor)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: IMessageDesignTokens.layer3AddressRowHeight, alignment: .top)
        .padding(.leading, IMessageDesignTokens.addressLeadingInset)
        .padding(.trailing, IMessageDesignTokens.addressLeadingInset)
        .padding(.top, IMessageDesignTokens.addressLabelTopInset)
    }

    private var senderLineLabel: String {
        let trimmed = app.senderLineLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "副号" : trimmed
    }

    private var senderBadgeText: String {
        let label = senderLineLabel
        if label.count <= 2 { return label }
        return String(label.prefix(2))
    }

    private var senderBadge: some View {
        Text(senderBadgeText)
            .font(.system(size: IMessageDesignTokens.senderBadgeFontSize, weight: .regular))
            .foregroundStyle(senderBadgeForeground)
            .padding(.horizontal, IMessageDesignTokens.senderBadgeHPadding)
            .padding(.vertical, IMessageDesignTokens.senderBadgeVPadding)
            .background(senderBadgeBackgroundColor)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: IMessageDesignTokens.senderBadgeCornerRadius,
                    style: .continuous
                )
            )
    }

    private var composerBottomPadding: CGFloat {
        let gap = IMessageDesignTokens.layer3KeyboardGap
        if keyboardTopInset > 0 {
            return keyboardTopInset + gap
        }
        return keyWindow?.safeAreaInsets.bottom ?? 0
    }

    private func updateKeyboardTopInset(from note: Notification) {
        guard
            let frame = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
            let window = keyWindow
        else { return }
        let keyboardFrame = window.convert(frame, from: nil)
        let overlap = max(0, window.bounds.maxY - keyboardFrame.minY)
        keyboardTopInset = overlap > 1 ? overlap : 0
    }

    private var keyWindow: UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)
    }

    private func close() {
        composerFocused = false
        KeyboardDismiss.resign()
        onClose()
    }

    private struct AddressRowVerticalLayout: ViewModifier {
        let centered: Bool

        func body(content: Content) -> some View {
            if centered {
                content
                    .frame(
                        height: IMessageDesignTokens.singleCardAddressInnerHeight,
                        alignment: .center
                    )
            } else {
                content
                    .frame(
                        height: IMessageDesignTokens.layer3AddressRowHeight,
                        alignment: .top
                    )
                    .padding(.top, IMessageDesignTokens.addressLabelTopInset)
            }
        }
    }

    private var dismissGesture: some Gesture {
        DragGesture(minimumDistance: 30)
            .onEnded { value in
                guard value.translation.height > 60 else { return }
                close()
            }
    }
}
