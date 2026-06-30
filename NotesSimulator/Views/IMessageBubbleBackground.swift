import SwiftUI

/// 发送气泡：按行数等比截取标准 16 行 Lab 渐变曲线。
struct IMessageBubbleBackground: View {
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
            top: IMessageDesignTokens.bubbleBlueTop,
            mid: IMessageDesignTokens.bubbleBlueMid,
            bottom: IMessageDesignTokens.bubbleBlueBottom
        )
        guard palette.count > 1 else {
            return [.init(color: Color(uiColor: IMessageDesignTokens.bubbleBlueFill), location: 0)]
        }
        return palette.enumerated().map { index, uiColor in
            Gradient.Stop(
                color: Color(uiColor: uiColor),
                location: CGFloat(index) / CGFloat(palette.count - 1)
            )
        }
    }
}
