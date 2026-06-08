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
        uiView.plainText = text
        uiView.hiddenPhone = hiddenPhone
        uiView.refreshAttributedBody()
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
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = NotesDesignTokens.PreviewBubble.longPressDelay
        addGestureRecognizer(longPress)
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

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        let point = gesture.location(in: self)
        guard let hit = PhoneUtilities.phone(at: point, in: self) else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        onLongPressPhone?(hit.phone, hit.rect)
    }
}
