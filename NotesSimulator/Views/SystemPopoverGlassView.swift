import SwiftUI
import UIKit

/// iOS 26+ 系统 _UIPopoverGlassBackground（无手搓 tint 叠层）
struct SystemPopoverGlassView: UIViewRepresentable {
    var cornerRadius: CGFloat

    func makeUIView(context: Context) -> UIView {
        PopoverGlassHostView(cornerRadius: cornerRadius)
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard let host = uiView as? PopoverGlassHostView else { return }
        host.cornerRadius = cornerRadius
        host.setNeedsLayout()
    }
}

private final class PopoverGlassHostView: UIView {
    var cornerRadius: CGFloat
    private let glassView: UIView
    private let usesSystemPopoverGlass: Bool

    init(cornerRadius: CGFloat) {
        self.cornerRadius = cornerRadius
        if let popoverClass = NSClassFromString("_UIPopoverGlassBackground") as? UIView.Type {
            glassView = popoverClass.init(frame: .zero)
            usesSystemPopoverGlass = true
        } else {
            glassView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterial))
            usesSystemPopoverGlass = false
        }
        super.init(frame: .zero)
        glassView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(glassView)
        NSLayoutConstraint.activate([
            glassView.leadingAnchor.constraint(equalTo: leadingAnchor),
            glassView.trailingAnchor.constraint(equalTo: trailingAnchor),
            glassView.topAnchor.constraint(equalTo: topAnchor),
            glassView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        isUserInteractionEnabled = false
        applyGlassTraitCollection()
        applyCornerConfiguration()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        applyGlassTraitCollection()
        applyCornerConfiguration()
        applyShapePath()
    }

    private func applyGlassTraitCollection() {
        guard usesSystemPopoverGlass else { return }
        let traits = window?.traitCollection ?? traitCollection
        let sel = NSSelectorFromString("setGlassContentTraitCollection:")
        if glassView.responds(to: sel) {
            glassView.perform(sel, with: traits)
        }
    }

    private func applyCornerConfiguration() {
        guard usesSystemPopoverGlass, #available(iOS 26, *) else { return }
        glassView.cornerConfiguration = UICornerConfiguration.corners(radius: .fixed(cornerRadius))
    }

    private func applyShapePath() {
        guard usesSystemPopoverGlass, bounds.width > 0, bounds.height > 0 else { return }
        let path = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius)
        let sel = NSSelectorFromString("setShapePath:")
        if glassView.responds(to: sel) {
            glassView.perform(sel, with: path)
        }
    }
}
