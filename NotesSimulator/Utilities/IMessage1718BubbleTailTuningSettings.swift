import CoreGraphics

/// iOS 16–18 单发气泡尾巴参数（由 `IMessage1718BubbleTailPreset` 选定后注入）
struct IMessage1718BubbleTailParams: Equatable {
    var presetID: String = IMessage1718BubbleTailPreset.defaultPresetID
    var cornerRadius: CGFloat = IMessage1718DesignTokens.bubbleCornerRadius
    var tailRightEdgeInset: CGFloat = IMessage1718DesignTokens.bubbleTailRightEdgeInset
    var tailTipExtension: CGFloat = IMessage1718DesignTokens.bubbleTailTipExtension
    var tailTipDrop: CGFloat = IMessage1718DesignTokens.bubbleTailTipDrop
    var tailRootAlongBottom: CGFloat = IMessage1718DesignTokens.bubbleTailRootAlongBottom
    var tailUpperCP1X: CGFloat = IMessage1718DesignTokens.bubbleTailUpperCP1X
    var tailUpperCP1Y: CGFloat = IMessage1718DesignTokens.bubbleTailUpperCP1Y
    var tailUpperCP2X: CGFloat = IMessage1718DesignTokens.bubbleTailUpperCP2X
    var tailUpperCP2Y: CGFloat = IMessage1718DesignTokens.bubbleTailUpperCP2Y
    var tailLowerCP1X: CGFloat = IMessage1718DesignTokens.bubbleTailLowerCP1X
    var tailLowerCP1Y: CGFloat = IMessage1718DesignTokens.bubbleTailLowerCP1Y
    var tailLowerCP2X: CGFloat = IMessage1718DesignTokens.bubbleTailLowerCP2X
    var tailLowerCP2Y: CGFloat = IMessage1718DesignTokens.bubbleTailLowerCP2Y
    /// Tutorial：右缘竖线内收（0 = 贴右缘 x=w）
    var tutorialRightLineInsetX: CGFloat = 5
    /// Tutorial：入弧点相对 w 的内收（原 gist 的 w-5）
    var tutorialApproachInsetX: CGFloat = 5
    /// Tutorial：下弧回到底边的汇合点距右缘
    var tutorialJunctionInset: CGFloat = 12
    /// Tutorial：下弧外凸向下（控制点 y = h + bulge）
    var tutorialHookBulge: CGFloat = 1
    /// Tutorial：右缘上弧起点与下弧汇合点之间的竖向间距
    var tutorialArcAnchorGap: CGFloat = 18
    /// Tutorial：上弧 CP1 相对右缘起点的向下偏移（保持竖直再内凹）
    var tutorialUpperLeadY: CGFloat = 5
    /// Tutorial：上弧 CP2 相对角点向左（接圆角更顺）
    var tutorialCornerBlendX: CGFloat = 4
    /// Tutorial：上弧 CP2 相对角点向上
    var tutorialCornerBlendY: CGFloat = 6
    /// Tutorial：上弧控制点距底边（旧参数，保留兼容）
    var tutorialUpperArcCurvature: CGFloat = 1
    /// Tutorial：下弧控制点水平展开（越大弧度越弯）
    var tutorialLowerArcCurvature: CGFloat = 4
    /// Tutorial：下弧 CP2 相对 hook 点向左（拉开与上弧间距，避免填充成丝）
    var tutorialLowerLeftBulge: CGFloat = 4
    var threadBubbleTrailingInset: CGFloat = IMessage1718DesignTokens.threadBubbleTrailingInset
    var threadBubbleMaxWidthReduction: CGFloat = IMessage1718DesignTokens.threadBubbleMaxWidthReduction
    var tailClipReserveRight: CGFloat = IMessage1718DesignTokens.bubbleTailClipReserveRight
    var tailClipReserveBottom: CGFloat = IMessage1718DesignTokens.bubbleTailClipReserveBottom

    /// 贴图尾巴宽（pt，@3x 27px → 9pt）
    var referenceTailWidth: CGFloat = 9
    /// 贴图尾巴高（pt，@3x 13px → 4pt）
    var referenceTailHeight: CGFloat = 4
    /// 贴图 frame.origin 相对本体右下角 (bodyW, bodyH)
    var referenceTailOffsetX: CGFloat = -9.333
    var referenceTailOffsetY: CGFloat = -4

