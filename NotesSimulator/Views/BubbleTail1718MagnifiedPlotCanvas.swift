import SwiftUI

/// 5× 放大描点画布（打开即对准气泡右缘 + 右侧尾巴区）
struct BubbleTail1718MagnifiedPlotCanvas: View {
    @Binding var settings: Notes1718TuningSettings
    let layout: BubbleTail1718PlotLayout
    var minCanvasHeight: CGFloat = 480
    /// 进入时把视口滚到右缘，让尾巴区落在屏幕中央
    var scrollToTailOnAppear: Bool = true

    @State private var dragPickActive = false

    private let labels = BubbleTail1718AnchorModel.labels
    private let tailFocusID = "tailFocus"

    private var canvasSize: CGSize {
        CGSize(
            width: layout.canvasWidth,
            height: max(layout.canvasHeight, minCanvasHeight)
        )
    }

    var body: some View {
        let resolvedModel = settings.resolvedTailAnchorModel(
            forBodyWidth: layout.bodyWidth,
            bodyHeight: layout.bodyHeight
        )

        ZStack(alignment: .top) {
            ScrollViewReader { proxy in
                ScrollView([.horizontal, .vertical], showsIndicators: true) {
                    ZStack(alignment: .topLeading) {
                        gridBackground
                        tailWorkspaceLayer
                        bodyLayer(model: resolvedModel)
                        rightEdgeGuide
                        tailOutlineLayer(model: resolvedModel)
                        anchorHandles(model: resolvedModel)
                        tailFocusMarker
                    }
                    .frame(width: canvasSize.width, height: canvasSize.height)
                    .contentShape(Rectangle())
                    .gesture(dragGesture(model: resolvedModel))
                }
                .onAppear {
                    guard scrollToTailOnAppear else { return }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        withAnimation(.easeOut(duration: 0.25)) {
                            proxy.scrollTo(tailFocusID, anchor: .center)
                        }
                    }
                }
            }

            scrollHintOverlay
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: min(520, canvasSize.height + 8), maxHeight: canvasSize.height + 8)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    /// 滚动定位点：右缘外 40pt、底边附近（尾巴典型位置）
    private var tailFocusMarker: some View {
        Color.clear
            .frame(width: 1, height: 1)
            .position(
                layout.displayPoint(
                    CGPoint(x: layout.bodyRightX + 48, y: layout.bodyBottomY + 4)
                )
            )
            .id(tailFocusID)
    }

    private var scrollHintOverlay: some View {
        VStack {
            HStack {
                Spacer()
                Text("← 左：气泡右缘 | 右：尾巴描点区 →")
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(8)
            }
            Spacer()
        }
        .allowsHitTesting(false)
    }

    private var gridBackground: some View {
        Canvas { context, size in
            let step = layout.zoom * layout.actualPtPerGrid
            let major = layout.zoom

            var backdrop = Path { path in
                path.addRect(CGRect(x: 0, y: 0, width: size.width, height: size.height))
            }
            context.fill(backdrop, with: .color(Color.primary.opacity(0.04)))

            var minor = Path()
            var majorPath = Path()
            var x: CGFloat = 0
            while x <= size.width + 0.5 {
                let line = Path { path in
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                }
                if Int((x / step).rounded()) % Int((major / step).rounded()) == 0 {
                    majorPath.addPath(line)
                } else {
                    minor.addPath(line)
                }
                x += step
            }
            var y: CGFloat = 0
            while y <= size.height + 0.5 {
                let line = Path { path in
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                }
                if Int((y / step).rounded()) % Int((major / step).rounded()) == 0 {
                    majorPath.addPath(line)
                } else {
                    minor.addPath(line)
                }
                y += step
            }
            context.stroke(minor, with: .color(.primary.opacity(0.07)), lineWidth: 0.5)
            context.stroke(majorPath, with: .color(.primary.opacity(0.16)), lineWidth: 0.75)
        }
        .frame(width: canvasSize.width, height: canvasSize.height)
    }

