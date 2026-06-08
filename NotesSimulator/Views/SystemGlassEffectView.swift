import SwiftUI
import UIKit

/// iOS 26+ 系统 UIGlassEffect；低版本回退 systemMaterial
struct SystemGlassEffectView: UIViewRepresentable {
    enum Style {
        case regular
        case clear
    }

    var style: Style = .regular
    var isInteractive: Bool = false
    /// 略增白感，贴近真机按钮「更实」观感
    var whiterTint: Bool = false
    var whiteTintOpacity: CGFloat = 0.12

    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView()
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        applyEffect(to: view)
        return view
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        applyEffect(to: uiView)
    }

    private func applyEffect(to view: UIVisualEffectView) {
        if #available(iOS 26, *) {
            let glassStyle: UIGlassEffect.Style = style == .regular ? .regular : .clear
            let glass = UIGlassEffect(style: glassStyle)
            glass.isInteractive = isInteractive
            if whiterTint {
                glass.tintColor = UIColor.white.withAlphaComponent(whiteTintOpacity)
            }
            view.effect = glass
        } else {
            view.effect = UIBlurEffect(style: .systemMaterial)
        }
    }
}
