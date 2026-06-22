import SwiftUI

/// 备忘录正文滚动进度（右侧系统风格细滑块）
struct NotesReadingProgressBar: View {
    let progress: CGFloat
    let trackHeight: CGFloat
    let viewportHeight: CGFloat
    let contentHeight: CGFloat

    private var thumbHeight: CGFloat {
        NotesDesignTokens.ReadingProgress.thumbHeight(
            trackHeight: trackHeight,
            viewportHeight: viewportHeight,
            contentHeight: contentHeight
        )
    }

    var body: some View {
        let clamped = min(max(progress, 0), 1)
        let thumbTravel = max(trackHeight - thumbHeight, 0)
        let thumbY = thumbTravel * clamped

        Capsule()
            .fill(NotesDesignTokens.ReadingProgress.thumbColor)
            .frame(
                width: NotesDesignTokens.ReadingProgress.thumbWidth,
                height: thumbHeight
            )
            .frame(height: trackHeight, alignment: .top)
            .offset(y: thumbY)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            .padding(.trailing, NotesDesignTokens.ReadingProgress.trailingInset)
            .allowsHitTesting(false)
            .animation(.interactiveSpring(response: 0.22, dampingFraction: 0.86), value: progress)
    }
}

struct NotesReadingProgressOverlay: View {
    let progress: CGFloat
    let trackHeight: CGFloat
    let viewportHeight: CGFloat
    let contentHeight: CGFloat
    let isVisible: Bool

    var body: some View {
        NotesReadingProgressBar(
            progress: progress,
            trackHeight: trackHeight,
            viewportHeight: viewportHeight,
            contentHeight: contentHeight
        )
        .frame(height: trackHeight, alignment: .top)
        .opacity(isVisible ? 1 : 0)
        .animation(
            .easeOut(
                duration: isVisible
                    ? NotesDesignTokens.ReadingProgress.revealFadeDuration
                    : NotesDesignTokens.ReadingProgress.hideFadeDuration
            ),
            value: isVisible
        )
        .allowsHitTesting(false)
    }
}

enum NotesReadingProgressTrackBounds {
    /// iOS 26：顶栏按键下沿 → 底栏按键上沿
    static func ios26(safeAreaInsets: EdgeInsets, containerHeight: CGFloat) -> (top: CGFloat, bottom: CGFloat, height: CGFloat) {
        let top = safeAreaInsets.top + NotesDesignTokens.Layout.navBarHeight
        let bottom = safeAreaInsets.bottom
            + NotesDesignTokens.Official.Toolbar.bottomSafeGap
            + NotesDesignTokens.Layout.bottomToolbarHeight
        let height = max(containerHeight - top - bottom, 0)
        return (top, bottom, height)
    }

    /// iOS 17–18 一体板：顶栏按键下沿 → 底栏按键上沿
    static func ios1718(safeTop: CGFloat, safeBottom: CGFloat, containerHeight: CGFloat) -> (top: CGFloat, bottom: CGFloat, height: CGFloat) {
        let top = safeTop
            + NotesStyle1718Tokens.unifiedNavExtraDownShift
            + NotesDesignTokens.Layout.navBarHeight
        let iconBandHeight = NotesStyle1718Tokens.chromeAboveToolbar
            + NotesDesignTokens.Layout.bottomToolbarHeight
        let bottom = safeBottom + iconBandHeight
        let height = max(containerHeight - top - bottom, 0)
        return (top, bottom, height)
    }
}

struct NotesScrollMetrics: Equatable {
    var offsetY: CGFloat = 0
    var contentHeight: CGFloat = 0
    var viewportHeight: CGFloat = 0
}

enum NotesScrollProgressProbe {
    static let coordinateSpaceName = "notesReadingScroll"

    struct OffsetKey: PreferenceKey {
        static var defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = nextValue()
        }
    }

    struct ContentHeightKey: PreferenceKey {
        static var defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = nextValue()
        }
    }

    struct ViewportHeightKey: PreferenceKey {
        static var defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = nextValue()
        }
    }
}

@available(iOS 18.0, *)
struct NotesScrollMetricsModifier: ViewModifier {
    @Binding var offsetY: CGFloat
    @Binding var contentHeight: CGFloat
    @Binding var viewportHeight: CGFloat

    func body(content: Content) -> some View {
        content
            .onScrollGeometryChange(for: NotesScrollMetrics.self) { geometry in
                NotesScrollMetrics(
                    offsetY: max(geometry.contentOffset.y, 0),
                    contentHeight: geometry.contentSize.height,
                    viewportHeight: geometry.containerSize.height
                )
            } action: { _, metrics in
                offsetY = metrics.offsetY
                contentHeight = metrics.contentHeight
                viewportHeight = metrics.viewportHeight
            }
    }
}

struct NotesLegacyScrollViewportModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .coordinateSpace(name: NotesScrollProgressProbe.coordinateSpaceName)
            .background {
                GeometryReader { geo in
                    Color.clear
                        .preference(
                            key: NotesScrollProgressProbe.ViewportHeightKey.self,
                            value: geo.size.height
                        )
                }
            }
    }
}

struct NotesScrollContentMetricsModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.background {
            GeometryReader { geo in
                Color.clear
                    .preference(
                        key: NotesScrollProgressProbe.OffsetKey.self,
                        value: -geo.frame(in: .named(NotesScrollProgressProbe.coordinateSpaceName)).minY
                    )
                    .preference(
                        key: NotesScrollProgressProbe.ContentHeightKey.self,
                        value: geo.size.height
                    )
            }
        }
    }
}

extension View {
    @ViewBuilder
    func trackNotesScrollMetrics(
        offsetY: Binding<CGFloat>,
        contentHeight: Binding<CGFloat>,
        viewportHeight: Binding<CGFloat>
    ) -> some View {
        if #available(iOS 18.0, *) {
            modifier(
                NotesScrollMetricsModifier(
                    offsetY: offsetY,
                    contentHeight: contentHeight,
                    viewportHeight: viewportHeight
                )
            )
        } else {
            modifier(NotesLegacyScrollViewportModifier())
                .onPreferenceChange(NotesScrollProgressProbe.OffsetKey.self) { offsetY.wrappedValue = $0 }
                .onPreferenceChange(NotesScrollProgressProbe.ContentHeightKey.self) { contentHeight.wrappedValue = $0 }
                .onPreferenceChange(NotesScrollProgressProbe.ViewportHeightKey.self) { viewportHeight.wrappedValue = $0 }
        }
    }

    func trackNotesScrollContentMetrics() -> some View {
        modifier(NotesScrollContentMetricsModifier())
    }
}
