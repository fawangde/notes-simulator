import SwiftUI
import UIKit

/// 第 2 层聊天底色：UIKit UIScrollView，供自研材质内核采样穿透
struct ComposeThreadBackdropHost: UIViewRepresentable {
    let chromeBottomY: CGFloat
    let composerBottomReserve: CGFloat
    let dateLine: String
    let showsIOS264ThreadHeader: Bool
    let isBlankThread: Bool
    let composeChromeStyle: IOS26ComposeChromeStyle
    let messageText: String
    let showsText: Bool
    let showsImage: Bool
    let bothContentOrder: BothContentOrder
    let image: UIImage?
    let senderLineLabel: String
    var showsSenderRow = true
    var bubbleFontSize: CGFloat = 17
    var messageLinkUnderlineHidden = false
    func makeUIView(context: Context) -> ComposeThreadScrollView {
        ComposeThreadScrollView()
    }

    func updateUIView(_ uiView: ComposeThreadScrollView, context: Context) {
        uiView.apply(
            chromeBottomY: chromeBottomY,
            composerBottomReserve: composerBottomReserve,
            dateLine: dateLine,
            showsIOS264ThreadHeader: showsIOS264ThreadHeader,
            isBlankThread: isBlankThread,
            composeChromeStyle: composeChromeStyle,
            messageText: messageText,
            showsText: showsText,
            showsImage: showsImage,
            bothContentOrder: bothContentOrder,
            image: image,
            senderLineLabel: senderLineLabel,
            showsSenderRow: showsSenderRow,
            horizontalPadding: IMessageDesignTokens.layer2ThreadPaddingH,
            bubbleFontSize: bubbleFontSize,
            messageLinkUnderlineHidden: messageLinkUnderlineHidden
        )
    }
}

final class ComposeThreadScrollView: UIView {
    private let scrollView = UIScrollView()
    private let stack = UIStackView()

    private var chromeBottomY: CGFloat = 0
    private var composerBottomReserve: CGFloat = 0
    private var lastContentHeight: CGFloat = 0
    private var lastComposerReserve: CGFloat = 0
    private var contentSignature: ThreadContentSignature?
    private var bubbleFontSize: CGFloat = 17
    private var messageLinkUnderlineHidden = false
    private var userDidScroll = false
    /// 长按打开信息页后首屏顶对齐（与参考图一致），文案变长后再走贴底上滚
    private var prefersInitialTopAlignment = true
    /// 已送达贴输入框后进入钉住态（对齐 1718 稳定算法）
    private var isComposerPinEngaged = false
    private var pendingTargetY: CGFloat?
    private var pendingPinLineY: CGFloat?
    private var settlePassesRemaining = 0
    private var reserveSettlePassesRemaining = 0
    private var lastReserveDelta: CGFloat = 0
    private var isProgrammaticScroll = false
    private var lastAnchorBottom: CGFloat = 0
    private var pendingInitialPinAfterBounds = false

    private struct PinMetrics {
        let targetY: CGFloat
        let anchorBottom: CGFloat
        let composerPinLine: CGFloat
        let insetBottom: CGFloat
        let bubbleRowSize: CGSize

        var gapToPinLine: CGFloat { anchorBottom - composerPinLine }
    }

    private struct PendingFullApply {
        let chromeBottomY: CGFloat
        let composerBottomReserve: CGFloat
        let dateLine: String
        let showsIOS264ThreadHeader: Bool
        let isBlankThread: Bool
        let composeChromeStyle: IOS26ComposeChromeStyle
        let messageText: String
        let showsText: Bool
        let showsImage: Bool
        let bothContentOrder: BothContentOrder
        let image: UIImage?
        let senderLineLabel: String
        let showsSenderRow: Bool
        let horizontalPadding: CGFloat
        let bubbleFontSize: CGFloat
        let messageLinkUnderlineHidden: Bool
    }

    private var pendingFullApply: PendingFullApply?

    private struct ThreadContentSignature: Equatable {
        let chromeBottomY: CGFloat
        let dateLine: String
        let showsIOS264ThreadHeader: Bool
        let isBlankThread: Bool
        let composeChromeStyle: IOS26ComposeChromeStyle
        let messageText: String
        let showsText: Bool
        let showsImage: Bool
        let bothContentOrder: BothContentOrder
        let imageKey: Int
        let showsSenderRow: Bool
    }

    private static func imageLayoutKey(for image: UIImage?) -> Int {
        image.map { ObjectIdentifier($0).hashValue } ?? 0
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        clipsToBounds = true

        scrollView.backgroundColor = .clear
        scrollView.clipsToBounds = true
        scrollView.alwaysBounceVertical = true
        scrollView.isScrollEnabled = true
        scrollView.delaysContentTouches = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.delegate = self
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)

