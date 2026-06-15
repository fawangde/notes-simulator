import SwiftUI

// MARK: - 1718 FromVC：uniform scale + offset + 顶圆角（与 transform 同序）

struct Notes1718FromViewModalLayer: AnimatableModifier {
    var progress: CGFloat
    var screenWidth: CGFloat
    var screenHeight: CGFloat
    var safeTop: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    private var clamped: CGFloat { min(max(progress, 0), 1) }

    private var scale: CGFloat {
        1 - clamped * (1 - IMessage1718DesignTokens.fromViewEndScale)
    }

    /// 终态顶边 = safeTop（纸色条填满 notesRevealGap）
    private var offsetY: CGFloat {
        guard clamped > 0.001, screenHeight > 1 else { return 0 }
        let endScale = IMessage1718DesignTokens.fromViewEndScale
        let topFromScaleAtFull = (screenHeight - screenHeight * endScale) * 0.5
        let endOffset = safeTop - topFromScaleAtFull
        return clamped * endOffset
    }

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale, anchor: .center)
            .offset(y: offsetY)
            .mask {
                Notes1718FromViewCardMask(
                    progress: clamped,
                    width: screenWidth,
                    height: screenHeight,
                    safeTop: safeTop,
                    scale: scale,
                    offsetY: offsetY
                )
            }
    }
}

// MARK: - 缩小卡片顶圆角（仅当 cardTop ≥ safeTop 时启用，避免进状态栏）

private struct Notes1718FromViewCardMask: View {
    var progress: CGFloat
    var width: CGFloat
    var height: CGFloat
    var safeTop: CGFloat
    var scale: CGFloat
    var offsetY: CGFloat

    var body: some View {
        GeometryReader { geo in
            let layoutW = width > 0.5 ? width : geo.size.width
            let layoutH = height > 0.5 ? height : geo.size.height
            let cardW = layoutW * scale
            let cardH = layoutH * scale
            let cardTop = (layoutH - cardH) * 0.5 + offsetY
            let radius = progress * IMessage1718DesignTokens.fromViewTopCornerRadius
            let useTopCorners = progress > 0.001 && cardTop >= safeTop - 0.5 && radius > 0.25

            Group {
                if useTopCorners {
                    UnevenRoundedRectangle(
                        topLeadingRadius: min(radius, cardW * 0.5),
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: min(radius, cardW * 0.5),
                        style: .continuous
                    )
                    .frame(width: cardW, height: cardH)
                    .position(x: layoutW * 0.5, y: cardTop + cardH * 0.5)
                } else {
                    Rectangle()
                        .frame(width: layoutW, height: layoutH)
                }
            }
        }
    }
}

#if DEBUG
enum Notes1718FromViewGeometryProbe {
    private static var lastLoggedProgress: CGFloat = -1

    static func logIfNeeded(progress: CGFloat, safeTop: CGFloat, height: CGFloat) {
        guard progress > 0.01 else {
            lastLoggedProgress = -1
            return
        }
        guard abs(progress - lastLoggedProgress) > 0.08 || progress > 0.99 else { return }
        lastLoggedProgress = progress

        let s = 1 - progress * (1 - IMessage1718DesignTokens.fromViewEndScale)
        let fullTopFromScale = (height - height * IMessage1718DesignTokens.fromViewEndScale) * 0.5
        let fullEndOffset = safeTop - fullTopFromScale
        let cardTop = (height - height * s) * 0.5 + progress * fullEndOffset
        let msg = String(
            format: "[1718 FromView] progress=%.2f H=%.0f cardTop=%.1f safeTop=%.1f Δ=%.1f",
            progress,
            height,
            cardTop,
            safeTop,
            cardTop - safeTop
        )
        if cardTop < safeTop + IMessage1718DesignTokens.notesRevealGap - 1 {
            print(msg + " ⚠️ 圆角会进状态栏区")
        } else {
            print(msg)
        }
    }
}
#endif
