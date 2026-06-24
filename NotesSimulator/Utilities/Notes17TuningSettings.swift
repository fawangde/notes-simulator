import SwiftUI
import UIKit

/// iOS 17 备忘录 / 长按菜单调参（开发对照 reference 用）
struct Notes17TuningSettings: Codable, Equatable {
    var bodyFontSize: Double = 16
    var phoneFontSize: Double = 16
    var titleFontSize: Double = 29
    /// 0 = 偏深（label），1 = 偏浅（secondaryLabel）
    var themeTextGrayness: Double = 0.50
    var avatarSize: Double = 55
    var previewPhoneFontSize: Double = 15
    var previewPhoneGrayness: Double = 0
    /// 预览泡左右边距在 15pt 基础上各再加（pt）
    var previewSideMarginExtra: Double = 5
    /// 预览泡内头像 + 号码整体放大倍率
    var previewContentScale: Double = 1.0
    /// 预览泡内头像 + 号码整体左移（pt）
    var previewContentShiftLeft: Double = 3
    /// 已废弃：预览泡现跟随纸面，保留字段兼容旧存档
    var previewBubbleGrayness: Double = 0
    var menuPanelGrayness: Double = 0.40
    /// 0 = 原灰，1 = 更偏青灰水泥色
    var menuPanelCyanGrayness: Double = 0.08
    /// 0 = label 纯黑，1 = secondaryLabel
    var menuIconGrayness: Double = 0
    /// 0 = label 纯黑，1 = secondaryLabel（仅菜单行文字，不含图标）
    var menuLabelGrayness: Double = 0.18
    var menuIconSize: Double = 18
    /// 备忘录纸面压暗（0…1，轻微整体变暗）
    var notesPaperDim: Double = 0.03
    /// 备忘录纸面暖感（0…1，仅极微降蓝）
    var notesPaperWarmth: Double = 0.02
    /// 长按全屏黑色压暗（仅 dim，不模糊背景）
    var longPressOverlayDim: Double = 0.37
    /// 长按时正文/标题文字模糊半径（pt，纸面不糊）
    var longPressTextBlurRadius: Double = 5.5
    /// 菜单宽度在基准值上缩减（pt，10…30）
    var menuWidthReduction: Double = 0
    /// 菜单顶栏号码字号（pt）
    var menuHeaderPhoneFontSize: Double = 11
    /// iOS 16–18 气泡尾巴样式（见 `IMessage17BubbleTailPreset`）
    var bubbleTailPresetID: String = IMessage17BubbleTailPreset.defaultPresetID
    /// 启用手动滑块微调（仅 Tutorial 样式）
    var bubbleTailManualTuningEnabled: Bool = false
    /// Tutorial：右缘竖线 X 内收（0 = 贴齐右缘）
    var tutorialRightLineInsetX: Double = 0
    /// Tutorial：尖向右伸出（相对本体右缘，落点 y=h）
    var tutorialTailExtension: Double = 8
    /// Tutorial：尖向下（新拓扑尖在底边 y=h，保留 0）
    var tutorialTailDrop: Double = 0
    /// Tutorial：底边根距右缘向左
    var tutorialTailRootAlongBottom: Double = 18
    /// Tutorial：下弧外凸向下
    var tutorialHookBulge: Double = 3
    /// Tutorial：上弧沿右缘继续向下的 lead
    var tutorialUpperLeadY: Double = 4
    /// Tutorial：下弧 CP1 相对尖向左外扩
    var tutorialLowerArcCurvature: Double = 5
    /// Tutorial：下弧 CP2 相对 hook 向左（厚度）
    var tutorialLowerLeftBulge: Double = 4

    // MARK: - 尾巴锚点编辑器（5× 网格）

