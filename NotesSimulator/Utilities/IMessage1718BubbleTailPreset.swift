import CoreGraphics

/// iOS 16–18 气泡尾巴：可选样式目录（对照参考图 / 社区 / 探针，供挑选后再定稿）
enum BubbleTail1718PathKind: String, Codable, CaseIterable {
    case classicHookCubic
    case classicHookQuad
    case ios26ChatKit
    case messageKitTutorial
    case messageKitPointed
    /// 真机透明 PNG 贴图尾巴（不用手调矢量）
    case referenceImageTail
    /// 社区 IMS 双 quad 尾巴（SwiftUI Shape 移植）
    case imsSendBubble
    /// 真机截图描边（`bubble_complete_transparent.png`）
    case tracedScreenshot
}

struct IMessage1718BubbleTailPreset: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    let era: String
    let sourceNote: String
    let referenceImageName: String?
    let pathKind: BubbleTail1718PathKind
    let params: IMessage1718BubbleTailParams

    /// 默认：真机对照 Tutorial 参数（见 `messageKitTutorial`）
    static let defaultPresetID = "ref_traced_screenshot"

    static let all: [IMessage1718BubbleTailPreset] = [
        IMessage1718BubbleTailPreset(
            id: "ref_traced_screenshot",
            title: "真机 · 标准 hook",
            subtitle: "默认 · Hello 同款",
            era: "iOS 16–18",
            sourceNote: "MessageKit 三 cubic · 尖下垂 + 内凹过渡",
            referenceImageName: "BubbleRefComplete1718",
            pathKind: .tracedScreenshot,
            params: .messageKitTutorial
        ),
        IMessage1718BubbleTailPreset(
            id: "src_messagekit_tutorial",
            title: "社区 · Nav Singh 教程",
            subtitle: "旧方案，非默认",
            era: "社区 2018",
            sourceNote: "gist · 参数与截图描边不一致",
            referenceImageName: nil,
            pathKind: .messageKitTutorial,
            params: .messageKitTutorial
        ),
        IMessage1718BubbleTailPreset(
            id: "ims_send_bubble",
            title: "IMS · 双 quad（简化）",
            subtitle: "仅小凸起，不推荐",
            era: "iOS 16–18",
            sourceNote: "IMSSendBubbleShape · 缺右缘+回钩，已映射真机 Path",
            referenceImageName: nil,
            pathKind: .imsSendBubble,
            params: .messageKitTutorial
        ),
        IMessage1718BubbleTailPreset(
            id: "ref_user_tail_image",
            title: "真机 · 尾巴贴图",
            subtitle: "透明 PNG 直接贴，不用手调",
            era: "iOS 16–18",
            sourceNote: "BubbleRefTailCrop1718 · 真机截图",
            referenceImageName: "BubbleRefTailCrop1718",
            pathKind: .referenceImageTail,
            params: .referenceImageTail
        ),
        IMessage1718BubbleTailPreset(
            id: "ref_user_complete",
            title: "参考 A · 整泡抠图",
            subtitle: "你提供的透明气泡",
            era: "iOS 16–18",
            sourceNote: "tools/extracted/bubble_complete_transparent.png",
            referenceImageName: "BubbleRefComplete1718",
            pathKind: .classicHookCubic,
            params: .referenceSilhouette
        ),
        IMessage1718BubbleTailPreset(
            id: "ref_user_tail_crop",
            title: "参考 B · 尾巴特写",
            subtitle: "透明抠图右下角",
            era: "iOS 16–18",
            sourceNote: "tools/extracted/bubble_tail_only.png",
            referenceImageName: "BubbleRefTailCrop1718",
            pathKind: .classicHookCubic,
            params: .referenceSilhouetteTight
        ),
        IMessage1718BubbleTailPreset(
            id: "asset_tail_slice",
            title: "参考 C · 项目切片",
            subtitle: "BubbleTail1718@3x",
            era: "iOS 16–18",
            sourceNote: "Assets/BubbleTail1718.imageset",
            referenceImageName: "BubbleTail1718",
            pathKind: .classicHookCubic,
            params: .assetTailSlice
        ),
        IMessage1718BubbleTailPreset(
            id: "impl_hook_cubic",
            title: "实现 1 · 双 cubic hook",
            subtitle: "右缘直线 + 上凹下凸",
            era: "iOS 16–18",
            sourceNote: "当前 1718 矢量方案",
            referenceImageName: nil,
            pathKind: .classicHookCubic,
            params: .classicHookCubic
        ),
        IMessage1718BubbleTailPreset(
            id: "impl_hook_quad",
            title: "实现 2 · 双 quad hook",
            subtitle: "简化版 hook",
            era: "iOS 16–18",
            sourceNote: "双二次贝塞尔",
            referenceImageName: nil,
            pathKind: .classicHookQuad,
            params: .classicHookQuad
        ),
        IMessage1718BubbleTailPreset(
            id: "src_ios26_chatkit",
            title: "对照 · iOS 26 ChatKit",
            subtitle: "Frida CKColoredBalloonView 探针",
            era: "iOS 26",
            sourceNote: "IOSOutgoingBubblePath.sentLastBubblePath",
            referenceImageName: nil,
            pathKind: .ios26ChatKit,
            params: .ios26ChatKit
        ),
        IMessage1718BubbleTailPreset(
            id: "src_messagekit_pointed",
            title: "社区 · 简线尖尾",
            subtitle: "MessageKit pointed / Medium",
            era: "社区 2018",
            sourceNote: "MessageKit _tail_v1 · Kyle Haptonstall",
            referenceImageName: nil,
            pathKind: .messageKitPointed,
            params: .messageKitPointed
        ),
        IMessage1718BubbleTailPreset(
            id: "src_messagekit_curved",
            title: "社区 · MessageKit curved",
            subtitle: "开源库 _tail_v2 近似",
            era: "社区 OSS",
            sourceNote: "MessageKit bubbleTail curved",
            referenceImageName: nil,
            pathKind: .classicHookQuad,
            params: .messageKitCurved
        ),
    ]

    static var `default`: IMessage1718BubbleTailPreset {
        preset(id: defaultPresetID)
    }

    static func preset(id: String) -> IMessage1718BubbleTailPreset {
        all.first { $0.id == id }
            ?? all.first { $0.id == defaultPresetID }
            ?? all[0]
    }

    static func resolvedParams(
        presetID: String,
        tuning: Notes1718TuningSettings? = nil
    ) -> IMessage1718BubbleTailParams {
        let effectivePresetID = IMessage1718BubbleTailPreset.defaultPresetID
        var params = preset(id: effectivePresetID).params
        params.presetID = effectivePresetID
        applyProductionChatTail(to: &params)
        if let tuning, tuning.bubbleTailManualTuningEnabled {
            let kind = preset(id: effectivePresetID).pathKind
            guard kind == .messageKitTutorial || kind == .tracedScreenshot else { return params }
            params.tailRootAlongBottom = CGFloat(tuning.tutorialTailRootAlongBottom)
            params.tailTipExtension = CGFloat(tuning.tutorialTailExtension)
            params.tailTipDrop = CGFloat(tuning.tutorialTailDrop)
            params.tutorialHookBulge = CGFloat(tuning.tutorialHookBulge)
            params.tutorialUpperLeadY = CGFloat(tuning.tutorialUpperLeadY)
            params.tutorialLowerArcCurvature = CGFloat(tuning.tutorialLowerArcCurvature)
            params.tutorialLowerLeftBulge = CGFloat(tuning.tutorialLowerLeftBulge)
        }
        return params
    }

    /// 聊天区：描点 / 右缘 inset / 填充模式写死，不读存档
    private static func applyProductionChatTail(to params: inout IMessage1718BubbleTailParams) {
        guard preset(id: params.presetID).pathKind == .tracedScreenshot else { return }
        params.plottedAnchorTail = BubbleTail1718AnchorModel.productionChatTail
        params.tailAnchorReferenceSize = BubbleTail1718AnchorModel.defaultReferenceBodySize
        params.plottedTailFillMode = .composite
        params.threadBubbleTrailingInset = IMessage1718DesignTokens.threadBubbleTrailingInset
    }
}

