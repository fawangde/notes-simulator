import CoreGraphics
import UIKit

/// iPhone X iOS 16.7.2 备忘录长按号码菜单（官方静态布局 pt）
enum PhoneMenu1718Layout {
    enum Design {
        static let horizontalMargin: CGFloat = 15
        static let previewWidthReference: CGFloat = 300
        static let previewHeightReference: CGFloat = 56
        static let previewCornerRadius: CGFloat = 10
        static let previewPadH: CGFloat = 16
        static let defaultAvatarSize: CGFloat = 55
        static let avatarSpacing: CGFloat = 12
        static let previewFontSize: CGFloat = 17

        static func previewSize(for screenWidth: CGFloat, sideMarginExtra: CGFloat = 0) -> CGSize {
            let margin = horizontalMargin + sideMarginExtra
            let width = screenWidth - margin * 2
            let height = width * (previewHeightReference / previewWidthReference)
            return CGSize(width: width, height: height)
        }

        static let menuWidth: CGFloat = 270
        static let menuRowHeight: CGFloat = 44
        /// 顶部号码行（略矮于操作项）
        static let menuHeaderHeight: CGFloat = 30
        static let menuActionRowCount: Int = 5
        static var menuDividerCount: Int { menuActionRowCount + 1 }
        static var menuHeight: CGFloat {
            menuHeaderHeight
                + CGFloat(menuActionRowCount) * menuRowHeight
                + CGFloat(menuDividerCount) * menuDividerHeight
        }
        static let menuDividerHeight: CGFloat = 1 / UIScreen.main.scale + 0.5
        static let menuRowHighlightCornerRadius: CGFloat = 8
        static let menuCornerRadius: CGFloat = 14
        static let menuBottomMargin: CGFloat = 40
        static let menuContentInsetH: CGFloat = 16
        static let menuTitleSize: CGFloat = 17
        static let menuIconSize: CGFloat = 18
        static let menuSubtitleSize: CGFloat = 13

        /// 号码底缘 → 预览泡顶缘（社区实测）
        static let numberToPreviewGap: CGFloat = 8
        /// 预览泡底缘 → 菜单顶缘
        static let previewToMenuGap: CGFloat = 15
        static let tapMenuGap: CGFloat = 5

        static let previewShadowOpacity: Double = 0.1
        static let previewShadowRadius: CGFloat = 5
        static let previewShadowY: CGFloat = 2
        static let menuShadowOpacity: Double = 0.1
        static let menuShadowRadius: CGFloat = 10
        static let menuShadowY: CGFloat = 4
    }

    /// 官方动画时间线（iOS 16.7.2）
    enum Animation {
        static let longPressDuration: TimeInterval = 0.5

        static let phoneMorphDuration: TimeInterval = 0.18
        static let phoneMorphResponse: TimeInterval = 0.26
        static let phoneMorphDamping: CGFloat = 0.68
        static let phoneMorphScale: CGFloat = 1.08
        static let phoneMorphLift: CGFloat = 12
        static let phoneCornerIdle: CGFloat = 4
        static let phoneCornerPressed: CGFloat = 12
        static let phoneTextPad: CGFloat = 8
        /// 小白底左右各缩 1pt（水平 padding 8→7）
        static let morphSettleBackHorizontal: CGFloat = 1

        /// 预览泡展开/收起整体节奏（1.0 = 基准；较 1.25 再慢 25%）
        static let previewTimelineSpeed: CGFloat = 1.0

        /// 小白底 100% = 号码随壳放大到正文的 1.2 倍
        static let morphPillTextScaleAt100: CGFloat = 1.2
        /// 号码缩至此倍数及以下时，小白底立即消失、压暗/模糊同步恢复
        static let morphPillVanishScaleThreshold: CGFloat = 1.01
        static var morphUnitScaleDuration: TimeInterval { 0.05 / Double(previewTimelineSpeed) }
        /// 入场：预览 spring 在小白底放大完成前启动，避免两段落缝
        static var morphToPreviewSpringOverlap: TimeInterval { morphUnitScaleDuration * 0.42 }

        /// 80% 预览泡大小时开始渐显头像/预览号码，100% 时完全就位
        static let morphToPreviewScaleThreshold: CGFloat = 0.8
        /// 退场：壳缩到小白底 150% 时黄字淡入，100% 时变实
        static let dismissYellowStartPillMultiplier: CGFloat = 1.5

