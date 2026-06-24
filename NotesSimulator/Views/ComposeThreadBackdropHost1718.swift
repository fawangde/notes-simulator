import SwiftUI
import UIKit

/// iOS 17–18 第 2 层聊天底色；scroll / pin 与 26 同算法，token 与气泡 tail 独立
struct ComposeThreadBackdropHost1718: UIViewRepresentable {
    let chromeBottomY: CGFloat
    let composerBottomReserve: CGFloat
    let dateLine: String
    let isBlankThread: Bool
    let messageText: String
    let showsText: Bool
    let showsImage: Bool
    let bothContentOrder: BothContentOrder
    let image: UIImage?
    let senderLineLabel: String
    var showsSenderRow = true
    var bubbleTailParams: IMessage1718BubbleTailParams = .default
    var bubbleFontSize: CGFloat = 17

    func makeUIView(context: Context) -> ComposeThreadScrollView1718 {
        ComposeThreadScrollView1718()
    }

    func updateUIView(_ uiView: ComposeThreadScrollView1718, context: Context) {
        uiView.apply(
            chromeBottomY: chromeBottomY,
            composerBottomReserve: composerBottomReserve,
            dateLine: dateLine,
            isBlankThread: isBlankThread,
            messageText: messageText,
            showsText: showsText,
            showsImage: showsImage,
            bothContentOrder: bothContentOrder,
            image: image,
            senderLineLabel: senderLineLabel,
            showsSenderRow: showsSenderRow,
            bubbleTailParams: bubbleTailParams,
            bubbleFontSize: bubbleFontSize
        )
    }
}

final class ComposeThreadScrollView1718: UIView {
    private let scrollView = UIScrollView()
    private let stack = UIStackView()

    private var chromeBottomY: CGFloat = 0
    private var composerBottomReserve: CGFloat = 0
    private var lastContentHeight: CGFloat = 0
    private var lastComposerReserve: CGFloat = 0
    private var contentSignature: ThreadContentSignature?
    private var bubbleTailParams = IMessage1718BubbleTailParams.default
    private var bubbleFontSize: CGFloat = 17
    private var userDidScroll = false
    /// 默认顶对齐：时间小字在收发件人下 10pt；触线前气泡向下长、offset 保持 0
    private var prefersInitialTopAlignment = true
    /// 已送达贴输入框上 15pt 后进入钉住态，继续加行只上滚
    private var isComposerPinEngaged = false
    /// 布局未稳定前禁止 snap 回顶（避免中/长文案「拽回来」）
    private var settlePassesRemaining = 0
    private var lastReserveDelta: CGFloat = 0
    /// width==0 时 UIStackView 会先算错气泡高度，等 bounds 有效后再 pin
    private var pendingInitialPinAfterBounds = false
    /// 连续两帧 targetY 一致才应用钉住（长文案 multiline 高度滞后） 
    private var pendingTargetY: CGFloat?
    private var pendingPinLineY: CGFloat?
    private var isProgrammaticScroll = false
    /// 键盘 inset 变化后暂缓 reconcile，等 pinLn 稳定
    private var reserveSettlePassesRemaining = 0
    private var lastAnchorBottom: CGFloat = 0

    private struct ThreadContentSignature: Equatable {
        let chromeBottomY: CGFloat
        let dateLine: String
        let isBlankThread: Bool
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
        clipsToBounds = false

        scrollView.backgroundColor = .clear
        scrollView.clipsToBounds = false
        scrollView.alwaysBounceVertical = true
        scrollView.alwaysBounceHorizontal = false
        scrollView.isDirectionalLockEnabled = true
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

    private func relayoutBubbleColumns() {
        func visit(_ view: UIView) {
            if let bubble = view as? ComposeBubbleColumnView1718 {
                bubble.invalidateLayoutForRowWidthChange()
            }
            view.subviews.forEach(visit)
        }
        stack.arrangedSubviews.forEach(visit)
        stack.setNeedsLayout()
        setNeedsLayout()
    }

