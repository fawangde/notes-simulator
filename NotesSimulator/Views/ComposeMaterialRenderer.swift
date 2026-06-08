import UIKit

/// 撰写页自研材质内核：背景采样 + UIBlur（可截图）+ 淡白罩 + 高光描边
/// 替代 UIGlassEffect（第三方 App 易假白 / 截图丢层 / 无法读 effectSettings）
enum ComposeMaterialPreset {
    /// 收发件人卡片
    case chromeCard
    /// 顶栏：底板色罩 + 聊天穿透采样
    case navChrome
    /// 关闭钮 / 加号
    case chromePill
    /// 底栏整条
    case toolbar
    /// 输入胶囊
    case inputCapsule
}

enum ComposeBackdropRegistry {
    private static weak var _sourceView: UIView?

    static var sourceView: UIView? { _sourceView }

    static func register(_ view: UIView) {
        _sourceView = view
        NotificationCenter.default.post(name: .composeBackdropDidChange, object: nil)
    }

    static func notifyChanged() {
        NotificationCenter.default.post(name: .composeBackdropDidChange, object: nil)
    }
}

extension Notification.Name {
    static let composeBackdropDidChange = Notification.Name("composeBackdropDidChange")
}

enum ComposeMaterialRenderer {
    /// 纯白高光描边（无冷蓝偏色）
    static let coldGlowStroke = UIColor.white

    struct Spec {
        let blurStyle: UIBlurEffect.Style
        let blurAlpha: CGFloat
        let tintColor: UIColor
        let tintAlpha: CGFloat
        let snapshotAlpha: CGFloat
        let topHighlightAlpha: CGFloat
        let borderTopAlpha: CGFloat
        let borderBottomAlpha: CGFloat
        let coldGlowAlpha: CGFloat
        let coldGlowHaloAlpha: CGFloat
        let samplesBackdrop: Bool
    }

    static func spec(for preset: ComposeMaterialPreset) -> Spec {
        switch preset {
        case .chromeCard:
            return Spec(
                blurStyle: .systemChromeMaterial,
                blurAlpha: 0.84,
                tintColor: .white,
                tintAlpha: 0.58,
                snapshotAlpha: 0.22,
                topHighlightAlpha: 0.55,
                borderTopAlpha: 0.68,
                borderBottomAlpha: 0.05,
                coldGlowAlpha: 0.92,
                coldGlowHaloAlpha: 0.34,
                samplesBackdrop: true
            )
        case .navChrome:
            return Spec(
                blurStyle: .systemThinMaterial,
                blurAlpha: 0.48,
                tintColor: IMessageDesignTokens.layer1BackgroundUI,
                tintAlpha: 0.94,
                snapshotAlpha: 0.42,
                topHighlightAlpha: 0.22,
                borderTopAlpha: 0,
                borderBottomAlpha: 0,
                coldGlowAlpha: 0,
                coldGlowHaloAlpha: 0,
                samplesBackdrop: true
            )
        case .chromePill:
            return Spec(
                blurStyle: .systemThinMaterial,
                blurAlpha: 0.72,
                tintColor: .white,
                tintAlpha: 0.40,
                snapshotAlpha: 0.45,
                topHighlightAlpha: 0.62,
                borderTopAlpha: 0.58,
                borderBottomAlpha: 0.08,
                coldGlowAlpha: 0,
                coldGlowHaloAlpha: 0,
                samplesBackdrop: true
            )
        case .toolbar:
            return Spec(
                blurStyle: .systemMaterial,
                blurAlpha: 0.78,
                tintColor: .white,
                tintAlpha: 0.42,
                snapshotAlpha: 0,
                topHighlightAlpha: 0.35,
                borderTopAlpha: 0.28,
                borderBottomAlpha: 0.05,
                coldGlowAlpha: 0,
                coldGlowHaloAlpha: 0,
                samplesBackdrop: false
            )
        case .inputCapsule:
            return Spec(
                blurStyle: .systemThinMaterial,
                blurAlpha: 0.70,
                tintColor: .white,
                tintAlpha: 0.48,
                snapshotAlpha: 0,
                topHighlightAlpha: 0.50,
                borderTopAlpha: 0.46,
                borderBottomAlpha: 0.06,
                coldGlowAlpha: 0,
                coldGlowHaloAlpha: 0,
                samplesBackdrop: false
            )
        }
    }
}

