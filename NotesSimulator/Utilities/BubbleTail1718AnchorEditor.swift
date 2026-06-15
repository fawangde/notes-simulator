import CoreGraphics
import SwiftUI

/// 尾巴连线类型（用户指定每段语义）
enum BubbleTail1718SegmentKind: String, Codable, CaseIterable, Identifiable {
    case upperStraight
    case upperArc
    case lowerArc

    var id: String { rawValue }

    var title: String {
        switch self {
        case .upperStraight: return "上弧直线"
        case .upperArc: return "上弧线"
        case .lowerArc: return "下弧线"
        }
    }

    var strokeColor: Color {
        switch self {
        case .upperStraight: return .orange
        case .upperArc: return .green
        case .lowerArc: return .purple
        }
    }
}

/// 描点画布布局：右下 5× 放大，网格 0.2 pt
struct BubbleTail1718PlotLayout {
    let bodyWidth: CGFloat
    let bodyHeight: CGFloat
    let cornerRadius: CGFloat
    let zoom: CGFloat
    let actualPtPerGrid: CGFloat
    let visibleBodyLeft: CGFloat
    let visibleBodyTop: CGFloat
    let tailMarginRight: CGFloat
    let tailMarginBottom: CGFloat
    let canvasInset: CGFloat

    init(
        bodyWidth: CGFloat,
        bodyHeight: CGFloat,
        cornerRadius: CGFloat = 18,
        zoom: CGFloat = 5,
        actualPtPerGrid: CGFloat = 0.2,
        visibleBodyLeft: CGFloat = 22,
        visibleBodyTop: CGFloat = 24,
        tailMarginRight: CGFloat = 200,
        tailMarginBottom: CGFloat = 72,
        canvasInset: CGFloat = 12
    ) {
        self.bodyWidth = bodyWidth
        self.bodyHeight = bodyHeight
        self.cornerRadius = cornerRadius
        self.zoom = zoom
        self.actualPtPerGrid = actualPtPerGrid
        self.visibleBodyLeft = visibleBodyLeft
        self.visibleBodyTop = visibleBodyTop
        self.tailMarginRight = tailMarginRight
        self.tailMarginBottom = tailMarginBottom
        self.canvasInset = canvasInset
    }

    /// 微调 sheet 默认 Hello 尺寸
    static let previewDefault = BubbleTail1718PlotLayout(bodyWidth: 120, bodyHeight: 44)

    var regionMinX: CGFloat { bodyWidth - visibleBodyLeft - canvasInset }
    var regionMinY: CGFloat { bodyHeight - visibleBodyTop - canvasInset }
    var regionMaxX: CGFloat { bodyWidth + tailMarginRight + canvasInset }
    var regionMaxY: CGFloat { bodyHeight + tailMarginBottom + canvasInset }

    var regionWidth: CGFloat { regionMaxX - regionMinX }
    var regionHeight: CGFloat { regionMaxY - regionMinY }

    var canvasWidth: CGFloat { regionWidth * zoom }
    var canvasHeight: CGFloat { regionHeight * zoom }

    var bodyRightX: CGFloat { bodyWidth }
    var bodyBottomY: CGFloat { bodyHeight }

    func snapActual(_ value: CGFloat) -> CGFloat {
        (value / actualPtPerGrid).rounded() * actualPtPerGrid
    }

    func displayPoint(_ actual: CGPoint) -> CGPoint {
        CGPoint(
            x: (actual.x - regionMinX) * zoom,
            y: (actual.y - regionMinY) * zoom
        )
    }

    func actualPoint(fromDisplay display: CGPoint) -> CGPoint {
        CGPoint(
            x: snapActual(display.x / zoom + regionMinX),
            y: snapActual(display.y / zoom + regionMinY)
        )
    }

    var actualToDisplayTransform: CGAffineTransform {
        CGAffineTransform(translationX: -regionMinX, y: -regionMinY)
            .scaledBy(x: zoom, y: zoom)
    }

    func clampActualPoint(_ point: CGPoint) -> CGPoint {
        CGPoint(
            x: snapActual(min(max(point.x, regionMinX), regionMaxX)),
            y: snapActual(min(max(point.y, regionMinY), regionMaxY))
        )
    }

    /// 右缘以右的尾巴主区域（虚线框）
    var tailRightZoneRect: CGRect {
        CGRect(
            x: bodyRightX,
            y: regionMinY,
            width: tailMarginRight + canvasInset,
            height: regionMaxY - regionMinY
        )
    }

    /// 底边以下的补充区域
    var tailBottomZoneRect: CGRect {
        CGRect(
            x: regionMinX,
            y: bodyBottomY,
            width: bodyRightX - regionMinX + tailMarginRight * 0.35,
            height: tailMarginBottom + canvasInset
        )
    }

