import SwiftUI
import UIKit

enum NotesReadingProgressTrackBounds {
    /// iOS 26 ScrollView 局部坐标
    static func ios26ScrollHost(safeAreaInsets: UIEdgeInsets, viewportHeight: CGFloat) -> (top: CGFloat, bottom: CGFloat, height: CGFloat) {
        let bottom = safeAreaInsets.bottom
            + NotesDesignTokens.Official.Toolbar.bottomSafeGap
            + NotesDesignTokens.Layout.bottomToolbarHeight
        let height = max(viewportHeight - bottom, 0)
        return (0, bottom, height)
    }

    /// iOS 17–18 ScrollView 局部坐标
    static func ios1718ScrollHost(safeBottom: CGFloat, viewportHeight: CGFloat) -> (top: CGFloat, bottom: CGFloat, height: CGFloat) {
        let bottom = safeBottom
            + NotesStyle1718Tokens.chromeAboveToolbar
            + NotesDesignTokens.Layout.bottomToolbarHeight
        let height = max(viewportHeight - bottom, 0)
        return (0, bottom, height)
    }
}

enum NotesReadingProgressTrackStyle {
    case ios26
    case ios1718(safeBottom: CGFloat)
}

/// 进度条与 ScrollView 并列挂载；滚动指标在 UIKit 层更新，避免惯性滚动每帧触发 SwiftUI 重绘正文。
struct NotesReadingProgressAttachment<Content: View>: View {
    let trackStyle: NotesReadingProgressTrackStyle
    private let content: Content

    init(trackStyle: NotesReadingProgressTrackStyle, @ViewBuilder content: () -> Content) {
        self.trackStyle = trackStyle
        self.content = content()
    }

    var body: some View {
        content
            .overlay(alignment: .trailing) {
                NotesReadingProgressUIKitIndicator(trackStyle: trackStyle)
            }
    }
}

extension View {
    /// iOS 16–17 旧路径保留入口；iOS 18+ 为 no-op（指标改由 UIKit 进度条读取）。
    @ViewBuilder
    func trackNotesReadingScrollContent() -> some View {
        self
    }
}

// MARK: - UIKit indicator

private struct NotesReadingProgressUIKitIndicator: UIViewRepresentable {
    let trackStyle: NotesReadingProgressTrackStyle

    func makeCoordinator() -> Coordinator {
        Coordinator(trackStyle: trackStyle)
    }

    func makeUIView(context: Context) -> NotesReadingProgressIndicatorView {
        let view = NotesReadingProgressIndicatorView()
        context.coordinator.indicatorView = view
        return view
    }

    func updateUIView(_ uiView: NotesReadingProgressIndicatorView, context: Context) {
        context.coordinator.trackStyle = trackStyle
        context.coordinator.scheduleAttach(from: uiView)
    }

    static func dismantleUIView(_ uiView: NotesReadingProgressIndicatorView, coordinator: Coordinator) {
        coordinator.detach()
    }

    final class Coordinator {
        var trackStyle: NotesReadingProgressTrackStyle
        weak var indicatorView: NotesReadingProgressIndicatorView?
        weak var scrollView: UIScrollView?
        private var observations: [NSKeyValueObservation] = []
        private var hideWorkItem: DispatchWorkItem?

        init(trackStyle: NotesReadingProgressTrackStyle) {
            self.trackStyle = trackStyle
        }

        func scheduleAttach(from view: UIView, attemptsRemaining: Int = 12) {
            DispatchQueue.main.async { [weak self, weak view] in
                guard let self, let view else { return }
                if let scrollView = view.findScrollView() {
                    self.attach(to: scrollView)
                    return
                }
                guard attemptsRemaining > 0 else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
                    self.scheduleAttach(from: view, attemptsRemaining: attemptsRemaining - 1)
                }
            }
        }

        func attach(to scrollView: UIScrollView) {
            guard scrollView !== self.scrollView else {
                refresh()
                return
            }
            detach()
            self.scrollView = scrollView
            refresh()
            observations = [
                scrollView.observe(\.contentOffset, options: [.new]) { [weak self] _, _ in
                    self?.scrollDidChange()
                },
                scrollView.observe(\.contentSize, options: [.new]) { [weak self] _, _ in
                    self?.refresh()
                },
                scrollView.observe(\.bounds, options: [.new]) { [weak self] _, _ in
                    self?.refresh()
                },
            ]
        }