extension IMessage1718BubbleTailParams {
    static let classicHookCubic = IMessage1718BubbleTailParams(
        tailRightEdgeInset: 15,
        tailTipExtension: 6,
        tailTipDrop: 3,
        tailRootAlongBottom: 17,
        tailUpperCP1X: -3,
        tailUpperCP1Y: 4,
        tailUpperCP2X: 4,
        tailUpperCP2Y: 10,
        tailLowerCP1X: 4,
        tailLowerCP1Y: 5,
        tailLowerCP2X: -14,
        tailLowerCP2Y: -1
    )

    static let classicHookQuad = IMessage1718BubbleTailParams(
        tailRightEdgeInset: 15,
        tailTipExtension: 6,
        tailTipDrop: 3,
        tailRootAlongBottom: 18,
        tailUpperCP1X: -5,
        tailUpperCP1Y: 8,
        tailUpperCP2X: -5,
        tailUpperCP2Y: 8,
        tailLowerCP1X: -10,
        tailLowerCP1Y: 4,
        tailLowerCP2X: -10,
        tailLowerCP2Y: 4
    )

    static let tracedScreenshot = IMessage1718BubbleTailParams(
        tailRightEdgeInset: 18,
        tailTipExtension: 4.333333333,
        tailTipDrop: 0.666666667,
        tailRootAlongBottom: 15.666666667,
        tailClipReserveRight: 14,
        tailClipReserveBottom: 8
    )

