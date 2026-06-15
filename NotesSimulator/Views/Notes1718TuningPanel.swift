import SwiftUI

/// 备忘录文字样式（仅保留可调项，其余参数已定档）
struct Notes1718TuningPanel: View {
    @Binding var settings: Notes1718TuningSettings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    sliderRow("主题大小", value: $settings.titleFontSize, range: 18...40, step: 0.5, format: "%.1f pt")
                    sliderRow("主题灰度", value: $settings.themeTextGrayness, range: 0...1, step: 0.01, format: "%.0f%%") {
                        $0 * 100
                    }
                    sliderRow("正文大小", value: $settings.bodyFontSize, range: 12...28, step: 0.5, format: "%.1f pt")
                    sliderRow("号码大小", value: $settings.phoneFontSize, range: 12...28, step: 0.5, format: "%.1f pt")
                }
            }
            .navigationTitle("文字样式")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }

    private func sliderRow(
        _ title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        format: String,
        display: ((Double) -> Double)? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                Spacer()
                Text(String(format: format, display?(value.wrappedValue) ?? value.wrappedValue))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Slider(value: value, in: range, step: step)
        }
    }
}
