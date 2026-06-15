import UIKit

/// 1718 气泡图形探针快照（不 attach 系统进程，仅读仿真 App 内矢量）
struct BubbleTail1718ProbeSnapshot: Equatable {
    struct PointLabel: Equatable {
        let name: String
        let point: CGPoint
    }

    struct PlottedSegment: Equatable {
        let from: CGPoint
        let to: CGPoint
        let kind: BubbleTail1718SegmentKind
        let curvature: CGFloat
    }

    let bubbleFrameInWindow: CGRect
    let bodySize: CGSize
    let layoutSize: CGSize
    let presetID: String
    let pathKind: BubbleTail1718PathKind
    let anchors: [PointLabel]
    let controlPoints: [PointLabel]
    let plottedSegments: [PlottedSegment]
    let measurements: [String]
    let exportText: String
}

enum BubbleTail1718ProbeRegistry {
    private static weak var bubbleView: IOSOutgoingChatBubbleView1718?
    private(set) static var isManuallyActive = false
    private(set) static var isPlotModeActive = false
    static var onUpdate: ((BubbleTail1718ProbeSnapshot?) -> Void)?

    static func register(_ bubble: IOSOutgoingChatBubbleView1718) {
        bubbleView = bubble
        guard isManuallyActive else { return }
        publish()
    }

    /// 撰写页手动开关探针（关闭时清 overlay）
    static func setManualActive(_ active: Bool) {
        isManuallyActive = active
        if !active { isPlotModeActive = false }
        if active {
            publish()
        } else {
            onUpdate?(nil)
        }
    }

    /// 撰写页描点模式（需气泡 frame，不依赖探针 dev 开关）
    static func setPlotModeActive(_ active: Bool) {
        isPlotModeActive = active
        isManuallyActive = active
        if active {
            publish()
        } else {
            onUpdate?(nil)
        }
    }

    static func deactivate() {
        isManuallyActive = false
        isPlotModeActive = false
        onUpdate?(nil)
    }

    static func publish() {
        guard isManuallyActive else { return }
        guard DevelopmentFlags.showBubbleTailLayoutProbe || isPlotModeActive else {
            return
        }
        guard let bubble = bubbleView else {
            onUpdate?(nil)
            #if DEBUG
            print("[bubble-probe] 无气泡 view（请进入撰写页并显示发送泡）")
            #endif
            return
        }
        let snapshot = bubble.makeProbeSnapshot()
        #if DEBUG
        print(
            "[bubble-probe] snapshot body="
                + String(format: "%.0f×%.0f", snapshot.bodySize.width, snapshot.bodySize.height)
                + " anchors=\(snapshot.anchors.count)"
                + " preset=\(snapshot.presetID)"
        )
        #endif
        onUpdate?(snapshot)
    }
}