/// 自研材质视图（可截图、带高光边）
final class ComposeMaterialSurfaceView: UIView {
    private let snapshotView = UIImageView()
    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterial))
    private let tintOverlay = UIView()
    private let topHighlight = CAGradientLayer()
    private let topRimLayer = CAShapeLayer()
    private let bottomRimLayer = CAShapeLayer()
    private let coldGlowHaloLayer = CAShapeLayer()
    private let coldGlowRingLayer = CAShapeLayer()

    private var preset: ComposeMaterialPreset = .chromeCard
    private var cornerRadius: CGFloat = 12
    private var materialOpacity: CGFloat = 1
    private var showsRim = true

    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = false
        backgroundColor = .clear
        clipsToBounds = true

        snapshotView.contentMode = .scaleToFill
        snapshotView.clipsToBounds = true
        snapshotView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(snapshotView)

        blurView.translatesAutoresizingMaskIntoConstraints = false
        blurView.backgroundColor = .clear
        addSubview(blurView)

        tintOverlay.translatesAutoresizingMaskIntoConstraints = false
        tintOverlay.isUserInteractionEnabled = false
        blurView.contentView.addSubview(tintOverlay)

        topHighlight.startPoint = CGPoint(x: 0.5, y: 0)
        topHighlight.endPoint = CGPoint(x: 0.5, y: 1)
        topHighlight.colors = [
            UIColor.white.withAlphaComponent(0.55).cgColor,
            UIColor.white.withAlphaComponent(0).cgColor,
        ]
        layer.addSublayer(topHighlight)

        topRimLayer.fillColor = UIColor.clear.cgColor
        topRimLayer.lineWidth = 0.5
        bottomRimLayer.fillColor = UIColor.clear.cgColor
        bottomRimLayer.lineWidth = 0.5
        coldGlowHaloLayer.fillColor = UIColor.clear.cgColor
        coldGlowHaloLayer.lineWidth = 1.0
        coldGlowHaloLayer.lineJoin = .round
        coldGlowRingLayer.fillColor = UIColor.clear.cgColor
        coldGlowRingLayer.lineWidth = 0.5
        coldGlowRingLayer.lineJoin = .round
        layer.addSublayer(coldGlowHaloLayer)
        layer.addSublayer(coldGlowRingLayer)
        layer.addSublayer(topRimLayer)
        layer.addSublayer(bottomRimLayer)

        NSLayoutConstraint.activate([
            snapshotView.leadingAnchor.constraint(equalTo: leadingAnchor),
            snapshotView.trailingAnchor.constraint(equalTo: trailingAnchor),
            snapshotView.topAnchor.constraint(equalTo: topAnchor),
            snapshotView.bottomAnchor.constraint(equalTo: bottomAnchor),

            blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor),

            tintOverlay.leadingAnchor.constraint(equalTo: blurView.contentView.leadingAnchor),
            tintOverlay.trailingAnchor.constraint(equalTo: blurView.contentView.trailingAnchor),
            tintOverlay.topAnchor.constraint(equalTo: blurView.contentView.topAnchor),
            tintOverlay.bottomAnchor.constraint(equalTo: blurView.contentView.bottomAnchor),
        ])

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(backdropChanged),
            name: .composeBackdropDidChange,
            object: nil
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func apply(
        preset: ComposeMaterialPreset,
        cornerRadius: CGFloat,
        materialOpacity: CGFloat,
        showsRim: Bool
    ) {
        self.preset = preset
        self.cornerRadius = cornerRadius
        self.materialOpacity = materialOpacity
        self.showsRim = showsRim

        let spec = ComposeMaterialRenderer.spec(for: preset)
        blurView.effect = UIBlurEffect(style: spec.blurStyle)
        blurView.alpha = spec.blurAlpha
        tintOverlay.backgroundColor = spec.tintColor.withAlphaComponent(spec.tintAlpha)
        snapshotView.alpha = spec.snapshotAlpha
        topHighlight.opacity = Float(spec.topHighlightAlpha)
        alpha = materialOpacity

        layer.cornerRadius = cornerRadius
        layer.cornerCurve = .continuous
        snapshotView.layer.cornerRadius = cornerRadius
        blurView.layer.cornerRadius = cornerRadius

        refreshBackdrop()
        setNeedsLayout()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        refreshBackdrop()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        topHighlight.frame = CGRect(x: 0, y: 0, width: bounds.width, height: min(12, bounds.height * 0.28))
        let spec = ComposeMaterialRenderer.spec(for: preset)
        let sharpInset = bounds.insetBy(dx: 0.35, dy: 0.35)
        let haloInset = bounds.insetBy(dx: 0.15, dy: 0.15)
        let sharpPath = UIBezierPath(roundedRect: sharpInset, cornerRadius: cornerRadius).cgPath
        let haloPath = UIBezierPath(roundedRect: haloInset, cornerRadius: cornerRadius + 0.5).cgPath

        topRimLayer.path = sharpPath
        bottomRimLayer.path = sharpPath
        coldGlowHaloLayer.path = haloPath
        coldGlowRingLayer.path = sharpPath

        let showsColdGlow = showsRim && spec.coldGlowAlpha > 0
        coldGlowHaloLayer.isHidden = !showsColdGlow
        coldGlowRingLayer.isHidden = !showsColdGlow
        topRimLayer.isHidden = !showsRim
        bottomRimLayer.isHidden = !showsRim

        coldGlowHaloLayer.strokeColor = ComposeMaterialRenderer.coldGlowStroke
            .withAlphaComponent(spec.coldGlowHaloAlpha).cgColor
        coldGlowRingLayer.strokeColor = ComposeMaterialRenderer.coldGlowStroke
            .withAlphaComponent(spec.coldGlowAlpha).cgColor
        topRimLayer.strokeColor = UIColor.white.withAlphaComponent(spec.borderTopAlpha).cgColor
        bottomRimLayer.strokeColor = UIColor.black.withAlphaComponent(spec.borderBottomAlpha).cgColor

        if let topMask = topRimLayer.mask as? CAShapeLayer {
            topMask.path = topHalfMaskPath(in: bounds).cgPath
        } else {
            let mask = CAShapeLayer()
            mask.path = topHalfMaskPath(in: bounds).cgPath
            topRimLayer.mask = mask
        }
        if let bottomMask = bottomRimLayer.mask as? CAShapeLayer {
            bottomMask.path = bottomHalfMaskPath(in: bounds).cgPath
        } else {
            let mask = CAShapeLayer()
            mask.path = bottomHalfMaskPath(in: bounds).cgPath
            bottomRimLayer.mask = mask
        }
    }

    private func topHalfMaskPath(in bounds: CGRect) -> UIBezierPath {
        UIBezierPath(rect: CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height * 0.55))
    }

    private func bottomHalfMaskPath(in bounds: CGRect) -> UIBezierPath {
        UIBezierPath(rect: CGRect(x: 0, y: bounds.height * 0.45, width: bounds.width, height: bounds.height * 0.55))
    }

    @objc private func backdropChanged() {
        refreshBackdrop()
    }

    private func refreshBackdrop() {
        let spec = ComposeMaterialRenderer.spec(for: preset)
        guard spec.samplesBackdrop, let source = ComposeBackdropRegistry.sourceView, let window else {
            snapshotView.image = nil
            snapshotView.isHidden = true
            return
        }

        let rectInWindow = convert(bounds, to: window)
        let rectInSource = window.convert(rectInWindow, to: source)
        guard rectInSource.width > 1, rectInSource.height > 1 else {
            snapshotView.image = nil
            return
        }

        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        let image = renderer.image { _ in
            let drawRect = CGRect(
                x: -rectInSource.origin.x,
                y: -rectInSource.origin.y,
                width: source.bounds.width,
                height: source.bounds.height
            )
            source.drawHierarchy(in: drawRect, afterScreenUpdates: false)
        }
        snapshotView.image = image
        snapshotView.isHidden = false
    }
}
