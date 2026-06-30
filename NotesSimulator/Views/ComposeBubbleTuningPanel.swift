import SwiftUI

/// 信息页气泡文字样式（26 / 1718 共用）
struct ComposeBubbleTuningPanel: View {
    @Binding var settings: ComposeBubbleTuningSettings
    var embedInNavigation: Bool = true
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            if embedInNavigation {
                NavigationStack {
                    formContent
                        .navigationTitle("气泡文字")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("完成") { dismiss() }
                            }
                        }
                }
            } else {
                formContent
            }
        }
    }

    private var formContent: some View {
        Form {
            Section {
                sliderRow("气泡字号", value: $settings.fontSize, range: 12...24, step: 0.5, format: "%.1f pt")
            } footer: {
                Text("仅影响聊天区蓝色气泡内文字；「已送达」小字与尾巴几何不变。")
            }
        }
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
