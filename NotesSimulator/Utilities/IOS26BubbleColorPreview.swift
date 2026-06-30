import SwiftUI
import UIKit

/// iOS 26 发送气泡实色预览：支持数码测色计 RGB / Hex 输入（仅预览，不改真实气泡）。
enum IOS26BubbleColorPreview {
    /// 真机目标 · 顶（调节面板对照用，非代码填色）
    static let deviceTargetTop = UIColor(red: 0.433, green: 0.729, blue: 0.960, alpha: 1)
    static let deviceTargetMid = UIColor(red: 0.377, green: 0.677, blue: 0.965, alpha: 1)
    static let deviceTargetBottom = UIColor(red: 0.320, green: 0.625, blue: 0.969, alpha: 1)

    static var deviceMeasuredUIColor: UIColor { deviceTargetMid }

    static var frozenUIColor: UIColor {
        IMessageDesignTokens.bubbleBlueFill
    }

    static var deviceMeasuredRGBA01: (red: CGFloat, green: CGFloat, blue: CGFloat) {
        let c = deviceMeasuredUIColor.rgbaComponents
        return (c.r, c.g, c.b)
    }

    static var deviceMeasuredRGB888: (red: Int, green: Int, blue: Int) {
        let c = deviceMeasuredRGBA01
        return (
            Int(round(c.red * 255)),
            Int(round(c.green * 255)),
            Int(round(c.blue * 255))
        )
    }

    static func color(red: Int, green: Int, blue: Int) -> UIColor {
        UIColor(
            red: CGFloat(clampByte(red)) / 255,
            green: CGFloat(clampByte(green)) / 255,
            blue: CGFloat(clampByte(blue)) / 255,
            alpha: 1
        )
    }

    static func parseRGBInputs(_ red: String, _ green: String, _ blue: String) -> UIColor? {
        guard let r = parseComponent(red),
              let g = parseComponent(green),
              let b = parseComponent(blue) else {
            return nil
        }
        return UIColor(red: r, green: g, blue: b, alpha: 1)
    }

    static func parseHex(_ text: String) -> UIColor? {
        var hex = text.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if hex.hasPrefix("#") {
            hex.removeFirst()
        }
        guard hex.count == 6, let value = Int(hex, radix: 16) else {
            return nil
        }
        return color(
            red: (value >> 16) & 0xFF,
            green: (value >> 8) & 0xFF,
            blue: value & 0xFF
        )
    }

    static func resolvedMeasuredColor(red: String, green: String, blue: String, hex: String) -> UIColor? {
        if !hex.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           let color = parseHex(hex) {
            return color
        }
        return parseRGBInputs(red, green, blue)
    }

    /// 解析「0.337,0.635,0.961」或「86 162 245」形式的多点测色。
    static func parseSampleLine(_ text: String) -> UIColor? {
        let parts = text
            .split { $0 == "," || $0 == " " || $0 == ";" || $0 == "\t" }
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        guard parts.count >= 3 else { return nil }
        return parseRGBInputs(String(parts[0]), String(parts[1]), String(parts[2]))
    }

    static func averageColor(_ colors: [UIColor]) -> UIColor? {
        guard !colors.isEmpty else { return nil }
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        for color in colors {
            let c = color.rgbaComponents
            red += c.r
            green += c.g
            blue += c.b
        }
        let count = CGFloat(colors.count)
        return UIColor(red: red / count, green: green / count, blue: blue / count, alpha: 1)
    }

    static func exportGradientText(top: UIColor, mid: UIColor, bottom: UIColor, average: UIColor?) -> String {
        let topRGBA = top.rgbaComponents
        let midRGBA = mid.rgbaComponents
        let bottomRGBA = bottom.rgbaComponents
        var lines = """
        iOS26 bubble multi-sample preview
        strategy: vertical 3-stop gradient (top / mid / bottom)
        topRGBA01: \(fmt(topRGBA.r)), \(fmt(topRGBA.g)), \(fmt(topRGBA.b))
        midRGBA01: \(fmt(midRGBA.r)), \(fmt(midRGBA.g)), \(fmt(midRGBA.b))
        bottomRGBA01: \(fmt(bottomRGBA.r)), \(fmt(bottomRGBA.g)), \(fmt(bottomRGBA.b))
        """
        if let average {
            let avg = average.rgbaComponents
            lines += """

            averageRGBA01: \(fmt(avg.r)), \(fmt(avg.g)), \(fmt(avg.b))
            """
        }
        return lines
    }

    static func exportGradientText(top: UIColor, bottom: UIColor, average: UIColor?) -> String {
        exportGradientText(
            top: top,
            mid: average ?? top,
            bottom: bottom,
            average: average
        )
    }

