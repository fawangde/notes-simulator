import SwiftUI
import UIKit

struct NotesBodyEditor: UIViewRepresentable {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Binding var text: String
    var hiddenPhone: String?
    var menuAnimatedPhone: String?
    var phoneMenuBodyDismissSignal: Int = 0
    var usesIOS1718Style = false
    var tuning1718: Notes1718TuningSettings = .default
    var tuning26: Notes26TuningSettings = .default
    var onLongPressPhone: (String, CGRect, PhoneMenuPresentation) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> NotesTextView {
        let textView = NotesTextView()
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.isScrollEnabled = false
        textView.setContentCompressionResistancePriority(.required, for: .vertical)
        textView.setContentHuggingPriority(.defaultLow, for: .vertical)
        textView.delegate = context.coordinator
        textView.plainText = text
        textView.hiddenPhone = effectiveHiddenPhone
        textView.usesIOS1718Style = usesIOS1718Style
        textView.tuning1718 = tuning1718
        textView.tuning26 = tuning26
        DisplaySharpness.apply(to: textView)
        textView.refreshAttributedBody()
        textView.onLongPressPhone = { phone, rect, presentation in
            onLongPressPhone(phone, rect, presentation)
        }
        context.coordinator.lastDismissSignal = phoneMenuBodyDismissSignal
        return textView
    }

    func updateUIView(_ uiView: NotesTextView, context: Context) {
        context.coordinator.parent = self
        _ = dynamicTypeSize

        var needsRefresh = false
        let nextHiddenPhone = effectiveHiddenPhone
        if uiView.hiddenPhone != nextHiddenPhone {
            uiView.hiddenPhone = nextHiddenPhone
            needsRefresh = true
        }

        let previousAnimatedPhone = uiView.menuAnimatedPhone
        let animatedPhoneChanged = uiView.menuAnimatedPhone != menuAnimatedPhone
        if animatedPhoneChanged {
            uiView.menuAnimatedPhone = menuAnimatedPhone
            needsRefresh = true
        }

        if context.coordinator.lastDismissSignal != phoneMenuBodyDismissSignal {
            context.coordinator.lastDismissSignal = phoneMenuBodyDismissSignal
            if menuAnimatedPhone != nil {
                uiView.playLongPressDismissAnimation()
            }
        }

        if uiView.usesIOS1718Style != usesIOS1718Style {
            uiView.usesIOS1718Style = usesIOS1718Style
            needsRefresh = true
        }
        if uiView.tuning1718 != tuning1718 {
            uiView.tuning1718 = tuning1718
            needsRefresh = true
        }
        if uiView.tuning26 != tuning26 {
            uiView.tuning26 = tuning26
            needsRefresh = true
        }
        if uiView.plainText != text {
            uiView.plainText = text
            needsRefresh = true
        }

        if let longPress = uiView.gestureRecognizers?.compactMap({ $0 as? UILongPressGestureRecognizer }).first {
            let duration = usesIOS1718Style
                ? NotesStyle1718Tokens.PhoneMenu.longPressDelay
                : NotesDesignTokens.PreviewBubble.longPressDelay
            if longPress.minimumPressDuration != duration {
                longPress.minimumPressDuration = duration
            }
        }

        guard needsRefresh else { return }
        DisplaySharpness.apply(to: uiView)
        uiView.refreshAttributedBody()

        if animatedPhoneChanged {
            if let phone = menuAnimatedPhone {
                uiView.preparePhoneScaleOverlay(phone: phone)
                uiView.playLongPressShowAnimation()
            } else {
                uiView.hidePhoneScaleOverlay()
            }
        } else if menuAnimatedPhone != nil {
            uiView.repositionPhoneScaleOverlay()
        } else if previousAnimatedPhone != nil {
            uiView.hidePhoneScaleOverlay()
        }
    }

