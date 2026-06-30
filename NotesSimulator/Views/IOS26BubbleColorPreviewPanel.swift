import SwiftUI
import UIKit

/// iOS 26 撰写页「+」：数码测色计 RGB/Hex 实色预览（不影响真实气泡）。
struct IOS26BubbleColorPreviewPanel: View {
    @EnvironmentObject private var app: AppState
    private enum FocusField: Hashable {
        case red
        case green
        case blue
        case hex
        case topSample
        case midSample
        case bottomSample
    }

    @State private var redText = IOS26BubbleColorPreviewStore.redText
    @State private var greenText = IOS26BubbleColorPreviewStore.greenText
    @State private var blueText = IOS26BubbleColorPreviewStore.blueText
    @State private var hexText = IOS26BubbleColorPreviewStore.hexText
    @State private var topSampleText = IOS26BubbleColorPreviewStore.topSampleText
    @State private var midSampleText = IOS26BubbleColorPreviewStore.midSampleText
    @State private var bottomSampleText = IOS26BubbleColorPreviewStore.bottomSampleText
    @State private var copiedMessage: String?
    @FocusState private var focusedField: FocusField?

    private var measuredColor: UIColor? {
        IOS26BubbleColorPreview.resolvedMeasuredColor(
            red: redText,
            green: greenText,
            blue: blueText,
            hex: hexText
        )
    }

    private var topSampleColor: UIColor? {
        IOS26BubbleColorPreview.parseSampleLine(topSampleText)
    }

    private var midSampleColor: UIColor? {
        IOS26BubbleColorPreview.parseSampleLine(midSampleText)
    }

    private var bottomSampleColor: UIColor? {
        IOS26BubbleColorPreview.parseSampleLine(bottomSampleText)
    }

    private var sampleColors: [UIColor] {
        [topSampleColor, midSampleColor, bottomSampleColor].compactMap { $0 }
    }

    private var averagedSampleColor: UIColor? {
        IOS26BubbleColorPreview.averageColor(sampleColors)
    }

    private var threeStopGradientPreview: (top: UIColor, mid: UIColor, bottom: UIColor)? {
        guard let topSampleColor, let midSampleColor, let bottomSampleColor else {
            return nil
        }
        return (topSampleColor, midSampleColor, bottomSampleColor)
    }

    private var gradientPreview: (top: UIColor, bottom: UIColor)? {
        if let topSampleColor, let bottomSampleColor {
            return (topSampleColor, bottomSampleColor)
        }
        if let topSampleColor, let midSampleColor {
            return (topSampleColor, midSampleColor)
        }
        if let midSampleColor, let bottomSampleColor {
            return (midSampleColor, bottomSampleColor)
        }
        return nil
    }

