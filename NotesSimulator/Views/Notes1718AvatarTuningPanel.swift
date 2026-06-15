import SwiftUI
import UIKit

/// 头像预览（形状固定为 ContactAvatar1718 参考图裁圆）
struct Notes1718AvatarTuningPanel: View {
    @Binding var settings: Notes1718TuningSettings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    avatarPreviewBlock
                        .listRowInsets(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
                        .listRowBackground(Color.clear)
                }

                Section {
                    sliderRow("头像直径", value: $settings.avatarSize, range: 28...72, step: 1, format: "%.0f pt")
                } footer: {
                    Text("ContactAvatar1718 参考图裁圆：保留灰圆内白人形，裁掉方形 PNG 外围白边。直径可在「预览泡」里调整。")
                }
            }
            .navigationTitle("头像预览")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }

    private var avatarPreviewBlock: some View {
        VStack(spacing: 20) {
            HStack(spacing: 24) {
                previewTile(title: "放大", size: 88)
                previewTile(title: "预览泡", size: CGFloat(settings.avatarSize))
            }

            previewBubbleMock
        }
        .frame(maxWidth: .infinity)
    }

    private func previewTile(title: String, size: CGFloat) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            ContactPlaceholderAvatar1718(size: size, tuning: settings)
                .frame(width: size, height: size)
        }
    }

    private var previewBubbleMock: some View {
        HStack(spacing: PhoneMenu1718Layout.Animation.previewAvatarPhoneSpacing) {
            ContactPlaceholderAvatar1718(
                size: CGFloat(settings.avatarSize),
                tuning: settings
            )
            .frame(width: CGFloat(settings.avatarSize), height: CGFloat(settings.avatarSize))

            Text("139 8583 9482")
                .font(.system(size: CGFloat(settings.previewPhoneFontSize), weight: .medium))
                .foregroundStyle(Color(uiColor: settings.previewPhoneUIColor()))
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(settings.paperBackgroundColor())
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 0.5)
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