    /// 描点定稿时参考的本体宽（pt）
    var tailAnchorRefBodyWidth: Double = 189
    /// 描点定稿时参考的本体高（pt）
    var tailAnchorRefBodyHeight: Double = 50
    /// 当前选中的锚点 0…3（A…D）
    var tailAnchorSelectedIndex: Int = 0
    var tailAnchor0X: Double = 189
    var tailAnchor0Y: Double = 29.60
    var tailAnchor1X: Double = 189
    var tailAnchor1Y: Double = 40.30
    var tailAnchor2X: Double = 194.40
    var tailAnchor2Y: Double = 49.10
    var tailAnchor3X: Double = 179.20
    var tailAnchor3Y: Double = 42.80
    var tailAnchorSegment0Kind: String = BubbleTail1718SegmentKind.upperStraight.rawValue
    var tailAnchorSegment1Kind: String = BubbleTail1718SegmentKind.upperArc.rawValue
    var tailAnchorSegment2Kind: String = BubbleTail1718SegmentKind.lowerArc.rawValue
    var tailAnchorSegment0Curvature: Double = 0
    var tailAnchorSegment1Curvature: Double = 2
    var tailAnchorSegment2Curvature: Double = 4
    /// 描点填充：false=本体+楔形；true=仅本体（空尾巴，彩色描边便于画笔填色）
    var plottedTailFillBodyOnly: Bool = false
    /// 描点定稿版本；低于当前值时 load 会强制写回 production 描点
    var tailAnchorRevision: Int = 13

    /// 探针参考图叠加强度（BubbleRefTailCrop17；撰写页点「探针」后生效）
    var bubbleReferenceOverlayOpacity: Double = 0.80
    /// 参考图相对锚点 X 偏移（pt，正=右）
    var bubbleReferenceOffsetX: Double = 2
    /// 参考图相对锚点 Y 偏移（pt，正=下）
    var bubbleReferenceOffsetY: Double = 4
    /// 参考图缩放（1 = 默认大小）
    var bubbleReferenceScale: Double = 0.50

    // MARK: - 头像图形（同心圆弧肩）

    /// 0 = systemGray4，1 = 更浅
    var avatarCircleGrayness: Double = 0
    /// 内弧半径 / 外圈半径（同心，越小肩弧越靠内）
    var avatarInnerRadiusRatio: Double = 0.78
    /// 头径 / 外圈直径
    var avatarHeadDiameterRatio: Double = 0.34
    /// 头心 Y / 外圈直径（自顶向下）
    var avatarHeadCenterYRatio: Double = 0.36
    /// 颈半宽 / 头半径
    var avatarNeckHalfWidthRatio: Double = 0.62
    /// 颈线相对头心的下移（× 头半径）
    var avatarNeckDropRatio: Double = 0.08
    /// 肩弧张角（度），底弧与外圈同心
    var avatarShoulderArcSpanDegrees: Double = 148
    /// 整体人形下移（× 外圈直径，正值往下拉）
    var avatarPersonOffsetYRatio: Double = 0.04

    static let `default` = Notes17TuningSettings()

    mutating func resetAvatarDefaults() {
        avatarCircleGrayness = 0
        avatarInnerRadiusRatio = 0.78
        avatarHeadDiameterRatio = 0.34
        avatarHeadCenterYRatio = 0.36
        avatarNeckHalfWidthRatio = 0.62
        avatarNeckDropRatio = 0.08
        avatarShoulderArcSpanDegrees = 148
        avatarPersonOffsetYRatio = 0.04
    }

    func avatarCircleUIColor() -> UIColor {
        let t = CGFloat(min(max(avatarCircleGrayness, 0), 1))
        guard t > 0 else { return UIColor.systemGray4 }
        return UIColor { _ in
            let g4 = UIColor.systemGray4
            let g3 = UIColor.systemGray3
            var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
            var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
            g4.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
            g3.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
            return UIColor(
                red: r1 + (r2 - r1) * t,
                green: g1 + (g2 - g1) * t,
                blue: b1 + (b2 - b1) * t,
                alpha: a1 + (a2 - a1) * t
            )
        }
    }