    var body: some View {
        Form {
            Section {
                hintContent
            }

            Section {
                Button("填入标准校准气泡") {
                    if app.mode == .image {
                        app.mode = .text
                    }
                    app.messageText = IOS26BubbleColorCalibration.messageText
                    copiedMessage = "已写入设置页「iMessage 气泡文字」"
                }
                Text(IOS26BubbleColorCalibration.samplingNote)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } header: {
                Text("标准校准气泡")
            } footer: {
                Text("顶/底色值请用标准校准气泡取样。填色以中色为锚：行数越多，越向顶/底对称扩展；16 行对齐全段顶→底渐变。")
            }

            Section("与当前对比") {
                compareRow
            }

            Section {
                sampleField(
                    title: "顶部",
                    placeholder: "0.40,0.72,0.98",
                    text: $topSampleText,
                    focus: .topSample
                )
                sampleField(
                    title: "中间",
                    placeholder: IOS26BubbleColorPreviewStore.defaultMidSampleText,
                    text: $midSampleText,
                    focus: .midSample
                )
                sampleField(
                    title: "底部",
                    placeholder: "0.35,0.65,0.95",
                    text: $bottomSampleText,
                    focus: .bottomSample
                )
            } header: {
                Text("多点测色（推荐）")
            } footer: {
                Text("真机每个像素色值不同，属正常。顶=第一行右侧「1」旁，底=最后一行右侧「1」旁，中=两行间平坦区。格式：R,G,B（0–1 或 0–255）。")
            }

            if averagedSampleColor != nil || gradientPreview != nil || threeStopGradientPreview != nil {
                Section("多点预览") {
                    multiSamplePreviewRow
                }
            }

            Section {
                HStack {
                    Text("R")
                        .foregroundStyle(.secondary)
                    TextField("0.337", text: $redText)
                        .keyboardType(.numbersAndPunctuation)
                        .multilineTextAlignment(.trailing)
                        .monospacedDigit()
                        .focused($focusedField, equals: .red)
                        .onChange(of: redText) { _ in persistInputs() }
                }

                HStack {
                    Text("G")
                        .foregroundStyle(.secondary)
                    TextField("0.635", text: $greenText)
                        .keyboardType(.numbersAndPunctuation)
                        .multilineTextAlignment(.trailing)
                        .monospacedDigit()
                        .focused($focusedField, equals: .green)
                        .onChange(of: greenText) { _ in persistInputs() }
                }

                HStack {
                    Text("B")
                        .foregroundStyle(.secondary)
                    TextField("0.961", text: $blueText)
                        .keyboardType(.numbersAndPunctuation)
                        .multilineTextAlignment(.trailing)
                        .monospacedDigit()
                        .focused($focusedField, equals: .blue)
                        .onChange(of: blueText) { _ in persistInputs() }
                }

                HStack {
                    Text("Hex")
                        .foregroundStyle(.secondary)
                    TextField("#56A2F5", text: $hexText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.asciiCapable)
                        .multilineTextAlignment(.trailing)
                        .monospaced()
                        .focused($focusedField, equals: .hex)
                        .onChange(of: hexText) { _ in persistInputs() }
                }

                Button("重置单点测色") {
                    loadDeviceMeasuredInputs()
                }
            } header: {
                Text("单点测色（备用）")
            }

            Section("参数") {
                exportContent
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("完成") {
                    focusedField = nil
                }
            }
        }
    }

