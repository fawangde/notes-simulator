import SwiftUI

/// iOS 26 撰写页「+」控制台：气泡文字 + 气泡颜色预览。
struct IOS26ComposeTuningSheet: View {
    @Binding var bubbleTextSettings: ComposeBubbleTuningSettings
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: Tab = .text

    private enum Tab: String, CaseIterable, Identifiable {
        case text = "气泡文字"
        case color = "气泡颜色"

        var id: String { rawValue }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("调节项", selection: $selectedTab) {
                    ForEach(Tab.allCases) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                switch selectedTab {
                case .text:
                    ComposeBubbleTuningPanel(settings: $bubbleTextSettings, embedInNavigation: false)
                case .color:
                    IOS26BubbleColorPreviewPanel()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("撰写页调节")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}