    func themeTextUIColor() -> UIColor {
        Self.blendedGrayUIColor(amount: themeTextGrayness)
    }

    func previewPhoneUIColor() -> UIColor {
        Self.blendedGrayUIColor(amount: previewPhoneGrayness)
    }

    func menuIconUIColor() -> UIColor {
        Self.blendedGrayUIColor(amount: menuIconGrayness)
    }

    func menuLabelUIColor() -> UIColor {
        Self.blendedGrayUIColor(amount: menuLabelGrayness)
    }

    func paperBackgroundColor() -> Color {
        Color(uiColor: paperBackgroundUIColor())
    }

    func paperBackgroundUIColor() -> UIColor {
        guard notesPaperDim > 0 || notesPaperWarmth > 0 else {
            return NotesStyle17Tokens.paperUIColor
        }
        let gray6 = NotesStyle17Tokens.paperUIColor
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        gray6.getRed(&r, green: &g, blue: &b, alpha: &a)
        return Self.warmDimmedUIColor(
            base: (Double(r), Double(g), Double(b)),
            warmth: notesPaperWarmth,
            dim: notesPaperDim
        )
    }

    /// 预览泡 / 小白底与备忘录纸面同色，回收时与背景无缝融合
    func previewBubbleFillColor() -> Color {
        paperBackgroundColor()
    }

    func menuPanelTintColor() -> Color {
        Self.menuPanelColor(grayness: menuPanelGrayness, cyanGrayness: menuPanelCyanGrayness)
    }

    private static func menuPanelColor(grayness: Double, cyanGrayness: Double) -> Color {
        let gray = min(max(grayness, 0), 1)
        let cyan = min(max(cyanGrayness, 0), 1)
        let warmCement = (red: 0.84, green: 0.835, blue: 0.805)
        var red = 1 + (warmCement.red - 1) * gray
        var green = 1 + (warmCement.green - 1) * gray
        var blue = 1 + (warmCement.blue - 1) * gray
        let cyanCement = (red: 0.76, green: 0.795, blue: 0.815)
        red = red + (cyanCement.red - red) * cyan
        green = green + (cyanCement.green - green) * cyan
        blue = blue + (cyanCement.blue - blue) * cyan
        return Color(red: red, green: green, blue: blue)
    }

    var bodyPhoneLineHeight: CGFloat {
        CGFloat(22 * bodyFontSize / 19)
    }

    var bodyPhoneParagraphSpacing: CGFloat {
        CGFloat(7 * bodyFontSize / 19)
    }

    private static func warmDimmedRGB(
        base: (red: Double, green: Double, blue: Double),
        warmth: Double,
        dim: Double
    ) -> (red: Double, green: Double, blue: Double) {
        let w = min(max(warmth, 0), 1)
        let d = min(max(dim, 0), 1)
        let darken = 1 - d * 0.035
        let red = base.red * darken
        let green = base.green * darken
        let blue = base.blue * darken * (1 - w * 0.01)
        return (
            red: min(max(red, 0), 1),
            green: min(max(green, 0), 1),
            blue: min(max(blue, 0), 1)
        )
    }

    private static func warmDimmedUIColor(
        base: (red: Double, green: Double, blue: Double),
        warmth: Double,
        dim: Double
    ) -> UIColor {
        let rgb = warmDimmedRGB(base: base, warmth: warmth, dim: dim)
        return UIColor(red: rgb.red, green: rgb.green, blue: rgb.blue, alpha: 1)
    }