    private func runInitialPinAfterValidBoundsIfNeeded() {
        guard pendingInitialPinAfterBounds, hasValidBounds(), let signature = contentSignature else { return }
        pendingInitialPinAfterBounds = false
        relayoutBubbleColumns()
        layoutIfNeeded()
        pendingTargetY = nil
        applyPrewarmedEntryOffsetIfMatching(signature: signature)
        scheduleReconcileAfterLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let previousReserve = lastComposerReserve
        scrollView.contentInset.bottom = composerBottomReserve
        scrollView.contentInset.right = 0

        guard hasValidBounds() else {
            pendingInitialPinAfterBounds = contentSignature != nil
            publishDebugSnapshot(source: "layout:wait-bounds")
            return
        }

        runInitialPinAfterValidBoundsIfNeeded()
        let reserveDelta = composerBottomReserve - previousReserve
        let reserveChanged = abs(reserveDelta) > 0.5
        lastReserveDelta = reserveChanged ? reserveDelta : 0

        if ComposeThread1718Session.isClosing {
            lastComposerReserve = composerBottomReserve
            publishDebugSnapshot(source: "layout:closing-freeze")
            return
        }

        if reserveChanged {
            pendingTargetY = nil
            pendingPinLineY = nil
            reserveSettlePassesRemaining = max(reserveSettlePassesRemaining, 4)
            // 仅已有 scroll 时平移 offset；offset=0 时不加 Δres（键盘弹起不应把顶对齐拽走）
            if scrollView.contentOffset.y > 0.5 {
                let maxY = maxScrollOffsetY()
                let adjusted = max(0, min(scrollView.contentOffset.y + reserveDelta, maxY))
                if abs(adjusted - scrollView.contentOffset.y) > 0.5 {
                    setScrollOffsetY(adjusted, animated: false)
                }
            }
            lastComposerReserve = composerBottomReserve
            publishDebugSnapshot(source: "layout:reserve-settle Δ\(String(format: "%.0f", reserveDelta))")
            return
        }

        if reserveSettlePassesRemaining > 0 {
            reserveSettlePassesRemaining -= 1
            lastComposerReserve = composerBottomReserve
            publishDebugSnapshot(source: "layout:reserve-wait-\(reserveSettlePassesRemaining)")
            return
        }

        lastComposerReserve = composerBottomReserve
        guard !userDidScroll else { return }
        if prefersInitialTopAlignment, !reserveChanged, !isComposerPinEngaged {
            // 触线前保持 offset=0 随气泡向下长；一旦 anchor 越过钉住线必须 reconcile
            if targetPinnedOffsetY().targetY <= 0.5 {
                publishDebugSnapshot(source: "layout:hold-top")
                return
            }
        }
        reconcileScrollOffset(animated: false, source: reserveChanged ? "layout:reserve" : "layout")
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func apply(
        chromeBottomY: CGFloat,
        composerBottomReserve: CGFloat,
        dateLine: String,
        isBlankThread: Bool,
        messageText: String,
        showsText: Bool,
        showsImage: Bool,
        bothContentOrder: BothContentOrder,
        image: UIImage?,
        senderLineLabel: String,
        showsSenderRow: Bool,
        bubbleTailParams: IMessage1718BubbleTailParams,
        bubbleFontSize: CGFloat
    ) {
        let reserveChanged = abs(composerBottomReserve - self.composerBottomReserve) > 0.5
        self.composerBottomReserve = composerBottomReserve
        let tailParamsChanged = self.bubbleTailParams != bubbleTailParams
        self.bubbleTailParams = bubbleTailParams
        let fontChanged = abs(self.bubbleFontSize - bubbleFontSize) > 0.25
        self.bubbleFontSize = bubbleFontSize

        let signature = ThreadContentSignature(
            chromeBottomY: chromeBottomY,
            dateLine: dateLine,
            isBlankThread: isBlankThread,
            messageText: messageText,
            showsText: showsText,
            showsImage: showsImage,
            bothContentOrder: bothContentOrder,
            imageKey: Self.imageLayoutKey(for: image),
            showsSenderRow: showsSenderRow
        )

        if signature == contentSignature {
            if tailParamsChanged {
                updateVisibleBubbleTailParams(bubbleTailParams)
            }
            if fontChanged {
                updateVisibleBubbleFontSize(bubbleFontSize)
            }
            if reserveChanged || tailParamsChanged || fontChanged || signature.showsImage {
                setNeedsLayout()
                layoutIfNeeded()
                if fontChanged {
                    pendingTargetY = nil
                    pendingPinLineY = nil
                    scheduleReconcileAfterLayout()
                }
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
           previous.messageText != signature.messageText || previous.dateLine != signature.dateLine {
            contentSignature = signature
            updateVisibleMessageText(signature.messageText, dateLine: signature.dateLine)
            setNeedsLayout()
            pendingTargetY = nil
            pendingPinLineY = nil
            settlePassesRemaining = 3
            lastAnchorBottom = 0
            scheduleReconcileAfterLayout()
            return
        }

        contentSignature = signature
        self.chromeBottomY = chromeBottomY
        ComposeThread1718Session.isClosing = false
        userDidScroll = false
        prefersInitialTopAlignment = true
        isComposerPinEngaged = false

        stack.arrangedSubviews.forEach {
            stack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        let topSpacer = fixedSpacer(
            chromeBottomY
                + IMessage1718DesignTokens.threadTimestampBelowCard
                + IMessage1718DesignTokens.layer2TimeOffsetY
        )
        stack.addArrangedSubview(topSpacer)

        if isBlankThread {
            stack.addArrangedSubview(
                fixedSpacer(IMessageDesignTokens.threadManualScrollSlack)
            )
            lastContentHeight = 0
            pendingTargetY = nil
            pendingPinLineY = nil
            reserveSettlePassesRemaining = 0
            lastAnchorBottom = 0
            scrollView.contentOffset = .zero
            pendingInitialPinAfterBounds = true
            setNeedsLayout()
            if hasValidBounds() {
                layoutIfNeeded()
                pendingInitialPinAfterBounds = false
                scheduleReconcileAfterLayout()
            }
            return
        }

        stack.addArrangedSubview(
            centeredMetaRow(
                makeThreadHeaderStack(dateLine: dateLine)
            )
        )

        stack.addArrangedSubview(
            fixedSpacer(IMessage1718DesignTokens.threadBubbleBelowTimestamp)
        )

        appendMessageContent(
            messageText: messageText,
            showsText: showsText,
            showsImage: showsImage,
            bothContentOrder: bothContentOrder,
            image: image,
            senderLineLabel: senderLineLabel,
            showsSenderRow: showsSenderRow
        )

        stack.addArrangedSubview(
            fixedSpacer(IMessageDesignTokens.threadManualScrollSlack)
        )

        lastContentHeight = 0
        pendingTargetY = nil
        pendingPinLineY = nil
        reserveSettlePassesRemaining = 0
        lastAnchorBottom = 0
        scrollView.contentOffset = .zero
        pendingInitialPinAfterBounds = true
        setNeedsLayout()
        if hasValidBounds() {
            layoutIfNeeded()
            relayoutBubbleColumns()
            layoutIfNeeded()
            pendingInitialPinAfterBounds = false
            applyPrewarmedEntryOffsetIfMatching(signature: signature)
            scheduleReconcileAfterLayout()
        }
    }

    private func applyPrewarmedEntryOffsetIfMatching(signature: ThreadContentSignature) {
        let cacheKey = ComposeThread1718PinWarmup.cacheKey(
            messageText: signature.messageText,
            dateLine: signature.dateLine,
            chromeBottomY: signature.chromeBottomY,
            bubbleTailPresetID: bubbleTailParams.presetID,
            bubbleFontSize: bubbleFontSize
        )
        if let prewarm = ComposeThread1718PinWarmup.current, prewarm.cacheKey == cacheKey {
            ComposeThreadPinDebug1718.shared.log(
                "prewarm-hint off=\(String(format: "%.1f", prewarm.initialOffsetY)) (live reconcile decides)"
            )
        }
        settlePassesRemaining = 4
    }

    /// 等多行气泡高度稳定后再判断是否触线钉住（首帧 + 次帧 + 第三帧 + 第四帧）
    private func scheduleReconcileAfterLayout() {
        func pass(_ tag: String, next: (() -> Void)?) {
            guard hasValidBounds() else {
                pendingInitialPinAfterBounds = true
                publishDebugSnapshot(source: "\(tag):wait-bounds")
                guard let next else { return }
                DispatchQueue.main.async(execute: next)
                return
            }
            layoutIfNeeded()
            reconcileScrollOffset(animated: false, source: tag)
            lastContentHeight = scrollView.contentSize.height
            guard let next else {
                ComposeBackdropRegistry.notifyChanged()
                return
            }
            DispatchQueue.main.async(execute: next)
        }
        DispatchQueue.main.async {
            pass("reconcile:1") {
                pass("reconcile:2") {
                    pass("reconcile:3") {
                        pass("reconcile:4", next: nil)
                    }
                }
            }
        }
    }

    private func setScrollOffsetY(_ y: CGFloat, animated: Bool) {
        isProgrammaticScroll = true
        scrollView.setContentOffset(CGPoint(x: 0, y: y), animated: animated)
        isProgrammaticScroll = false
    }

    private func updateVisibleBubbleTailParams(_ params: IMessage1718BubbleTailParams) {
        func visit(_ view: UIView) {
            if let bubble = view as? ComposeBubbleColumnView1718 {
                bubble.applyTailParams(params)
            } else if let column = view as? ComposeImageColumnView1718 {
                column.applyTailParams(params)
            }
            view.subviews.forEach { visit($0) }
        }
        stack.arrangedSubviews.forEach { visit($0) }
    }

    private func updateVisibleBubbleFontSize(_ size: CGFloat) {
        func visit(_ view: UIView) {
            if let bubble = view as? ComposeBubbleColumnView1718 {
                bubble.applyBubbleFontSize(size)
            }
            view.subviews.forEach { visit($0) }
        }
        stack.arrangedSubviews.forEach { visit($0) }
        stack.setNeedsLayout()
        setNeedsLayout()
    }

    private func updateVisibleMessageText(_ text: String, dateLine: String) {
        func visit(_ view: UIView) {
            if let bubble = view as? ComposeBubbleColumnView1718 {
                bubble.updateText(text)
            } else if let header = view as? UIStackView,
                      header.arrangedSubviews.contains(where: { $0 is UILabel }) {
                (header.arrangedSubviews.last as? UILabel)?.text = dateLine
            }
            view.subviews.forEach { visit($0) }
        }
        stack.arrangedSubviews.forEach { visit($0) }
        stack.setNeedsLayout()
        setNeedsLayout()
    }

    private func appendMessageContent(
        messageText: String,
        showsText: Bool,
        showsImage: Bool,
        bothContentOrder: BothContentOrder,
        image: UIImage?,
        senderLineLabel: String,
        showsSenderRow: Bool
    ) {
        let trailingInset = bubbleTailParams.threadBubbleTrailingInset
        let addText = {
            guard showsText else { return }
            let bubble = ComposeBubbleColumnView1718(
                text: messageText,
                bubbleTailParams: self.bubbleTailParams,
                senderLineLabel: senderLineLabel,
                showsSenderRow: showsSenderRow,
                bubbleFontSize: self.bubbleFontSize
            )
            let bubbleRow = self.trailingRow(
                bubble,
                horizontalPadding: trailingInset
            )
            self.stack.addArrangedSubview(bubbleRow)
        }

        let addImage = {
            guard showsImage, let image else { return }
            let column = ComposeImageColumnView1718(
                image: image,
                bubbleTailParams: self.bubbleTailParams,
                senderLineLabel: senderLineLabel,
                showsSenderRow: showsSenderRow,
                showsDelivered: !showsText
            )
            let imageRow = self.trailingRow(
                column,
                horizontalPadding: trailingInset
            )
            self.stack.addArrangedSubview(imageRow)
        }

        switch bothContentOrder {
        case .textFirst:
            addText()
            addImage()
        case .imageFirst:
            addImage()
            addText()
        }
    }

    private func makeThreadHeaderStack(dateLine: String) -> UIStackView {
        let headerStack = UIStackView()
        headerStack.axis = .vertical
        headerStack.alignment = .center
        headerStack.spacing = IMessage1718DesignTokens.timestampLineSpacing

        let serviceLabel = makeThreadMetaLabel(text: "iMessage 信息")
        headerStack.addArrangedSubview(serviceLabel)

        let dateLabel = makeThreadMetaLabel(text: dateLine)
        headerStack.addArrangedSubview(dateLabel)

        return headerStack
    }

    private func makeThreadMetaLabel(text: String) -> UILabel {
        let label = UILabel()
        label.font = IMessage1718DesignTokens.threadMetaFontUI
        label.textColor = IMessage1718DesignTokens.threadMetaTextUI
        label.textAlignment = .center
        label.text = text
        return label
    }

    private func fixedSpacer(_ height: CGFloat) -> UIView {
        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        spacer.heightAnchor.constraint(equalToConstant: height).isActive = true
        return spacer
    }

    private func centeredMetaRow(_ view: UIView) -> UIView {
        let row = UIView()
        row.translatesAutoresizingMaskIntoConstraints = false
        view.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(view)
        NSLayoutConstraint.activate([
            view.centerXAnchor.constraint(equalTo: row.centerXAnchor),
            view.topAnchor.constraint(equalTo: row.topAnchor),
            view.bottomAnchor.constraint(equalTo: row.bottomAnchor),
            view.leadingAnchor.constraint(greaterThanOrEqualTo: row.leadingAnchor),
            view.trailingAnchor.constraint(lessThanOrEqualTo: row.trailingAnchor),
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

    private func messagePinAnchorBottomY() -> CGFloat? {
        scrollView.layoutIfNeeded()
        stack.layoutIfNeeded()

        var rows = stack.arrangedSubviews
        guard rows.count > 1 else { return nil }
        rows.removeLast()

        for row in rows.reversed() {
            for child in row.subviews {
                if let column = child as? ComposeBubbleColumnView1718 {
                    column.layoutIfNeeded()
                    return column.pinAnchorBottomY(in: stack)
                }
                if let column = child as? ComposeImageColumnView1718 {
                    column.layoutIfNeeded()
                    return column.pinAnchorBottomY(in: stack)
                }
            }
        }
        return nil
    }

    private struct PinMetrics {
        let targetY: CGFloat
        let anchorBottom: CGFloat
        let composerPinLine: CGFloat
        let insetBottom: CGFloat
        let bubbleRowSize: CGSize
        let textLineCount: Int

        var gapToPinLine: CGFloat { anchorBottom - composerPinLine }
    }

    private func composerPinLineY(viewport: CGFloat) -> CGFloat {
        ComposeThread1718PinMath.composerPinLineY(
            viewport: viewport,
            insetBottom: scrollView.contentInset.bottom
        )
    }

    private func pinMetrics() -> PinMetrics {
        scrollView.layoutIfNeeded()
        stack.layoutIfNeeded()
        let viewport = scrollView.bounds.height
        let insetBottom = scrollView.contentInset.bottom
        let composerPinLine = viewport > 0 ? composerPinLineY(viewport: viewport) : 0
        let anchorBottom = messagePinAnchorBottomY() ?? 0
        let bubbleRowSize = bubbleRowDimensions()
        let textLineCount = bubbleTextLineCount()

        guard viewport > 0, anchorBottom > 0, composerPinLine > 0 else {
            return PinMetrics(
                targetY: 0,
                anchorBottom: anchorBottom,
                composerPinLine: composerPinLine,
                insetBottom: insetBottom,
                bubbleRowSize: bubbleRowSize,
                textLineCount: textLineCount
            )
        }

        if anchorBottom <= composerPinLine + 0.5 {
            return PinMetrics(
                targetY: 0,
                anchorBottom: anchorBottom,
                composerPinLine: composerPinLine,
                insetBottom: insetBottom,
                bubbleRowSize: bubbleRowSize,
                textLineCount: textLineCount
            )
        }

        // 长文案首次入场：已送达还在视口下方时先顶对齐
        let offsetY = scrollView.contentOffset.y
        if offsetY <= 0.5, !isComposerPinEngaged, anchorBottom > viewport - 1 {
            return PinMetrics(
                targetY: 0,
                anchorBottom: anchorBottom,
                composerPinLine: composerPinLine,
                insetBottom: insetBottom,
                bubbleRowSize: bubbleRowSize,
                textLineCount: textLineCount
            )
        }

        let pinOffset = anchorBottom - composerPinLine
        let maxY = ComposeThread1718PinMath.naturalMaxScrollOffsetY(
            viewport: viewport,
            contentHeight: scrollView.contentSize.height,
            insetBottom: insetBottom
        )
        return PinMetrics(
            targetY: max(0, min(pinOffset, maxY)),
            anchorBottom: anchorBottom,
            composerPinLine: composerPinLine,
            insetBottom: insetBottom,
            bubbleRowSize: bubbleRowSize,
            textLineCount: textLineCount
        )
    }

    private func bubbleRowDimensions() -> CGSize {
        for row in stack.arrangedSubviews.reversed() {
            for child in row.subviews where child is ComposeBubbleColumnView1718 {
                row.layoutIfNeeded()
                return row.bounds.size
            }
        }
        return .zero
    }

    private func bubbleTextLineCount() -> Int {
        for row in stack.arrangedSubviews.reversed() {
            for child in row.subviews {
                if let column = child as? ComposeBubbleColumnView1718 {
                    return column.textLineCount()
                }
            }
        }
        return 0
    }

    private func targetPinnedOffsetY() -> PinMetrics {
        pinMetrics()
    }

    private func publishDebugSnapshot(source: String) {
        let metrics = pinMetrics()
        let phase: String
        if isComposerPinEngaged {
            phase = "pinned"
        } else if metrics.targetY > 0.5 {
            phase = "should-pin"
        } else if prefersInitialTopAlignment {
            phase = "top-align"
        } else {
            phase = "free"
        }
        ComposeThreadPinDebug1718.shared.publish(
            .init(
                phase: phase,
                source: source,
                prefersTop: prefersInitialTopAlignment,
                pinEngaged: isComposerPinEngaged,
                userScrolled: userDidScroll,
                isClosing: ComposeThread1718Session.isClosing,
                offsetY: scrollView.contentOffset.y,
                targetY: metrics.targetY,
                anchorBottom: metrics.anchorBottom,
                composerPinLine: metrics.composerPinLine,
                insetBottom: metrics.insetBottom,
                reserveDelta: lastReserveDelta,
                gapToPinLine: metrics.gapToPinLine,
                contentH: scrollView.contentSize.height,
                viewportH: scrollView.bounds.height,
                bubbleRowH: metrics.bubbleRowSize.height,
                bubbleRowW: metrics.bubbleRowSize.width,
                textLines: metrics.textLineCount,
                prewarmOffset: ComposeThread1718PinWarmup.current?.initialOffsetY ?? 0
            )
        )
    }

    private func isLayoutStable(_ metrics: PinMetrics) -> Bool {
        guard hasValidBounds() else { return false }
        return metrics.bubbleRowSize.width > 10 && metrics.bubbleRowSize.height > 62
    }

    private func reconcileScrollOffset(animated: Bool, source: String) {
        if ComposeThread1718Session.isClosing {
            publishDebugSnapshot(source: "reconcile:closing-skip")
            return
        }
        guard hasValidBounds() else {
            pendingInitialPinAfterBounds = true
            publishDebugSnapshot(source: "\(source):wait-bounds")
            return
        }
        if scrollView.contentOffset.x != 0 {
            scrollView.contentOffset.x = 0
        }

        let maxY = maxScrollOffsetY()
        let contentH = scrollView.contentSize.height
        let metrics = targetPinnedOffsetY()
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
                // 已钉住：始终跟踪 pinLn（键盘动画期间 pinLn 下移时 offset 也要跟着减）
                nextY = clampedY
                pendingTargetY = nil
                pendingPinLineY = nil
            } else {
                // 首次钉住：targetY + pinLn 连续两帧一致才应用
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
                    publishDebugSnapshot(source: "\(source):pending-tgt-\(String(format: "%.0f", clampedY))")
                    lastContentHeight = contentH
                    return
                }
            }
            if abs(scrollView.contentOffset.y - nextY) > 0.5 {
                setScrollOffsetY(nextY, animated: animated)
            }
            lastContentHeight = contentH
            publishDebugSnapshot(source: source)
            return
        }

        lastAnchorBottom = metrics.anchorBottom
        pendingTargetY = nil
        pendingPinLineY = nil

        let stable = isLayoutStable(metrics)
        let allowSnapBack = stable && settlePassesRemaining == 0 && reserveSettlePassesRemaining == 0
        if !allowSnapBack, scrollView.contentOffset.y > 0.5 {
            // 布局 / 键盘 inset 未稳定时保留当前 offset
            isComposerPinEngaged = true
            prefersInitialTopAlignment = false
        } else if isComposerPinEngaged, metrics.gapToPinLine > 0.5, targetY <= 0.5 {
            // pinLn 仍在动导致 target 暂时为 0，保持钉住态并贴齐当前 pinLn
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
        publishDebugSnapshot(source: source)
    }
}

extension ComposeThreadScrollView1718: UIScrollViewDelegate {
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
}

private final class ComposeBubbleColumnView1718: UIView {
    private let bubbleView: IOSOutgoingChatBubbleView1718
    private let delivered = UILabel()
    private var bubbleTailParams: IMessage1718BubbleTailParams
    private let senderLineLabel: String
    private let showsSenderRow: Bool
    private var widthConstraint: NSLayoutConstraint?
    private var heightConstraint: NSLayoutConstraint?

    init(
        text: String,
        bubbleTailParams: IMessage1718BubbleTailParams,
        senderLineLabel: String,
        showsSenderRow: Bool,
        bubbleFontSize: CGFloat = 17
    ) {
        self.bubbleTailParams = bubbleTailParams
        self.senderLineLabel = senderLineLabel
        self.showsSenderRow = showsSenderRow
        bubbleView = IOSOutgoingChatBubbleView1718(tailParams: bubbleTailParams)
        super.init(frame: .zero)
        clipsToBounds = false
        setContentHuggingPriority(.required, for: .horizontal)
        setContentHuggingPriority(.required, for: .vertical)
        setContentCompressionResistancePriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .vertical)

        bubbleView.applyBubbleFontSize(bubbleFontSize)
        bubbleView.setBubbleText(text)

        delivered.text = "已送达"
        delivered.font = IMessage1718DesignTokens.deliveredFontUI
        delivered.textColor = IMessage1718DesignTokens.threadMetaTextUI
        delivered.textAlignment = .right

        addSubview(bubbleView)
        addSubview(delivered)

        widthConstraint = widthAnchor.constraint(equalToConstant: 120)
        heightConstraint = heightAnchor.constraint(equalToConstant: 60)
        widthConstraint?.priority = UILayoutPriority(999)
        heightConstraint?.priority = UILayoutPriority(999)
        widthConstraint?.isActive = true
        heightConstraint?.isActive = true
    }

    func invalidateLayoutForRowWidthChange() {
        setNeedsLayout()
    }

    func applyTailParams(_ params: IMessage1718BubbleTailParams) {
        bubbleTailParams = params
        bubbleView.applyTailParams(params)
        setNeedsLayout()
    }

    func applyBubbleFontSize(_ size: CGFloat) {
        bubbleView.applyBubbleFontSize(size)
        setNeedsLayout()
    }

    func updateText(_ text: String) {
        bubbleView.setBubbleText(text)
        setNeedsLayout()
    }

    func prepareForWidth(_ rowWidth: CGFloat) {
        guard rowWidth > 10 else { return }
        let maxW = min(
            rowWidth,
            UIScreen.main.bounds.width * IMessage1718DesignTokens.bubbleMaxWidthFraction
        )
        bubbleView.label.preferredMaxLayoutWidth = max(1, maxW - 40)
    }

    func pinAnchorBottomY(in stack: UIStackView) -> CGFloat {
        layoutIfNeeded()
        return delivered.convert(CGPoint(x: 0, y: delivered.bounds.height), to: stack).y
    }

    func textLineCount() -> Int {
        layoutIfNeeded()
        return bubbleView.label.numberOfLines > 0
            ? bubbleView.label.numberOfLines
            : max(1, bubbleView.label.text?.components(separatedBy: "\n").count ?? 1)
    }

    private func bubbleFitMaxWidth() -> CGFloat {
        let rowWidth = superview?.bounds.width ?? 0
        let tailReserve = bubbleTailParams.tailHorizontalOverflow
        let trailingInset = bubbleTailParams.threadBubbleTrailingInset
        let contentWidth = rowWidth > 1 ? rowWidth : UIScreen.main.bounds.width

        let senderCap = IMessage1718DesignTokens.imageBubbleMaxLayoutWidth(
            contentWidth: contentWidth,
            senderLineLabel: senderLineLabel,
            trailingInset: trailingInset,
            showsSenderRow: showsSenderRow
        )
        let screenCap = UIScreen.main.bounds.width * IMessage1718DesignTokens.bubbleMaxWidthFraction
            - IMessage1718DesignTokens.layer2ThreadPaddingH * 2
            - bubbleTailParams.threadBubbleMaxWidthReduction
            + IMessage1718DesignTokens.bubbleMaxWidthExtra
            - tailReserve
        return max(1, min(senderCap, screenCap))
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let rowWidth = superview?.bounds.width ?? 0
        guard rowWidth > 10 else { return }

        prepareForWidth(rowWidth)

        let tailReserve = bubbleTailParams.tailHorizontalOverflow
        let bubbleSize = bubbleView.sizeThatFits(
            CGSize(
                width: bubbleFitMaxWidth() + tailReserve,
                height: .greatestFiniteMagnitude
            )
        )
        bubbleView.frame = CGRect(
            x: bounds.width - bubbleSize.width,
            y: 0,
            width: bubbleSize.width,
            height: bubbleSize.height
        )
        bubbleView.layoutIfNeeded()

        let deliveredSize = delivered.sizeThatFits(
            CGSize(width: bounds.width, height: .greatestFiniteMagnitude)
        )
        let tailAnchorX = bubbleView.frame.minX + bubbleView.tailAnchorPointInSelf().x
        let tailBottomY = bubbleView.frame.minY + bubbleView.tailTipPointInSelf().y
        let deliveredY = tailBottomY - deliveredSize.height
            + IMessage1718DesignTokens.deliveredOffsetBelowTailBottom
        let deliveredX = tailAnchorX - deliveredSize.width
        delivered.frame = CGRect(
            x: deliveredX,
            y: deliveredY,
            width: deliveredSize.width,
            height: deliveredSize.height
        )

        widthConstraint?.constant = bubbleSize.width
        heightConstraint?.constant = max(
            bubbleSize.height,
            delivered.frame.maxY + bubbleTailParams.tailClipReserveBottom
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private final class ComposeImageColumnView1718: UIView {
    private let imageBubbleView: IOSOutgoingImageBubbleView1718
    private let delivered = UILabel()
    private var bubbleTailParams: IMessage1718BubbleTailParams
    private let senderLineLabel: String
    private let showsSenderRow: Bool
    private let showsDelivered: Bool
    private var widthConstraint: NSLayoutConstraint?
    private var heightConstraint: NSLayoutConstraint?

    init(
        image: UIImage,
        bubbleTailParams: IMessage1718BubbleTailParams,
        senderLineLabel: String,
        showsSenderRow: Bool,
        showsDelivered: Bool
    ) {
        self.bubbleTailParams = bubbleTailParams
        self.senderLineLabel = senderLineLabel
        self.showsSenderRow = showsSenderRow
        self.showsDelivered = showsDelivered
        imageBubbleView = IOSOutgoingImageBubbleView1718(
            image: image,
            tailParams: bubbleTailParams
        )
        super.init(frame: .zero)
        clipsToBounds = false
        setContentHuggingPriority(.required, for: .horizontal)
        setContentHuggingPriority(.required, for: .vertical)
        setContentCompressionResistancePriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .vertical)

        delivered.text = "已送达"
        delivered.font = IMessage1718DesignTokens.deliveredFontUI
        delivered.textColor = IMessage1718DesignTokens.threadMetaTextUI
        delivered.textAlignment = .right
        delivered.isHidden = !showsDelivered

        addSubview(imageBubbleView)
        addSubview(delivered)

        widthConstraint = widthAnchor.constraint(equalToConstant: 120)
        heightConstraint = heightAnchor.constraint(equalToConstant: 60)
        widthConstraint?.priority = UILayoutPriority(999)
        heightConstraint?.priority = UILayoutPriority(999)
        widthConstraint?.isActive = true
        heightConstraint?.isActive = true
    }

    func applyTailParams(_ params: IMessage1718BubbleTailParams) {
        bubbleTailParams = params
        imageBubbleView.applyTailParams(params)
        setNeedsLayout()
    }

    func pinAnchorBottomY(in stack: UIStackView) -> CGFloat {
        layoutIfNeeded()
        if showsDelivered, !delivered.isHidden {
            return delivered.convert(CGPoint(x: 0, y: delivered.bounds.height), to: stack).y
        }
        return convert(CGPoint(x: 0, y: bounds.height), to: stack).y
    }

    private func imageFitMaxWidth(rowWidth: CGFloat) -> CGFloat {
        let tailReserve = bubbleTailParams.tailHorizontalOverflow
        let trailingInset = bubbleTailParams.threadBubbleTrailingInset
        let contentWidth = rowWidth > 1 ? rowWidth : UIScreen.main.bounds.width

        let senderCap = IMessage1718DesignTokens.imageBubbleMaxLayoutWidth(
            contentWidth: contentWidth,
            senderLineLabel: senderLineLabel,
            trailingInset: trailingInset,
            showsSenderRow: showsSenderRow
        )
        let screenCap = UIScreen.main.bounds.width * IMessage1718DesignTokens.bubbleMaxWidthFraction
            - IMessage1718DesignTokens.layer2ThreadPaddingH * 2
            - bubbleTailParams.threadBubbleMaxWidthReduction
            + IMessage1718DesignTokens.bubbleMaxWidthExtra
            - tailReserve
        return max(1, min(senderCap, screenCap))
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let rowWidth = superview?.bounds.width ?? 0
        guard rowWidth > 10 else { return }

        let maxBodyWidth = imageFitMaxWidth(rowWidth: rowWidth)
        let bubbleSize = imageBubbleView.sizeThatFits(
            CGSize(width: maxBodyWidth, height: .greatestFiniteMagnitude)
        )
        guard bubbleSize.width > 1, bubbleSize.height > 1 else { return }

        imageBubbleView.frame = CGRect(
            x: bounds.width - bubbleSize.width,
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
                + IMessage1718DesignTokens.deliveredOffsetBelowTailBottom
            delivered.frame = CGRect(
                x: tailAnchorX - deliveredSize.width,
                y: deliveredY,
                width: deliveredSize.width,
                height: deliveredSize.height
            )
            contentHeight = max(contentHeight, delivered.frame.maxY + bubbleTailParams.tailClipReserveBottom)
        }

        widthConstraint?.constant = bubbleSize.width
        heightConstraint?.constant = contentHeight
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Pin math & entry prewarm

enum ComposeThread1718PinMath {
    static func composerPinLineY(viewport: CGFloat, insetBottom: CGFloat) -> CGFloat {
        let keyboardSafeInset = max(
            0,
            insetBottom
                - IMessage1718DesignTokens.composerToolbarReserveBlock
                - IMessage1718DesignTokens.threadDeliveredAboveInput
        )
        let pinInsetFromBottom =
            IMessage1718DesignTokens.threadDeliveredPinInsetFromScrollBottom + keyboardSafeInset
        return viewport - pinInsetFromBottom
    }

    static func naturalMaxScrollOffsetY(
        viewport: CGFloat,
        contentHeight: CGFloat,
        insetBottom: CGFloat
    ) -> CGFloat {
        guard viewport > 0 else { return 0 }
        let content = contentHeight + insetBottom
        return max(0, content - viewport)
    }

    static func targetOffsetY(
        anchorBottom: CGFloat,
        viewport: CGFloat,
        insetBottom: CGFloat,
        contentHeight: CGFloat
    ) -> CGFloat {
        guard viewport > 0, anchorBottom > 0 else { return 0 }
        let composerPinLine = composerPinLineY(viewport: viewport, insetBottom: insetBottom)
        guard composerPinLine > 0, anchorBottom > composerPinLine + 0.5 else { return 0 }
        let pinOffset = anchorBottom - composerPinLine
        let maxY = naturalMaxScrollOffsetY(
            viewport: viewport,
            contentHeight: contentHeight,
            insetBottom: insetBottom
        )
        return max(0, min(pinOffset, maxY))
    }
}

enum ComposeThread1718PinWarmup {
    struct Snapshot: Equatable {
        let cacheKey: String
        let initialOffsetY: CGFloat
        let prefersTopAlign: Bool
    }

    private(set) static var current: Snapshot?

    static func cacheKey(
        messageText: String,
        dateLine: String,
        chromeBottomY: CGFloat,
        bubbleTailPresetID: String,
        bubbleFontSize: CGFloat
    ) -> String {
        "\(messageText)|\(dateLine)|\(chromeBottomY)|\(bubbleTailPresetID)|\(bubbleFontSize)"
    }

    @MainActor
    static func refresh(app: AppState, keyboardTopInset: CGFloat = 0) {
        guard app.usesLegacyNotesShell, app.showsMessageText else {
            current = nil
            return
        }

        let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)
        let bounds = window?.bounds ?? UIScreen.main.bounds
        let safeTop = window?.safeAreaInsets.top ?? 0
        let safeBottom = window?.safeAreaInsets.bottom ?? 0
        let topGap = IMessage1718DesignTokens.composeSheetTopInset(safeAreaTop: safeTop)
        let viewport = bounds.height - topGap
        let chromeBottomY = IMessage1718DesignTokens.addressChromeBottom(
            showsSenderRow: app.simCardMode == .dual
        )
        let composerPadding: CGFloat
        if keyboardTopInset > 0 {
            composerPadding = keyboardTopInset + IMessage1718DesignTokens.layer3KeyboardGap
        } else {
            composerPadding = safeBottom
        }
        let insetBottom = IMessage1718DesignTokens.composerToolbarReserveBlock
            + composerPadding
            + IMessage1718DesignTokens.threadDeliveredAboveInput
        let bridgedTuning = app.bridgedLegacyTuningForCompose()
        let tailParams = IMessage1718BubbleTailPreset.resolvedParams(
            presetID: bridgedTuning.bubbleTailPresetID,
            tuning: bridgedTuning
        )
        let cacheKey = cacheKey(
            messageText: app.messagePreviewText,
            dateLine: app.threadDateLine,
            chromeBottomY: chromeBottomY,
            bubbleTailPresetID: tailParams.presetID,
            bubbleFontSize: CGFloat(app.composeBubbleTuning.fontSize)
        )

        if current?.cacheKey == cacheKey { return }

        let measured = ComposeThread1718MeasureHarness.measure(
            messageText: app.messagePreviewText,
            dateLine: app.threadDateLine,
            chromeBottomY: chromeBottomY,
            bubbleTailParams: tailParams,
            senderLineLabel: app.senderLineLabel,
            showsSenderRow: app.simCardMode == .dual,
            bubbleFontSize: CGFloat(app.composeBubbleTuning.fontSize),
            viewport: viewport,
            insetBottom: insetBottom,
            contentWidth: bounds.width
        )
        let offsetY = ComposeThread1718PinMath.targetOffsetY(
            anchorBottom: measured.anchorBottom,
            viewport: viewport,
            insetBottom: insetBottom,
            contentHeight: measured.contentHeight
        )
        current = Snapshot(
            cacheKey: cacheKey,
            initialOffsetY: offsetY,
            prefersTopAlign: offsetY <= 0.5
        )
        ComposeThreadPinDebug1718.shared.log(
            "prewarm-compute off=\(String(format: "%.1f", offsetY)) kb=\(String(format: "%.0f", keyboardTopInset)) anchor=\(String(format: "%.1f", measured.anchorBottom)) pinLn=\(String(format: "%.1f", ComposeThread1718PinMath.composerPinLineY(viewport: viewport, insetBottom: insetBottom)))"
        )
    }
}

private enum ComposeThread1718MeasureHarness {
    struct Result {
        let anchorBottom: CGFloat
        let contentHeight: CGFloat
    }

    static func measure(
        messageText: String,
        dateLine: String,
        chromeBottomY: CGFloat,
        bubbleTailParams: IMessage1718BubbleTailParams,
        senderLineLabel: String,
        showsSenderRow: Bool,
        bubbleFontSize: CGFloat,
        viewport: CGFloat,
        insetBottom: CGFloat,
        contentWidth: CGFloat
    ) -> Result {
        let host = UIView(frame: CGRect(x: 0, y: 0, width: contentWidth, height: viewport + insetBottom + 800))
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        host.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: host.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: host.trailingAnchor),
            stack.topAnchor.constraint(equalTo: host.topAnchor),
            stack.widthAnchor.constraint(equalToConstant: contentWidth),
        ])

        func fixedSpacer(_ height: CGFloat) -> UIView {
            let spacer = UIView()
            spacer.translatesAutoresizingMaskIntoConstraints = false
            spacer.heightAnchor.constraint(equalToConstant: height).isActive = true
            return spacer
        }

        stack.addArrangedSubview(
            fixedSpacer(
                chromeBottomY
                    + IMessage1718DesignTokens.threadTimestampBelowCard
                    + IMessage1718DesignTokens.layer2TimeOffsetY
            )
        )

        let headerStack = UIStackView()
        headerStack.axis = .vertical
        headerStack.alignment = .center
        headerStack.spacing = IMessage1718DesignTokens.timestampLineSpacing
        for text in ["iMessage 信息", dateLine] {
            let label = UILabel()
            label.font = IMessage1718DesignTokens.threadMetaFontUI
            label.text = text
            label.textAlignment = .center
            headerStack.addArrangedSubview(label)
        }
        let headerRow = UIView()
        headerRow.translatesAutoresizingMaskIntoConstraints = false
        headerStack.translatesAutoresizingMaskIntoConstraints = false
        headerRow.addSubview(headerStack)
        NSLayoutConstraint.activate([
            headerStack.centerXAnchor.constraint(equalTo: headerRow.centerXAnchor),
            headerStack.topAnchor.constraint(equalTo: headerRow.topAnchor),
            headerStack.bottomAnchor.constraint(equalTo: headerRow.bottomAnchor),
        ])
        stack.addArrangedSubview(headerRow)

        stack.addArrangedSubview(
            fixedSpacer(IMessage1718DesignTokens.threadBubbleBelowTimestamp)
        )

        let bubble = ComposeBubbleColumnView1718(
            text: messageText,
            bubbleTailParams: bubbleTailParams,
            senderLineLabel: senderLineLabel,
            showsSenderRow: showsSenderRow,
            bubbleFontSize: bubbleFontSize
        )
        let bubbleRow = UIView()
        bubbleRow.translatesAutoresizingMaskIntoConstraints = false
        bubble.translatesAutoresizingMaskIntoConstraints = false
        bubbleRow.addSubview(bubble)
        let trailingInset = bubbleTailParams.threadBubbleTrailingInset
        NSLayoutConstraint.activate([
            bubble.trailingAnchor.constraint(
                equalTo: bubbleRow.trailingAnchor,
                constant: -trailingInset
            ),
            bubble.topAnchor.constraint(equalTo: bubbleRow.topAnchor),
            bubble.bottomAnchor.constraint(equalTo: bubbleRow.bottomAnchor),
            bubble.leadingAnchor.constraint(
                greaterThanOrEqualTo: bubbleRow.leadingAnchor,
                constant: IMessage1718DesignTokens.layer2ThreadPaddingH
            ),
        ])
        stack.addArrangedSubview(bubbleRow)
        stack.addArrangedSubview(fixedSpacer(IMessageDesignTokens.threadManualScrollSlack))

        host.setNeedsLayout()
        host.layoutIfNeeded()
        stack.layoutIfNeeded()
        bubbleRow.layoutIfNeeded()
        bubble.layoutIfNeeded()

        return Result(
            anchorBottom: bubble.pinAnchorBottomY(in: stack),
            contentHeight: stack.bounds.height
        )
    }
}