        func detach() {
            observations.removeAll()
            scrollView = nil
            hideWorkItem?.cancel()
            hideWorkItem = nil
            indicatorView?.setVisible(false, animated: false)
        }

        private func scrollDidChange() {
            refresh()
            revealIndicator()
            scheduleHide()
        }

        private func revealIndicator() {
            indicatorView?.setVisible(true, animated: true)
        }

        private func scheduleHide() {
            hideWorkItem?.cancel()
            let work = DispatchWorkItem { [weak self] in
                self?.indicatorView?.setVisible(false, animated: true)
            }
            hideWorkItem = work
            DispatchQueue.main.asyncAfter(
                deadline: .now() + NotesDesignTokens.ReadingProgress.autoHideDelay,
                execute: work
            )
        }

        func refresh() {
            guard let scrollView, let indicatorView else { return }
            guard let host = indicatorView.superview else { return }

            let viewportHeight = scrollView.bounds.height
            let contentHeight = scrollView.contentSize.height
            guard viewportHeight > 0, contentHeight > viewportHeight + 1 else {
                indicatorView.setVisible(false, animated: false)
                return
            }

            let safeBottom = host.safeAreaInsets.bottom
            let bounds: (top: CGFloat, bottom: CGFloat, height: CGFloat) = {
                switch trackStyle {
                case .ios26:
                    return NotesReadingProgressTrackBounds.ios26ScrollHost(
                        safeAreaInsets: UIEdgeInsets(top: 0, left: 0, bottom: safeBottom, right: 0),
                        viewportHeight: viewportHeight
                    )
                case let .ios1718(safeBottom):
                    return NotesReadingProgressTrackBounds.ios1718ScrollHost(
                        safeBottom: safeBottom,
                        viewportHeight: viewportHeight
                    )
                }
            }()

            let maxScroll = max(contentHeight - viewportHeight, 1)
            let progress = min(max(scrollView.contentOffset.y / maxScroll, 0), 1)
            let thumbHeight = NotesDesignTokens.ReadingProgress.thumbHeight(
                trackHeight: bounds.height,
                viewportHeight: viewportHeight,
                contentHeight: contentHeight
            )
            let thumbTravel = max(bounds.height - thumbHeight, 0)
            let thumbY = bounds.top + thumbTravel * progress

            indicatorView.updateThumb(
                y: thumbY,
                height: thumbHeight,
                width: NotesDesignTokens.ReadingProgress.thumbWidth,
                trailingInset: NotesDesignTokens.ReadingProgress.trailingInset
            )
        }
    }
}

private final class NotesReadingProgressIndicatorView: UIView {
    private let thumbView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = .clear

        thumbView.backgroundColor = UIColor(NotesDesignTokens.ReadingProgress.thumbColor)
        thumbView.layer.cornerRadius = NotesDesignTokens.ReadingProgress.thumbWidth / 2
        thumbView.alpha = 0
        addSubview(thumbView)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateThumb(y: CGFloat, height: CGFloat, width: CGFloat, trailingInset: CGFloat) {
        let x = bounds.width - trailingInset - width
        thumbView.frame = CGRect(x: x, y: y, width: width, height: height)
    }

    func setVisible(_ visible: Bool, animated: Bool) {
        let target: CGFloat = visible ? 1 : 0
        guard abs(thumbView.alpha - target) > 0.01 else { return }
        if animated {
            let duration = visible
                ? NotesDesignTokens.ReadingProgress.revealFadeDuration
                : NotesDesignTokens.ReadingProgress.hideFadeDuration
            UIView.animate(withDuration: duration) {
                self.thumbView.alpha = target
            }
        } else {
            thumbView.alpha = target
        }
    }
}

private extension UIView {
    func findScrollView() -> UIScrollView? {
        if let scrollView = self as? UIScrollView { return scrollView }
        var current: UIView? = self
        while let view = current {
            for subview in view.subviews {
                if let found = subview.findScrollViewDeep() { return found }
            }
            current = view.superview
        }
        return nil
    }

    func findScrollViewDeep() -> UIScrollView? {
        if let scrollView = self as? UIScrollView { return scrollView }
        for subview in subviews {
            if let found = subview.findScrollViewDeep() { return found }
        }
        return nil
    }
}