    private static func blendedGrayUIColor(amount: Double) -> UIColor {
        let t = CGFloat(min(max(amount, 0), 1))
        return UIColor { traits in
            let label = UIColor.label.resolvedColor(with: traits)
            let secondary = UIColor.secondaryLabel.resolvedColor(with: traits)
            var lr: CGFloat = 0, lg: CGFloat = 0, lb: CGFloat = 0, la: CGFloat = 0
            var sr: CGFloat = 0, sg: CGFloat = 0, sb: CGFloat = 0, sa: CGFloat = 0
            label.getRed(&lr, green: &lg, blue: &lb, alpha: &la)
            secondary.getRed(&sr, green: &sg, blue: &sb, alpha: &sa)
            return UIColor(
                red: lr + (sr - lr) * t,
                green: lg + (sg - lg) * t,
                blue: lb + (sb - lb) * t,
                alpha: la + (sa - la) * t
            )
        }
    }

    private static func blendedPanelColor(
        base: (red: Double, green: Double, blue: Double),
        grayness: Double,
        baseOpacity: Double = 1
    ) -> Color {
        let t = min(max(grayness, 0), 1)
        let target = (red: 0.84, green: 0.835, blue: 0.805)
        return Color(
            red: base.red + (target.red - base.red) * t,
            green: base.green + (target.green - base.green) * t,
            blue: base.blue + (target.blue - base.blue) * t,
            opacity: baseOpacity
        )
    }
}

enum Notes17TuningStore {
    private static let key = "Notes17Tuning.v35"
    private static let legacyKey = "Notes17Tuning.v34"
    private static let tailAnchorRevisionCurrent = 13

    static func load() -> Notes17TuningSettings {
        let data = UserDefaults.standard.data(forKey: key)
            ?? UserDefaults.standard.data(forKey: legacyKey)
        guard let data,
              var settings = try? JSONDecoder().decode(Notes17TuningSettings.self, from: data) else {
            return .default
        }
        settings = migrateBubbleTailPreset(settings)
        settings = migrateBubbleTailTutorialParams(settings)
        settings = migrateTailAnchorTopology(settings)
        settings = migrateTailAnchorReferenceBody(settings)
        settings = migrateTailAnchorRevision(settings)
        return settings
    }

    /// 强制写回当前定稿描点（旧存档 / 手调残留）
    private static func migrateTailAnchorRevision(_ settings: Notes17TuningSettings) -> Notes17TuningSettings {
        var migrated = settings
        guard migrated.tailAnchorRevision < tailAnchorRevisionCurrent else { return migrated }
        migrated.resetTailAnchorDefaults()
        migrated.bubbleTailPresetID = IMessage17BubbleTailPreset.defaultPresetID
        migrated.bubbleTailManualTuningEnabled = false
        migrated.plottedTailFillBodyOnly = false
        migrated.tailAnchorRevision = tailAnchorRevisionCurrent
        save(migrated)
        return migrated
    }

    /// 旧版 120×44 绝对坐标 → 真机定稿 189×50 + BR 偏移存储
    private static func migrateTailAnchorReferenceBody(_ settings: Notes17TuningSettings) -> Notes17TuningSettings {
        var migrated = settings
        guard migrated.tailAnchorRefBodyWidth <= 0 || migrated.tailAnchorRefBodyHeight <= 0 else {
            return migrated
        }
        let legacy120 = migrated.tailAnchor0X <= 121
            && migrated.tailAnchor1X <= 121
            && migrated.tailAnchor2X <= 132
        if legacy120 {
            migrated.resetTailAnchorDefaults()
        } else {
            migrated.tailAnchorRefBodyWidth = 189
            migrated.tailAnchorRefBodyHeight = 50
        }
        save(migrated)
        return migrated
    }

    /// 旧 A→B 上弧 / C→D 直线 → A→B 直线、B→C 上弧、C→D 下弧，C=尖
    private static func migrateTailAnchorTopology(_ settings: Notes17TuningSettings) -> Notes17TuningSettings {
        var migrated = settings
        let oldTopology = migrated.tailAnchorSegment0Kind == BubbleTail1718SegmentKind.upperArc.rawValue
            && migrated.tailAnchorSegment2Kind == BubbleTail1718SegmentKind.upperStraight.rawValue
        let tipOnB = migrated.tailAnchor1X > 127 && abs(migrated.tailAnchor1Y - 44) < 1
        guard oldTopology || tipOnB else { return migrated }
        migrated.resetTailAnchorDefaults()
        save(migrated)
        return migrated
    }

