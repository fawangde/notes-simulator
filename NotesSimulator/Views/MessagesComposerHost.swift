import SwiftUI
import UIKit

/// 底板块：keyboardLayoutGuide 锚定键盘顶，输入框在视图树内（探针 Phase 7 实测可行）
struct MessagesComposerHost: UIViewControllerRepresentable {
    @Binding var text: String
    var wantsFocus: Bool
    var onPlusTap: (() -> Void)? = nil

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    func makeUIViewController(context: Context) -> MessagesComposerHostController {
        let controller = MessagesComposerHostController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ controller: MessagesComposerHostController, context: Context) {
        controller.applyFrozenLayout()
        controller.syncText(text)
        controller.bindPlusTap(onPlusTap)
        if wantsFocus {
            controller.requestFocus()
        } else {
            controller.resignFocus()
        }
    }

    final class Coordinator: NSObject, MessagesComposerHostDelegate {
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

protocol MessagesComposerHostDelegate: AnyObject {
    func composerTextDidChange(_ text: String)
}

final class MessagesComposerHostController: UIViewController {
    weak var delegate: MessagesComposerHostDelegate?
    let plate = MessagesComposerPlateView()
    private var wantsFocus = false
    private var focusAttempts = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        view.clipsToBounds = false
        view.isUserInteractionEnabled = true

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

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardFrameDidChange),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardFrameDidChange),
            name: UIResponder.keyboardDidChangeFrameNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if wantsFocus {
            scheduleFocus()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        plate.refreshChromeLayout()
        if wantsFocus {
            scheduleFocus()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        plate.refreshChromeLayout()
    }

    @objc private func keyboardFrameDidChange() {
        plate.refreshChromeLayout()
    }

    func bindPlusTap(_ handler: (() -> Void)?) {
        plate.onPlusTap = handler
    }

    func applyFrozenLayout() {
        plate.applyFrozenLayout()
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
        focusAttempts = 0
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
            }
            if self.plate.field.isFirstResponder {
                self.plate.refreshChromeLayout()
            } else if self.focusAttempts < 6 {
                self.scheduleFocus()
            }
        }
    }
}

final class MessagesComposerPlateView: UIView {
    let field = UITextField()
    var onTextChange: ((String) -> Void)?
    var onPlusTap: (() -> Void)?

    private let plusChrome = ComposeChromeGlassHostView(
        cornerRadius: IMessageDesignTokens.plusButtonSize / 2,
        borderEmphasis: IMessageDesignTokens.chromeControlBorderEmphasis
    )
    private let plusTapButton = UIButton(type: .system)
    private let fieldChrome = ComposeChromeGlassHostView(
        cornerRadius: IMessageDesignTokens.inputCornerRadius,
        borderEmphasis: IMessageDesignTokens.chromeControlBorderEmphasis
    )
    private let fieldWrap = UIView()
    private let plusIconView = UIImageView()
    private let mic = UIImageView()

    private var plusWidth: NSLayoutConstraint!
    private var plusHeight: NSLayoutConstraint!
    private var fieldWrapHeight: NSLayoutConstraint!
    private var micWidth: NSLayoutConstraint!
    private var micHeight: NSLayoutConstraint!

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = true
        backgroundColor = .clear
        clipsToBounds = false

        plusChrome.translatesAutoresizingMaskIntoConstraints = false
        plusChrome.isUserInteractionEnabled = true

        let plusConfig = UIImage.SymbolConfiguration(
            pointSize: IMessageDesignTokens.plusIconSize,
            weight: .semibold
        )
        plusIconView.image = UIImage(systemName: IMessageDesignTokens.plusIcon, withConfiguration: plusConfig)
        plusIconView.tintColor = .placeholderText
        plusIconView.contentMode = .scaleAspectFit
        plusIconView.isUserInteractionEnabled = false
        plusIconView.translatesAutoresizingMaskIntoConstraints = false
        plusChrome.addSubview(plusIconView)