    var tailWorkspaceActualRect: CGRect { tailRightZoneRect }
}

/// 兼容旧引用
enum BubbleTail1718AnchorEditorLayout {
    static var previewDefault: BubbleTail1718PlotLayout { .previewDefault }
    static let zoom: CGFloat = 5
    static let actualPtPerGrid: CGFloat = 0.2

    static func snapActual(_ value: CGFloat) -> CGFloat {
        previewDefault.snapActual(value)
    }
}

struct BubbleTail1718AnchorModel: Equatable {
    var points: [CGPoint]
    var segmentKinds: [BubbleTail1718SegmentKind]
    var segmentCurvatures: [CGFloat]

    static let labels = ["A", "B", "C", "D"]

    /// 真机截图描点定稿（参考本体 189×50 pt，`anchorCoordOrigin=bodyTopLeft`）
    static var tracedScreenshotDefault: BubbleTail1718AnchorModel {
        BubbleTail1718AnchorModel(
            points: [
                CGPoint(x: 189, y: 29.60),  // A 右缘 hook 起点
                CGPoint(x: 189, y: 40.30),  // B
                CGPoint(x: 194.40, y: 49.10),  // C 尖
                CGPoint(x: 179.20, y: 42.80),  // D 底根
            ],
            segmentKinds: [.upperStraight, .upperArc, .lowerArc],
            segmentCurvatures: [0, 2, 4]
        )
    }

    static var helloDefault: BubbleTail1718AnchorModel { tracedScreenshotDefault }

    /// 聊天区唯一描点（定稿，不读 UserDefaults）
    static var productionChatTail: BubbleTail1718AnchorModel { tracedScreenshotDefault }

    static let defaultReferenceBodySize = CGSize(width: 189, height: 50)

    /// 将参考本体坐标系下的描点映射到当前气泡本体尺寸（保持相对右下角的偏移）
    func resolved(forBodyWidth bodyWidth: CGFloat, bodyHeight: CGFloat, referenceSize ref: CGSize) -> BubbleTail1718AnchorModel {
        guard ref.width > 0, ref.height > 0 else { return self }
        let resolvedPoints = points.map { point in
            CGPoint(
                x: bodyWidth + (point.x - ref.width),
                y: bodyHeight + (point.y - ref.height)
            )
        }
        return BubbleTail1718AnchorModel(
            points: resolvedPoints,
            segmentKinds: segmentKinds,
            segmentCurvatures: segmentCurvatures
        )
    }

    /// 把当前本体上的描点写回参考本体坐标系
    func stored(forBodyWidth bodyWidth: CGFloat, bodyHeight: CGFloat, referenceSize ref: CGSize) -> BubbleTail1718AnchorModel {
        guard ref.width > 0, ref.height > 0 else { return self }
        let storedPoints = points.map { point in
            CGPoint(
                x: ref.width + (point.x - bodyWidth),
                y: ref.height + (point.y - bodyHeight)
            )
        }
        return BubbleTail1718AnchorModel(
            points: storedPoints,
            segmentKinds: segmentKinds,
            segmentCurvatures: segmentCurvatures
        )
    }

    var segmentCount: Int { max(0, points.count - 1) }

    func point(at index: Int) -> CGPoint {
        guard points.indices.contains(index) else { return .zero }
        return points[index]
    }

    mutating func setPoint(at index: Int, to point: CGPoint) {
        guard points.indices.contains(index) else { return }
        points[index] = point
    }
}

enum BubbleTail1718AnchorPathBuilder {
    static func bodyOnlyPath(
        width: CGFloat,
        height: CGFloat,
        radius: CGFloat = 18
    ) -> Path {
        Path(IOSOutgoingBubblePath1718.bodyOnlyRoundedRect(
            bodyWidth: width,
            bodyHeight: height,
            cornerRadius: radius
        ).cgPath)
    }

    static func segmentPath(
        from start: CGPoint,
        to end: CGPoint,
        kind: BubbleTail1718SegmentKind,
        curvature: CGFloat
    ) -> Path {
        var path = Path()
        path.move(to: start)
        switch kind {
        case .upperStraight:
            path.addLine(to: end)
        case .upperArc, .lowerArc:
            let (cp1, cp2) = cubicControls(from: start, to: end, kind: kind, curvature: curvature)
            path.addCurve(to: end, control1: cp1, control2: cp2)
        }
        return path
    }

    static func appendSegment(
        to path: UIBezierPath,
        from start: CGPoint,
        to end: CGPoint,
        kind: BubbleTail1718SegmentKind,
        curvature: CGFloat
    ) {
        switch kind {
        case .upperStraight:
            path.addLine(to: end)
        case .upperArc, .lowerArc:
            let (cp1, cp2) = cubicControls(from: start, to: end, kind: kind, curvature: curvature)
            path.addCurve(to: end, controlPoint1: cp1, controlPoint2: cp2)
        }
    }

