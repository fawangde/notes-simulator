import SwiftUI
import UIKit

/// Messages / CNCompose 材质：UIGlassEffect、UIGlassContainerEffect、systemChromeMaterial
enum SystemMessagesMaterial {
    enum Kind {
        case materialPlus
        case materialRegularPlus
    }

    static func effect(for kind: Kind) -> UIVisualEffect {
        composeGlassEffect(for: kind == .materialRegularPlus ? .toolbar : .chrome)
    }

    /// 撰写页分层玻璃（真机 iOS 26：CNCompose 细高光边 + 近底色透明）
    static func composeGlassEffect(for style: ComposeGlassStyle) -> UIVisualEffect {
        if #available(iOS 26, *) {
            switch style {
            case .chrome:
                let glass = UIGlassEffect(style: .clear)
                glass.isInteractive = false
                glass.tintColor = UIColor.white.withAlphaComponent(0.06)
                return glass
            case .toolbar:
                let glass = UIGlassEffect(style: .regular)
                glass.isInteractive = true
                return glass
            case .pill:
                let glass = UIGlassEffect(style: .clear)
                glass.isInteractive = true
                return glass
            }
        }
        switch style {
        case .chrome:
            return UIBlurEffect(style: .systemChromeMaterial)
        case .toolbar, .pill:
            return UIBlurEffect(style: .systemMaterial)
        }
    }

    /// 细高光描边渐变（模拟 CUIGlassHighlight / 系统 compose 外圈）
    static func highlightRimColors(for style: ComposeGlassStyle) -> [CGColor] {
        switch style {
        case .chrome:
            return [
                UIColor.white.withAlphaComponent(0.62).cgColor,
                UIColor.white.withAlphaComponent(0.18).cgColor,
                UIColor.black.withAlphaComponent(0.05).cgColor,
            ]
        case .toolbar, .pill:
            return [
                UIColor.white.withAlphaComponent(0.48).cgColor,
                UIColor.white.withAlphaComponent(0.14).cgColor,
                UIColor.black.withAlphaComponent(0.04).cgColor,
            ]
        }
    }

    /// UIGlassContainerEffect（探针 Phase 6b 可挂载；用于多玻璃元件编组）
    static func glassContainerEffect(spacing: CGFloat = 8) -> UIVisualEffect? {
        guard let cls = NSClassFromString("UIGlassContainerEffect") as? NSObject.Type,
              let effect = cls.init() as? UIVisualEffect
        else { return nil }
        let spacingSel = NSSelectorFromString("setSpacing:")
        if effect.responds(to: spacingSel) {
            effect.perform(spacingSel, with: NSNumber(value: Double(spacing)))
        }
        return effect
    }
}

struct SystemMessagesMaterialView: UIViewRepresentable {
    var kind: SystemMessagesMaterial.Kind

    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: SystemMessagesMaterial.effect(for: kind))
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = SystemMessagesMaterial.effect(for: kind)
    }
}
