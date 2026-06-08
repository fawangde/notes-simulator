import SwiftUI

/// 顶栏向上延伸至状态栏的渐变毛玻璃：材质用 systemThinMaterial，渐变仅作遮罩形状（不改材质 α）
struct NotesTopGlassFade: View {
    var fadeBelowNav: CGFloat = 24

    var body: some View {
        GeometryReader { geo in
            let safeTop = geo.safeAreaInsets.top
            let navH = NotesDesignTokens.Layout.navBarHeight
            let totalH = safeTop + navH + fadeBelowNav

            VisualEffectBlur(style: NotesDesignTokens.Official.MaterialName.topFade)
                .frame(height: totalH)
                .mask(fadeMask)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .ignoresSafeArea(edges: .top)
        .allowsHitTesting(false)
    }

    private var fadeMask: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: .black, location: 0),
                .init(color: .black.opacity(0.85), location: 0.38),
                .init(color: .black.opacity(0.45), location: 0.72),
                .init(color: .clear, location: 1.0),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