    private var hintContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("真机气泡不是单一 hex：系统渲染有轻微明暗变化、抗锯齿、屏幕子像素，测色计在不同位置读数会不一样。不要追求「一个像素级绝对值」。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Text("做法：16 行气泡测顶/中/底 3 点 → 代码以中色为锚、按行数向上下对称扩展。调节面板仅预览，真实气泡以撰写页为准。")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.orange)
        }
        .listRowBackground(Color.clear)
    }

    private var compareRow: some View {
        HStack(spacing: 12) {
            bubbleColumn(
                title: "本项目当前",
                text: "当前",
                color: IOS26BubbleColorPreview.frozenUIColor
            )

            bubbleColumn(
                title: "单点输入",
                text: "单点",
                color: measuredColor,
                placeholder: "见下方"
            )
        }
        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
    }

    private var multiSamplePreviewRow: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let threeStopGradientPreview {
                previewBubbleRow(
                    title: "顶/中/底渐变（与真机一致）",
                    content: AnyView(
                        IOS26OutgoingBubbleGradientPreview(
                            topColor: threeStopGradientPreview.top,
                            midColor: threeStopGradientPreview.mid,
                            bottomColor: threeStopGradientPreview.bottom
                        )
                    )
                )
            } else if let gradientPreview {
                previewBubbleRow(
                    title: "顶→底渐变",
                    content: AnyView(
                        IOS26OutgoingBubbleTwoStopGradientPreview(
                            topColor: gradientPreview.top,
                            bottomColor: gradientPreview.bottom
                        )
                    )
                )
            }

            if let averagedSampleColor {
                previewBubbleRow(
                    title: "平均值",
                    content: AnyView(
                        OutgoingBubbleShape()
                            .fill(Color(uiColor: averagedSampleColor))
                    )
                )
            }
        }
        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
    }

    private func previewBubbleRow(title: String, content: AnyView) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                Spacer(minLength: 0)
                Text("预览")
                    .font(.system(size: 17))
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(content)
                    .padding(.trailing, 8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private func sampleField(
        title: String,
        placeholder: String,
        text: Binding<String>,
        focus: FocusField
    ) -> some View {
        HStack {
            Text(title)
                .frame(width: 36, alignment: .leading)
                .foregroundStyle(.secondary)
            TextField(placeholder, text: text)
                .keyboardType(.numbersAndPunctuation)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .monospaced()
                .focused($focusedField, equals: focus)
                .onChange(of: text.wrappedValue) { _ in persistInputs() }
        }
    }

    private func bubbleColumn(
        title: String,
        text: String,
        color: UIColor?,
        placeholder: String? = nil
    ) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                Spacer(minLength: 0)
                if let color {
                    Text(text)
                        .font(.system(size: 15))
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            OutgoingBubbleShape()
                                .fill(Color(uiColor: color))
                        )
                        .padding(.trailing, 6)
                } else if let placeholder {
                    Text(placeholder)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .frame(height: 36)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var exportContent: some View {
        if let threeStopGradientPreview {
            Text(
                IOS26BubbleColorPreview.exportGradientText(
                    top: threeStopGradientPreview.top,
                    mid: threeStopGradientPreview.mid,
                    bottom: threeStopGradientPreview.bottom,
                    average: averagedSampleColor
                )
            )
            .font(.caption.monospaced())
            .foregroundStyle(.secondary)

            Button {
                UIPasteboard.general.string = IOS26BubbleColorPreview.exportGradientText(
                    top: threeStopGradientPreview.top,
                    mid: threeStopGradientPreview.mid,
                    bottom: threeStopGradientPreview.bottom,
                    average: averagedSampleColor
                )
                copiedMessage = "已复制三点渐变参数"
            } label: {
                Text("复制三点渐变参数")
            }
        } else if let gradientPreview {
            Text(
                IOS26BubbleColorPreview.exportGradientText(
                    top: gradientPreview.top,
                    bottom: gradientPreview.bottom,
                    average: averagedSampleColor
                )
            )
            .font(.caption.monospaced())
            .foregroundStyle(.secondary)

            Button {
                UIPasteboard.general.string = IOS26BubbleColorPreview.exportGradientText(
                    top: gradientPreview.top,
                    bottom: gradientPreview.bottom,
                    average: averagedSampleColor
                )
                copiedMessage = "已复制渐变参数"
            } label: {
                Text("复制渐变参数")
            }
        } else if let measuredColor {
            Text(IOS26BubbleColorPreview.exportText(for: measuredColor, source: "digital color meter"))
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)

            Button {
                UIPasteboard.general.string = IOS26BubbleColorPreview.exportText(
                    for: measuredColor,
                    source: "digital color meter"
                )
                copiedMessage = "已复制到剪贴板"
            } label: {
                Text("复制单点参数")
            }
        } else if let averagedSampleColor {
            Text(IOS26BubbleColorPreview.exportText(for: averagedSampleColor, source: "multi-sample average"))
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)

            Button {
                UIPasteboard.general.string = IOS26BubbleColorPreview.exportText(
                    for: averagedSampleColor,
                    source: "multi-sample average"
                )
                copiedMessage = "已复制平均值"
            } label: {
                Text("复制平均值")
            }
        } else {
            Text("填入多点或单点测色后，这里会显示可复制的参数。")
                .font(.caption)
                .foregroundStyle(.secondary)
        }

        if let copiedMessage {
            Text(copiedMessage)
                .font(.caption)
                .foregroundStyle(.green)
        }
    }

    private func loadDeviceMeasuredInputs() {
        IOS26BubbleColorPreviewStore.loadDeviceMeasuredInputs()
        redText = IOS26BubbleColorPreviewStore.redText
        greenText = IOS26BubbleColorPreviewStore.greenText
        blueText = IOS26BubbleColorPreviewStore.blueText
        hexText = IOS26BubbleColorPreviewStore.hexText
    }

    private func persistInputs() {
        IOS26BubbleColorPreviewStore.redText = redText
        IOS26BubbleColorPreviewStore.greenText = greenText
        IOS26BubbleColorPreviewStore.blueText = blueText
        IOS26BubbleColorPreviewStore.hexText = hexText
        IOS26BubbleColorPreviewStore.topSampleText = topSampleText
        IOS26BubbleColorPreviewStore.midSampleText = midSampleText
        IOS26BubbleColorPreviewStore.bottomSampleText = bottomSampleText
    }
}