    private var tailWorkspaceLayer: some View {
        Canvas { context, _ in
            let rightZone = Path(layout.tailRightZoneRect.applying(layout.actualToDisplayTransform))
            context.stroke(
                rightZone,
                with: .color(.cyan.opacity(0.9)),
                style: StrokeStyle(lineWidth: 2.5, dash: [8, 5])
            )
            let bottomZone = Path(layout.tailBottomZoneRect.applying(layout.actualToDisplayTransform))
            context.stroke(
                bottomZone,
                with: .color(.cyan.opacity(0.45)),
                style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
            )
            let labelPoint = layout.displayPoint(
                CGPoint(x: layout.bodyRightX + 12, y: layout.regionMinY + 8)
            )
            context.draw(
                context.resolve(
                    Text("在这里描尾巴 →")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.cyan)
                ),
                at: labelPoint,
                anchor: .leading
            )
        }
        .allowsHitTesting(false)
    }

    private var rightEdgeGuide: some View {
        Canvas { context, _ in
            let top = layout.displayPoint(CGPoint(x: layout.bodyRightX, y: layout.regionMinY))
            let bottom = layout.displayPoint(CGPoint(x: layout.bodyRightX, y: layout.regionMaxY))
            var line = Path()
            line.move(to: top)
            line.addLine(to: bottom)
            context.stroke(
                line,
                with: .color(.white.opacity(0.85)),
                style: StrokeStyle(lineWidth: 2, dash: [4, 3])
            )
            context.draw(
                context.resolve(
                    Text("右缘 x=\(Int(layout.bodyRightX))")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                ),
                at: CGPoint(x: top.x + 6, y: top.y + 10),
                anchor: .leading
            )
        }
        .allowsHitTesting(false)
    }

    private func bodyLayer(model: BubbleTail1718AnchorModel) -> some View {
        Canvas { context, _ in
            let fillMode: IOSOutgoingBubblePath1718.PlottedTailFillMode =
                settings.plottedTailFillBodyOnly ? .bodyOnly : .composite
            let bubblePath = Path(
                IOSOutgoingBubblePath1718.plottedAnchorPreviewPath(
                    bodyWidth: layout.bodyWidth,
                    bodyHeight: layout.bodyHeight,
                    cornerRadius: layout.cornerRadius,
                    model: model,
                    fillMode: fillMode
                ).cgPath
            ).applying(layout.actualToDisplayTransform)
            context.fill(bubblePath, with: .color(Color(uiColor: IMessage1718DesignTokens.bubbleFillUI)))
            context.stroke(bubblePath, with: .color(.white.opacity(0.4)), lineWidth: 1.5)
            if settings.plottedTailFillBodyOnly {
                tailWedgeStroke(context: context, model: model)
            }
            let br = layout.displayPoint(CGPoint(x: layout.bodyRightX, y: layout.bodyBottomY))
            context.draw(
                context.resolve(
                    Text("BR")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                ),
                at: br,
                anchor: .bottomTrailing
            )
        }
        .allowsHitTesting(false)
    }

    private func tailWedgeStroke(context: GraphicsContext, model: BubbleTail1718AnchorModel) {
        let wedge = Path(
            IOSOutgoingBubblePath1718.plottedAnchorTailWedgePathForPreview(
                bodyWidth: layout.bodyWidth,
                bodyHeight: layout.bodyHeight,
                cornerRadius: layout.cornerRadius,
                model: model
            ).cgPath
        ).applying(layout.actualToDisplayTransform)
        context.stroke(
            wedge,
            with: .color(Color(uiColor: IMessage1718DesignTokens.bubbleFillUI).opacity(0.85)),
            style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round, dash: [5, 4])
        )
    }

    private func tailOutlineLayer(model: BubbleTail1718AnchorModel) -> some View {
        Canvas { context, _ in
            for index in 0 ..< model.segmentCount {
                guard model.segmentKinds.indices.contains(index) else { continue }
                let kind = model.segmentKinds[index]
                let segment = BubbleTail1718AnchorPathBuilder.segmentPath(
                    from: model.points[index],
                    to: model.points[index + 1],
                    kind: kind,
                    curvature: model.segmentCurvatures.indices.contains(index)
                        ? model.segmentCurvatures[index] : 0
                ).applying(layout.actualToDisplayTransform)
                context.stroke(
                    segment,
                    with: .color(kind.strokeColor),
                    style: StrokeStyle(
                        lineWidth: 2.5,
                        lineCap: .round,
                        lineJoin: .round,
                        dash: kind == .upperStraight ? [] : [6, 3]
                    )
                )
            }
        }
        .allowsHitTesting(false)
    }

    private func anchorHandles(model: BubbleTail1718AnchorModel) -> some View {
        ZStack {
            ForEach(Array(model.points.enumerated()), id: \.offset) { index, point in
                let display = layout.displayPoint(point)
                let selected = settings.tailAnchorSelectedIndex == index
                ZStack {
                    Circle()
                        .fill(handleColor(index).opacity(selected ? 1 : 0.9))
                        .frame(width: selected ? 26 : 20, height: selected ? 26 : 20)
                        .overlay { Circle().stroke(.white, lineWidth: selected ? 2.5 : 1.5) }
                    Text(labels[index] + (index == 2 ? "尖" : ""))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                }
                .position(display)
                Text(String(format: "(%.1f, %.1f)", point.x, point.y))
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundStyle(.primary.opacity(0.8))
                    .position(x: display.x, y: display.y - 18)
            }
        }
        .allowsHitTesting(false)
    }

    private func dragGesture(model: BubbleTail1718AnchorModel) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { value in
                if !dragPickActive {
                    dragPickActive = true
                    selectNearestPoint(to: value.startLocation, model: model)
                }
                moveSelectedPoint(to: layout.actualPoint(fromDisplay: value.location))
            }
            .onEnded { _ in
                dragPickActive = false
            }
    }

    private func selectNearestPoint(to displayLocation: CGPoint, model: BubbleTail1718AnchorModel) {
        var bestIndex = settings.tailAnchorSelectedIndex
        var bestDistance = CGFloat.greatestFiniteMagnitude
        for (index, point) in model.points.enumerated() {
            let display = layout.displayPoint(point)
            let distance = hypot(display.x - displayLocation.x, display.y - displayLocation.y)
            if distance < bestDistance {
                bestDistance = distance
                bestIndex = index
            }
        }
        if bestDistance <= 32 {
            settings.tailAnchorSelectedIndex = bestIndex
        }
    }

    private func moveSelectedPoint(to actual: CGPoint) {
        var resolved = settings.resolvedTailAnchorModel(
            forBodyWidth: layout.bodyWidth,
            bodyHeight: layout.bodyHeight
        )
        let index = min(max(settings.tailAnchorSelectedIndex, 0), 3)
        resolved.setPoint(at: index, to: layout.clampActualPoint(actual))
        settings.setTailAnchorModel(
            resolved,
            editedOnBodyWidth: layout.bodyWidth,
            editedOnBodyHeight: layout.bodyHeight
        )
    }

    private func handleColor(_ index: Int) -> Color {
        switch index {
        case 0: return .red
        case 1: return .green
        case 2: return .purple
        case 3: return .orange
        default: return .blue
        }
    }
}