        stack.axis = .vertical
        stack.spacing = 0
        stack.clipsToBounds = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stack)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
        ])
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        ComposeBackdropRegistry.register(scrollView)
        if window != nil, pendingInitialPinAfterBounds {
            setNeedsLayout()
        }
    }

    private func hasValidBounds() -> Bool {
        scrollView.bounds.width > 10 && scrollView.bounds.height > 10
    }

    private func setScrollOffsetY(_ y: CGFloat, animated: Bool) {
        isProgrammaticScroll = true
        scrollView.setContentOffset(CGPoint(x: 0, y: y), animated: animated)
        isProgrammaticScroll = false
    }

    /// 等多行气泡高度稳定后再判断是否触线钉住
    private func scheduleReconcileAfterLayout() {
        func pass(_ next: (() -> Void)?) {
            guard hasValidBounds() else {
                pendingInitialPinAfterBounds = true
                guard let next else { return }
                DispatchQueue.main.async(execute: next)
                return
            }
            layoutIfNeeded()
            reconcileScrollOffset(animated: false)
            lastContentHeight = scrollView.contentSize.height
            guard let next else {
                ComposeBackdropRegistry.notifyChanged()
                return
            }
            DispatchQueue.main.async(execute: next)
        }
        DispatchQueue.main.async {
            pass {
                pass {
                    pass {
                        pass(nil)
                    }
                }
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if let pending = pendingFullApply, bounds.width > 1 {
            let snapshot = pending
            pendingFullApply = nil
            apply(
                chromeBottomY: snapshot.chromeBottomY,
                composerBottomReserve: snapshot.composerBottomReserve,
                dateLine: snapshot.dateLine,
                showsIOS264ThreadHeader: snapshot.showsIOS264ThreadHeader,
                isBlankThread: snapshot.isBlankThread,
                composeChromeStyle: snapshot.composeChromeStyle,
                messageText: snapshot.messageText,
                showsText: snapshot.showsText,
                showsImage: snapshot.showsImage,
                bothContentOrder: snapshot.bothContentOrder,
                image: snapshot.image,
                senderLineLabel: snapshot.senderLineLabel,
                showsSenderRow: snapshot.showsSenderRow,
                horizontalPadding: snapshot.horizontalPadding,
                bubbleFontSize: snapshot.bubbleFontSize,
                messageLinkUnderlineHidden: snapshot.messageLinkUnderlineHidden
            )
        }

        let previousReserve = lastComposerReserve
        scrollView.contentInset.bottom = composerBottomReserve

        guard hasValidBounds() else {
            pendingInitialPinAfterBounds = contentSignature != nil
            return
        }

        if pendingInitialPinAfterBounds, contentSignature != nil {
            pendingInitialPinAfterBounds = false
            layoutIfNeeded()
            scheduleReconcileAfterLayout()
        }

        let reserveDelta = composerBottomReserve - previousReserve
        let reserveChanged = abs(reserveDelta) > 0.5
        lastReserveDelta = reserveChanged ? reserveDelta : 0

        if reserveChanged {
            pendingTargetY = nil
            pendingPinLineY = nil
            reserveSettlePassesRemaining = max(reserveSettlePassesRemaining, 4)
            if scrollView.contentOffset.y > 0.5 {
                let maxY = maxScrollOffsetY()
                let adjusted = max(0, min(scrollView.contentOffset.y + reserveDelta, maxY))
                if abs(adjusted - scrollView.contentOffset.y) > 0.5 {
                    setScrollOffsetY(adjusted, animated: false)
                }
            }
            lastComposerReserve = composerBottomReserve
            return
        }

        if reserveSettlePassesRemaining > 0 {
            reserveSettlePassesRemaining -= 1
            lastComposerReserve = composerBottomReserve
            return
        }

        lastComposerReserve = composerBottomReserve
        guard !userDidScroll else { return }
        if prefersInitialTopAlignment, !isComposerPinEngaged {
            if pinMetrics().targetY <= 0.5 {
                return
            }
        }
        reconcileScrollOffset(animated: false)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func apply(
        chromeBottomY: CGFloat,
        composerBottomReserve: CGFloat,
        dateLine: String,
        showsIOS264ThreadHeader: Bool,
        isBlankThread: Bool,
        composeChromeStyle: IOS26ComposeChromeStyle,
        messageText: String,
        showsText: Bool,
        showsImage: Bool,
        bothContentOrder: BothContentOrder,
        image: UIImage?,
        senderLineLabel: String,
        showsSenderRow: Bool,
        horizontalPadding: CGFloat,
        bubbleFontSize: CGFloat,
        messageLinkUnderlineHidden: Bool
    ) {
        let reserveChanged = abs(composerBottomReserve - self.composerBottomReserve) > 0.5
        self.composerBottomReserve = composerBottomReserve
        let fontChanged = abs(self.bubbleFontSize - bubbleFontSize) > 0.25
        self.bubbleFontSize = bubbleFontSize
        let linkUnderlineChanged = self.messageLinkUnderlineHidden != messageLinkUnderlineHidden
        self.messageLinkUnderlineHidden = messageLinkUnderlineHidden

        let signature = ThreadContentSignature(
            chromeBottomY: chromeBottomY,
            dateLine: dateLine,
            showsIOS264ThreadHeader: showsIOS264ThreadHeader,
            isBlankThread: isBlankThread,
            composeChromeStyle: composeChromeStyle,
            messageText: messageText,
            showsText: showsText,
            showsImage: showsImage,
            bothContentOrder: bothContentOrder,
            imageKey: Self.imageLayoutKey(for: image),
            showsSenderRow: showsSenderRow
        )

        if signature == contentSignature {
            if fontChanged {
                updateVisibleBubbleFontSize(bubbleFontSize)
                setNeedsLayout()
                layoutIfNeeded()
                settlePassesRemaining = 3
                scheduleReconcileAfterLayout()
            } else if linkUnderlineChanged {
                updateVisibleLinkUnderlineHidden(messageLinkUnderlineHidden)
            } else if reserveChanged || signature.showsImage {
                setNeedsLayout()
                layoutIfNeeded()
            }
            return
        }

        if let previous = contentSignature,
           previous.chromeBottomY == signature.chromeBottomY,
           previous.showsText == signature.showsText,
           previous.showsImage == signature.showsImage,
           previous.bothContentOrder == signature.bothContentOrder,
           previous.imageKey == signature.imageKey,
           previous.showsSenderRow == signature.showsSenderRow,
           previous.showsIOS264ThreadHeader == signature.showsIOS264ThreadHeader,
           previous.messageText != signature.messageText || previous.dateLine != signature.dateLine {
            contentSignature = signature
            prefersInitialTopAlignment = false
            updateVisibleMessageText(signature.messageText, dateLine: signature.dateLine)
            setNeedsLayout()
            layoutIfNeeded()
            pendingTargetY = nil
            pendingPinLineY = nil
            settlePassesRemaining = 3
            scheduleReconcileAfterLayout()
            return
        }

        guard bounds.width > 1 else {
            pendingFullApply = PendingFullApply(
                chromeBottomY: chromeBottomY,
                composerBottomReserve: composerBottomReserve,
                dateLine: dateLine,
                showsIOS264ThreadHeader: showsIOS264ThreadHeader,
                isBlankThread: isBlankThread,
                composeChromeStyle: composeChromeStyle,
                messageText: messageText,
                showsText: showsText,
                showsImage: showsImage,
                bothContentOrder: bothContentOrder,
                image: image,
                senderLineLabel: senderLineLabel,
                showsSenderRow: showsSenderRow,
                horizontalPadding: horizontalPadding,
                bubbleFontSize: bubbleFontSize,
                messageLinkUnderlineHidden: messageLinkUnderlineHidden
            )
            setNeedsLayout()
            return
        }
        pendingFullApply = nil

        contentSignature = signature
        self.chromeBottomY = chromeBottomY
        userDidScroll = false
        prefersInitialTopAlignment = true
        isComposerPinEngaged = false
        pendingTargetY = nil
        pendingPinLineY = nil
        settlePassesRemaining = 0
        reserveSettlePassesRemaining = 0
        lastAnchorBottom = 0

        stack.arrangedSubviews.forEach {
            stack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        let topSpacer = fixedSpacer(
            chromeBottomY
                + IMessageDesignTokens.threadTimestampBelowCard
                + IMessageDesignTokens.layer2TimeOffsetY
        )
        stack.addArrangedSubview(topSpacer)

        if isBlankThread {
            if showsIOS264ThreadHeader {
                let headerRow = insetRow(
                    makeThreadHeaderStack(
                        dateLine: dateLine,
                        showsIOS264ThreadHeader: true,
                        isBlankThread: true,
                        composeChromeStyle: composeChromeStyle
                    ),
                    horizontalPadding: horizontalPadding
                )
                stack.addArrangedSubview(headerRow)
            }
            stack.addArrangedSubview(
                fixedSpacer(IMessageDesignTokens.threadManualScrollSlack)
            )
            lastContentHeight = 0
            setNeedsLayout()
            DispatchQueue.main.async {
                self.layoutIfNeeded()
                self.scrollView.setContentOffset(.zero, animated: false)
                self.lastContentHeight = self.scrollView.contentSize.height
                ComposeBackdropRegistry.notifyChanged()
            }
            return
        }

        let timeRow = insetRow(
            makeThreadHeaderStack(
                dateLine: dateLine,
                showsIOS264ThreadHeader: showsIOS264ThreadHeader,
                isBlankThread: false,
                composeChromeStyle: composeChromeStyle
            ),
            horizontalPadding: horizontalPadding
        )
        stack.addArrangedSubview(timeRow)

        stack.addArrangedSubview(
            fixedSpacer(IMessageDesignTokens.threadBubbleBelowTimestamp)
        )

        appendMessageContent(
            messageText: messageText,
            showsText: showsText,
            showsImage: showsImage,
            bothContentOrder: bothContentOrder,
            image: image,
            senderLineLabel: senderLineLabel,
            showsSenderRow: showsSenderRow,
            horizontalPadding: horizontalPadding
        )

        stack.addArrangedSubview(
            fixedSpacer(IMessageDesignTokens.threadManualScrollSlack)
        )

        lastContentHeight = 0
        setNeedsLayout()
        pendingInitialPinAfterBounds = !hasValidBounds()
        if hasValidBounds() {
            scheduleReconcileAfterLayout()
        }
    }

    private func updateVisibleMessageText(_ text: String, dateLine: String) {
        func visit(_ view: UIView) {
            if let bubble = view as? ComposeBubbleColumnView {
                bubble.updateText(text)
            } else if let header = view as? UIStackView,
                      header.arrangedSubviews.contains(where: { $0 is UILabel }) {
                (header.arrangedSubviews.last as? UILabel)?.text = dateLine
            }
            view.subviews.forEach { visit($0) }
        }
        stack.arrangedSubviews.forEach { visit($0) }
    }

    private func updateVisibleBubbleFontSize(_ size: CGFloat) {
        func visit(_ view: UIView) {
            if let bubble = view as? ComposeBubbleColumnView {
                bubble.applyBubbleFontSize(size)
            }
            view.subviews.forEach { visit($0) }
        }
        stack.arrangedSubviews.forEach { visit($0) }
    }

    private func updateVisibleLinkUnderlineHidden(_ hidden: Bool) {
        func visit(_ view: UIView) {
            if let bubble = view as? ComposeBubbleColumnView {
                bubble.applyLinkUnderlineHidden(hidden)
            }
            view.subviews.forEach { visit($0) }
        }
        stack.arrangedSubviews.forEach { visit($0) }
    }

    private func appendMessageContent(
        messageText: String,
        showsText: Bool,
        showsImage: Bool,
        bothContentOrder: BothContentOrder,
        image: UIImage?,
        senderLineLabel: String,
        showsSenderRow: Bool,
        horizontalPadding: CGFloat
    ) {
        let isBoth = showsText && showsImage

        let addText = {
            guard showsText else { return }
            let showsDelivered = !isBoth || bothContentOrder == .imageFirst
            let showsTail = !isBoth || bothContentOrder == .imageFirst
            let bubble = ComposeBubbleColumnView(
                text: messageText,
                bubbleFontSize: self.bubbleFontSize,
                linkUnderlineHidden: self.messageLinkUnderlineHidden,
                showsDelivered: showsDelivered,
                showsTail: showsTail,
                usesBothModeTextCorner: isBoth
            )
            let bubbleRow = self.trailingRow(
                bubble,
                horizontalPadding: IMessageDesignTokens.threadBubbleTrailingInset
            )
            self.stack.addArrangedSubview(bubbleRow)
        }

        let addImage = {
            guard showsImage, let image else { return }
            let showsDelivered = !isBoth || bothContentOrder == .textFirst
            let column = ComposeImageColumnView(
                image: image,
                senderLineLabel: senderLineLabel,
                showsDelivered: showsDelivered
            )
            let imageRow = self.trailingRow(
                column,
                horizontalPadding: IMessageDesignTokens.threadBubbleTrailingInset
            )
            self.stack.addArrangedSubview(imageRow)
        }

        switch bothContentOrder {
        case .textFirst:
            addText()
            if isBoth {
                stack.addArrangedSubview(
                    fixedSpacer(IMessageDesignTokens.threadBothTextFirstTextBottomToImageTop)
                )
            }
            addImage()
        case .imageFirst:
            addImage()
            if isBoth {
                stack.addArrangedSubview(
                    fixedSpacer(IMessageDesignTokens.threadBothImageFirstTailToTextTop)
                )
            }
            addText()
        }
    }

    private func makeThreadHeaderStack(
        dateLine: String,
        showsIOS264ThreadHeader: Bool,
        isBlankThread: Bool,
        composeChromeStyle: IOS26ComposeChromeStyle
    ) -> UIStackView {
        let headerStack = UIStackView()
        headerStack.axis = .vertical
        headerStack.alignment = .center
        headerStack.spacing = IMessageDesignTokens.timestampLineSpacing

        let serviceLabel: UILabel
        if isBlankThread, composeChromeStyle == .greenSMS {
            serviceLabel = makeThreadMetaLabel(
                attributed: IMessageDesignTokens.makeSMSThreadMetaLabelAttributed()
            )
        } else {
            serviceLabel = makeThreadMetaLabel(text: "iMessage 信息")
        }
        headerStack.addArrangedSubview(serviceLabel)

        if showsIOS264ThreadHeader, !(isBlankThread && composeChromeStyle == .greenSMS) {
            let encryptedRow = makeEncryptedRow()
            headerStack.addArrangedSubview(encryptedRow)
            headerStack.setCustomSpacing(
                IMessageDesignTokens.timestampLineSpacing,
                after: serviceLabel
            )
            if !isBlankThread {
                headerStack.setCustomSpacing(
                    IMessageDesignTokens.thread264EncryptedToDateSpacing,
                    after: encryptedRow
                )
            }
        }

        if !isBlankThread {
            let dateLabel = makeThreadMetaLabel(text: dateLine)
            headerStack.addArrangedSubview(dateLabel)
        }

        return headerStack
    }

    private func makeEncryptedRow() -> UIStackView {
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = IMessageDesignTokens.threadEncryptedLockSpacing

        let lockConfig = UIImage.SymbolConfiguration(
            pointSize: IMessageDesignTokens.threadEncryptedLockPointSize,
            weight: .medium
        )
        let lockView = UIImageView(
            image: UIImage(
                systemName: IMessageDesignTokens.threadEncryptedLockSymbol,
                withConfiguration: lockConfig
            )
        )
        lockView.tintColor = IMessageDesignTokens.threadMetaTextUI
        lockView.contentMode = .scaleAspectFit
        lockView.setContentHuggingPriority(.required, for: .horizontal)
        lockView.setContentCompressionResistancePriority(.required, for: .horizontal)

        row.addArrangedSubview(lockView)
        row.addArrangedSubview(makeThreadMetaLabel(text: "已加密"))
        return row
    }

    private func makeThreadMetaLabel(text: String) -> UILabel {
        let label = UILabel()
        label.font = IMessageDesignTokens.threadMetaFontUI
        label.textColor = IMessageDesignTokens.threadMetaTextUI
        label.textAlignment = .center
        label.text = text
        return label
    }

    private func makeThreadMetaLabel(attributed: NSAttributedString) -> UILabel {
        let label = UILabel()
        label.textAlignment = .center
        label.attributedText = attributed
        return label
    }

    private func fixedSpacer(_ height: CGFloat) -> UIView {
        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        spacer.heightAnchor.constraint(equalToConstant: height).isActive = true
        return spacer
    }

    private func insetRow(_ view: UIView, horizontalPadding: CGFloat) -> UIView {
        let row = UIView()
        row.translatesAutoresizingMaskIntoConstraints = false
        view.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(view)
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: horizontalPadding),
            view.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -horizontalPadding),
            view.topAnchor.constraint(equalTo: row.topAnchor),
            view.bottomAnchor.constraint(equalTo: row.bottomAnchor),
        ])
        return row
    }

    private func trailingRow(_ view: UIView, horizontalPadding: CGFloat) -> UIView {
        let row = UIView()
        row.translatesAutoresizingMaskIntoConstraints = false
        view.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(view)
        row.clipsToBounds = false
        NSLayoutConstraint.activate([
            view.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -horizontalPadding),
            view.topAnchor.constraint(equalTo: row.topAnchor),
            view.bottomAnchor.constraint(equalTo: row.bottomAnchor),
            view.leadingAnchor.constraint(greaterThanOrEqualTo: row.leadingAnchor, constant: horizontalPadding),
        ])
        return row
    }

    private func naturalMaxScrollOffsetY() -> CGFloat {
        scrollView.layoutIfNeeded()
        let viewport = scrollView.bounds.height
        guard viewport > 0 else { return 0 }
        let content = scrollView.contentSize.height + scrollView.contentInset.bottom
        return max(0, content - viewport)
    }

    private func maxScrollOffsetY() -> CGFloat {
        naturalMaxScrollOffsetY()
    }

    /// 消息区（气泡/图片 +「已送达」）在 stack 坐标系下的底边
    private func messagePinAnchorBottomY() -> CGFloat? {
        scrollView.layoutIfNeeded()
        stack.layoutIfNeeded()

        var rows = stack.arrangedSubviews
        guard rows.count > 1 else { return nil }
        rows.removeLast()

        for row in rows.reversed() {
            if let bottom = pinBottomInStack(for: row) {
                return bottom
            }
        }
        return nil
    }

    private func pinBottomInStack(for row: UIView) -> CGFloat? {
        for child in row.subviews {
            if let column = child as? ComposeBubbleColumnView {
                column.layoutIfNeeded()
                return column.convert(CGPoint(x: 0, y: column.bounds.height), to: stack).y
            }
            if let column = child as? ComposeImageColumnView {
                column.layoutIfNeeded()
                return column.convert(CGPoint(x: 0, y: column.bounds.height), to: stack).y
            }
        }
        return nil
    }

    private func bubbleRowDimensions() -> CGSize {
        for row in stack.arrangedSubviews.reversed() {
            for child in row.subviews where child is ComposeBubbleColumnView {
                row.layoutIfNeeded()
                return row.bounds.size
            }
        }
        return .zero
    }

    private func isLayoutStable(_ metrics: PinMetrics) -> Bool {
        guard hasValidBounds() else { return false }
        return metrics.bubbleRowSize.width > 10 && metrics.bubbleRowSize.height > 62
    }

    private func composerPinLineY(viewport: CGFloat) -> CGFloat {
        viewport - scrollView.contentInset.bottom
    }

    private func pinMetrics() -> PinMetrics {
        scrollView.layoutIfNeeded()
        stack.layoutIfNeeded()
        let viewport = scrollView.bounds.height
        let insetBottom = scrollView.contentInset.bottom
        let composerPinLine = viewport > 0 ? composerPinLineY(viewport: viewport) : 0
        let anchorBottom = messagePinAnchorBottomY() ?? 0
        let bubbleRowSize = bubbleRowDimensions()

        guard viewport > 0, anchorBottom > 0, composerPinLine > 0 else {
            return PinMetrics(
                targetY: 0,
                anchorBottom: anchorBottom,
                composerPinLine: composerPinLine,
                insetBottom: insetBottom,
                bubbleRowSize: bubbleRowSize
            )
        }

        if anchorBottom <= composerPinLine + 0.5 {
            return PinMetrics(
                targetY: 0,
                anchorBottom: anchorBottom,
                composerPinLine: composerPinLine,
                insetBottom: insetBottom,
                bubbleRowSize: bubbleRowSize
            )
        }

        let offsetY = scrollView.contentOffset.y
        if offsetY <= 0.5, !isComposerPinEngaged, anchorBottom > viewport - 1 {
            return PinMetrics(
                targetY: 0,
                anchorBottom: anchorBottom,
                composerPinLine: composerPinLine,
                insetBottom: insetBottom,
                bubbleRowSize: bubbleRowSize
            )
        }

        let pinOffset = anchorBottom - composerPinLine
        let maxY = naturalMaxScrollOffsetY()
        return PinMetrics(
            targetY: max(0, min(pinOffset, maxY)),
            anchorBottom: anchorBottom,
            composerPinLine: composerPinLine,
            insetBottom: insetBottom,
            bubbleRowSize: bubbleRowSize
        )
    }

    /// 先向下长；「已送达」贴输入区顶后停止下移，再多则上滚
    private func reconcileScrollOffset(animated: Bool) {
        if scrollView.contentOffset.x != 0 {
            scrollView.contentOffset.x = 0
        }

        let maxY = maxScrollOffsetY()
        let contentH = scrollView.contentSize.height
        let metrics = pinMetrics()
        let targetY = metrics.targetY

        if targetY > 0.5 {
            prefersInitialTopAlignment = false
            let wasPinned = isComposerPinEngaged
            isComposerPinEngaged = true
            let clampedY = min(targetY, maxY)
            lastAnchorBottom = metrics.anchorBottom
            let nextY: CGFloat
            if userDidScroll {
                nextY = scrollView.contentOffset.y
                pendingTargetY = nil
                pendingPinLineY = nil
            } else if wasPinned {
                nextY = clampedY
                pendingTargetY = nil
                pendingPinLineY = nil
            } else {
                let pinLn = metrics.composerPinLine
                if let pendingT = pendingTargetY,
                   let pendingL = pendingPinLineY,
                   abs(pendingT - clampedY) <= 2,
                   abs(pendingL - pinLn) <= 2 {
                    nextY = clampedY
                    pendingTargetY = nil
                    pendingPinLineY = nil
                } else {
                    pendingTargetY = clampedY
                    pendingPinLineY = pinLn
                    lastContentHeight = contentH
                    return
                }
            }
            if abs(scrollView.contentOffset.y - nextY) > 0.5 {
                setScrollOffsetY(nextY, animated: animated)
            }
            lastContentHeight = contentH
            return
        }

        lastAnchorBottom = metrics.anchorBottom
        pendingTargetY = nil
        pendingPinLineY = nil

        let stable = isLayoutStable(metrics)
        let allowSnapBack = stable && settlePassesRemaining == 0 && reserveSettlePassesRemaining == 0
        if !allowSnapBack, scrollView.contentOffset.y > 0.5 {
            isComposerPinEngaged = true
            prefersInitialTopAlignment = false
        } else if isComposerPinEngaged, metrics.gapToPinLine > 0.5, targetY <= 0.5 {
            let pinY = min(max(0, metrics.anchorBottom - metrics.composerPinLine), maxY)
            if abs(scrollView.contentOffset.y - pinY) > 0.5 {
                setScrollOffsetY(pinY, animated: animated)
            }
            prefersInitialTopAlignment = false
        } else {
            isComposerPinEngaged = false
            if !userDidScroll, scrollView.contentOffset.y > 0.5, allowSnapBack {
                setScrollOffsetY(0, animated: animated)
                prefersInitialTopAlignment = true
            }
        }

        if settlePassesRemaining > 0 {
            settlePassesRemaining -= 1
        }

        lastContentHeight = contentH
        if scrollView.contentOffset.y > maxY {
            scrollView.contentOffset.y = maxY
        }
    }

    private func snapComposerPinAfterUserScroll() {
        guard !isProgrammaticScroll else { return }
        let metrics = pinMetrics()
        guard metrics.targetY > 0.5, isComposerPinEngaged else { return }
        let target = min(metrics.targetY, maxScrollOffsetY())
        let current = scrollView.contentOffset.y
        if current > target + 12 {
            return
        }
        userDidScroll = false
        if abs(current - target) > 0.5 {
            setScrollOffsetY(target, animated: true)
        } else {
            reconcileScrollOffset(animated: false)
        }
    }
}