    static let imsSendBubble = IMessage1718BubbleTailParams(
        tailTipExtension: 8,
        tailTipDrop: 2,
        tailClipReserveRight: 6,
        tailClipReserveBottom: 2,
        imsTailRootHalfWidth: 6,
        imsTailUpperCtrlX: 0,
        imsTailUpperCtrlY: 1,
        imsTailLowerCtrlX: 4,
        imsTailLowerCtrlY: 3
    )

    static let referenceImageTail = IMessage1718BubbleTailParams(
        tailTipExtension: 4.5,
        tailTipDrop: 3,
        tailClipReserveRight: 4,
        tailClipReserveBottom: 2,
        referenceTailWidth: 9,
        referenceTailHeight: 4.333,
        referenceTailOffsetX: 0,
        referenceTailOffsetY: 0
    )

    static let referenceSilhouette = IMessage1718BubbleTailParams(
        tailRightEdgeInset: 14,
        tailTipExtension: 7,
        tailTipDrop: 3.5,
        tailRootAlongBottom: 16,
        tailUpperCP1X: -4,
        tailUpperCP1Y: 5,
        tailUpperCP2X: 3,
        tailUpperCP2Y: 9,
        tailLowerCP1X: 3,
        tailLowerCP1Y: 6,
        tailLowerCP2X: -12,
        tailLowerCP2Y: -2
    )

    static let referenceSilhouetteTight = IMessage1718BubbleTailParams(
        tailRightEdgeInset: 12,
        tailTipExtension: 7,
        tailTipDrop: 3.3,
        tailRootAlongBottom: 14,
        tailUpperCP1X: -3,
        tailUpperCP1Y: 4,
        tailUpperCP2X: 5,
        tailUpperCP2Y: 8,
        tailLowerCP1X: 5,
        tailLowerCP1Y: 4,
        tailLowerCP2X: -11,
        tailLowerCP2Y: -2
    )

    static let assetTailSlice = IMessage1718BubbleTailParams(
        tailRightEdgeInset: 13,
        tailTipExtension: 6.5,
        tailTipDrop: 3.3,
        tailRootAlongBottom: 15,
        tailUpperCP1X: -4,
        tailUpperCP1Y: 6,
        tailUpperCP2X: 3,
        tailUpperCP2Y: 9,
        tailLowerCP1X: 4,
        tailLowerCP1Y: 5,
        tailLowerCP2X: -13,
        tailLowerCP2Y: -1
    )

    static let ios26ChatKit = IMessage1718BubbleTailParams(
        tailRightEdgeInset: 0,
        tailTipExtension: 0,
        tailTipDrop: 6.11,
        tailRootAlongBottom: 0,
        tailClipReserveRight: 0,
        tailClipReserveBottom: 4
    )

    static let messageKitTutorial = IMessage1718BubbleTailParams(
        tailTipExtension: 8,
        tailTipDrop: 0,
        tailRootAlongBottom: 18,
        tutorialRightLineInsetX: 0,
        tutorialHookBulge: 3,
        tutorialUpperLeadY: 4,
        tutorialLowerArcCurvature: 5,
        tutorialLowerLeftBulge: 4,
        tailClipReserveRight: 10,
        tailClipReserveBottom: 4
    )

    static let messageKitPointed = IMessage1718BubbleTailParams(
        tailRightEdgeInset: 10,
        tailTipExtension: 0,
        tailTipDrop: 0,
        tailRootAlongBottom: 10,
        tailClipReserveRight: 0,
        tailClipReserveBottom: 0
    )

    static let messageKitCurved = IMessage1718BubbleTailParams(
        tailRightEdgeInset: 16,
        tailTipExtension: 5,
        tailTipDrop: 2,
        tailRootAlongBottom: 20,
        tailUpperCP1X: -6,
        tailUpperCP1Y: 6,
        tailUpperCP2X: -6,
        tailUpperCP2Y: 6,
        tailLowerCP1X: -8,
        tailLowerCP1Y: 6,
        tailLowerCP2X: -8,
        tailLowerCP2Y: 6
    )
}
