import SwiftUI

/// iOS 17–18 撰写页：扁平导航/收发件人/底栏 + 系统键盘 + 金色光标
struct NewIMessageView1718: View {
    @EnvironmentObject private var app: AppState
    let onClose: () -> Void

    @State private var composerText = ""
    @State private var composerFocused = true
    @State private var keyboardTopInset: CGFloat = 0

    private var recipient: String {
        guard let phone = app.selectedPhone else { return "" }
        return PhoneUtilities.formatIMessage(phone)
    }

    var body: some View {
        GeometryReader { geo in
            let topGap = resolvedTopGap(fallback: geo.safeAreaInsets.top)
            let cornerRadius = IMessage1718DesignTokens.layer1CornerRadius

            ZStack(alignment: .top) {
                VStack(spacing: 0) {
                    Color.clear
                        .frame(height: topGap)
                        .contentShape(Rectangle())
                        .gesture(dismissGesture)

                    IMessage1718DesignTokens.layer1Background
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
            ComposeThread1718PinWarmup.refresh(app: app, keyboardTopInset: inset)
        }
        .onDisappear {
            composerFocused = false
            keyboardTopInset = 0
            KeyboardDismiss.resign()
        }
    }

    /// ignoresSafeArea 后 GeometryReader 的 safeAreaInsets 常为 0，改读 keyWindow
    private func resolvedTopGap(fallback: CGFloat) -> CGFloat {
        let windowTop = keyWindow?.safeAreaInsets.top ?? 0
        let safeTop = max(fallback, windowTop)
        return IMessage1718DesignTokens.composeSheetTopInset(safeAreaTop: safeTop)
    }

    private var composerBar: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
                .allowsHitTesting(false)
            MessagesComposerHost1718(text: $composerText, wantsFocus: composerFocused)
                .frame(height: IMessage1718DesignTokens.layer3ToolbarHeight)
                .padding(.horizontal, 6)
                .offset(
                    x: 0,
                    y: IMessage1718DesignTokens.layer3ToolbarOffsetY + IMessage1718DesignTokens.layer3KeyboardOffsetY
                )
                .padding(.bottom, composerBottomPadding)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var composeLayers: some View {
        ZStack(alignment: .top) {
            ComposeThreadBackdropHost1718(
                chromeBottomY: IMessage1718DesignTokens.addressChromeBottom(
                    showsSenderRow: app.simCardMode == .dual
                ),
                composerBottomReserve: composerBottomReserve,
                dateLine: app.threadDateLine,
                messageText: app.messagePreviewText,
                showsText: app.showsMessageText,
                showsImage: app.showsMessageImage,
                bothContentOrder: app.bothContentOrder,
                image: app.messageImage,
                bubbleTailParams: IMessage1718BubbleTailPreset.resolvedParams(
                    presetID: app.notes1718Tuning.bubbleTailPresetID,
                    tuning: app.notes1718Tuning
                )
            )
            .id(
                "\(app.mode.rawValue)|\(app.bothContentOrder.rawValue)|"
                    + "\(app.simCardMode.rawValue)|\(app.senderLineLabel)|"
                    + "\(app.showsMessageText)|\(app.showsMessageImage)|"
                    + "\(app.notes1718Tuning.bubbleTailPresetID)|1718"
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
            .fill(IMessage1718DesignTokens.navRecipientDividerColor)
            .frame(height: IMessage1718DesignTokens.addressSeparatorHeight)
            .frame(maxWidth: .infinity)
    }

    private var navigationBar: some View {
        ZStack(alignment: .top) {
            IMessage1718DesignTokens.navBarBackground
                .frame(maxWidth: .infinity)
                .frame(height: IMessage1718DesignTokens.navBarHeight)

            ZStack {
                Text("新 iMessage 信息")
                    .font(IMessage1718DesignTokens.navTitleFont)
                    .tracking(IMessage1718DesignTokens.navTitleTracking)
                    .foregroundStyle(Color.primary)
                HStack {
                    Spacer(minLength: 0)
                    Button(action: close) {
                        Text("取消")
                            .font(IMessage1718DesignTokens.navCancelFont)
                            .foregroundStyle(IMessage1718DesignTokens.navCancelColor)
                    }
                    .buttonStyle(.plain)
                    .simultaneousGesture(
                        LongPressGesture(minimumDuration: 0.6).onEnded { _ in
                            ComposeThreadPinDebug1718.shared.isEnabled.toggle()
                        }
                    )
                    .padding(.trailing, IMessage1718DesignTokens.navCancelTrailingPadding)
                }
            }
            .frame(height: IMessage1718DesignTokens.navBarBaseHeight)
            .offset(y: IMessage1718DesignTokens.navBarContentOffsetY)
        }
        .frame(height: IMessage1718DesignTokens.navBarHeight)
    }

    private var addressSection: some View {
        VStack(spacing: 0) {
            addressRow {
                Text("收件人：")
                    .font(IMessage1718DesignTokens.addressLabelFont)
                    .foregroundStyle(IMessage1718DesignTokens.addressLabelColor)
                Text(recipient)
                    .font(IMessage1718DesignTokens.addressLabelFont)
                    .foregroundStyle(IMessage1718DesignTokens.recipientPhoneTint)
                    .padding(.horizontal, IMessage1718DesignTokens.recipientCapsuleHPadding)
                    .padding(.vertical, IMessage1718DesignTokens.recipientCapsuleVPadding)
                    .background(IMessage1718DesignTokens.recipientCapsuleFill)
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
        .background(IMessage1718DesignTokens.addressBackground)
    }

    private var senderAddressRow: some View {
        HStack(alignment: .center, spacing: 4) {
            Text("发件人：")
                .font(IMessage1718DesignTokens.addressLabelFont)
                .foregroundStyle(IMessage1718DesignTokens.addressLabelColor)
            senderBadge
            Text(senderLineLabel)
                .font(IMessage1718DesignTokens.addressLabelFont)
                .foregroundStyle(IMessage1718DesignTokens.senderLineTint)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, addressLeadingInset)
        .padding(.trailing, IMessage1718DesignTokens.addressLeadingInset)
        .frame(height: IMessage1718DesignTokens.addressRowHeight, alignment: .center)
    }

    private var senderBadgeText: String {
        let label = senderLineLabel
        if label.count <= 2 { return label }
        return String(label.prefix(2))
    }

    private var senderBadge: some View {
        Text(senderBadgeText)
            .font(.system(size: IMessage1718DesignTokens.senderBadgeFontSize, weight: .regular))
            .foregroundStyle(IMessage1718DesignTokens.senderBadgeTextColor)
            .padding(.horizontal, IMessage1718DesignTokens.senderBadgeHPadding)
            .padding(.vertical, IMessage1718DesignTokens.senderBadgeVPadding)
            .background(IMessage1718DesignTokens.senderBadgeBackground)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: IMessage1718DesignTokens.senderBadgeCornerRadius,
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
        .padding(.trailing, IMessage1718DesignTokens.addressLeadingInset)
        .frame(height: IMessage1718DesignTokens.addressRowHeight, alignment: .center)
    }

    private var addressLeadingInset: CGFloat {
        IMessage1718DesignTokens.addressLeadingInset + IMessage1718DesignTokens.addressContentOffsetX
    }

    private var fullWidthDivider: some View {
        Rectangle()
            .fill(IMessage1718DesignTokens.addressSeparatorColor)
            .frame(height: IMessage1718DesignTokens.addressSeparatorHeight)
            .frame(maxWidth: .infinity)
    }

    private var insetAddressDivider: some View {
        Rectangle()
            .fill(IMessage1718DesignTokens.addressSeparatorColor)
            .frame(height: IMessage1718DesignTokens.addressSeparatorHeight)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, addressLeadingInset)
    }

    private var composerBottomReserve: CGFloat {
        IMessage1718DesignTokens.composerToolbarReserveBlock
            + composerBottomPadding
            + IMessage1718DesignTokens.threadDeliveredAboveInput
    }

    private var senderLineLabel: String {
        let trimmed = app.senderLineLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "副号" : trimmed
    }

    private var composerBottomPadding: CGFloat {
        if keyboardTopInset > 0 {
            return keyboardTopInset + IMessage1718DesignTokens.layer3KeyboardGap
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
