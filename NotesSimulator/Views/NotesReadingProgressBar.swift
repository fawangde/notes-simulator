import SwiftUI
import UIKit

enum NotesReadingProgressTrackBounds {
    /// iOS 26：轨道顶 = 顶栏按键底缘，轨道底 = 底栏按键顶缘（indicator 宿主坐标）
    static func ios26Host(hostHeight: CGFloat, safeAreaInsets: UIEdgeInsets) -> (top: CGFloat, bottom: CGFloat, height: CGFloat) {
        let navBar = NotesDesignTokens.Layout.navBarHeight
        let navButton = NotesDesignTokens.Official.Nav.buttonSize
        let toolBar = NotesDesignTokens.Layout.bottomToolbarHeight
        let toolButton = NotesDesignTokens.Official.Toolbar.buttonSize
        let toolGap = NotesDesignTokens.Official.Toolbar.bottomSafeGap

        let top = safeAreaInsets.top + (navBar + navButton) / 2
        let toolbarTop = hostHeight - safeAreaInsets.bottom - toolGap - toolBar
        let bottom = toolbarTop + (toolBar - toolButton) / 2
        let height = max(bottom - top, 0)
        return (top, bottom, height)
    }

    /// iOS 26 ScrollView 局部坐标（legacy，保留供对照）
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

enum NotesReadingProgressTrackStyle: Equatable {
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
                    .allowsHitTesting(false)
            }
    }
}

extension View {
    /// iOS 26：挂在 notesContent 最外层（safeAreaInset / 底栏之后），避免二次进入时找不到 ScrollView。
    func notesReadingProgressIndicator(trackStyle: NotesReadingProgressTrackStyle) -> some View {
        overlay(alignment: .trailing) {
            NotesReadingProgressUIKitIndicator(trackStyle: trackStyle)
                .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    func notesReadingProgressIndicatorIfNeeded(
        _ enabled: Bool,
        trackStyle: NotesReadingProgressTrackStyle
    ) -> some View {
        if enabled {
            notesReadingProgressIndicator(trackStyle: trackStyle)
        } else {
            self
        }
    }

    @ViewBuilder
    func trackNotesReadingScrollContent() -> some View {
        self
    }
}

// MARK: - UIKit indicator

private struct NotesReadingProgressUIKitIndicator: UIViewRepresentable {
    let trackStyle: NotesReadingProgressTrackStyle

    private static var keyWindow: UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(trackStyle: trackStyle)
    }

    func makeUIView(context: Context) -> NotesReadingProgressIndicatorView {
        let view = NotesReadingProgressIndicatorView()
        view.coordinator = context.coordinator
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
        private var attachGeneration = 0

        init(trackStyle: NotesReadingProgressTrackStyle) {
            self.trackStyle = trackStyle
        }

        func scheduleAttach(from view: UIView, attemptsRemaining: Int = 24) {
            attachGeneration += 1
            let generation = attachGeneration
            DispatchQueue.main.async { [weak self, weak view] in
                guard let self, let view, generation == self.attachGeneration else { return }
                guard view.window != nil else {
                    self.retryAttach(from: view, generation: generation, attemptsRemaining: attemptsRemaining)
                    return
                }
                if let scrollView = view.findAssociatedScrollView() {
                    self.attach(to: scrollView)
                    return
                }
                self.retryAttach(from: view, generation: generation, attemptsRemaining: attemptsRemaining)
            }
        }

        private func retryAttach(from view: UIView, generation: Int, attemptsRemaining: Int) {
            guard attemptsRemaining > 0 else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self, weak view] in
                guard let self, let view, generation == self.attachGeneration else { return }
                guard view.window != nil else {
                    self.retryAttach(from: view, generation: generation, attemptsRemaining: attemptsRemaining - 1)
                    return
                }
                if let scrollView = view.findAssociatedScrollView() {
                    self.attach(to: scrollView)
                    return
                }
                self.retryAttach(from: view, generation: generation, attemptsRemaining: attemptsRemaining - 1)
            }
        }

