import SwiftUI

/// iOS 17–18 撰写页：扁平导航/收发件人/底栏 + 系统键盘 + 金色光标
struct NewIMessageView17: View {
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

    var body: some View {
        GeometryReader { geo in
            let topGap = resolvedTopGap(fallback: geo.safeAreaInsets.top)
            let cornerRadius = IMessage17DesignTokens.layer1CornerRadius

            ZStack(alignment: .top) {
                VStack(spacing: 0) {
                    Color.clear
                        .frame(height: topGap)
                        .contentShape(Rectangle())
                        .gesture(dismissGesture)

                    IMessage17DesignTokens.layer1Background
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
            ComposeThread17PinWarmup.refresh(app: app, keyboardTopInset: inset)
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
        return IMessage17DesignTokens.composeSheetTopInset(safeAreaTop: safeTop)
    }

    private var composerBar: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
                .allowsHitTesting(false)
            MessagesComposerHost1718(
                text: $composerText,
                wantsFocus: composerFocused,
                onPlusTap: { showBubbleTuningPanel = true }
            )
                .frame(height: IMessage17DesignTokens.layer3ToolbarHeight)
                .padding(.horizontal, 6)
                .offset(
                    x: 0,
                    y: IMessage17DesignTokens.layer3ToolbarOffsetY + IMessage17DesignTokens.layer3KeyboardOffsetY
                )
                .padding(.bottom, composerBottomPadding)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var composeLayers: some View {
        ZStack(alignment: .top) {
            ComposeThreadBackdropHost1718(
                chromeBottomY: IMessage17DesignTokens.addressChromeBottom(
                    showsSenderRow: app.simCardMode == .dual
                ),
                composerBottomReserve: composerBottomReserve,
                dateLine: app.threadDateLine,
                isBlankThread: false,
                messageText: app.messagePreviewText,
                showsText: app.showsMessageText,
                showsImage: app.showsMessageImage,
                bothContentOrder: app.bothContentOrder,
                image: app.messageDisplayImage,
                senderLineLabel: app.senderLineLabel,
                showsSenderRow: app.simCardMode == .dual,
                bubbleTailParams: IMessage17BubbleTailPreset.resolvedParams(
                    presetID: app.notes17Tuning.bubbleTailPresetID,
                    tuning: app.notes17Tuning
                ),
                bubbleFontSize: CGFloat(app.composeBubbleTuning.fontSize),
                messageLinkUnderlineHidden: app.messageLinkUnderlineHidden
            )
            .id(
                "\(app.mode.rawValue)|\(app.bothContentOrder.rawValue)|"
                    + "\(app.simCardMode.rawValue)|\(app.senderLineLabel)|"
                    + "\(app.showsMessageText)|\(app.showsMessageImage)|"
                    + "\(app.notes17Tuning.bubbleTailPresetID)|17"
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
            .fill(IMessage17DesignTokens.navRecipientDividerColor)
            .frame(height: IMessage17DesignTokens.addressSeparatorHeight)
            .frame(maxWidth: .infinity)
    }

    private var navigationBar: some View {
        ZStack(alignment: .top) {
            IMessage17DesignTokens.navBarBackground
                .frame(maxWidth: .infinity)
                .frame(height: IMessage17DesignTokens.navBarHeight)

            ZStack {
                Text("新 iMessage 信息")
                    .font(IMessage17DesignTokens.navTitleFont)
                    .tracking(IMessage17DesignTokens.navTitleTracking)
                    .foregroundStyle(Color.primary)
                HStack {
                    Spacer(minLength: 0)
                    Button(action: close) {
                        Text("取消")
                            .font(IMessage17DesignTokens.navCancelFont)
                            .foregroundStyle(IMessage17DesignTokens.navCancelColor)
                    }
                    .buttonStyle(.plain)
                    .simultaneousGesture(
                        LongPressGesture(minimumDuration: 0.6).onEnded { _ in
                            ComposeThreadPinDebug1718.shared.isEnabled.toggle()
                        }
                    )
                    .padding(.trailing, IMessage17DesignTokens.navCancelTrailingPadding)
                }
            }
            .frame(height: IMessage17DesignTokens.navBarBaseHeight)
            .offset(y: IMessage17DesignTokens.navBarContentOffsetY)
        }
        .frame(height: IMessage17DesignTokens.navBarHeight)
    }

    private var addressSection: some View {
        VStack(spacing: 0) {
            addressRow {
                Text("收件人：")
                    .font(IMessage17DesignTokens.addressLabelFont)
                    .foregroundStyle(IMessage17DesignTokens.addressLabelColor)
                Text(recipient)
                    .font(IMessage17DesignTokens.addressLabelFont)
                    .foregroundStyle(IMessage17DesignTokens.recipientPhoneTint)
                    .padding(.horizontal, IMessage17DesignTokens.recipientCapsuleHPadding)
                    .padding(.vertical, IMessage17DesignTokens.recipientCapsuleVPadding)
                    .background(IMessage17DesignTokens.recipientCapsuleFill)
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
        .background(IMessage17DesignTokens.addressBackground)
    }

    private var senderAddressRow: some View {
        HStack(alignment: .center, spacing: 4) {
            Text("发件人：")
                .font(IMessage17DesignTokens.addressLabelFont)
                .foregroundStyle(IMessage17DesignTokens.addressLabelColor)
            senderBadge
            Text(senderLineLabel)
                .font(IMessage17DesignTokens.addressLabelFont)
                .foregroundStyle(IMessage17DesignTokens.senderLineTint)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, addressLeadingInset)
        .padding(.trailing, IMessage17DesignTokens.addressLeadingInset)
        .frame(height: IMessage17DesignTokens.addressRowHeight, alignment: .center)
    }

    private var senderBadgeText: String {
        let label = senderLineLabel
        if label.count <= 2 { return label }
        return String(label.prefix(2))
    }

    private var senderBadge: some View {
        Text(senderBadgeText)
            .font(.system(size: IMessage17DesignTokens.senderBadgeFontSize, weight: .regular))
            .foregroundStyle(IMessage17DesignTokens.senderBadgeTextColor)
            .padding(.horizontal, IMessage17DesignTokens.senderBadgeHPadding)
            .padding(.vertical, IMessage17DesignTokens.senderBadgeVPadding)
            .background(IMessage17DesignTokens.senderBadgeBackground)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: IMessage17DesignTokens.senderBadgeCornerRadius,
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
        .padding(.trailing, IMessage17DesignTokens.addressLeadingInset)
        .frame(height: IMessage17DesignTokens.addressRowHeight, alignment: .center)
    }

    private var addressLeadingInset: CGFloat {
        IMessage17DesignTokens.addressLeadingInset + IMessage17DesignTokens.addressContentOffsetX
    }

    private var fullWidthDivider: some View {
        Rectangle()
            .fill(IMessage17DesignTokens.addressSeparatorColor)
            .frame(height: IMessage17DesignTokens.addressSeparatorHeight)
            .frame(maxWidth: .infinity)
    }

    private var insetAddressDivider: some View {
        Rectangle()
            .fill(IMessage17DesignTokens.addressSeparatorColor)
            .frame(height: IMessage17DesignTokens.addressSeparatorHeight)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, addressLeadingInset)
    }

    private var composerBottomReserve: CGFloat {
        IMessage17DesignTokens.composerToolbarReserveBlock
            + composerBottomPadding
            + IMessage17DesignTokens.threadDeliveredAboveInput
    }

    private var senderLineLabel: String {
        let trimmed = app.senderLineLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "副号" : trimmed
    }

    private var composerBottomPadding: CGFloat {
        if keyboardTopInset > 0 {
            return keyboardTopInset + IMessage17DesignTokens.layer3KeyboardGap
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