extension ComposeThreadScrollView: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        userDidScroll = true
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.x != 0 {
            scrollView.contentOffset.x = 0
        }
        let maxY = maxScrollOffsetY()
        if scrollView.contentOffset.y > maxY {
            scrollView.contentOffset.y = maxY
        }
        if !isProgrammaticScroll {
            ComposeBackdropRegistry.notifyChanged()
        }
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            snapComposerPinAfterUserScroll()
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        snapComposerPinAfterUserScroll()
    }
}

private final class ComposeBubbleColumnView: UIView {
    private let bubbleView = IOSOutgoingChatBubbleView()
    private let delivered = UILabel()
    private let showsDelivered: Bool
    private var widthConstraint: NSLayoutConstraint?
    private var heightConstraint: NSLayoutConstraint?

    init(
        text: String,
        bubbleFontSize: CGFloat = 17,
        linkUnderlineHidden: Bool = false,
        showsDelivered: Bool = true,
        showsTail: Bool = true,
        usesBothModeTextCorner: Bool = false
    ) {
        self.showsDelivered = showsDelivered
        super.init(frame: .zero)
        clipsToBounds = false
        setContentHuggingPriority(.required, for: .horizontal)
        setContentHuggingPriority(.required, for: .vertical)
        setContentCompressionResistancePriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .vertical)

