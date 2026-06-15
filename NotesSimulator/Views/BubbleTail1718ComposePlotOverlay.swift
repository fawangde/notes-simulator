import SwiftUI

/// 撰写页全屏 5× 描点（大画布，不再挤在气泡角落）
struct BubbleTail1718ComposePlotOverlay: View {
    @Binding var settings: Notes1718TuningSettings
    let snapshot: BubbleTail1718ProbeSnapshot?
    var onDone: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()

            if let snapshot {
                let layout = BubbleTail1718PlotLayout(
                    bodyWidth: snapshot.bodySize.width,
                    bodyHeight: snapshot.bodySize.height
                )
                VStack(spacing: 0) {
                    header(layout: layout)
                    BubbleTail1718MagnifiedPlotCanvas(
                        settings: $settings,
                        layout: layout,
                        minCanvasHeight: 560
                    )
                    .padding(.horizontal, 8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    BubbleTail1718PlotControlBar(
                        settings: $settings,
                        subtitle: "5× 放大 · 点/拖画布 · 每格 0.2 pt",
                        onCopy: { UIPasteboard.general.string = settings.bubbleTailExportText },
                        onDone: onDone
                    )
                    .padding(.horizontal, 10)
                    .padding(.bottom, 10)
                }
            } else {
                waitingCard
            }
        }
    }

    private func header(layout: BubbleTail1718PlotLayout) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("撰写页描点")
                    .font(.headline)
                Text(String(format: "本体 %.0f×%.0f · 右+%.0f 下+%.0f pt",
                              layout.bodyWidth, layout.bodyHeight,
                              layout.tailMarginRight, layout.tailMarginBottom))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("关闭") { onDone() }
                .buttonStyle(.bordered)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }

    private var waitingCard: some View {
        VStack(spacing: 10) {
            Text("等待气泡…")
                .font(.headline)
            Text("请确认撰写页已显示蓝色发送泡")
                .font(.caption)
                .foregroundStyle(.secondary)
            Button("关闭") { onDone() }
                .buttonStyle(.borderedProminent)
        }
        .padding(24)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