    /// 旧 Tutorial 默认 → hookStart=y−r/2、尖 w+8@h
    private static func migrateBubbleTailTutorialParams(_ settings: Notes17TuningSettings) -> Notes17TuningSettings {
        var migrated = settings
        let stale = migrated.tutorialTailExtension < 7.5 || migrated.tutorialTailDrop > 0.5
        guard stale else { return migrated }
        migrated.tutorialTailExtension = 8
        migrated.tutorialTailDrop = 0
        migrated.tutorialTailRootAlongBottom = 18
        migrated.tutorialHookBulge = 3
        migrated.tutorialUpperLeadY = 4
        migrated.tutorialLowerArcCurvature = 5
        migrated.tutorialLowerLeftBulge = 4
        save(migrated)
        return migrated
    }

    /// 旧预设 → 截图描边（唯一默认）
    private static func migrateBubbleTailPreset(_ settings: Notes17TuningSettings) -> Notes17TuningSettings {
        var migrated = settings
        let legacyPresets: Set<String> = [
            "src_messagekit_tutorial",
            "ims_send_bubble",
            "ref_user_tail_image",
        ]
        guard legacyPresets.contains(migrated.bubbleTailPresetID) else { return migrated }
        migrated.bubbleTailPresetID = IMessage17BubbleTailPreset.defaultPresetID
        migrated.bubbleTailManualTuningEnabled = false
        save(migrated)
        return migrated
    }

    static func save(_ settings: Notes17TuningSettings) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}

extension Notes17TuningSettings {
    var summaryLines: [String] {
        [
            "正文 \(fmt(bodyFontSize)) pt · 号码 \(fmt(phoneFontSize)) pt · 标题 \(fmt(titleFontSize)) pt",
            "主题灰 \(pct(themeTextGrayness)) · 纸面压暗 \(pct(notesPaperDim)) · 纸面暖感 \(pct(notesPaperWarmth))",
            "预览号码 \(fmt(previewPhoneFontSize)) pt · 灰 \(pct(previewPhoneGrayness)) · 左移 \(Int(previewContentShiftLeft)) pt",
            "头像 \(Int(avatarSize)) pt · 预览泡=纸面 · 内容 \(fmt(previewContentScale))×",
            "预览边距 +\(Int(previewSideMarginExtra)) pt · 菜单宽 −\(Int(menuWidthReduction)) pt · 菜单灰 \(pct(menuPanelGrayness)) · 青灰 \(pct(menuPanelCyanGrayness))",
            "图标 \(fmt(menuIconSize)) pt · 文字灰 \(pct(menuLabelGrayness)) · 图标灰 \(pct(menuIconGrayness))",
            "压暗 \(pct(longPressOverlayDim)) · 文字模糊 \(fmt(longPressTextBlurRadius)) pt",
        ]
    }