    private var effectiveHiddenPhone: String? {
        if let hiddenPhone { return hiddenPhone }
        if menuAnimatedPhone != nil { return menuAnimatedPhone }
        return nil
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: NotesTextView, context: Context) -> CGSize? {
        let width = proposal.width ?? uiView.bounds.width
        guard width > 0 else { return nil }
        let fitted = uiView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        return CGSize(width: width, height: ceil(fitted.height))
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: NotesBodyEditor
        var lastDismissSignal = 0

        init(parent: NotesBodyEditor) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            guard let notesTextView = textView as? NotesTextView else { return }
            let plain = textView.text ?? ""
            guard parent.text != plain else { return }
            parent.text = plain
            notesTextView.plainText = plain
            notesTextView.refreshAttributedBody()
        }
    }
}

final class NotesTextView: UITextView {
    var onLongPressPhone: ((String, CGRect, PhoneMenuPresentation) -> Void)?
    var plainText = ""
    var hiddenPhone: String?
    var menuAnimatedPhone: String?
    var usesIOS1718Style = false
    var tuning1718: Notes1718TuningSettings = .default
    var tuning26: Notes26TuningSettings = .default

    private let phoneScaleOverlay = UILabel()
    private var bodyPhoneMenuScale: CGFloat = 1.0
    private var overlayPreparedPhone: String?

    private var longPressBodyPopScale: CGFloat {
        let cloneStart = CGFloat(tuning26.phoneFontSize) / NotesDesignTokens.PreviewBubble.fontSize
        return 1.04 / cloneStart
    }

    func refreshAttributedBody() {
        applyEditorAccent()
        let selected = selectedRange
        let tuning1718Arg = usesIOS1718Style ? tuning1718 : nil
        let tuning26Arg = usesIOS1718Style ? nil : tuning26
        attributedText = PhoneUtilities.attributedBody(
            plainText,
            hiddenPhone: hiddenPhone,
            compatibleWith: traitCollection,
            tuning1718: tuning1718Arg,
            tuning26: tuning26Arg
        )
        selectedRange = selected
        invalidateIntrinsicContentSize()
    }

    private func applyEditorAccent() {
        if usesIOS1718Style {
            tintColor = NotesDetectedLinkColor.uiColor
        } else {
            tintColor = .label
        }
    }

