import SwiftUI
import UIKit

/// SwiftUI 预览用 iMessage 末条发送气泡
struct OutgoingBubbleShape: Shape {
    var tailScale: CGFloat = 1
    var tailShiftX: CGFloat = 0
    var tailOffsetY: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        let flatBottom = rect.height - IMessageDesignTokens.bubbleTailDrop * tailScale
        let uiPath = IOSOutgoingBubblePath.sentLastBubblePath(
            bodyWidth: rect.width,
            flatBottomY: flatBottom,
            tailScale: tailScale,
            tailShiftX: tailShiftX,
            tailOffsetY: tailOffsetY
        )
        return Path(uiPath.cgPath)
    }
}
