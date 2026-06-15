import SwiftUI
import UIKit

/// iOS 16–18 气泡尾巴样式挑选（参考图 + 实时矢量预览）
struct BubbleTail1718PickerPanel: View {
    @Binding var selectedPresetID: String
    @Environment(\.dismiss) private var dismiss

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(IMessage1718BubbleTailPreset.all) { preset in
                        presetCard(preset)
                    }
                }
                .padding(16)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("气泡尾巴样式")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                selectionFooter
            }
        }
    }

    private var selectionFooter: some View {
        let preset = IMessage1718BubbleTailPreset.preset(id: selectedPresetID)
        return VStack(alignment: .leading, spacing: 6) {
            Text("已选：\(preset.title)")
                .font(.subheadline.weight(.semibold))
            Text("编号 `\(preset.id)` · \(preset.era)")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(preset.sourceNote)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.bar)
    }

    private func presetCard(_ preset: IMessage1718BubbleTailPreset) -> some View {
        let isSelected = preset.id == selectedPresetID
        return Button {
            selectedPresetID = preset.id
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .bottomTrailing) {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(uiColor: .secondarySystemGroupedBackground))

                    if let imageName = preset.referenceImageName {
                        Image(imageName)
                            .resizable()
                            .scaledToFit()
                            .padding(8)
                            .opacity(0.92)
                    }

                    BubbleTail1718LivePreview(preset: preset)
                        .frame(height: 52)
                        .padding(.horizontal, 6)
                        .padding(.bottom, 4)
                }
                .frame(height: 108)
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(isSelected ? Color.accentColor : Color.black.opacity(0.08), lineWidth: isSelected ? 2.5 : 0.5)
                }

                Text(preset.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(preset.subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(preset.era)
                    .font(.system(size: 10, weight: .medium))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(eraColor(preset.era).opacity(0.15))
                    .foregroundStyle(eraColor(preset.era))
                    .clipShape(Capsule())
            }
        }
        .buttonStyle(.plain)
    }

    private func eraColor(_ era: String) -> Color {
        if era.contains("26") { return .orange }
        if era.contains("16") { return .blue }
        return .purple
    }
}

/// 固定宽度下的矢量尾巴预览
struct BubbleTail1718LivePreview: UIViewRepresentable {
    let preset: IMessage1718BubbleTailPreset
    var params: IMessage1718BubbleTailParams?

    func makeUIView(context: Context) -> BubbleTail1718PreviewUIView {
        BubbleTail1718PreviewUIView()
    }

    func updateUIView(_ uiView: BubbleTail1718PreviewUIView, context: Context) {
        uiView.apply(preset: preset, params: params)
    }
}

final class BubbleTail1718PreviewUIView: UIView {
    private let shapeLayer = CAShapeLayer()
    private let tailImageView = UIImageView()
    private var preset = IMessage1718BubbleTailPreset.default
    private var overrideParams: IMessage1718BubbleTailParams?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = false
        shapeLayer.fillColor = IMessage1718DesignTokens.bubbleFillUI.cgColor
        shapeLayer.contentsScale = UIScreen.main.scale
        layer.addSublayer(shapeLayer)
        tailImageView.contentMode = .scaleToFill
        tailImageView.isUserInteractionEnabled = false
        tailImageView.isHidden = true
        addSubview(tailImageView)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    func apply(preset: IMessage1718BubbleTailPreset, params: IMessage1718BubbleTailParams? = nil) {
        self.preset = preset
        overrideParams = params
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let params = overrideParams ?? IMessage1718BubbleTailPreset.resolvedParams(presetID: preset.id)
        let bodyWidth: CGFloat = 168
        let bodyHeight: CGFloat = 44
        let layout = IOSOutgoingBubblePath1718.layoutSize(
            bodySize: CGSize(width: bodyWidth, height: bodyHeight),
            params: params
        )
        shapeLayer.frame = CGRect(
            x: bounds.width - layout.width,
            y: bounds.height - layout.height,
            width: layout.width,
            height: layout.height
        )
        shapeLayer.path = IOSOutgoingBubblePath1718.sentBubblePath(
            bodyWidth: bodyWidth,
            bodyHeight: bodyHeight,
            params: params
        ).cgPath

        if params.pathKind == .referenceImageTail {
            tailImageView.isHidden = false
            tailImageView.image = IOSOutgoingBubblePath1718.referenceTailImage(
                named: params.referenceTailImageName,
                fill: IMessage1718DesignTokens.bubbleFillUI
            )
            tailImageView.frame = IOSOutgoingBubblePath1718.referenceTailImageFrame(
                bodyWidth: bodyWidth,
                bodyHeight: bodyHeight,
                params: params
            ).offsetBy(dx: shapeLayer.frame.minX, dy: shapeLayer.frame.minY)
            bringSubviewToFront(tailImageView)
        } else {
            tailImageView.isHidden = true
            tailImageView.image = nil
        }
    }
}