        static var overlayDismissDelay: TimeInterval { 0.22 / Double(previewTimelineSpeed) }
        static var previewEnterDuration: TimeInterval { 0.28 / Double(previewTimelineSpeed) }
        static var previewEnterResponse: TimeInterval { 0.34 / Double(previewTimelineSpeed) }
        static let previewEnterDamping: CGFloat = 0.64
        static var previewExitResponse: TimeInterval { 0.32 / Double(previewTimelineSpeed) }
        /// 高阻尼：一次 spring 缩回正文，不在 pill100 处停顿
        static let previewExitDamping: CGFloat = 0.88
        static var shellBgFadeDuration: TimeInterval { 0.22 / Double(previewTimelineSpeed) }
        static var overlayEnterDuration: TimeInterval { 0.12 / Double(previewTimelineSpeed) }
        /// 预览泡内头像与号码间距
        static let previewAvatarPhoneSpacing: CGFloat = 10
        static let previewEnterScaleFrom: CGFloat = 0.72

        static var menuRowEnterDelayStep: TimeInterval { 0.018 / Double(previewTimelineSpeed) }
        static let menuRowEnterOffsetY: CGFloat = 8

        static var menuRowExitDuration: TimeInterval { 0.2 / Double(previewTimelineSpeed) }
        static var menuRowExitDelayStep: TimeInterval { 0.02 / Double(previewTimelineSpeed) }
        static let menuRowExitOffsetY: CGFloat = 8

        static let previewExitDuration: TimeInterval = 0.2
        static let previewExitDelayAfterMenuStart: TimeInterval = 0.16
        static let previewExitScaleTo: CGFloat = 0.85

        static let phoneRestoreDuration: TimeInterval = 0.2
        static let phoneRestoreResponse: TimeInterval = 0.3
        static let phoneRestoreDamping: CGFloat = 0.7
    }

    struct Metrics {
        let leftMargin: CGFloat
        let previewSize: CGSize
        let menuSize: CGSize
        let previewMenuGap: CGFloat
        let numberToPreviewGap: CGFloat
        let tapMenuGap: CGFloat
        let menuRowHighlightCornerRadius: CGFloat
        let minContentTop: CGFloat
        let maxContentBottom: CGFloat
        let previewCornerRadius: CGFloat
        let menuCornerRadius: CGFloat
        let avatarSize: CGFloat
        let avatarSpacing: CGFloat
        let previewPadH: CGFloat
        let previewContentShiftLeft: CGFloat
        let previewContentScale: CGFloat
        let previewSideMarginExtra: CGFloat
        let previewFontSize: CGFloat
        let menuContentInsetH: CGFloat
        let menuIconSize: CGFloat
        let menuTitleSize: CGFloat
        let menuSubtitleSize: CGFloat
        let menuHeaderPhoneFontSize: CGFloat
        let rowHeight: CGFloat
        let headerHeight: CGFloat
        let dividerHeight: CGFloat
        let previewShadowOpacity: Double
        let previewShadowRadius: CGFloat
        let previewShadowY: CGFloat
        let menuShadowOpacity: Double
        let menuShadowRadius: CGFloat
        let menuShadowY: CGFloat
    }

    struct Placement {
        let previewFrame: CGRect
        let menuFrame: CGRect
        let menuGrowUp: Bool
        let phoneLeadingSpacer: CGFloat
    }

    static func metrics(
        in screen: CGSize,
        safeTop: CGFloat,
        safeBottom: CGFloat,
        tuning: Notes1718TuningSettings = .default
    ) -> Metrics {
        let divider = Design.menuDividerHeight
        let navH = NotesDesignTokens.Layout.navBarHeight
        let barH = NotesDesignTokens.Layout.bottomToolbarHeight + NotesStyle1718Tokens.toolbarExtraDownShift
        let menuWidth = max(
            Design.menuWidth - 30,
            Design.menuWidth - CGFloat(tuning.menuWidthReduction)
        )

        return Metrics(
            leftMargin: Design.horizontalMargin,
            previewSize: Design.previewSize(
                for: screen.width,
                sideMarginExtra: CGFloat(tuning.previewSideMarginExtra)
            ),
            menuSize: CGSize(width: menuWidth, height: Design.menuHeight),
            previewMenuGap: Design.previewToMenuGap,
            numberToPreviewGap: Design.numberToPreviewGap,
            tapMenuGap: Design.tapMenuGap,
            menuRowHighlightCornerRadius: Design.menuRowHighlightCornerRadius,
            minContentTop: safeTop + navH * 0.5,
            maxContentBottom: screen.height - safeBottom - barH * 0.5 - Design.menuBottomMargin,
            previewCornerRadius: Design.previewCornerRadius,
            menuCornerRadius: Design.menuCornerRadius,
            avatarSize: CGFloat(tuning.avatarSize),
            avatarSpacing: Design.avatarSpacing,
            previewPadH: Design.previewPadH,
            previewContentShiftLeft: CGFloat(tuning.previewContentShiftLeft),
            previewContentScale: CGFloat(tuning.previewContentScale),
            previewSideMarginExtra: CGFloat(tuning.previewSideMarginExtra),
            previewFontSize: CGFloat(tuning.previewPhoneFontSize),
            menuContentInsetH: Design.menuContentInsetH,
            menuIconSize: CGFloat(tuning.menuIconSize),
            menuTitleSize: Design.menuTitleSize,
            menuSubtitleSize: Design.menuSubtitleSize,
            menuHeaderPhoneFontSize: CGFloat(tuning.menuHeaderPhoneFontSize),
            rowHeight: Design.menuRowHeight,
            headerHeight: Design.menuHeaderHeight,
            dividerHeight: divider,
            previewShadowOpacity: Design.previewShadowOpacity,
            previewShadowRadius: Design.previewShadowRadius,
            previewShadowY: Design.previewShadowY,
            menuShadowOpacity: Design.menuShadowOpacity,
            menuShadowRadius: Design.menuShadowRadius,
            menuShadowY: Design.menuShadowY
        )
    }