        plusTapButton.backgroundColor = .clear
        plusTapButton.translatesAutoresizingMaskIntoConstraints = false
        plusTapButton.addTarget(self, action: #selector(plusTapped), for: .touchUpInside)
        plusChrome.addSubview(plusTapButton)

        field.placeholder = "iMessage 信息"
        field.font = .systemFont(ofSize: IMessageDesignTokens.inputFontSize)
        field.backgroundColor = .clear
        field.textColor = IOSTheme.labelPrimaryUI
        field.borderStyle = .none
        field.autocorrectionType = .default
        let inset = IMessageDesignTokens.inputFieldHorizontalInset
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: inset, height: 1))
        field.leftViewMode = .always
        field.translatesAutoresizingMaskIntoConstraints = false
        field.addTarget(self, action: #selector(editingChanged), for: .editingChanged)

        let micConfig = UIImage.SymbolConfiguration(
            pointSize: IMessageDesignTokens.micIconSize,
            weight: .regular
        )
        mic.image = UIImage(systemName: IMessageDesignTokens.micIcon, withConfiguration: micConfig)
        mic.tintColor = .tertiaryLabel
        mic.contentMode = .scaleAspectFit
        mic.isUserInteractionEnabled = false
        mic.translatesAutoresizingMaskIntoConstraints = false

        fieldChrome.translatesAutoresizingMaskIntoConstraints = false
        fieldChrome.isUserInteractionEnabled = false

        fieldWrap.translatesAutoresizingMaskIntoConstraints = false
        fieldWrap.clipsToBounds = false
        fieldWrap.addSubview(fieldChrome)
        fieldWrap.addSubview(field)
        fieldWrap.addSubview(mic)

        plusWidth = plusChrome.widthAnchor.constraint(equalToConstant: IMessageDesignTokens.plusButtonSize)
        plusHeight = plusChrome.heightAnchor.constraint(equalToConstant: IMessageDesignTokens.plusButtonSize)
        fieldWrapHeight = fieldWrap.heightAnchor.constraint(equalToConstant: IMessageDesignTokens.inputMinHeight)
        micWidth = mic.widthAnchor.constraint(equalToConstant: IMessageDesignTokens.micIconSize)
        micHeight = mic.heightAnchor.constraint(equalToConstant: IMessageDesignTokens.micIconSize)

        NSLayoutConstraint.activate([
            plusIconView.centerXAnchor.constraint(equalTo: plusChrome.centerXAnchor),
            plusIconView.centerYAnchor.constraint(equalTo: plusChrome.centerYAnchor),
            plusTapButton.leadingAnchor.constraint(equalTo: plusChrome.leadingAnchor),
            plusTapButton.trailingAnchor.constraint(equalTo: plusChrome.trailingAnchor),
            plusTapButton.topAnchor.constraint(equalTo: plusChrome.topAnchor),
            plusTapButton.bottomAnchor.constraint(equalTo: plusChrome.bottomAnchor),
            plusWidth, plusHeight,
        ])
        layoutRow(leading: plusChrome, fieldWrap: fieldWrap)

        NSLayoutConstraint.activate([
            fieldWrapHeight,

            fieldChrome.leadingAnchor.constraint(equalTo: fieldWrap.leadingAnchor),
            fieldChrome.trailingAnchor.constraint(equalTo: fieldWrap.trailingAnchor),
            fieldChrome.topAnchor.constraint(equalTo: fieldWrap.topAnchor),
            fieldChrome.bottomAnchor.constraint(equalTo: fieldWrap.bottomAnchor),

            field.leadingAnchor.constraint(equalTo: fieldWrap.leadingAnchor),
            field.trailingAnchor.constraint(equalTo: mic.leadingAnchor, constant: -6),
            field.topAnchor.constraint(equalTo: fieldWrap.topAnchor),
            field.bottomAnchor.constraint(equalTo: fieldWrap.bottomAnchor),

            mic.trailingAnchor.constraint(
                equalTo: fieldWrap.trailingAnchor,
                constant: -IMessageDesignTokens.inputFieldHorizontalInset
            ),
            mic.centerYAnchor.constraint(equalTo: fieldWrap.centerYAnchor),
            micWidth, micHeight,
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func refreshChromeLayout() {
        plusChrome.refreshChromeLayout()
        fieldChrome.refreshChromeLayout()
        setNeedsLayout()
        layoutIfNeeded()
    }

    func applyFrozenLayout() {
        let plusSize = IMessageDesignTokens.layer3PlusSize
        plusWidth.constant = plusSize
        plusHeight.constant = plusSize
        plusChrome.setCornerRadius(plusSize / 2)

        let inputHeight = IMessageDesignTokens.layer3InputHeight
        fieldWrapHeight.constant = inputHeight
        fieldChrome.setCornerRadius(IMessageDesignTokens.inputCornerRadius)
        fieldChrome.update(
            cornerRadius: IMessageDesignTokens.inputCornerRadius,
            borderEmphasis: IMessageDesignTokens.chromeControlBorderEmphasis,
            materialWhiten: IMessageDesignTokens.chromeControlMaterialWhiten
        )
        plusChrome.update(
            cornerRadius: plusSize / 2,
            borderEmphasis: IMessageDesignTokens.chromeControlBorderEmphasis,
            materialWhiten: IMessageDesignTokens.chromeControlMaterialWhiten
        )
        let micSize = IMessageDesignTokens.layer3MicSize
        micWidth.constant = micSize
        micHeight.constant = micSize
        let micConfig = UIImage.SymbolConfiguration(pointSize: micSize, weight: .regular)
        mic.image = UIImage(systemName: IMessageDesignTokens.micIcon, withConfiguration: micConfig)
        refreshChromeLayout()

        plusChrome.transform = CGAffineTransform(
            translationX: IMessageDesignTokens.layer3PlusOffsetX,
            y: IMessageDesignTokens.layer3PlusOffsetY
        )
        fieldWrap.transform = CGAffineTransform(
            translationX: IMessageDesignTokens.layer3InputOffsetX,
            y: IMessageDesignTokens.layer3InputOffsetY
        )
    }

    private func layoutRow(leading: UIView, fieldWrap: UIView) {
        let row = UIStackView(arrangedSubviews: [leading, fieldWrap])
        row.axis = .horizontal
        row.spacing = IMessageDesignTokens.toolbarItemSpacing
        row.alignment = .center
        row.translatesAutoresizingMaskIntoConstraints = false
        addSubview(row)
        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(
                equalTo: leadingAnchor,
                constant: IMessageDesignTokens.toolbarHorizontalPadding
            ),
            row.trailingAnchor.constraint(
                equalTo: trailingAnchor,
                constant: -IMessageDesignTokens.toolbarHorizontalPadding
            ),
            row.topAnchor.constraint(
                equalTo: topAnchor,
                constant: IMessageDesignTokens.toolbarVerticalPadding
            ),
            row.bottomAnchor.constraint(
                equalTo: bottomAnchor,
                constant: -IMessageDesignTokens.toolbarVerticalPadding
            ),
        ])
    }

    @objc private func editingChanged() {
        onTextChange?(field.text ?? "")
    }

    @objc private func plusTapped() {
        onPlusTap?()
    }
}
