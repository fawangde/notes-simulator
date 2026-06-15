import SwiftUI

/// 微调 sheet 内的大号 5× 描点预览（固定 Hello 尺寸对照）
struct BubbleTail1718AnchorEditorView: View {
    @Binding var settings: Notes1718TuningSettings

    private let layout = BubbleTail1718PlotLayout.previewDefault

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("5× 右下放大 · 本体 \(Int(layout.bodyWidth))×\(Int(layout.bodyHeight))")
                .font(.caption.weight(.semibold))
            Text("右外 +\(Int(layout.tailMarginRight)) pt · 下外 +\(Int(layout.tailMarginBottom)) pt · 网格 0.2 pt")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Button("重置默认点位") {
                var copy = settings
                copy.resetTailAnchorDefaults()
                settings = copy
            }
            .font(.caption)
            BubbleTail1718MagnifiedPlotCanvas(
                settings: $settings,
                layout: layout,
                minCanvasHeight: 520
            )
            pointPicker
            coordinateSliders
            segmentControls
        }
    }

    private let labels = BubbleTail1718AnchorModel.labels

    private var pointPicker: some View {
        Picker("点位", selection: $settings.tailAnchorSelectedIndex) {
            ForEach(0 ..< 4, id: \.self) { index in
                Text("\(labels[index]) 点").tag(index)
            }
        }
        .pickerStyle(.segmented)
    }

    private var coordinateSliders: some View {
        let index = min(max(settings.tailAnchorSelectedIndex, 0), 3)
        return VStack(alignment: .leading, spacing: 8) {
            sliderRow("\(labels[index]) X", value: binding(for: index, axis: .x), range: layout.regionMinX ... layout.regionMaxX)
            sliderRow("\(labels[index]) Y", value: binding(for: index, axis: .y), range: layout.regionMinY ... layout.regionMaxY)
        }
    }

    private var segmentControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("连线类型与弧度")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            ForEach(0 ..< 3, id: \.self) { index in
                segmentRow(index: index)
            }
        }
    }

    private func segmentRow(index: Int) -> some View {
        let from = labels[index]
        let to = labels[index + 1]
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("\(from)→\(to)").font(.caption.weight(.semibold))
                Spacer()
                Picker("", selection: segmentKindBinding(index: index)) {
                    ForEach(BubbleTail1718SegmentKind.allCases) { kind in
                        Text(kind.title).tag(kind)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
            }
            if segmentKindBinding(index: index).wrappedValue != .upperStraight {
                HStack {
                    Text("弧度").font(.caption)
                    Slider(value: segmentCurvatureBinding(index: index), in: 0 ... 12, step: 0.2)
                    Text(String(format: "%.1f", segmentCurvatureBinding(index: index).wrappedValue))
                        .font(.caption.monospacedDigit())
                        .frame(width: 36, alignment: .trailing)
                }
            }
        }
        .padding(10)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private enum Axis { case x, y }

    private func binding(for index: Int, axis: Axis) -> Binding<Double> {
        Binding(
            get: {
                let point = settings.resolvedTailAnchorModel(
                    forBodyWidth: layout.bodyWidth,
                    bodyHeight: layout.bodyHeight
                ).point(at: index)
                switch axis {
                case .x: return Double(point.x)
                case .y: return Double(point.y)
                }
            },
            set: { newValue in
                var resolved = settings.resolvedTailAnchorModel(
                    forBodyWidth: layout.bodyWidth,
                    bodyHeight: layout.bodyHeight
                )
                var point = resolved.point(at: index)
                let snapped = layout.snapActual(CGFloat(newValue))
                switch axis {
                case .x: point.x = snapped
                case .y: point.y = snapped
                }
                resolved.setPoint(at: index, to: layout.clampActualPoint(point))
                settings.setTailAnchorModel(
                    resolved,
                    editedOnBodyWidth: layout.bodyWidth,
                    editedOnBodyHeight: layout.bodyHeight
                )
            }
        )
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

    private func sliderRow(_ title: String, value: Binding<Double>, range: ClosedRange<CGFloat>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title).font(.caption)
                Spacer()
                Text(String(format: "%.1f pt", value.wrappedValue))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Slider(value: value, in: Double(range.lowerBound) ... Double(range.upperBound), step: 0.2)
        }
    }
}
