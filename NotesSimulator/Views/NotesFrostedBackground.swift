import SwiftUI

/// 备忘录主页按键：与撰写页收发件人卡片同款玻璃（参数一致，形状由外层 clip 决定）
enum NotesFrostedBackground {
    /// 与 `IMessageDesignTokens.layer3AddressCardRadius` 材质参数一致；圆角随按键尺寸（44pt 高 → 22pt）
    static var buttonGlassCornerRadius: CGFloat {
        NotesDesignTokens.Official.Nav.buttonCornerRadius
    }

    static func addressCardMatchedGlass(showsLiftShadow: Bool = false) -> some View {
        ComposeAddressGlassBackground(
            cornerRadius: buttonGlassCornerRadius,
            renderMode: .addressCard,
            showsLiftShadow: showsLiftShadow
        )
    }

    static func navButtonGlass() -> some View {
        addressCardMatchedGlass()
    }

    static func toolbarGlass() -> some View {
        addressCardMatchedGlass()
    }

    static var addressCardLiftShadow: (color: Color, radius: CGFloat, y: CGFloat) {
        (
            color: .black.opacity(IMessageDesignTokens.addressGlassLiftShadowOpacity),
            radius: IMessageDesignTokens.addressGlassLiftShadowRadius,
            y: IMessageDesignTokens.addressGlassLiftShadowY
        )
    }

    static func phoneMenuPanel<S: Shape>(in shape: S) -> some View {
        if #available(iOS 26, *) {
            AnyView(SystemGlassEffectView(style: .regular).clipShape(shape))
        } else {
            AnyView(shape.fill(NotesDesignTokens.Official.MaterialName.phoneMenu))
        }
    }
}