    override var intrinsicContentSize: CGSize {
        guard bounds.width > 0 else {
            return super.intrinsicContentSize
        }
        return sizeThatFits(CGSize(width: bounds.width, height: .greatestFiniteMagnitude))
    }

    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        applyEditorAccent()
        phoneScaleOverlay.isUserInteractionEnabled = false
        phoneScaleOverlay.backgroundColor = .clear
        phoneScaleOverlay.numberOfLines = 1
        phoneScaleOverlay.isHidden = true
        phoneScaleOverlay.layer.anchorPoint = CGPoint(x: 0, y: 1)
        addSubview(phoneScaleOverlay)

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handlePhoneAction(_:)))
        longPress.minimumPressDuration = usesIOS1718Style
            ? NotesStyle1718Tokens.PhoneMenu.longPressDelay
            : NotesDesignTokens.PreviewBubble.longPressDelay
        longPress.delegate = self
        addGestureRecognizer(longPress)

        let tap = UITapGestureRecognizer(target: self, action: #selector(handlePhoneAction(_:)))
        tap.delegate = self
        addGestureRecognizer(tap)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        DisplaySharpness.apply(to: self)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard previousTraitCollection?.preferredContentSizeCategory
            != traitCollection.preferredContentSizeCategory else { return }
        refreshAttributedBody()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if !phoneScaleOverlay.isHidden {
            repositionPhoneScaleOverlay()
        }
    }

    func preparePhoneScaleOverlay(phone: String) {
        guard overlayPreparedPhone != phone else { return }
        overlayPreparedPhone = phone

        let font = IOSTheme.phoneUIFont(
            baseSize: CGFloat(tuning26.phoneFontSize),
            compatibleWith: traitCollection
        )
        let color = NotesDesignTokens.PhoneLink.uiColor
        phoneScaleOverlay.attributedText = NSAttributedString(
            string: phone,
            attributes: [
                .font: font,
                .foregroundColor: color,
                .underlineStyle: NSUnderlineStyle.single.rawValue,
                .underlineColor: color,
            ]
        )
        phoneScaleOverlay.sizeToFit()
    }

    func repositionPhoneScaleOverlay() {
        guard let phone = menuAnimatedPhone,
              let rect = PhoneUtilities.rect(forPhone: phone, in: self) else { return }

        phoneScaleOverlay.bounds = CGRect(origin: .zero, size: phoneScaleOverlay.intrinsicContentSize)
        phoneScaleOverlay.layer.position = CGPoint(x: rect.minX, y: rect.maxY)
        applyPhoneScaleOverlayTransform()
        bringSubviewToFront(phoneScaleOverlay)
    }

    private func applyPhoneScaleOverlayTransform() {
        phoneScaleOverlay.transform = CGAffineTransform(
            scaleX: bodyPhoneMenuScale,
            y: bodyPhoneMenuScale
        )
    }

    func playLongPressShowAnimation() {
        guard menuAnimatedPhone != nil else { return }
        phoneScaleOverlay.layer.removeAllAnimations()
        bodyPhoneMenuScale = 1.0
        phoneScaleOverlay.isHidden = false
        repositionPhoneScaleOverlay()

        let popScale = longPressBodyPopScale
        UIView.animateKeyframes(
            withDuration: 0.42,
            delay: 0,
            options: [.calculationModeCubic, .allowUserInteraction, .beginFromCurrentState]
        ) {
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.68) {
                self.bodyPhoneMenuScale = popScale
                self.applyPhoneScaleOverlayTransform()
            }
            UIView.addKeyframe(withRelativeStartTime: 0.68, relativeDuration: 0.32) {
                self.bodyPhoneMenuScale = 1.0
                self.applyPhoneScaleOverlayTransform()
            }
        }
    }

    func playLongPressDismissAnimation() {
        guard menuAnimatedPhone != nil else { return }
        phoneScaleOverlay.layer.removeAllAnimations()

        let popScale = longPressBodyPopScale
        UIView.animateKeyframes(
            withDuration: 0.30,
            delay: 0,
            options: [.calculationModeCubic, .allowUserInteraction, .beginFromCurrentState]
        ) {
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.55) {
                self.bodyPhoneMenuScale = popScale
                self.applyPhoneScaleOverlayTransform()
            }
            UIView.addKeyframe(withRelativeStartTime: 0.55, relativeDuration: 0.45) {
                self.bodyPhoneMenuScale = 1.0
                self.applyPhoneScaleOverlayTransform()
            }
        }
    }

    func hidePhoneScaleOverlay() {
        phoneScaleOverlay.layer.removeAllAnimations()
        phoneScaleOverlay.isHidden = true
        bodyPhoneMenuScale = 1.0
        overlayPreparedPhone = nil
        applyPhoneScaleOverlayTransform()
    }

    @objc private func handlePhoneAction(_ gesture: UIGestureRecognizer) {
        if let longPress = gesture as? UILongPressGestureRecognizer, longPress.state != .began {
            return
        }
        if let tap = gesture as? UITapGestureRecognizer, tap.state != .ended {
            return
        }
        let point = gesture.location(in: self)
        guard let hit = PhoneUtilities.phone(at: point, in: self) else { return }
        let presentation: PhoneMenuPresentation = usesIOS1718Style || gesture is UILongPressGestureRecognizer
            ? .longPress
            : .tap
        UIImpactFeedbackGenerator(style: presentation == .tap ? .light : .medium).impactOccurred()
        onLongPressPhone?(hit.phone, hit.rect, presentation)
    }
}

