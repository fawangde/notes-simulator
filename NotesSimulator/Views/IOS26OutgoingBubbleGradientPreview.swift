import SwiftUI

/// 发送气泡纵向平滑渐变（顶 / 中 / 底 Lab 插值）。
struct IOS26OutgoingBubbleGradientPreview: View {
    var topColor: UIColor
    var midColor: UIColor
    var bottomColor: UIColor
    var lineCount: Int = IOS26BubbleColorCalibration.lineCount

    var body: some View {
        OutgoingBubbleShape()
            .fill(
                LinearGradient(
                    stops: gradientStops,
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
    }

    private var gradientStops: [Gradient.Stop] {
        let palette = BubbleBlueGradient.scaledColors(
            lineCount: lineCount,
            top: topColor,
            mid: midColor,
            bottom: bottomColor
        )
        guard palette.count > 1 else {
            return [.init(color: Color(uiColor: midColor), location: 0)]
        }
        return palette.enumerated().map { index, uiColor in
            Gradient.Stop(
                color: Color(uiColor: uiColor),
                location: CGFloat(index) / CGFloat(palette.count - 1)
            )
        }
    }
}

/// 两点纵向渐变（调节面板备用）。
struct IOS26OutgoingBubbleTwoStopGradientPreview: View {
    var topColor: UIColor
    var bottomColor: UIColor

    var body: some View {
        OutgoingBubbleShape()
            .fill(
                LinearGradient(
                    colors: [Color(uiColor: topColor), Color(uiColor: bottomColor)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
    }
}
