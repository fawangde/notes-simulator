import UIKit

/// 发送气泡蓝：Lab 空间多档插值，顶 / 中 / 底平滑融合；按标准校准行数等比缩放。
enum BubbleBlueGradient {
    static let stepCount = 13

    static var referenceLineCount: Int { IOS26BubbleColorCalibration.lineCount }

    /// 文案行数（含空行），与标准校准气泡一致按 `\n` 计数。
    static func lineCount(in text: String) -> Int {
        guard !text.isEmpty else { return 1 }
        return text.split(separator: "\n", omittingEmptySubsequences: false).count
    }

    /// 在标准 16 行曲线上，以中点 (t=0.5) 为锚、向上下对称扩展的半宽（16 行=0.5 → 全段 0…1）。
    static func referenceHalfSpan(forLineCount lineCount: Int) -> CGFloat {
        referenceSpan(forLineCount: lineCount) / 2
    }

    /// 当前行数在参考曲线上占用的总跨度（第 N 行 → N/16）。
    static func referenceSpan(forLineCount lineCount: Int) -> CGFloat {
        let total = referenceLineCount
        guard total > 0 else { return 1 }
        let lines = max(1, lineCount)
        return min(1, CGFloat(lines) / CGFloat(total))
    }

    /// 气泡纵向位置 p∈[0,1]（顶→底）映射到参考曲线，以中色为中心向上下扩。
    static func referenceProgress(forBubbleProgress bubbleProgress: CGFloat, lineCount: Int) -> CGFloat {
        let half = referenceHalfSpan(forLineCount: lineCount)
        let center: CGFloat = 0.5
        return min(max(center - half + bubbleProgress * (half * 2), 0), 1)
    }

    static func color(atReferenceProgress progress: CGFloat, top: UIColor, mid: UIColor, bottom: UIColor) -> UIColor {
        let p = min(max(progress, 0), 1)
        if p <= 0.5 {
            return blendInLab(from: top, to: mid, progress: p / 0.5)
        }
        return blendInLab(from: mid, to: bottom, progress: (p - 0.5) / 0.5)
    }

    static func colors(top: UIColor, mid: UIColor, bottom: UIColor) -> [UIColor] {
        scaledColors(lineCount: referenceLineCount, top: top, mid: mid, bottom: bottom)
    }

    /// 以中色为锚：行数↑则在参考曲线上向顶/底对称扩展（1 行≈中色±1/32，16 行=顶→底全段）。
    static func scaledColors(lineCount: Int, top: UIColor, mid: UIColor, bottom: UIColor) -> [UIColor] {
        guard stepCount > 1 else { return [mid] }
        return (0 ..< stepCount).map { index in
            let bubbleProgress = CGFloat(index) / CGFloat(stepCount - 1)
            let refProgress = referenceProgress(forBubbleProgress: bubbleProgress, lineCount: lineCount)
            return color(atReferenceProgress: refProgress, top: top, mid: mid, bottom: bottom)
        }
    }

    static func cgColors(top: UIColor, mid: UIColor, bottom: UIColor) -> [CGColor] {
        colors(top: top, mid: mid, bottom: bottom).map(\.cgColor)
    }

    static func scaledCGColors(lineCount: Int, top: UIColor, mid: UIColor, bottom: UIColor) -> [CGColor] {
        scaledColors(lineCount: lineCount, top: top, mid: mid, bottom: bottom).map(\.cgColor)
    }

    static func locations() -> [NSNumber] {
        guard stepCount > 1 else { return [0] }
        return (0 ..< stepCount).map { index in
            NSNumber(value: Float(index) / Float(stepCount - 1))
        }
    }

    static func scaledLocations(lineCount: Int) -> [NSNumber] {
        locations()
    }

    private static func blendInLab(from start: UIColor, to end: UIColor, progress: CGFloat) -> UIColor {
        let t = min(max(progress, 0), 1)
        let startLab = rgbToLab(start)
        let endLab = rgbToLab(end)
        return labToRGB(LabColor(
            L: startLab.L + (endLab.L - startLab.L) * Double(t),
            a: startLab.a + (endLab.a - startLab.a) * Double(t),
            b: startLab.b + (endLab.b - startLab.b) * Double(t)
        ))
    }

    private struct LabColor {
        var L: Double
        var a: Double
        var b: Double
    }

    private static func rgbToLab(_ color: UIColor) -> LabColor {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        func pivot(_ value: Double) -> Double {
            value > 0.04045 ? pow((value + 0.055) / 1.055, 2.4) : value / 12.92
        }

        let r = pivot(Double(red))
        let g = pivot(Double(green))
        let b = pivot(Double(blue))

        let x = (r * 0.4124564 + g * 0.3575761 + b * 0.1804375) / 0.95047
        let y = (r * 0.2126729 + g * 0.7151522 + b * 0.0721750) / 1.00000
        let z = (r * 0.0193339 + g * 0.1191920 + b * 0.9503041) / 1.08883

        func f(_ value: Double) -> Double {
            value > 0.008856 ? pow(value, 1.0 / 3.0) : (7.787 * value) + (16.0 / 116.0)
        }

        let fx = f(x)
        let fy = f(y)
        let fz = f(z)

        return LabColor(
            L: max(0, (116 * fy) - 16),
            a: 500 * (fx - fy),
            b: 200 * (fy - fz)
        )
    }

    private static func labToRGB(_ lab: LabColor) -> UIColor {
        let fy = (lab.L + 16) / 116
        let fx = lab.a / 500 + fy
        let fz = fy - lab.b / 200

        func fInv(_ t: Double) -> Double {
            let t3 = t * t * t
            return t3 > 0.008856 ? t3 : (t - 16.0 / 116.0) / 7.787
        }

        let x = fInv(fx) * 0.95047
        let y = fInv(fy) * 1.00000
        let z = fInv(fz) * 1.08883

        var r = x * 3.2404542 + y * -1.5371385 + z * -0.4985314
        var g = x * -0.9692660 + y * 1.8760108 + z * 0.0415560
        var b = x * 0.0556434 + y * -0.2040259 + z * 1.0572252

        func unpivot(_ value: Double) -> Double {
            value > 0.0031308 ? 1.055 * pow(value, 1 / 2.4) - 0.055 : 12.92 * value
        }

        r = unpivot(r)
        g = unpivot(g)
        b = unpivot(b)

        return UIColor(
            red: CGFloat(min(max(r, 0), 1)),
            green: CGFloat(min(max(g, 0), 1)),
            blue: CGFloat(min(max(b, 0), 1)),
            alpha: 1
        )
    }
}