    static func cubicControls(
        from start: CGPoint,
        to end: CGPoint,
        kind: BubbleTail1718SegmentKind,
        curvature: CGFloat
    ) -> (CGPoint, CGPoint) {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let length = max(hypot(dx, dy), 0.001)
        let nx = -dy / length
        let ny = dx / length
        let bulge = max(curvature, 0)
        let sign: CGFloat = kind == .lowerArc ? -1 : 1
        let cp1 = CGPoint(
            x: start.x + dx * 0.33 + nx * sign * bulge,
            y: start.y + dy * 0.33 + ny * sign * bulge
        )
        let cp2 = CGPoint(
            x: start.x + dx * 0.66 + nx * sign * bulge * 0.85,
            y: start.y + dy * 0.66 + ny * sign * bulge * 0.85
        )
        return (cp1, cp2)
    }
}

private extension BubbleTail1718AnchorModel {
    func segmentCurvature(at index: Int) -> CGFloat {
        guard segmentCurvatures.indices.contains(index) else { return 0 }
        return segmentCurvatures[index]
    }
}

extension Notes1718TuningSettings {
    var tailAnchorReferenceSize: CGSize {
        CGSize(width: tailAnchorRefBodyWidth, height: tailAnchorRefBodyHeight)
    }

    func resolvedTailAnchorModel(forBodyWidth bodyWidth: CGFloat, bodyHeight: CGFloat) -> BubbleTail1718AnchorModel {
        tailAnchorModel.resolved(
            forBodyWidth: bodyWidth,
            bodyHeight: bodyHeight,
            referenceSize: tailAnchorReferenceSize
        )
    }

    mutating func setTailAnchorModel(
        _ resolved: BubbleTail1718AnchorModel,
        editedOnBodyWidth bodyWidth: CGFloat,
        editedOnBodyHeight bodyHeight: CGFloat
    ) {
        tailAnchorModel = resolved.stored(
            forBodyWidth: bodyWidth,
            bodyHeight: bodyHeight,
            referenceSize: tailAnchorReferenceSize
        )
    }

    var tailAnchorModel: BubbleTail1718AnchorModel {
        get {
            BubbleTail1718AnchorModel(
                points: [
                    CGPoint(x: tailAnchor0X, y: tailAnchor0Y),
                    CGPoint(x: tailAnchor1X, y: tailAnchor1Y),
                    CGPoint(x: tailAnchor2X, y: tailAnchor2Y),
                    CGPoint(x: tailAnchor3X, y: tailAnchor3Y),
                ],
                segmentKinds: [
                    BubbleTail1718SegmentKind(rawValue: tailAnchorSegment0Kind) ?? .upperStraight,
                    BubbleTail1718SegmentKind(rawValue: tailAnchorSegment1Kind) ?? .upperArc,
                    BubbleTail1718SegmentKind(rawValue: tailAnchorSegment2Kind) ?? .lowerArc,
                ],
                segmentCurvatures: [
                    CGFloat(tailAnchorSegment0Curvature),
                    CGFloat(tailAnchorSegment1Curvature),
                    CGFloat(tailAnchorSegment2Curvature),
                ]
            )
        }
        set {
            guard newValue.points.count >= 4,
                  newValue.segmentKinds.count >= 3,
                  newValue.segmentCurvatures.count >= 3 else { return }
            tailAnchor0X = Double(newValue.points[0].x)
            tailAnchor0Y = Double(newValue.points[0].y)
            tailAnchor1X = Double(newValue.points[1].x)
            tailAnchor1Y = Double(newValue.points[1].y)
            tailAnchor2X = Double(newValue.points[2].x)
            tailAnchor2Y = Double(newValue.points[2].y)
            tailAnchor3X = Double(newValue.points[3].x)
            tailAnchor3Y = Double(newValue.points[3].y)
            tailAnchorSegment0Kind = newValue.segmentKinds[0].rawValue
            tailAnchorSegment1Kind = newValue.segmentKinds[1].rawValue
            tailAnchorSegment2Kind = newValue.segmentKinds[2].rawValue
            tailAnchorSegment0Curvature = Double(newValue.segmentCurvatures[0])
            tailAnchorSegment1Curvature = Double(newValue.segmentCurvatures[1])
            tailAnchorSegment2Curvature = Double(newValue.segmentCurvatures[2])
        }
    }

    mutating func resetTailAnchorDefaults() {
        tailAnchorRefBodyWidth = Double(BubbleTail1718AnchorModel.defaultReferenceBodySize.width)
        tailAnchorRefBodyHeight = Double(BubbleTail1718AnchorModel.defaultReferenceBodySize.height)
        tailAnchorModel = .tracedScreenshotDefault
        tailAnchorSelectedIndex = 0
    }
}
