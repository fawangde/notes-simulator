import SwiftUI
import UIKit

/// SwiftUI 包装：自研 ComposeMaterialSurfaceView
struct ComposeGlassSurface: UIViewRepresentable {
    var cornerRadius: CGFloat
    var preset: ComposeMaterialPreset = .chromeCard
    var showsHighlightRim: Bool = true
    var materialOpacity: CGFloat = 1

    func makeUIView(context: Context) -> ComposeMaterialSurfaceView {
        let view = ComposeMaterialSurfaceView()
        apply(to: view)
        return view
    }

    func updateUIView(_ uiView: ComposeMaterialSurfaceView, context: Context) {
        apply(to: uiView)
    }

    private func apply(to view: ComposeMaterialSurfaceView) {
        view.apply(
            preset: preset,
            cornerRadius: cornerRadius,
            materialOpacity: materialOpacity,
            showsRim: showsHighlightRim
        )
    }
}

/// 兼容旧 ComposeGlassStyle 映射
extension ComposeMaterialPreset {
    static func from(_ style: ComposeGlassStyle) -> ComposeMaterialPreset {
        switch style {
        case .chrome: .chromeCard
        case .toolbar: .toolbar
        case .pill: .chromePill
        }
    }
}

enum ComposeGlassStyle {
    case chrome
    case toolbar
    case pill
}

/// 与收发件人卡片同款控件玻璃（纯 UIKit）
struct ComposeChromeGlassSurface: UIViewRepresentable {
    var cornerRadius: CGFloat
    var borderEmphasis: CGFloat = IMessageDesignTokens.chromeControlBorderEmphasis
    var materialWhiten: CGFloat = IMessageDesignTokens.chromeControlMaterialWhiten

    func makeUIView(context: Context) -> ComposeChromeGlassHostView {
        ComposeChromeGlassHostView(
            cornerRadius: cornerRadius,
            borderEmphasis: borderEmphasis,
            materialWhiten: materialWhiten
        )
    }

    func updateUIView(_ uiView: ComposeChromeGlassHostView, context: Context) {
        uiView.update(
            cornerRadius: cornerRadius,
            borderEmphasis: borderEmphasis,
            materialWhiten: materialWhiten
        )
    }
}

/// 底栏 / 关闭钮玻璃宿主
final class ComposeChromeGlassHostView: UIView {
    private let chromeView: ComposeControlChromeUIView

