import SwiftUI

/// iOS 17–18 撰写页：扁平导航/收发件人/底栏 + 系统键盘 + 金色光标
struct NewIMessageView18: View {
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

    private var composeChrome: IOS18ComposeChromeStyle {
        app.ios18ComposeChromeStyle
    }

    private var navTitleText: String {
        composeChrome == .greenSMS ? "新信息" : "新 iMessage 信息"
    }

    private var recipientPhoneColor: Color {
        composeChrome == .greenSMS
            ? IMessage18DesignTokens.smsGreenTint
            : IMessage18DesignTokens.recipientPhoneTint
    }

    private var recipientCapsuleBackground: Color {
        composeChrome == .greenSMS
            ? IMessage18DesignTokens.smsRecipientCapsuleFill
            : IMessage18DesignTokens.recipientCapsuleFill
    }

    private var senderLabelColor: Color {
        composeChrome == .greenSMS
            ? IMessage18DesignTokens.smsGreenTint
            : IMessage18DesignTokens.senderLineTint
    }

    private var senderBadgeForeground: Color {
        composeChrome == .greenSMS
            ? IMessage18DesignTokens.smsSenderBadgeTextColor
            : IMessage18DesignTokens.senderBadgeTextColor
    }

    private var senderBadgeBackgroundColor: Color {
        composeChrome == .greenSMS
            ? IMessage18DesignTokens.smsSenderBadgeBackground
            : IMessage18DesignTokens.senderBadgeBackground
    }