    static func exportText(for uiColor: UIColor, source: String) -> String {
        let rgba = uiColor.rgbaComponents
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

        let frozen = frozenUIColor.rgbaComponents
        let r8 = Int(round(rgba.r * 255))
        let g8 = Int(round(rgba.g * 255))
        let b8 = Int(round(rgba.b * 255))

        return """
        iOS26 bubble measured preview
        source: \(source)
        hex: #\(String(format: "%02X%02X%02X", r8, g8, b8))
        RGB888: \(r8), \(g8), \(b8)
        RGBA01: \(fmt(rgba.r)), \(fmt(rgba.g)), \(fmt(rgba.b)), \(fmt(rgba.a))
        HSB: \(fmt(hue)), \(fmt(saturation)), \(fmt(brightness))
        frozenRGBA01: \(fmt(frozen.r)), \(fmt(frozen.g)), \(fmt(frozen.b))
        """
    }

    private static func parseComponent(_ text: String) -> CGFloat? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }

        if trimmed.contains(".") {
            guard let value = Double(trimmed), value >= 0, value <= 1 else { return nil }
            return CGFloat(value)
        }

        guard let value = Int(trimmed), value >= 0, value <= 255 else { return nil }
        return CGFloat(value) / 255
    }

    private static func clampByte(_ value: Int) -> Int {
        min(max(value, 0), 255)
    }

    private static func fmt(_ value: CGFloat) -> String {
        String(format: "%.4f", value)
    }
}

/// 气泡颜色校准用标准文案：固定高度使顶/底渐变频带与取样点对齐。
enum IOS26BubbleColorCalibration {
    /// 第一行；测色计取行内右侧 `1` 旁平坦蓝区（气泡顶）
    static let topLine = "1。                                                     1"
    /// 最后一行；测色计取行内右侧 `1` 旁平坦蓝区（气泡底）
    static let bottomLine = "1。                             1"
    /// 中间空行数（不含顶/底），共 16 行气泡
    static let blankLineCount = 14

    static var messageText: String {
        topLine + String(repeating: "\n", count: blankLineCount) + bottomLine
    }

    static var lineCount: Int { blankLineCount + 2 }

    static let samplingNote = """
    标准校准气泡共 \(lineCount) 行：第 1 行=顶色，第 \(lineCount) 行=底色。\
    填色以中色为锚，行数↑则色值向顶/底对称扩展（1 行≈中色±1/32，16 行=顶→底全段）。
    """
}

enum IOS26BubbleColorPreviewStore {
    private static let redKey = "IOS26BubbleMeasuredRed.v2"
    private static let greenKey = "IOS26BubbleMeasuredGreen.v2"
    private static let blueKey = "IOS26BubbleMeasuredBlue.v2"
    private static let hexKey = "IOS26BubbleMeasuredHex.v2"

    static var redText: String {
        get { UserDefaults.standard.string(forKey: redKey) ?? defaultRedText }
        set { UserDefaults.standard.set(newValue, forKey: redKey) }
    }

    static var greenText: String {
        get { UserDefaults.standard.string(forKey: greenKey) ?? defaultGreenText }
        set { UserDefaults.standard.set(newValue, forKey: greenKey) }
    }

    static var blueText: String {
        get { UserDefaults.standard.string(forKey: blueKey) ?? defaultBlueText }
        set { UserDefaults.standard.set(newValue, forKey: blueKey) }
    }

    static var hexText: String {
        get { UserDefaults.standard.string(forKey: hexKey) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: hexKey) }
    }

    static var defaultRedText: String { "0.377" }
    static var defaultGreenText: String { "0.677" }
    static var defaultBlueText: String { "0.965" }

    static var defaultTopSampleText: String { "0.433,0.729,0.960" }
    static var defaultMidSampleText: String { "0.377,0.677,0.965" }
    static var defaultBottomSampleText: String { "0.320,0.625,0.969" }

    static func loadDeviceMeasuredInputs() {
        redText = defaultRedText
        greenText = defaultGreenText
        blueText = defaultBlueText
        hexText = ""
        topSampleText = defaultTopSampleText
        midSampleText = defaultMidSampleText
        bottomSampleText = defaultBottomSampleText
    }

    private static let topSampleKey = "IOS26BubbleTopSample.v1"
    private static let midSampleKey = "IOS26BubbleMidSample.v1"
    private static let bottomSampleKey = "IOS26BubbleBottomSample.v1"

    static var midSampleText: String {
        get { UserDefaults.standard.string(forKey: midSampleKey) ?? defaultMidSampleText }
        set { UserDefaults.standard.set(newValue, forKey: midSampleKey) }
    }

    static var bottomSampleText: String {
        get { UserDefaults.standard.string(forKey: bottomSampleKey) ?? defaultBottomSampleText }
        set { UserDefaults.standard.set(newValue, forKey: bottomSampleKey) }
    }

    static var topSampleText: String {
        get { UserDefaults.standard.string(forKey: topSampleKey) ?? defaultTopSampleText }
        set { UserDefaults.standard.set(newValue, forKey: topSampleKey) }
    }
}