    /// 单行 key=value，方便复制发回
    var exportText: String {
        [
            "bodyFontSize=\(fmt(bodyFontSize))",
            "phoneFontSize=\(fmt(phoneFontSize))",
            "titleFontSize=\(fmt(titleFontSize))",
            "themeTextGrayness=\(fmt(themeTextGrayness))",
            "avatarSize=\(fmt(avatarSize))",
            "previewPhoneFontSize=\(fmt(previewPhoneFontSize))",
            "previewPhoneGrayness=\(fmt(previewPhoneGrayness))",
            "previewSideMarginExtra=\(fmt(previewSideMarginExtra))",
            "previewContentScale=\(fmt(previewContentScale))",
            "previewContentShiftLeft=\(fmt(previewContentShiftLeft))",
            "previewBubbleGrayness=\(fmt(previewBubbleGrayness))",
            "menuPanelGrayness=\(fmt(menuPanelGrayness))",
            "menuPanelCyanGrayness=\(fmt(menuPanelCyanGrayness))",
            "menuIconGrayness=\(fmt(menuIconGrayness))",
            "menuLabelGrayness=\(fmt(menuLabelGrayness))",
            "menuIconSize=\(fmt(menuIconSize))",
            "notesPaperDim=\(fmt(notesPaperDim))",
            "notesPaperWarmth=\(fmt(notesPaperWarmth))",
            "longPressOverlayDim=\(fmt(longPressOverlayDim))",
            "longPressTextBlurRadius=\(fmt(longPressTextBlurRadius))",
            "menuWidthReduction=\(fmt(menuWidthReduction))",
            "menuHeaderPhoneFontSize=\(fmt(menuHeaderPhoneFontSize))",
        ].joined(separator: "\n")
    }

    var avatarExportText: String {
        [
            "avatarSize=\(fmt(avatarSize))",
            "avatarCircleGrayness=\(fmt(avatarCircleGrayness))",
            "avatarInnerRadiusRatio=\(fmt(avatarInnerRadiusRatio))",
            "avatarHeadDiameterRatio=\(fmt(avatarHeadDiameterRatio))",
            "avatarHeadCenterYRatio=\(fmt(avatarHeadCenterYRatio))",
            "avatarNeckHalfWidthRatio=\(fmt(avatarNeckHalfWidthRatio))",
            "avatarNeckDropRatio=\(fmt(avatarNeckDropRatio))",
            "avatarShoulderArcSpanDegrees=\(fmt(avatarShoulderArcSpanDegrees))",
            "avatarPersonOffsetYRatio=\(fmt(avatarPersonOffsetYRatio))",
        ].joined(separator: "\n")
    }

    /// 尾巴定稿参数（复制发给开发者写入代码）
    var bubbleTailExportText: String {
        let model = tailAnchorModel
        let labels = BubbleTail1718AnchorModel.labels
        var lines = [
            "bubbleTailPresetID=\(bubbleTailPresetID)",
            "anchorEditorBody=\(Int(tailAnchorRefBodyWidth))×\(Int(tailAnchorRefBodyHeight))",
            "anchorCoordOrigin=bodyTopLeft",
        ]
        for (index, point) in model.points.enumerated() {
            lines.append("tailAnchor\(labels[index])=(\(fmt(Double(point.x))), \(fmt(Double(point.y))))")
        }
        for index in 0 ..< model.segmentCount {
            let from = labels[index]
            let to = labels[index + 1]
            let kind = model.segmentKinds.indices.contains(index) ? model.segmentKinds[index].title : "?"
            let curve = model.segmentCurvatures.indices.contains(index)
                ? fmt(Double(model.segmentCurvatures[index])) : "0"
            lines.append("tailSegment\(from)\(to)=\(kind) curvature=\(curve)")
        }
        lines += [
            "--- legacy sliders ---",
            "bubbleTailManualTuningEnabled=\(bubbleTailManualTuningEnabled ? 1 : 0)",
            "tutorialTailExtension=\(fmt(tutorialTailExtension))",
            "tutorialTailRootAlongBottom=\(fmt(tutorialTailRootAlongBottom))",
            "tutorialUpperLeadY=\(fmt(tutorialUpperLeadY))",
            "tutorialHookBulge=\(fmt(tutorialHookBulge))",
            "tutorialLowerArcCurvature=\(fmt(tutorialLowerArcCurvature))",
            "tutorialLowerLeftBulge=\(fmt(tutorialLowerLeftBulge))",
        ]
        return lines.joined(separator: "\n")
    }

    private func fmt(_ value: Double) -> String {
        String(format: "%.2f", value)
    }

    private func pct(_ value: Double) -> String {
        "\(Int((value * 100).rounded()))%"
    }
}