/// 描点控制条（A–D、线段、完成）
struct BubbleTail1718PlotControlBar: View {
    @Binding var settings: Notes1718TuningSettings
    var subtitle: String
    var onCopy: () -> Void
    var onDone: () -> Void

    private let labels = BubbleTail1718AnchorModel.labels

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(subtitle)
                .font(.caption.weight(.semibold))
            Text("A→B 直线 · B→C 上弧 · C→D 下弧；C 是尖 (128,44)。在右缘虚线右侧点/拖。")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Picker("当前点", selection: $settings.tailAnchorSelectedIndex) {
                ForEach(0 ..< 4, id: \.self) { index in
                    Text("\(labels[index])").tag(index)
                }
            }
            .pickerStyle(.segmented)

            segmentQuickPick(index: 0, title: "A→B")
            segmentQuickPick(index: 1, title: "B→C")
            segmentQuickPick(index: 2, title: "C→D")

            HStack {
                Button("复制参数", action: onCopy)
                    .buttonStyle(.bordered)
                Spacer()
                Button("完成", action: onDone)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    private func segmentQuickPick(index: Int, title: String) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.caption2.monospaced())
                .frame(width: 32, alignment: .leading)
            Picker("", selection: segmentKindBinding(index: index)) {
                ForEach(BubbleTail1718SegmentKind.allCases) { kind in
                    Text(kind.title).tag(kind)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            if segmentKindBinding(index: index).wrappedValue != .upperStraight {
                Slider(value: segmentCurvatureBinding(index: index), in: 0 ... 12, step: 0.2)
                Text(String(format: "%.1f", segmentCurvatureBinding(index: index).wrappedValue))
                    .font(.caption2.monospacedDigit())
                    .frame(width: 28, alignment: .trailing)
            }
        }
    }

    private func segmentKindBinding(index: Int) -> Binding<BubbleTail1718SegmentKind> {
        Binding(
            get: {
                let kinds = settings.tailAnchorModel.segmentKinds
                guard kinds.indices.contains(index) else { return .upperArc }
                return kinds[index]
            },
            set: { newKind in
                var model = settings.tailAnchorModel
                guard model.segmentKinds.indices.contains(index) else { return }
                model.segmentKinds[index] = newKind
                settings.tailAnchorModel = model
            }
        )
    }

    private func segmentCurvatureBinding(index: Int) -> Binding<Double> {
        Binding(
            get: {
                let values = settings.tailAnchorModel.segmentCurvatures
                guard values.indices.contains(index) else { return 0 }
                return Double(values[index])
            },
            set: { newValue in
                var model = settings.tailAnchorModel
                guard model.segmentCurvatures.indices.contains(index) else { return }
                model.segmentCurvatures[index] = CGFloat(newValue)
                settings.tailAnchorModel = model
            }
        )
    }
}