    /// IMS Shape：尾巴根部左右各伸出（pt）
    var imsTailRootHalfWidth: CGFloat = 6
    var imsTailUpperCtrlX: CGFloat = 0
    var imsTailUpperCtrlY: CGFloat = 1
    var imsTailLowerCtrlX: CGFloat = 4
    var imsTailLowerCtrlY: CGFloat = 3

    /// 撰写页描点 A–D（有 4 点时优先于 Tutorial 公式尾巴）
    var plottedAnchorTail: BubbleTail1718AnchorModel?
    /// 描点存储时参考的本体尺寸（用于映射到任意文本泡宽/高）
    var tailAnchorReferenceSize: CGSize = BubbleTail1718AnchorModel.defaultReferenceBodySize
    /// 描点填充：composite 本体+楔形；bodyOnly 仅本体（空尾巴，自行填色）
    var plottedTailFillMode: IOSOutgoingBubblePath1718.PlottedTailFillMode = .composite

    func resolvedPlottedAnchorTail(bodyWidth: CGFloat, bodyHeight: CGFloat) -> BubbleTail1718AnchorModel? {
        guard let model = plottedAnchorTail else { return nil }
        return model.resolved(
            forBodyWidth: bodyWidth,
            bodyHeight: bodyHeight,
            referenceSize: tailAnchorReferenceSize
        )
    }

    var usesPlottedAnchorTail: Bool {
        guard let model = plottedAnchorTail, model.points.count >= 4 else { return false }
        return model.segmentKinds.count >= 3
    }

    var referenceTailImageName: String {
        IMessage1718BubbleTailPreset.preset(id: presetID).referenceImageName ?? "BubbleRefTailCrop1718"
    }

    var pathKind: BubbleTail1718PathKind {
        IMessage1718BubbleTailPreset.preset(id: presetID).pathKind
    }

    var tailHorizontalOverflow: CGFloat {
        switch pathKind {
        case .ios26ChatKit:
            return tailClipReserveRight
        case .referenceImageTail:
            return tailTipExtension + tailClipReserveRight
        case .tracedScreenshot, .imsSendBubble, .messageKitTutorial:
            if usesPlottedAnchorTail, let model = plottedAnchorTail {
                let ref = tailAnchorReferenceSize
                let resolved = model.resolved(
                    forBodyWidth: ref.width,
                    bodyHeight: ref.height,
                    referenceSize: ref
                )
                let overflow = IOSOutgoingBubblePath1718.plottedAnchorPathOverflow(
                    bodyWidth: ref.width,
                    bodyHeight: ref.height,
                    params: self,
                    model: resolved
                )
                return overflow.width + tailClipReserveRight
            }
            return max(tailTipExtension, 1) + tailClipReserveRight
        default:
            return tailTipExtension + tailClipReserveRight
        }
    }

    var tailVerticalOverflow: CGFloat {
        switch pathKind {
        case .ios26ChatKit:
            return IMessage1718DesignTokens.bubbleTailDropIOS26 + tailClipReserveBottom
        case .referenceImageTail:
            return tailTipDrop + tailClipReserveBottom
        case .tracedScreenshot, .imsSendBubble, .messageKitTutorial:
            if usesPlottedAnchorTail, let model = plottedAnchorTail {
                let ref = tailAnchorReferenceSize
                let resolved = model.resolved(
                    forBodyWidth: ref.width,
                    bodyHeight: ref.height,
                    referenceSize: ref
                )
                let overflow = IOSOutgoingBubblePath1718.plottedAnchorPathOverflow(
                    bodyWidth: ref.width,
                    bodyHeight: ref.height,
                    params: self,
                    model: resolved
                )
                return overflow.height + tailClipReserveBottom
            }
            return max(
                tailTipDrop,
                tutorialHookBulge,
                plottedAnchorTailVerticalBulge(bodyHeight: tailAnchorReferenceSize.height)
            ) + tailClipReserveBottom
        default:
            return max(tailTipDrop, tutorialHookBulge) + tailClipReserveBottom
        }
    }

    private func plottedAnchorTailVerticalBulge(bodyHeight: CGFloat) -> CGFloat {
        guard usesPlottedAnchorTail,
              let model = resolvedPlottedAnchorTail(bodyWidth: 120, bodyHeight: bodyHeight) else { return 0 }
        return max(0, (model.points.map(\.y).max() ?? 0) - bodyHeight)
    }

    static var `default`: IMessage1718BubbleTailParams {
        IMessage1718BubbleTailPreset.resolvedParams(presetID: IMessage1718BubbleTailPreset.defaultPresetID)
    }
}