    init(
        cornerRadius: CGFloat,
        borderEmphasis: CGFloat = IMessageDesignTokens.chromeControlBorderEmphasis,
        materialWhiten: CGFloat = IMessageDesignTokens.chromeControlMaterialWhiten
    ) {
        chromeView = ComposeControlChromeUIView(
            cornerRadius: cornerRadius,
            borderEmphasis: borderEmphasis,
            materialWhiten: materialWhiten
        )
        super.init(frame: .zero)
        backgroundColor = .clear
        clipsToBounds = false
        isUserInteractionEnabled = false

        chromeView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(chromeView)
        NSLayoutConstraint.activate([
            chromeView.leadingAnchor.constraint(equalTo: leadingAnchor),
            chromeView.trailingAnchor.constraint(equalTo: trailingAnchor),
            chromeView.topAnchor.constraint(equalTo: topAnchor),
            chromeView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setCornerRadius(_ radius: CGFloat) {
        update(
            cornerRadius: radius,
            borderEmphasis: chromeView.borderEmphasis,
            materialWhiten: chromeView.materialWhiten
        )
    }

    func update(cornerRadius: CGFloat, borderEmphasis: CGFloat, materialWhiten: CGFloat? = nil) {
        chromeView.apply(
            cornerRadius: cornerRadius,
            borderEmphasis: borderEmphasis,
            materialWhiten: materialWhiten ?? chromeView.materialWhiten
        )
    }

    func refreshChromeLayout() {
        chromeView.refreshChromeLayout()
    }
}

/// 撰写页小控件玻璃：手搓材质 + 双层高光描边
final class ComposeControlChromeUIView: UIView {
    private let effectView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterial))
    private let whiteVeil = UIView()
    private let frostVeil = UIView()
    private let topSheen = CAGradientLayer()
    private let whiteRing = CAShapeLayer()
    private let specularRing = CAShapeLayer()

    private(set) var cornerRadius: CGFloat
    private(set) var borderEmphasis: CGFloat
    private(set) var materialWhiten: CGFloat

    private var frost: CGFloat {
        max(0.04, min(0.98, 1 - IMessageDesignTokens.addressGlassTranslucency))
    }

    init(
        cornerRadius: CGFloat,
        borderEmphasis: CGFloat,
        materialWhiten: CGFloat = IMessageDesignTokens.chromeControlMaterialWhiten
    ) {
        self.cornerRadius = cornerRadius
        self.borderEmphasis = borderEmphasis
        self.materialWhiten = materialWhiten
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        backgroundColor = .clear
        clipsToBounds = false

        effectView.translatesAutoresizingMaskIntoConstraints = false
        effectView.alpha = 0.96
        addSubview(effectView)

        whiteVeil.isUserInteractionEnabled = false
        whiteVeil.translatesAutoresizingMaskIntoConstraints = false
        effectView.contentView.addSubview(whiteVeil)

        frostVeil.isUserInteractionEnabled = false
        frostVeil.translatesAutoresizingMaskIntoConstraints = false
        effectView.contentView.addSubview(frostVeil)

        topSheen.startPoint = CGPoint(x: 0.5, y: 0)
        topSheen.endPoint = CGPoint(x: 0.5, y: 1)
        effectView.layer.addSublayer(topSheen)

        whiteRing.fillColor = UIColor.clear.cgColor
        whiteRing.lineWidth = 0.5
        specularRing.fillColor = UIColor.clear.cgColor
        specularRing.lineWidth = 0.8
        effectView.layer.addSublayer(whiteRing)
        effectView.layer.addSublayer(specularRing)

        NSLayoutConstraint.activate([
            effectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            effectView.trailingAnchor.constraint(equalTo: trailingAnchor),
            effectView.topAnchor.constraint(equalTo: topAnchor),
            effectView.bottomAnchor.constraint(equalTo: bottomAnchor),

            whiteVeil.leadingAnchor.constraint(equalTo: effectView.contentView.leadingAnchor),
            whiteVeil.trailingAnchor.constraint(equalTo: effectView.contentView.trailingAnchor),
            whiteVeil.topAnchor.constraint(equalTo: effectView.contentView.topAnchor),
            whiteVeil.bottomAnchor.constraint(equalTo: effectView.contentView.bottomAnchor),

            frostVeil.leadingAnchor.constraint(equalTo: effectView.contentView.leadingAnchor),
            frostVeil.trailingAnchor.constraint(equalTo: effectView.contentView.trailingAnchor),
            frostVeil.topAnchor.constraint(equalTo: effectView.contentView.topAnchor),
            frostVeil.bottomAnchor.constraint(equalTo: effectView.contentView.bottomAnchor),
        ])

        applyVeilColors()
        applyShadow()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func apply(cornerRadius: CGFloat, borderEmphasis: CGFloat, materialWhiten: CGFloat) {
        self.cornerRadius = cornerRadius
        self.borderEmphasis = borderEmphasis
        self.materialWhiten = materialWhiten
        applyVeilColors()
        refreshChromeLayout()
    }

    func refreshChromeLayout() {
        setNeedsLayout()
        layoutIfNeeded()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        refreshChromeLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let radius = cornerRadius
        effectView.layer.cornerRadius = radius
        effectView.layer.cornerCurve = .continuous
        effectView.clipsToBounds = true

        topSheen.frame = CGRect(x: 0, y: 0, width: bounds.width, height: min(10, bounds.height * 0.28))
        topSheen.colors = [
            UIColor.white.withAlphaComponent(0.42 * borderEmphasis).cgColor,
            UIColor.white.withAlphaComponent(0).cgColor,
        ]

        let outerInset = bounds.insetBy(dx: 0.35, dy: 0.35)
        let innerInset = bounds.insetBy(dx: 0.85, dy: 0.85)
        let outerRadius = max(0, radius - 0.35)
        let innerRadius = max(0, radius - 0.85)

        whiteRing.path = UIBezierPath(roundedRect: outerInset, cornerRadius: outerRadius).cgPath
        specularRing.path = UIBezierPath(roundedRect: innerInset, cornerRadius: innerRadius).cgPath

        let edge = borderEmphasis
        whiteRing.strokeColor = UIColor.white.withAlphaComponent((0.50 + frost * 0.48) * edge).cgColor
        specularRing.strokeColor = UIColor.white.withAlphaComponent(
            IMessageDesignTokens.chromeControlSpecularAlpha * edge
        ).cgColor

        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: radius).cgPath
    }

    private func applyVeilColors() {
        whiteVeil.backgroundColor = UIColor.white.withAlphaComponent(materialWhiten)
        frostVeil.backgroundColor = UIColor.white.withAlphaComponent(
            IMessageDesignTokens.addressGlassWhiten * frost * min(1.12, borderEmphasis * 0.72)
        )
    }

    private func applyShadow() {
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = Float(IMessageDesignTokens.chromeControlShadowOpacity)
        layer.shadowRadius = IMessageDesignTokens.chromeControlShadowRadius
        layer.shadowOffset = CGSize(width: 0, height: IMessageDesignTokens.chromeControlShadowY)
        layer.masksToBounds = false
    }
}
