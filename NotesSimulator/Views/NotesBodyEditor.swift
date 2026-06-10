import SwiftUI
import UIKit

struct NotesBodyEditor: UIViewRepresentable {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Binding var text: String
    var hiddenPhone: String?
    var onLongPressPhone: (String, CGRect) -> Void

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
        textView.hiddenPhone = hiddenPhone
        DisplaySharpness.apply(to: textView)
        textView.refreshAttributedBody()
        textView.onLongPressPhone = { phone, rect in
            onLongPressPhone(phone, rect)
        }
        return textView
    }

    func updateUIView(_ uiView: NotesTextView, context: Context) {
        context.coordinator.parent = self
        _ = dynamicTypeSize
        DisplaySharpness.apply(to: uiView)
        uiView.hiddenPhone = hiddenPhone
        if uiView.plainText != text {
            uiView.plainText = text
            uiView.refreshAttributedBody()
        } else {
            uiView.refreshAttributedBody()
        }
        uiView.setNeedsLayout()
        uiView.layoutIfNeeded()
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: NotesTextView, context: Context) -> CGSize? {
        let width = proposal.width ?? uiView.bounds.width
        guard width > 0 else { return nil }
        let fitted = uiView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        return CGSize(width: width, height: ceil(fitted.height))
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: NotesBodyEditor

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
    var onLongPressPhone: ((String, CGRect) -> Void)?
    var plainText = ""
    var hiddenPhone: String?
    func refreshAttributedBody() {
        let selected = selectedRange
        attributedText = PhoneUtilities.attributedBody(
            plainText,
            hiddenPhone: hiddenPhone,
            compatibleWith: traitCollection
        )
        selectedRange = selected
        invalidateIntrinsicContentSize()
    }

    override var intrinsicContentSize: CGSize {
        guard bounds.width > 0 else {
            return super.intrinsicContentSize
        }
        return sizeThatFits(CGSize(width: bounds.width, height: .greatestFiniteMagnitude))
    }

    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handlePhoneAction(_:)))
        longPress.minimumPressDuration = NotesDesignTokens.PreviewBubble.longPressDelay
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

    @objc private func handlePhoneAction(_ gesture: UIGestureRecognizer) {
        if let longPress = gesture as? UILongPressGestureRecognizer, longPress.state != .began {
            return
        }
        if let tap = gesture as? UITapGestureRecognizer, tap.state != .ended {
            return
        }
        let point = gesture.location(in: self)
        guard let hit = PhoneUtilities.phone(at: point, in: self) else { return }
        let style: UIImpactFeedbackGenerator.FeedbackStyle =
            gesture is UITapGestureRecognizer ? .light : .medium
        UIImpactFeedbackGenerator(style: style).impactOccurred()
        onLongPressPhone?(hit.phone, hit.rect)
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

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    func makeUIView(context: Context) -> NotesTitleTextView {
        let textView = NotesTitleTextView()
        textView.usesIOS1718Style = usesIOS1718Style
        textView.delegate = context.coordinator
        textView.syncText(text)
        DisplaySharpness.apply(to: textView)
        return textView
    }

    func updateUIView(_ uiView: NotesTitleTextView, context: Context) {
        uiView.usesIOS1718Style = usesIOS1718Style
        DisplaySharpness.apply(to: uiView)
        uiView.syncText(text)
        uiView.setNeedsLayout()
        uiView.layoutIfNeeded()
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
        let font = UIFont.systemFont(
            ofSize: NotesDesignTokens.Official.Title.fontSize,
            weight: .bold
        )
        let color = IOSTheme.titleLabelUI
        self.font = font
        textColor = color
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
