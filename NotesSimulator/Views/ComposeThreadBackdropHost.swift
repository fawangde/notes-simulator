import SwiftUI
import UIKit

/// 第 2 层聊天底色：UIKit UIScrollView，供自研材质内核采样穿透
struct ComposeThreadBackdropHost: UIViewRepresentable {
    let chromeBottomY: CGFloat
    let composerBottomReserve: CGFloat
    let dateLine: String
    let showsIOS264ThreadHeader: Bool
    let messageText: String
    let showsText: Bool
    let showsImage: Bool
    let bothContentOrder: BothContentOrder
    let image: UIImage?
    func makeUIView(context: Context) -> ComposeThreadScrollView {
        ComposeThreadScrollView()
    }

    func updateUIView(_ uiView: ComposeThreadScrollView, context: Context) {
        uiView.apply(
            chromeBottomY: chromeBottomY,
            composerBottomReserve: composerBottomReserve,
            dateLine: dateLine,
            showsIOS264ThreadHeader: showsIOS264ThreadHeader,
            messageText: messageText,
            showsText: showsText,
            showsImage: showsImage,
            bothContentOrder: bothContentOrder,
            image: image,
            horizontalPadding: IMessageDesignTokens.layer2ThreadPaddingH
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
    private var userDidScroll = false
    /// 长按打开信息页后首屏顶对齐（与参考图一致），文案变长后再走贴底上滚
    private var prefersInitialTopAlignment = true

    private struct ThreadContentSignature: Equatable {
        let chromeBottomY: CGFloat
        let dateLine: String
        let showsIOS264ThreadHeader: Bool
        let messageText: String
        let showsText: Bool
        let showsImage: Bool
        let bothContentOrder: BothContentOrder
        let imageKey: Int
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
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        scrollView.contentInset.bottom = composerBottomReserve
        let reserveChanged = abs(composerBottomReserve - lastComposerReserve) > 0.5
        lastComposerReserve = composerBottomReserve
        guard !userDidScroll else { return }
        if needsDeliveredPin() {
            prefersInitialTopAlignment = false
        }
        if prefersInitialTopAlignment, !reserveChanged, !needsDeliveredPin() {
            return
        }
        reconcileScrollOffset(animated: false, forcePin: reserveChanged || needsDeliveredPin())
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
        messageText: String,
        showsText: Bool,
        showsImage: Bool,
        bothContentOrder: BothContentOrder,
        image: UIImage?,
        horizontalPadding: CGFloat
    ) {
        let reserveChanged = abs(composerBottomReserve - self.composerBottomReserve) > 0.5
        self.composerBottomReserve = composerBottomReserve

        let signature = ThreadContentSignature(
            chromeBottomY: chromeBottomY,
            dateLine: dateLine,
            showsIOS264ThreadHeader: showsIOS264ThreadHeader,
            messageText: messageText,
            showsText: showsText,
            showsImage: showsImage,
            bothContentOrder: bothContentOrder,
            imageKey: image.map { ObjectIdentifier($0).hashValue } ?? 0
        )

        if signature == contentSignature {
            if reserveChanged {
                setNeedsLayout()
            }
            return
        }

        if let previous = contentSignature,
           previous.chromeBottomY == signature.chromeBottomY,
           previous.showsText == signature.showsText,
           previous.showsImage == signature.showsImage,
           previous.bothContentOrder == signature.bothContentOrder,
           previous.imageKey == signature.imageKey,
           previous.showsIOS264ThreadHeader == signature.showsIOS264ThreadHeader,
           previous.messageText != signature.messageText || previous.dateLine != signature.dateLine {
            contentSignature = signature
            prefersInitialTopAlignment = false
            updateVisibleMessageText(signature.messageText, dateLine: signature.dateLine)
            setNeedsLayout()
            layoutIfNeeded()
            reconcileScrollOffset(animated: false, forcePin: !userDidScroll)
            return
        }

        contentSignature = signature
        self.chromeBottomY = chromeBottomY
        userDidScroll = false
        prefersInitialTopAlignment = true

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

        let timeRow = insetRow(
            makeThreadHeaderStack(dateLine: dateLine, showsIOS264ThreadHeader: showsIOS264ThreadHeader),
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
            horizontalPadding: horizontalPadding
        )

        stack.addArrangedSubview(
            fixedSpacer(IMessageDesignTokens.threadManualScrollSlack)
        )

        lastContentHeight = 0
        setNeedsLayout()
        DispatchQueue.main.async {
            self.layoutIfNeeded()
            if self.needsDeliveredPin() {
                self.prefersInitialTopAlignment = false
                self.reconcileScrollOffset(animated: false, forcePin: true)
            } else {
                self.scrollView.setContentOffset(.zero, animated: false)
            }
            self.lastContentHeight = self.scrollView.contentSize.height
            ComposeBackdropRegistry.notifyChanged()
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

    private func appendMessageContent(
        messageText: String,
        showsText: Bool,
        showsImage: Bool,
        bothContentOrder: BothContentOrder,
        image: UIImage?,
        horizontalPadding: CGFloat
    ) {
        let addText = {
            guard showsText else { return }
            let bubble = ComposeBubbleColumnView(text: messageText)
            let bubbleRow = self.trailingRow(
                bubble,
                horizontalPadding: IMessageDesignTokens.threadBubbleTrailingInset
            )
            self.stack.addArrangedSubview(bubbleRow)
        }

        let addImage = {
            guard showsImage, let image else { return }
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFit
            imageView.clipsToBounds = true
            imageView.layer.cornerRadius = 14
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.widthAnchor.constraint(
                lessThanOrEqualToConstant: IMessageDesignTokens.imageBubbleMaxWidth
            ).isActive = true
            let imageRow = self.trailingRow(
                imageView,
                horizontalPadding: IMessageDesignTokens.threadBubbleTrailingInset
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

    private func makeThreadHeaderStack(dateLine: String, showsIOS264ThreadHeader: Bool) -> UIStackView {
        let headerStack = UIStackView()
        headerStack.axis = .vertical
        headerStack.alignment = .center
        headerStack.spacing = IMessageDesignTokens.timestampLineSpacing

        let serviceLabel = makeThreadMetaLabel(text: "iMessage 信息")
        headerStack.addArrangedSubview(serviceLabel)

        if showsIOS264ThreadHeader {
            let encryptedRow = makeEncryptedRow()
            headerStack.addArrangedSubview(encryptedRow)
            headerStack.setCustomSpacing(
                IMessageDesignTokens.timestampLineSpacing,
                after: serviceLabel
            )
            headerStack.setCustomSpacing(
                IMessageDesignTokens.thread264EncryptedToDateSpacing,
                after: encryptedRow
            )
        }

        let dateLabel = makeThreadMetaLabel(text: dateLine)
        headerStack.addArrangedSubview(dateLabel)

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
            if let image = child as? UIImageView, image.image != nil {
                image.layoutIfNeeded()
                return image.convert(CGPoint(x: 0, y: image.bounds.height), to: stack).y
            }
        }
        return nil
    }

    /// 先向下长；「已送达」贴输入区顶后停止下移，再多则上滚
    private func targetPinnedOffsetY() -> CGFloat {
        scrollView.layoutIfNeeded()
        let viewport = scrollView.bounds.height
        guard viewport > 0,
              let anchorBottom = messagePinAnchorBottomY() else { return 0 }

        let composerLine = viewport - scrollView.contentInset.bottom
        if anchorBottom <= composerLine + 0.5 {
            return 0
        }

        let pinOffset = anchorBottom - composerLine
        return max(0, min(pinOffset, naturalMaxScrollOffsetY()))
    }

    private func needsDeliveredPin() -> Bool {
        targetPinnedOffsetY() > 0.5
    }

    /// 先向下长；「已送达」触输入框上 5pt 后自动上滚；短文案也可手动上滑
    private func reconcileScrollOffset(animated: Bool, forcePin: Bool = false) {
        let maxY = maxScrollOffsetY()
        let contentH = scrollView.contentSize.height

        let grew = contentH > lastContentHeight + 1
        lastContentHeight = contentH

        let targetY = targetPinnedOffsetY()
        if targetY > 0.5 {
            prefersInitialTopAlignment = false
        }
        if forcePin || (grew && targetY > 0.5) {
            scrollView.setContentOffset(CGPoint(x: 0, y: targetY), animated: animated)
            return
        }

        if scrollView.contentOffset.y > maxY {
            scrollView.contentOffset.y = maxY
        }
    }
}

extension ComposeThreadScrollView: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        userDidScroll = true
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let maxY = maxScrollOffsetY()
        if scrollView.contentOffset.y > maxY {
            scrollView.contentOffset.y = maxY
        }
        ComposeBackdropRegistry.notifyChanged()
    }
}

private final class ComposeBubbleColumnView: UIView {
    private let bubbleView = IOSOutgoingChatBubbleView()
    private let delivered = UILabel()
    private var widthConstraint: NSLayoutConstraint?
    private var heightConstraint: NSLayoutConstraint?

    init(text: String) {
        super.init(frame: .zero)
        clipsToBounds = false
        setContentHuggingPriority(.required, for: .horizontal)
        setContentHuggingPriority(.required, for: .vertical)
        setContentCompressionResistancePriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .vertical)

        bubbleView.label.text = text
        bubbleView.applyRenderParams(Self.composeBubbleParams(.frozenDefault))

        delivered.text = "已送达"
        delivered.font = IMessageDesignTokens.deliveredFontUI
        delivered.textColor = IMessageDesignTokens.threadMetaTextUI
        delivered.textAlignment = .right

        addSubview(bubbleView)
        addSubview(delivered)

        widthConstraint = widthAnchor.constraint(equalToConstant: 120)
        heightConstraint = heightAnchor.constraint(equalToConstant: 60)
        widthConstraint?.isActive = true
        heightConstraint?.isActive = true
    }

    func updateText(_ text: String) {
        bubbleView.label.text = text
        setNeedsLayout()
    }

    /// 撰写页气泡填充色固定为收件人号码蓝；尾巴几何仍走调参
    private static func composeBubbleParams(_ params: BubbleTailRenderParams) -> BubbleTailRenderParams {
        let fill = IMessageDesignTokens.bubbleBlueFill.rgbaComponents
        var merged = params
        merged.fillRed = Double(fill.r)
        merged.fillGreen = Double(fill.g)
        merged.fillBlue = Double(fill.b)
        return merged
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

        widthConstraint?.constant = bubbleSize.width
        heightConstraint?.constant = max(bubbleSize.height, delivered.frame.maxY)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