        bubbleView.applyLinkUnderlineHidden(linkUnderlineHidden)
        bubbleView.setBubbleText(text)
        bubbleView.applyBubbleFontSize(bubbleFontSize)
        var params = Self.composeBubbleParams(.frozenDefault)
        params.showsTail = showsTail
        if usesBothModeTextCorner {
            params.bodyCornerRadius = IMessageDesignTokens.bubbleCornerBothTextNoTail
        }
        bubbleView.applyRenderParams(params)

        delivered.text = "已送达"
        delivered.font = IMessageDesignTokens.deliveredFontUI
        delivered.textColor = IMessageDesignTokens.threadMetaTextUI
        delivered.textAlignment = .right
        delivered.isHidden = !showsDelivered

        addSubview(bubbleView)
        addSubview(delivered)

        widthConstraint = widthAnchor.constraint(equalToConstant: 120)
        heightConstraint = heightAnchor.constraint(equalToConstant: 60)
        widthConstraint?.isActive = true
        heightConstraint?.isActive = true
    }

    func updateText(_ text: String) {
        bubbleView.setBubbleText(text)
        setNeedsLayout()
    }

    func applyLinkUnderlineHidden(_ hidden: Bool) {
        bubbleView.applyLinkUnderlineHidden(hidden)
        setNeedsLayout()
    }

    func applyBubbleFontSize(_ size: CGFloat) {
        bubbleView.applyBubbleFontSize(size)
        setNeedsLayout()
    }

    /// 撰写页气泡：填充色走 IMessageDesignTokens 三点渐变；此处只保留尾巴几何。
    private static func composeBubbleParams(_ params: BubbleTailRenderParams) -> BubbleTailRenderParams {
        params
    }

    private func bubbleFitMaxWidth() -> CGFloat {
        let rowWidth = superview?.bounds.width ?? 0
        let screenCap = UIScreen.main.bounds.width * IMessageDesignTokens.bubbleMaxWidthFraction
            - IMessageDesignTokens.layer2ThreadPaddingH
            - IMessageDesignTokens.threadBubbleTrailingInset
        if rowWidth > 1 {
            let rowCap = rowWidth
                - IMessageDesignTokens.layer2ThreadPaddingH
                - IMessageDesignTokens.threadBubbleTrailingInset
            return min(rowCap, screenCap)
        }
        return screenCap
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let bubbleSize = bubbleView.sizeThatFits(
            CGSize(width: bubbleFitMaxWidth(), height: .greatestFiniteMagnitude)
        )
        bubbleView.frame = CGRect(
            x: bounds.width - bubbleSize.width,
            y: 0,
            width: bubbleSize.width,
            height: bubbleSize.height
        )
        bubbleView.layoutIfNeeded()

        widthConstraint?.constant = bubbleSize.width

        guard showsDelivered else {
            heightConstraint?.constant = bubbleSize.height
            return
        }

        let deliveredSize = delivered.sizeThatFits(
            CGSize(width: bounds.width, height: .greatestFiniteMagnitude)
        )
        let tailAnchorX = bubbleView.frame.minX + bubbleView.tailAnchorPointInSelf().x
        let tailBottomY = bubbleView.frame.minY + bubbleView.tailTipPointInSelf().y
        let deliveredY = tailBottomY - deliveredSize.height
            + IMessageDesignTokens.deliveredOffsetBelowTailBottom
        delivered.frame = CGRect(
            x: tailAnchorX - deliveredSize.width - IMessageDesignTokens.deliveredTrailingInset,
            y: deliveredY,
            width: deliveredSize.width,
            height: deliveredSize.height
        )

        heightConstraint?.constant = max(bubbleSize.height, delivered.frame.maxY)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// iOS 26 单图：固定右缘 20pt；满宽按发件人首字中心→右缘推算，尺寸规则同比缩放
final class ComposeImageColumnView: UIView {
    private let imageBubbleView: IOSOutgoingImageBubbleView
    private let delivered = UILabel()
    private let senderLineLabel: String
    private let showsDelivered: Bool
    private var widthConstraint: NSLayoutConstraint?
    private var heightConstraint: NSLayoutConstraint?

    init(image: UIImage, senderLineLabel: String, showsDelivered: Bool) {
        self.senderLineLabel = senderLineLabel
        self.showsDelivered = showsDelivered
        imageBubbleView = IOSOutgoingImageBubbleView(image: image)
        super.init(frame: .zero)
        clipsToBounds = false
        setContentHuggingPriority(.required, for: .horizontal)
        setContentHuggingPriority(.required, for: .vertical)
        setContentCompressionResistancePriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .vertical)

        imageBubbleView.applyRenderParams(.frozenDefault)

        delivered.text = "已送达"
        delivered.font = IMessageDesignTokens.deliveredFontUI
        delivered.textColor = IMessageDesignTokens.threadMetaTextUI
        delivered.textAlignment = .right
        delivered.isHidden = !showsDelivered

        addSubview(imageBubbleView)
        addSubview(delivered)

        widthConstraint = widthAnchor.constraint(equalToConstant: 120)
        heightConstraint = heightAnchor.constraint(equalToConstant: 60)
        widthConstraint?.isActive = true
        heightConstraint?.isActive = true
    }

    /// 线程区全宽（= 屏宽），用于首字→右缘满宽推算
    private func threadContentWidth() -> CGFloat {
        var view: UIView? = self
        while let current = view {
            if let scroll = current.superview as? UIScrollView {
                let width = scroll.bounds.width
                if width > 1 { return width }
                break
            }
            view = current.superview
        }
        return UIScreen.main.bounds.width
    }

    private func imageLayoutMaxWidth() -> CGFloat {
        IMessageDesignTokens.imageBubbleMaxLayoutWidth(
            contentWidth: threadContentWidth(),
            senderLineLabel: senderLineLabel
        )
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let maxLayoutWidth = imageLayoutMaxWidth()
        guard maxLayoutWidth > 1 else { return }

        let bubbleSize = imageBubbleView.sizeThatFits(
            CGSize(width: maxLayoutWidth, height: .greatestFiniteMagnitude)
        )
        guard bubbleSize.width > 1, bubbleSize.height > 1 else { return }

        widthConstraint?.constant = bubbleSize.width
        heightConstraint?.constant = bubbleSize.height

        imageBubbleView.frame = CGRect(
            x: 0,
            y: 0,
            width: bubbleSize.width,
            height: bubbleSize.height
        )
        imageBubbleView.layoutIfNeeded()

        var contentHeight = imageBubbleView.frame.maxY
        if showsDelivered {
            let deliveredSize = delivered.sizeThatFits(
                CGSize(width: bounds.width, height: .greatestFiniteMagnitude)
            )
            let tailAnchorX = imageBubbleView.frame.minX + imageBubbleView.tailAnchorPointInSelf().x
            let tailBottomY = imageBubbleView.frame.minY + imageBubbleView.tailTipPointInSelf().y
            let deliveredY = tailBottomY - deliveredSize.height
                + IMessageDesignTokens.deliveredOffsetBelowTailBottom
            delivered.frame = CGRect(
                x: tailAnchorX - deliveredSize.width - IMessageDesignTokens.deliveredTrailingInset,
                y: deliveredY,
                width: deliveredSize.width,
                height: deliveredSize.height
            )
            contentHeight = max(contentHeight, delivered.frame.maxY)
        }

        heightConstraint?.constant = contentHeight
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