extension NotesTextView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let point = touch.location(in: self)
        return PhoneUtilities.phone(at: point, in: self) != nil
    }
}

/// 标题：UIKit 绘制，避免 SwiftUI TextField 首行裁切/提前换行
struct NotesTitleEditor: UIViewRepresentable {
    @Binding var text: String
    var usesIOS1718Style = false
    var tuning1718: Notes1718TuningSettings = .default
    var tuning26: Notes26TuningSettings = .default

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    func makeUIView(context: Context) -> NotesTitleTextView {
        let textView = NotesTitleTextView()
        textView.usesIOS1718Style = usesIOS1718Style
        textView.tuning1718 = tuning1718
        textView.tuning26 = tuning26
        textView.delegate = context.coordinator
        textView.syncText(text)
        DisplaySharpness.apply(to: textView)
        return textView
    }

    func updateUIView(_ uiView: NotesTitleTextView, context: Context) {
        var styleChanged = false
        if uiView.usesIOS1718Style != usesIOS1718Style {
            uiView.usesIOS1718Style = usesIOS1718Style
            styleChanged = true
        }
        if uiView.tuning1718 != tuning1718 {
            uiView.tuning1718 = tuning1718
            styleChanged = true
        }
        if uiView.tuning26 != tuning26 {
            uiView.tuning26 = tuning26
            styleChanged = true
        }

        let textChanged = uiView.text != text
        if styleChanged || textChanged {
            DisplaySharpness.apply(to: uiView)
            uiView.syncText(text)
        }
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: NotesTitleTextView, context: Context) -> CGSize? {
        let width = proposal.width ?? uiView.bounds.width
        guard width > 0 else { return nil }
        let fitted = uiView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        return CGSize(width: width, height: ceil(fitted.height))
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        private var textBinding: Binding<String>

        init(text: Binding<String>) {
            textBinding = text
        }

        func textViewDidChange(_ textView: UITextView) {
            let plain = textView.text ?? ""
            if textBinding.wrappedValue != plain {
                textBinding.wrappedValue = plain
            }
            textView.invalidateIntrinsicContentSize()
        }
    }
}

final class NotesTitleTextView: UITextView {
    var usesIOS1718Style = false
    var tuning1718: Notes1718TuningSettings = .default
    var tuning26: Notes26TuningSettings = .default

    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        backgroundColor = .clear
        textContainerInset = .zero
        let container = self.textContainer
        container.lineFragmentPadding = 0
        container.widthTracksTextView = true
        container.lineBreakMode = .byWordWrapping
        isScrollEnabled = false
        setContentCompressionResistancePriority(.required, for: .vertical)
        setContentHuggingPriority(.defaultLow, for: .vertical)
        applyTitleStyle()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func syncText(_ value: String) {
        applyTitleStyle()
        guard text != value else { return }
        let selected = selectedRange
        text = value
        selectedRange = selected
        invalidateIntrinsicContentSize()
    }

    private func applyTitleStyle() {
        let font: UIFont
        let color: UIColor
        if usesIOS1718Style {
            font = UIFont.systemFont(ofSize: CGFloat(tuning1718.titleFontSize), weight: .bold)
            color = tuning1718.themeTextUIColor()
        } else {
            font = UIFont.systemFont(ofSize: CGFloat(tuning26.titleFontSize), weight: .bold)
            color = tuning26.themeTextUIColor()
        }
        self.font = font
        textColor = color
        if usesIOS1718Style {
            tintColor = NotesDetectedLinkColor.uiColor
        } else {
            tintColor = .label
        }
        typingAttributes = [
            .font: font,
            .foregroundColor: color,
        ]
    }

    override var intrinsicContentSize: CGSize {
        guard bounds.width > 0 else {
            return super.intrinsicContentSize
        }
        return sizeThatFits(CGSize(width: bounds.width, height: .greatestFiniteMagnitude))
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        applyTitleStyle()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        DisplaySharpness.apply(to: self)
    }
}
