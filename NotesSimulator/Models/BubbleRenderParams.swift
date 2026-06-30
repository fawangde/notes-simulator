import UIKit

extension UIColor {
    var rgbaComponents: (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return (r, g, b, a)
    }
}

/// 发送气泡尾巴渲染参数（冻结）
struct BubbleTailRenderParams: Equatable {
    var fillRed: Double
    var fillGreen: Double
    var fillBlue: Double
    var anchorXFraction: Double
    var offsetX: Double
    var offsetY: Double
    var scale: Double
    var showsTail: Bool
    /// 图文模式文字气泡四角统一圆角（nil = 撰写页默认 22pt）
    var bodyCornerRadius: CGFloat?

    var fillUIColor: UIColor {
        UIColor(red: fillRed, green: fillGreen, blue: fillBlue, alpha: 1)
    }

    static let frozenDefault: BubbleTailRenderParams = {
        let fill = IMessageDesignTokens.bubbleBlueMid.rgbaComponents
        return BubbleTailRenderParams(
            fillRed: Double(fill.r),
            fillGreen: Double(fill.g),
            fillBlue: Double(fill.b),
            anchorXFraction: Double(IMessageDesignTokens.bubbleTailAnchorXFraction),
            offsetX: Double(IMessageDesignTokens.bubbleTailOffsetX),
            offsetY: Double(IMessageDesignTokens.bubbleTailOffsetY),
            scale: Double(IMessageDesignTokens.bubbleTailScale),
            showsTail: true,
            bodyCornerRadius: nil
        )
    }()
}
