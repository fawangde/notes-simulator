import SwiftUI

/// 发送气泡：实色填充，无渐变无阴影
struct IMessageBubbleBackground: View {
    var body: some View {
        OutgoingBubbleShape()
            .fill(Color(uiColor: IMessageDesignTokens.bubbleBlueFill))
    }
}