    var body: some View {
        GeometryReader { geo in
            let topGap = resolvedTopGap(fallback: geo.safeAreaInsets.top)
            let cornerRadius = IMessage18DesignTokens.layer1CornerRadius

            ZStack(alignment: .top) {
                VStack(spacing: 0) {
                    Color.clear
                        .frame(height: topGap)
                        .contentShape(Rectangle())
                        .gesture(dismissGesture)

                    IMessage18DesignTokens.layer1Background
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipShape(TopRoundedRectangle(radius: cornerRadius))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .ignoresSafeArea(edges: .bottom)

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

                ComposeThreadPinDebugOverlay1718()
                    .zIndex(200)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
        .ignoresSafeArea()
        .onAppear {
            ComposeThread1718Session.isClosing = false
            composerFocused = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { note in
            updateKeyboardTopInset(from: note)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            keyboardTopInset = 0
        }
        .onChange(of: keyboardTopInset) { inset in
            guard inset > 0 else { return }
            ComposeThread18PinWarmup.refresh(app: app, keyboardTopInset: inset)
        }
        .onDisappear {
            composerFocused = false
            keyboardTopInset = 0
            KeyboardDismiss.resign()
        }
        .sheet(isPresented: $showBubbleTuningPanel) {
            ComposeBubbleTuningPanel(settings: $app.composeBubbleTuning)
        }
    }

    /// ignoresSafeArea 后 GeometryReader 的 safeAreaInsets 常为 0，改读 keyWindow
    private func resolvedTopGap(fallback: CGFloat) -> CGFloat {
        let windowTop = keyWindow?.safeAreaInsets.top ?? 0
        let safeTop = max(fallback, windowTop)
        return IMessage18DesignTokens.composeSheetTopInset(safeAreaTop: safeTop)
    }

    private var composerBar: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
                .allowsHitTesting(false)
            MessagesComposerHost1718(
                text: $composerText,
                wantsFocus: composerFocused,
                chromeStyle: composeChrome,
                onPlusTap: { showBubbleTuningPanel = true }
            )
                .frame(height: IMessage18DesignTokens.layer3ToolbarHeight)
                .padding(.horizontal, 6)
                .offset(
                    x: 0,
                    y: IMessage18DesignTokens.layer3ToolbarOffsetY + IMessage18DesignTokens.layer3KeyboardOffsetY
                )
                .padding(.bottom, composerBottomPadding)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var composeLayers: some View {
        ZStack(alignment: .top) {
            ComposeThreadBackdropHost1718(
                chromeBottomY: IMessage18DesignTokens.addressChromeBottom(
                    showsSenderRow: app.simCardMode == .dual
                ),
                composerBottomReserve: composerBottomReserve,
                dateLine: app.threadDateLine,
                isBlankThread: app.isIOS18BlankThreadForSelectedPhone,
                messageText: app.messagePreviewText,
                showsText: app.composeShowsMessageText,
                showsImage: app.composeShowsMessageImage,
                bothContentOrder: app.bothContentOrder,
                image: app.messageImage,
                senderLineLabel: app.senderLineLabel,
                showsSenderRow: app.simCardMode == .dual,
                bubbleTailParams: IMessage18BubbleTailPreset.resolvedParams(
                    presetID: app.notes18Tuning.bubbleTailPresetID,
                    tuning: app.notes18Tuning
                ),
                bubbleFontSize: CGFloat(app.composeBubbleTuning.fontSize)
            )
            .id(
                "\(app.mode.rawValue)|\(app.bothContentOrder.rawValue)|"
                    + "\(app.simCardMode.rawValue)|\(app.senderLineLabel)|"
                    + "\(app.composeShowsMessageText)|\(app.composeShowsMessageImage)|"
                    + "\(app.notes18Tuning.bubbleTailPresetID)|18|"
                    + "\(app.isIOS18BlankThreadForSelectedPhone)|\(app.ios18ComposeChromeStyle)"
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            composeChromeOverlay
        }
    }

    private var composeChromeOverlay: some View {
        VStack(spacing: 0) {
            navigationBar
            navRecipientDivider
            addressSection
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private var navRecipientDivider: some View {
        Rectangle()
            .fill(IMessage18DesignTokens.navRecipientDividerColor)
            .frame(height: IMessage18DesignTokens.addressSeparatorHeight)
            .frame(maxWidth: .infinity)
    }

    private var navigationBar: some View {
        ZStack(alignment: .top) {
            IMessage18DesignTokens.navBarBackground
                .frame(maxWidth: .infinity)
                .frame(height: IMessage18DesignTokens.navBarHeight)

            ZStack {
                Text(navTitleText)
                    .font(IMessage18DesignTokens.navTitleFont)
                    .tracking(IMessage18DesignTokens.navTitleTracking)
                    .foregroundStyle(Color.primary)
                HStack {
                    Spacer(minLength: 0)
                    Button(action: close) {
                        Text("取消")
                            .font(IMessage18DesignTokens.navCancelFont)
                            .foregroundStyle(IMessage18DesignTokens.navCancelColor)
                    }
                    .buttonStyle(.plain)
                    .simultaneousGesture(
                        LongPressGesture(minimumDuration: 0.6).onEnded { _ in
                            ComposeThreadPinDebug1718.shared.isEnabled.toggle()
                        }
                    )
                    .padding(.trailing, IMessage18DesignTokens.navCancelTrailingPadding)
                }
            }
            .frame(height: IMessage18DesignTokens.navBarBaseHeight)
            .offset(y: IMessage18DesignTokens.navBarContentOffsetY)
        }
        .frame(height: IMessage18DesignTokens.navBarHeight)
    }

    private var addressSection: some View {
        VStack(spacing: 0) {
            addressRow {
                Text("收件人：")
                    .font(IMessage18DesignTokens.addressLabelFont)
                    .foregroundStyle(IMessage18DesignTokens.addressLabelColor)
                Text(recipient)
                    .font(IMessage18DesignTokens.addressLabelFont)
                    .foregroundStyle(recipientPhoneColor)
                    .padding(.horizontal, IMessage18DesignTokens.recipientCapsuleHPadding)
                    .padding(.vertical, IMessage18DesignTokens.recipientCapsuleVPadding)
                    .background(recipientCapsuleBackground)
                    .clipShape(Capsule())
                Spacer(minLength: 0)
            }

            if app.simCardMode == .dual {
                insetAddressDivider
                senderAddressRow
                fullWidthDivider
            } else {
                fullWidthDivider
            }
        }
        .background(IMessage18DesignTokens.addressBackground)
    }

    private var senderAddressRow: some View {
        HStack(alignment: .center, spacing: 4) {
            Text("发件人：")
                .font(IMessage18DesignTokens.addressLabelFont)
                .foregroundStyle(IMessage18DesignTokens.addressLabelColor)
            senderBadge
            Text(senderLineLabel)
                .font(IMessage18DesignTokens.addressLabelFont)
                .foregroundStyle(senderLabelColor)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, addressLeadingInset)
        .padding(.trailing, IMessage18DesignTokens.addressLeadingInset)
        .frame(height: IMessage18DesignTokens.addressRowHeight, alignment: .center)
    }

    private var senderBadgeText: String {
        let label = senderLineLabel
        if label.count <= 2 { return label }
        return String(label.prefix(2))
    }

    private var senderBadge: some View {
        Text(senderBadgeText)
            .font(.system(size: IMessage18DesignTokens.senderBadgeFontSize, weight: .regular))
            .foregroundStyle(senderBadgeForeground)
            .padding(.horizontal, IMessage18DesignTokens.senderBadgeHPadding)
            .padding(.vertical, IMessage18DesignTokens.senderBadgeVPadding)
            .background(senderBadgeBackgroundColor)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: IMessage18DesignTokens.senderBadgeCornerRadius,
                    style: .continuous
                )
            )
    }

    private func addressRow(@ViewBuilder content: () -> some View) -> some View {
        HStack(alignment: .center, spacing: 4) {
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, addressLeadingInset)
        .padding(.trailing, IMessage18DesignTokens.addressLeadingInset)
        .frame(height: IMessage18DesignTokens.addressRowHeight, alignment: .center)
    }

    private var addressLeadingInset: CGFloat {
        IMessage18DesignTokens.addressLeadingInset + IMessage18DesignTokens.addressContentOffsetX
    }

    private var fullWidthDivider: some View {
        Rectangle()
            .fill(IMessage18DesignTokens.addressSeparatorColor)
            .frame(height: IMessage18DesignTokens.addressSeparatorHeight)
            .frame(maxWidth: .infinity)
    }

    private var insetAddressDivider: some View {
        Rectangle()
            .fill(IMessage18DesignTokens.addressSeparatorColor)
            .frame(height: IMessage18DesignTokens.addressSeparatorHeight)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, addressLeadingInset)
    }

    private var composerBottomReserve: CGFloat {
        IMessage18DesignTokens.composerToolbarReserveBlock
            + composerBottomPadding
            + IMessage18DesignTokens.threadDeliveredAboveInput
    }

    private var senderLineLabel: String {
        let trimmed = app.senderLineLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "副号" : trimmed
    }

    private var composerBottomPadding: CGFloat {
        if keyboardTopInset > 0 {
            return keyboardTopInset + IMessage18DesignTokens.layer3KeyboardGap
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
        ComposeThread1718Session.isClosing = true
        ComposeThreadPinDebug1718.shared.log("close: freeze scroll before keyboard dismiss")
        composerFocused = false
        KeyboardDismiss.resign()
        onClose()
    }

    private var dismissGesture: some Gesture {
        DragGesture(minimumDistance: 30)
            .onEnded { value in
                guard value.translation.height > 60 else { return }
                close()
            }
    }
}