    static func anchorInOverlay(_ windowAnchor: CGRect, overlayGlobalFrame: CGRect) -> CGRect {
        guard windowAnchor != .zero, overlayGlobalFrame != .zero else { return .zero }
        return CGRect(
            x: windowAnchor.minX - overlayGlobalFrame.minX,
            y: windowAnchor.minY - overlayGlobalFrame.minY,
            width: windowAnchor.width,
            height: windowAnchor.height
        )
    }

    static func placement(
        anchor: CGRect,
        metrics: Metrics,
        preferMenuBelow: Bool = true
    ) -> Placement {
        let previewW = metrics.previewSize.width
        let previewH = metrics.previewSize.height
        let menuW = metrics.menuSize.width
        let menuH = metrics.menuSize.height
        let gap = metrics.previewMenuGap
        let previewLeft = metrics.leftMargin + metrics.previewSideMarginExtra
        let menuLeft = previewLeft

        // 预览泡垂直以号码中线为锚，长按时从号码位置向上下展开，避免下跳
        let baseBubbleTop = anchor.midY - previewH / 2
        var menuGrowUp = false

        func packBelow(from bubbleTop: CGFloat) -> (CGFloat, CGFloat) {
            var top = bubbleTop
            var menuTop = top + previewH + gap
            let menuBottom = menuTop + menuH
            if menuBottom > metrics.maxContentBottom {
                let shift = menuBottom - metrics.maxContentBottom
                top -= shift
                menuTop -= shift
            }
            if top < metrics.minContentTop {
                top = metrics.minContentTop
                menuTop = top + previewH + gap
            }
            return (top, menuTop)
        }

        func packAbove(from bubbleTop: CGFloat) -> (CGFloat, CGFloat) {
            var menuTop = bubbleTop - gap - menuH
            var top = menuTop + menuH + gap - previewH
            if menuTop < metrics.minContentTop {
                menuTop = metrics.minContentTop
                top = menuTop + menuH + gap - previewH
            }
            return (top, menuTop)
        }

        var bubbleTopResolved: CGFloat
        var menuTop: CGFloat

        if preferMenuBelow {
            (bubbleTopResolved, menuTop) = packBelow(from: baseBubbleTop)
            if menuTop + menuH > metrics.maxContentBottom {
                menuGrowUp = true
                (bubbleTopResolved, menuTop) = packAbove(from: baseBubbleTop)
            }
        } else {
            menuGrowUp = true
            (bubbleTopResolved, menuTop) = packAbove(from: baseBubbleTop)
        }

        if bubbleTopResolved < metrics.minContentTop {
            bubbleTopResolved = metrics.minContentTop
        }

        let textStart = previewLeft + metrics.previewPadH - metrics.previewContentShiftLeft
            + metrics.avatarSize + metrics.avatarSpacing
        let phoneLeadingSpacer = max(0, anchor.minX - textStart)

        return Placement(
            previewFrame: CGRect(x: previewLeft, y: bubbleTopResolved, width: previewW, height: previewH),
            menuFrame: CGRect(x: menuLeft, y: menuTop, width: menuW, height: menuH),
            menuGrowUp: menuGrowUp,
            phoneLeadingSpacer: phoneLeadingSpacer
        )
    }

    static func tapPlacement(anchor: CGRect, metrics: Metrics) -> Placement {
        let menuW = metrics.menuSize.width
        let menuH = metrics.menuSize.height
        let left = metrics.leftMargin
        var menuTop = anchor.maxY + metrics.tapMenuGap
        var menuGrowUp = false

        if menuTop + menuH > metrics.maxContentBottom {
            menuTop = anchor.minY - metrics.tapMenuGap - menuH
            menuGrowUp = true
        }
        if menuTop < metrics.minContentTop {
            menuTop = metrics.minContentTop
        }

        return Placement(
            previewFrame: .zero,
            menuFrame: CGRect(x: left, y: menuTop, width: menuW, height: menuH),
            menuGrowUp: menuGrowUp,
            phoneLeadingSpacer: 0
        )
    }
}