        func attach(to scrollView: UIScrollView) {
            guard scrollView.window != nil else {
                if let indicatorView {
                    scheduleAttach(from: indicatorView)
                }
                return
            }
            if let indicatorView, let indicatorWindow = indicatorView.window, scrollView.window !== indicatorWindow {
                return
            }

            if scrollView === self.scrollView {
                refresh()
                return
            }

            detachObservations()
            self.scrollView = scrollView
            refresh()
            observations = [
                scrollView.observe(\.contentOffset, options: [.new]) { [weak self] observed, _ in
                    guard let self, observed === self.scrollView else { return }
                    self.scrollDidChange()
                },
                scrollView.observe(\.contentSize, options: [.new]) { [weak self] observed, _ in
                    guard let self, observed === self.scrollView else { return }
                    self.refresh()
                },
                scrollView.observe(\.bounds, options: [.new]) { [weak self] observed, _ in
                    guard let self, observed === self.scrollView else { return }
                    self.refresh()
                },
            ]
        }

        func handleIndicatorLeftWindow() {
            detachObservations()
        }

        func detach() {
            attachGeneration += 1
            detachObservations()
            hideWorkItem?.cancel()
            hideWorkItem = nil
            indicatorView?.setVisible(false, animated: false)
        }

        private func detachObservations() {
            observations.removeAll()
            scrollView = nil
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
            guard let scrollView, scrollView.window != nil, let indicatorView else {
                if let indicatorView, indicatorView.window != nil {
                    scheduleAttach(from: indicatorView)
                }
                return
            }

            let viewportHeight = scrollView.bounds.height
            let contentHeight = scrollView.contentSize.height
            guard viewportHeight > 0, contentHeight > viewportHeight + 1 else {
                indicatorView.setVisible(false, animated: false)
                return
            }

            let viewSafe = indicatorView.superview?.safeAreaInsets ?? indicatorView.safeAreaInsets
            let windowSafe = NotesReadingProgressUIKitIndicator.keyWindow?.safeAreaInsets ?? .zero
            let safeArea = UIEdgeInsets(
                top: max(viewSafe.top, windowSafe.top),
                left: 0,
                bottom: max(viewSafe.bottom, windowSafe.bottom),
                right: 0
            )
            let bounds: (top: CGFloat, bottom: CGFloat, height: CGFloat) = {
                switch trackStyle {
                case .ios26:
                    return NotesReadingProgressTrackBounds.ios26Host(
                        hostHeight: indicatorView.bounds.height,
                        safeAreaInsets: safeArea
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
    weak var coordinator: NotesReadingProgressUIKitIndicator.Coordinator?

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

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            coordinator?.scheduleAttach(from: self)
        } else {
            coordinator?.handleIndicatorLeftWindow()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        coordinator?.refresh()
    }

    func updateThumb(y: CGFloat, height: CGFloat, width: CGFloat, trailingInset: CGFloat) {
        let x = max(bounds.width - trailingInset - width, 0)
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
    /// 优先取包裹自身的 ScrollView；否则在同级/子树里找最近的 ScrollView（iOS 26 外层 overlay 需要）。
    func findAssociatedScrollView() -> UIScrollView? {
        if let enclosing = findEnclosingScrollView() {
            return enclosing
        }
        var current: UIView? = superview
        while let container = current {
            if let match = container.findFirstScrollViewInSubtree() {
                return match
            }
            current = container.superview
        }
        return nil
    }

    func findEnclosingScrollView() -> UIScrollView? {
        var current: UIView? = self
        while let view = current {
            if let scrollView = view as? UIScrollView {
                return scrollView
            }
            current = view.superview
        }
        return nil
    }

    func findFirstScrollViewInSubtree() -> UIScrollView? {
        if let scrollView = self as? UIScrollView {
            return scrollView
        }
        for subview in subviews {
            if let found = subview.findFirstScrollViewInSubtree() {
                return found
            }
        }
        return nil
    }
}
