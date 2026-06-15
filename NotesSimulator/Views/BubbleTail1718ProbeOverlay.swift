import SwiftUI

/// 开发用：气泡路径锚点 + 控制点 + 参考图叠加强度，对照真机截图调参
struct BubbleTail1718ProbeOverlay: View {
    let snapshot: BubbleTail1718ProbeSnapshot?
    var referenceOpacity: Double = 0.35
    var referenceOffsetX: Double = 0
    var referenceOffsetY: Double = 0
    var referenceScale: Double = 1.0
    var showReference: Bool = true

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                if let snapshot {
                    Canvas { context, _ in
                        drawProbe(snapshot, in: geo, context: &context)
                    }
                    .allowsHitTesting(false)

                    if showReference, referenceOpacity > 0.01 {
                        referenceOverlay(snapshot: snapshot, in: geo)
                    }

                    Text(snapshot.measurements.joined(separator: "\n"))
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white)
                        .padding(8)
                        .background(.black.opacity(0.72), in: RoundedRectangle(cornerRadius: 8))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                        .padding(12)
                        .allowsHitTesting(false)
                } else {
                    Text("图形探针已开启\n等待发送泡 layout…\n请确认线程区有蓝色气泡")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white)
                        .padding(10)
                        .background(.black.opacity(0.72), in: RoundedRectangle(cornerRadius: 8))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .padding(12)
                        .allowsHitTesting(false)
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func referenceOverlay(snapshot: BubbleTail1718ProbeSnapshot, in geo: GeometryProxy) -> some View {
        let bubble = mapBubbleFrame(snapshot.bubbleFrameInWindow, in: geo)
        let scale = CGFloat(referenceScale)
        let tailW = max(72, snapshot.layoutSize.width * 0.42) * scale
        let tailH = max(48, snapshot.layoutSize.height * 0.55) * scale
        let offsetX = CGFloat(referenceOffsetX)
        let offsetY = CGFloat(referenceOffsetY)

        // 默认以矢量「尖」为锚点；png 右下角大致对准尖，再靠滑块微调
        let anchor: CGPoint = {
            if let tip = snapshot.anchors.first(where: { $0.name == "尖" }) {
                return CGPoint(x: bubble.minX + tip.point.x, y: bubble.minY + tip.point.y)
            }
            return CGPoint(x: bubble.maxX, y: bubble.maxY)
        }()
        let center = CGPoint(
            x: anchor.x - tailW * 0.52 + offsetX,
            y: anchor.y - tailH * 0.48 + offsetY
        )

        return Image("BubbleRefTailCrop1718")
            .resizable()
            .interpolation(.high)
            .aspectRatio(contentMode: .fit)
            .frame(width: tailW, height: tailH)
            .opacity(referenceOpacity)
            .position(center)
            .allowsHitTesting(false)
    }

    private func drawProbe(
        _ snapshot: BubbleTail1718ProbeSnapshot,
        in geo: GeometryProxy,
        context: inout GraphicsContext
    ) {
        let bubble = mapBubbleFrame(snapshot.bubbleFrameInWindow, in: geo)
        let map: (CGPoint) -> CGPoint = { local in
            CGPoint(x: bubble.minX + local.x, y: bubble.minY + local.y)
        }

        var boundsPath = Path()
        boundsPath.addRect(bubble)
        context.stroke(boundsPath, with: .color(.green), lineWidth: 1.5)

        if !snapshot.plottedSegments.isEmpty {
            for segment in snapshot.plottedSegments {
                let path = BubbleTail1718AnchorPathBuilder.segmentPath(
                    from: segment.from,
                    to: segment.to,
                    kind: segment.kind,
                    curvature: segment.curvature
                )
                let mapped = path.applying(CGAffineTransform(translationX: bubble.minX, y: bubble.minY))
                context.stroke(
                    mapped,
                    with: .color(segment.kind.strokeColor),
                    style: StrokeStyle(
                        lineWidth: 2,
                        lineCap: .round,
                        lineJoin: .round,
                        dash: segment.kind == .upperStraight ? [] : [5, 3]
                    )
                )
            }
        } else if snapshot.pathKind == .messageKitTutorial,
           let top = snapshot.anchors.first(where: { $0.name == "右缘起点" }),
           let corner = snapshot.anchors.first(where: { $0.name == "角点" }),
           let tip = snapshot.anchors.first(where: { $0.name == "尖" }),
           let junction = snapshot.anchors.first(where: { $0.name == "汇合" }),
           let root = snapshot.anchors.first(where: { $0.name == "底根" }) {
            stroke(map(top.point), map(corner.point), color: .red, context: &context, dash: [4, 3])
            stroke(map(corner.point), map(tip.point), color: .yellow, context: &context)
            stroke(map(tip.point), map(junction.point), color: .cyan, context: &context)
            stroke(map(junction.point), map(root.point), color: .mint, context: &context)

            if let cp1 = snapshot.controlPoints.first(where: { $0.name == "上CP1" }),
               let cp2 = snapshot.controlPoints.first(where: { $0.name == "上CP2" }) {
                stroke(map(top.point), map(cp1.point), color: .orange.opacity(0.7), context: &context, dash: [2, 2])
                stroke(map(cp1.point), map(cp2.point), color: .orange.opacity(0.7), context: &context, dash: [2, 2])
                stroke(map(cp2.point), map(corner.point), color: .orange.opacity(0.7), context: &context, dash: [2, 2])
            }
            if let cp1 = snapshot.controlPoints.first(where: { $0.name == "下CP1" }),
               let cp2 = snapshot.controlPoints.first(where: { $0.name == "下CP2" }) {
                stroke(map(tip.point), map(cp1.point), color: .purple.opacity(0.7), context: &context, dash: [2, 2])
                stroke(map(cp1.point), map(cp2.point), color: .purple.opacity(0.7), context: &context, dash: [2, 2])
                stroke(map(cp2.point), map(junction.point), color: .purple.opacity(0.7), context: &context, dash: [2, 2])
            }
        }

        for anchor in snapshot.anchors {
            dot(map(anchor.point), color: .white, label: anchor.name, context: &context)
        }
        for cp in snapshot.controlPoints {
            dot(map(cp.point), color: .orange, label: cp.name, context: &context, radius: 3)
        }
    }

    private func mapBubbleFrame(_ screenFrame: CGRect, in geo: GeometryProxy) -> CGRect {
        let origin = geo.frame(in: .global).origin
        return screenFrame.offsetBy(dx: -origin.x, dy: -origin.y)
    }

    private func stroke(
        _ a: CGPoint,
        _ b: CGPoint,
        color: Color,
        context: inout GraphicsContext,
        dash: [CGFloat] = []
    ) {
        var path = Path()
        path.move(to: a)
        path.addLine(to: b)
        if dash.isEmpty {
            context.stroke(path, with: .color(color), lineWidth: 1.5)
        } else {
            context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: 1.5, dash: dash))
        }
    }

    private func dot(
        _ point: CGPoint,
        color: Color,
        label: String,
        context: inout GraphicsContext,
        radius: CGFloat = 4
    ) {
        let rect = CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)
        context.fill(Path(ellipseIn: rect), with: .color(color))
        context.draw(
            Text(label).font(.system(size: 8, weight: .bold)).foregroundColor(color),
            at: CGPoint(x: point.x + 6, y: point.y - 8),
            anchor: .leading
        )
    }
}
