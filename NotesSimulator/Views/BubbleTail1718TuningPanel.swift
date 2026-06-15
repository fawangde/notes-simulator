import SwiftUI

/// Tutorial 气泡尾巴手动微调 + 撰写页描点入口
struct BubbleTail1718TuningPanel: View {
    @Binding var settings: Notes1718TuningSettings
    var onStartComposePlot: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @State private var didCopyParams = false
    @State private var showFullScreenPlot = false

    private var previewParams: IMessage1718BubbleTailParams {
        IMessage1718BubbleTailPreset.resolvedParams(
            presetID: settings.bubbleTailPresetID,
            tuning: settings
        )
    }

    private var usesReferenceImageTail: Bool {
        IMessage1718BubbleTailPreset.preset(id: settings.bubbleTailPresetID).pathKind == .referenceImageTail
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if let onStartComposePlot {
                        Button {
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                onStartComposePlot()
                            }
                        } label: {
                            HStack {
                                Spacer()
                                Label("在撰写页描点", systemImage: "scope")
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.cyan)
                    }
                    Button {
                        UIPasteboard.general.string = settings.bubbleTailExportText
                        didCopyParams = true
                    } label: {
                        HStack {
                            Spacer()
                            Text(didCopyParams ? "已复制到剪贴板 ✓" : "复制锚点与参数")
                            Spacer()
                        }
                    }
                    .buttonStyle(.bordered)
                    .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                } footer: {
                    Text("推荐「全屏 5× 描点」。打开后自动对准右缘；在白色虚线右侧的淡蓝网格里描点（右 +200 pt）。")
                }

                if !usesReferenceImageTail {
                    Section {
                        Toggle("空尾巴（仅本体填充）", isOn: $settings.plottedTailFillBodyOnly)
                        Button {
                            showFullScreenPlot = true
                        } label: {
                            HStack {
                                Spacer()
                                Label("全屏 5× 描点", systemImage: "arrow.up.left.and.arrow.down.right")
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        BubbleTail1718AnchorEditorView(settings: $settings)
                            .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
                            .listRowBackground(Color(uiColor: .secondarySystemGroupedBackground))
                    } header: {
                        Text("5× 大预览描点")
                    } footer: {
                        let layout = BubbleTail1718PlotLayout.previewDefault
                        Text("画布 \(Int(layout.canvasWidth))×\(Int(max(layout.canvasHeight, 520))) px，右外 +\(Int(layout.tailMarginRight))、下外 +\(Int(layout.tailMarginBottom)) pt。「空尾巴」只填本体+18pt 圆角，尾巴虚线框可对照自行填色。")
                    }

                    Section {
                        pointPicker
                        coordinateSliders
                    } header: {
                        Text("滑块微调")
                    }
                }

                Section {
                    BubbleTail1718LivePreview(
                        preset: IMessage1718BubbleTailPreset.preset(id: settings.bubbleTailPresetID),
                        params: previewParams
                    )
                    .frame(height: 72)
                } header: {
                    Text("矢量预览")
                }

                if !usesReferenceImageTail {
                    Section {
                        Toggle("启用旧版滑块微调", isOn: $settings.bubbleTailManualTuningEnabled)
                        if settings.bubbleTailManualTuningEnabled {
                            legacySliders
                        }
                    } header: {
                        Text("旧版参数（可选）")
                    }
                }
            }
            .navigationTitle("尾巴微调")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
            .fullScreenCover(isPresented: $showFullScreenPlot) {
                fullScreenPlotSheet
            }
        }
    }

    private var fullScreenPlotSheet: some View {
        let layout = BubbleTail1718PlotLayout.previewDefault
        return NavigationStack {
            VStack(spacing: 0) {
                BubbleTail1718MagnifiedPlotCanvas(
                    settings: $settings,
                    layout: layout,
                    minCanvasHeight: 620
                )
                .padding(8)
                BubbleTail1718PlotControlBar(
                    settings: $settings,
                    subtitle: "全屏 5× · 点/拖放置 A–D",
                    onCopy: { UIPasteboard.general.string = settings.bubbleTailExportText },
                    onDone: { showFullScreenPlot = false }
                )
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("全屏描点")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { showFullScreenPlot = false }
                }
            }
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
        let layout = BubbleTail1718PlotLayout.previewDefault
        let index = min(max(settings.tailAnchorSelectedIndex, 0), 3)
        return VStack(alignment: .leading, spacing: 8) {
            sliderRow(
                "\(labels[index]) X",
                value: binding(for: index, axis: .x, layout: layout),
                range: Double(layout.regionMinX) ... Double(layout.regionMaxX),
                step: 0.2,
                format: "%.1f pt"
            )
            sliderRow(
                "\(labels[index]) Y",
                value: binding(for: index, axis: .y, layout: layout),
                range: Double(layout.regionMinY) ... Double(layout.regionMaxY),
                step: 0.2,
                format: "%.1f pt"
            )
        }
    }

    private var segmentControls: some View {
        ForEach(0 ..< 3, id: \.self) { index in
            segmentRow(index: index)
        }
    }

    private func segmentRow(index: Int) -> some View {
        let from = labels[index]
        let to = labels[index + 1]
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("\(from)→\(to)")
                    .font(.caption.weight(.semibold))
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
                    Text("弧度")
                        .font(.caption)
                    Slider(value: segmentCurvatureBinding(index: index), in: 0 ... 12, step: 0.2)
                    Text(String(format: "%.1f", segmentCurvatureBinding(index: index).wrappedValue))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(width: 36, alignment: .trailing)
                }
            }
        }
    }

    @ViewBuilder
    private var legacySliders: some View {
        sliderRow("尖向右伸出", value: $settings.tutorialTailExtension, range: 4 ... 12, step: 0.5, format: "%.1f pt")
        sliderRow("底边根左移", value: $settings.tutorialTailRootAlongBottom, range: 10 ... 30, step: 0.5, format: "%.1f pt")
        sliderRow("上弧竖直 lead", value: $settings.tutorialUpperLeadY, range: 0 ... 8, step: 0.5, format: "%.1f pt")
        sliderRow("下弧外凸", value: $settings.tutorialHookBulge, range: 0 ... 5, step: 0.5, format: "%.1f pt")
        sliderRow("下弧回接展开", value: $settings.tutorialLowerArcCurvature, range: 0 ... 8, step: 0.5, format: "%.1f pt")
        sliderRow("下弧左偏厚度", value: $settings.tutorialLowerLeftBulge, range: 0 ... 8, step: 0.5, format: "%.1f pt")
    }

    private enum Axis { case x, y }

    private func binding(for index: Int, axis: Axis, layout: BubbleTail1718PlotLayout) -> Binding<Double> {
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

    private func sliderRow(
        _ title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        format: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                Spacer()
                Text(String(format: format, value.wrappedValue))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Slider(value: value, in: range, step: step)
        }
    }
}
