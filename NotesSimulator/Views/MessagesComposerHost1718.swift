import SwiftUI
import UIKit

/// iOS 17–18 底栏：扁平 + / 输入框，系统键盘，金色光标
struct MessagesComposerHost1718: UIViewControllerRepresentable {
    @Binding var text: String
    var wantsFocus: Bool
    var onPlusTap: (() -> Void)? = nil

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    func makeUIViewController(context: Context) -> MessagesComposerHost1718Controller {
        let controller = MessagesComposerHost1718Controller()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ controller: MessagesComposerHost1718Controller, context: Context) {
        controller.syncText(text)
        controller.bindPlusTap(onPlusTap)
        if wantsFocus {
            controller.requestFocus()
        } else {
            controller.resignFocus()
        }
    }

    final class Coordinator: NSObject, MessagesComposerHost1718Delegate {
        private var textBinding: Binding<String>

        init(text: Binding<String>) {
            textBinding = text
        }

        func composerTextDidChange(_ text: String) {
            if textBinding.wrappedValue != text {
                textBinding.wrappedValue = text
            }
        }
    }
}

protocol MessagesComposerHost1718Delegate: AnyObject {
    func composerTextDidChange(_ text: String)
}

final class MessagesComposerHost1718Controller: UIViewController {
    weak var delegate: MessagesComposerHost1718Delegate?
    private let plate = MessagesComposerPlate1718View()
    private var wantsFocus = false
    private var focusAttempts = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        plate.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(plate)
        NSLayoutConstraint.activate([
            plate.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            plate.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            plate.topAnchor.constraint(equalTo: view.topAnchor),
            plate.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        plate.onTextChange = { [weak self] text in
            self?.delegate?.composerTextDidChange(text)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if wantsFocus { scheduleFocus() }
    }

    func bindPlusTap(_ handler: (() -> Void)?) {
        plate.onPlusTap = handler
    }

    func syncText(_ value: String) {
        if plate.field.text != value {
            plate.field.text = value
        }
    }

    func requestFocus() {
        wantsFocus = true
        focusAttempts = 0
        scheduleFocus()
    }

    func resignFocus() {
        wantsFocus = false
        plate.field.resignFirstResponder()
    }

    private func scheduleFocus() {
        guard wantsFocus, view.window != nil else { return }
        focusAttempts += 1
        let retryDelay = focusAttempts <= 1 ? 0.0 : 0.04 * Double(focusAttempts)
        DispatchQueue.main.asyncAfter(deadline: .now() + retryDelay) { [weak self] in
            guard let self, self.wantsFocus else { return }
            if !self.plate.field.isFirstResponder {
                _ = self.plate.field.becomeFirstResponder()
            } else if self.focusAttempts < 6 {
                self.scheduleFocus()
            }
        }
    }
}

final class MessagesComposerPlate1718View: UIView {
    let field = UITextField()
    var onTextChange: ((String) -> Void)?
    var onPlusTap: (() -> Void)?

    private let plusButton = UIView()
    private let plusTapButton = UIButton(type: .system)
    private let plusIconView = UIImageView()
    private let fieldWrap = UIView()
    private let mic = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = true
        backgroundColor = .clear

        plusButton.backgroundColor = IMessage1718DesignTokens.plusButtonBackgroundUI
        plusButton.layer.cornerRadius = IMessage1718DesignTokens.layer3PlusSize / 2
        plusButton.isUserInteractionEnabled = true
        plusButton.translatesAutoresizingMaskIntoConstraints = false

        let plusConfig = UIImage.SymbolConfiguration(
            pointSize: IMessage1718DesignTokens.plusIconSize,
            weight: .medium
        )
        plusIconView.image = UIImage(systemName: IMessage1718DesignTokens.plusIcon, withConfiguration: plusConfig)
        plusIconView.tintColor = IMessage1718DesignTokens.plusIconTintUI
        plusIconView.contentMode = .scaleAspectFit
        plusIconView.translatesAutoresizingMaskIntoConstraints = false
        plusButton.addSubview(plusIconView)

        plusTapButton.backgroundColor = .clear
        plusTapButton.translatesAutoresizingMaskIntoConstraints = false
        plusTapButton.addTarget(self, action: #selector(plusTapped), for: .touchUpInside)
        plusButton.addSubview(plusTapButton)

        fieldWrap.backgroundColor = IMessage1718DesignTokens.inputBackgroundUI
        fieldWrap.layer.cornerRadius = IMessage1718DesignTokens.inputCornerRadius
        fieldWrap.layer.borderWidth = IMessage1718DesignTokens.inputBorderWidth
        fieldWrap.layer.borderColor = IMessage1718DesignTokens.inputBorderColorUI.cgColor
        fieldWrap.translatesAutoresizingMaskIntoConstraints = false

        field.placeholder = "iMessage 信息"
        field.font = .systemFont(ofSize: IMessage1718DesignTokens.inputFontSize)
        field.backgroundColor = .clear
        field.textColor = UIColor.label
        field.tintColor = IMessage1718DesignTokens.cursorColorUI
        field.borderStyle = .none
        field.autocorrectionType = .default
        let inset = IMessage1718DesignTokens.inputFieldHorizontalInset
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: inset, height: 1))
        field.leftViewMode = .always
        field.attributedPlaceholder = NSAttributedString(
            string: "iMessage 信息",
            attributes: [.foregroundColor: IMessage1718DesignTokens.inputPlaceholderColorUI]
        )
        field.translatesAutoresizingMaskIntoConstraints = false
        field.addTarget(self, action: #selector(editingChanged), for: .editingChanged)

        let micConfig = UIImage.SymbolConfiguration(
            pointSize: IMessage1718DesignTokens.micIconSize,
            weight: .regular
        )
        mic.image = UIImage(systemName: IMessage1718DesignTokens.micIcon, withConfiguration: micConfig)
        mic.tintColor = .tertiaryLabel
        mic.contentMode = .scaleAspectFit
        mic.translatesAutoresizingMaskIntoConstraints = false

        fieldWrap.addSubview(field)
        fieldWrap.addSubview(mic)

        let row = UIStackView(arrangedSubviews: [plusButton, fieldWrap])
        row.axis = .horizontal
        row.spacing = IMessage1718DesignTokens.toolbarItemSpacing
        row.alignment = .center
        row.translatesAutoresizingMaskIntoConstraints = false
        addSubview(row)

        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(
                equalTo: leadingAnchor,
                constant: IMessage1718DesignTokens.toolbarHorizontalPadding
            ),
            row.trailingAnchor.constraint(
                equalTo: trailingAnchor,
                constant: -IMessage1718DesignTokens.toolbarHorizontalPadding
            ),
            row.topAnchor.constraint(equalTo: topAnchor, constant: IMessage1718DesignTokens.toolbarVerticalPadding),
            row.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -IMessage1718DesignTokens.toolbarVerticalPadding),

            plusButton.widthAnchor.constraint(equalToConstant: IMessage1718DesignTokens.layer3PlusSize),
            plusButton.heightAnchor.constraint(equalToConstant: IMessage1718DesignTokens.layer3PlusSize),
            plusIconView.centerXAnchor.constraint(equalTo: plusButton.centerXAnchor),
            plusIconView.centerYAnchor.constraint(equalTo: plusButton.centerYAnchor),
            plusTapButton.leadingAnchor.constraint(equalTo: plusButton.leadingAnchor),
            plusTapButton.trailingAnchor.constraint(equalTo: plusButton.trailingAnchor),
            plusTapButton.topAnchor.constraint(equalTo: plusButton.topAnchor),
            plusTapButton.bottomAnchor.constraint(equalTo: plusButton.bottomAnchor),

            fieldWrap.heightAnchor.constraint(equalToConstant: IMessage1718DesignTokens.layer3InputHeight),

            field.leadingAnchor.constraint(equalTo: fieldWrap.leadingAnchor),
            field.trailingAnchor.constraint(equalTo: mic.leadingAnchor, constant: -6),
            field.topAnchor.constraint(equalTo: fieldWrap.topAnchor),
            field.bottomAnchor.constraint(equalTo: fieldWrap.bottomAnchor),

            mic.trailingAnchor.constraint(
                equalTo: fieldWrap.trailingAnchor,
                constant: -IMessage1718DesignTokens.inputFieldHorizontalInset
            ),
            mic.centerYAnchor.constraint(equalTo: fieldWrap.centerYAnchor),
            mic.widthAnchor.constraint(equalToConstant: IMessage1718DesignTokens.micIconSize),
            mic.heightAnchor.constraint(equalToConstant: IMessage1718DesignTokens.micIconSize),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    @objc private func editingChanged() {
        onTextChange?(field.text ?? "")
    }

    @objc private func plusTapped() {
        onPlusTap?()
    }
}
