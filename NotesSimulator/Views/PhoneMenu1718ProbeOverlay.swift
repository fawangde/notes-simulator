import SwiftUI

/// 开发用：框线 + 数值，对照系统备忘录截图调 `PhoneMenu1718Layout.Design`
struct PhoneMenu1718ProbeOverlay: View {
    let presentation: PhoneMenuPresentation
    let anchor: CGRect
    let previewFrame: CGRect
    let menuFrame: CGRect
    let screenSize: CGSize
    let safeTop: CGFloat
    let safeBottom: CGFloat
    let previewMenuGap: CGFloat

    private var report: String {
        let sw = screenSize.width
        let sh = screenSize.height
        var lines: [String] = [
            "screen: \(Int(sw))×\(Int(sh)) safeT=\(Int(safeTop)) safeB=\(Int(safeBottom))",
            "anchor: \(fmt(anchor))",
        ]
        if presentation == .longPress, previewFrame != .zero {
            lines.append("preview: \(fmt(previewFrame)) r=\(PhoneMenu1718Layout.Design.previewCornerRadius)")
            lines.append("  margin L=\(Int(previewFrame.minX)) R=\(Int(sw - previewFrame.maxX)) T=\(Int(previewFrame.minY))")
        }
        if menuFrame != .zero {
            lines.append("menu: \(fmt(menuFrame)) r=\(PhoneMenu1718Layout.Design.menuCornerRadius)")
            lines.append("  margin L=\(Int(menuFrame.minX)) R=\(Int(sw - menuFrame.maxX)) B=\(Int(sh - menuFrame.maxY))")
        }
        if presentation == .longPress, previewFrame != .zero, menuFrame != .zero {
            lines.append("gap preview→menu: \(String(format: "%.1f", previewMenuGap))")
        }
        return lines.joined(separator: "\n")
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            if anchor != .zero {
                probeRect(anchor, color: .green, label: "anchor")
            }
            if presentation == .longPress, previewFrame != .zero {
                probeRect(previewFrame, color: .orange, label: "preview")
            }
            if menuFrame != .zero {
                probeRect(menuFrame, color: .cyan, label: "menu")
            }

            Text(report)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(.white)
                .padding(8)
                .background(.black.opacity(0.72), in: RoundedRectangle(cornerRadius: 8))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                .padding(12)
                .allowsHitTesting(false)
        }
        .allowsHitTesting(false)
    }

    private func probeRect(_ rect: CGRect, color: Color, label: String) -> some View {
        ZStack(alignment: .topLeading) {
            Rectangle()
                .stroke(color, lineWidth: 2)
                .background(color.opacity(0.08))
                .frame(width: rect.width, height: rect.height)
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(color)
                .padding(2)
                .background(.black.opacity(0.5), in: RoundedRectangle(cornerRadius: 3))
                .offset(x: 4, y: 4)
        }
        .offset(x: rect.minX, y: rect.minY)
    }

    private func fmt(_ r: CGRect) -> String {
        "\(Int(r.minX)),\(Int(r.minY)) \(Int(r.width))×\(Int(r.height))"
    }
}
