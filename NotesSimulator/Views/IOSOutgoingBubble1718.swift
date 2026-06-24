import UIKit

/// iOS 16–18 单发气泡：18pt 圆角 + 经典 hook 尾巴（与 iOS 26 ChatKit 路径无关）
enum IOSOutgoingBubblePath1718 {
    struct TailGeometry {
        let a: CGPoint
        let b: CGPoint
        let c: CGPoint
        let upperCP1: CGPoint
        let upperCP2: CGPoint
        let lowerCP1: CGPoint
        let lowerCP2: CGPoint
    }

    static func tailGeometry(
        bodyWidth: CGFloat,
        bodyHeight: CGFloat,
        params: IMessage1718BubbleTailParams
    ) -> TailGeometry {
        let w = bodyWidth
        let h = bodyHeight
        let a = CGPoint(x: w, y: h - params.tailRightEdgeInset)
        let b = CGPoint(x: w + params.tailTipExtension, y: h + params.tailTipDrop)
        let c = CGPoint(x: max(params.cornerRadius, w - params.tailRootAlongBottom), y: h)
        return TailGeometry(
            a: a,
            b: b,
            c: c,
            upperCP1: CGPoint(x: a.x + params.tailUpperCP1X, y: a.y + params.tailUpperCP1Y),
            upperCP2: CGPoint(x: a.x + params.tailUpperCP2X, y: a.y + params.tailUpperCP2Y),
            lowerCP1: CGPoint(x: b.x + params.tailLowerCP1X, y: b.y + params.tailLowerCP1Y),
            lowerCP2: CGPoint(x: b.x + params.tailLowerCP2X, y: b.y + params.tailLowerCP2Y)
        )
    }

    static func sentBubblePath(
        bodyWidth: CGFloat,
        bodyHeight: CGFloat,
        params: IMessage1718BubbleTailParams
    ) -> UIBezierPath {
        switch params.pathKind {
        case .classicHookCubic:
            return sentBubblePathClassicHookCubic(
                bodyWidth: bodyWidth,
                bodyHeight: bodyHeight,
                params: params,
                useQuad: false
            )
        case .classicHookQuad:
            return sentBubblePathClassicHookCubic(
                bodyWidth: bodyWidth,
                bodyHeight: bodyHeight,
                params: params,
                useQuad: true
            )
        case .ios26ChatKit:
            return sentBubblePathIOS26ChatKit(bodyWidth: bodyWidth, bodyHeight: bodyHeight)
        case .messageKitTutorial:
            return sentBubblePathMessageKitTutorial(bodyWidth: bodyWidth, bodyHeight: bodyHeight, params: params)
        case .messageKitPointed:
            return sentBubblePathMessageKitPointed(bodyWidth: bodyWidth, bodyHeight: bodyHeight, params: params)
        case .referenceImageTail:
            return sentBubblePathReferenceBody(bodyWidth: bodyWidth, bodyHeight: bodyHeight, params: params)
        case .imsSendBubble, .tracedScreenshot:
            if let model = params.resolvedPlottedAnchorTail(bodyWidth: bodyWidth, bodyHeight: bodyHeight),
               model.points.count >= 4 {
                return sentBubblePathPlottedAnchor(
                    bodyWidth: bodyWidth,
                    bodyHeight: bodyHeight,
                    params: params,
                    model: model
                )
            }
            return sentBubblePathMessageKitTutorial(
                bodyWidth: bodyWidth,
                bodyHeight: bodyHeight,
                params: params
            )
        }
    }

    /// 贴图尾巴：本体右下为直角，尾巴由 PNG 叠在右下
    private static func sentBubblePathReferenceBody(
        bodyWidth: CGFloat,
        bodyHeight: CGFloat,
        params: IMessage1718BubbleTailParams
    ) -> UIBezierPath {
        let w = bodyWidth
        let h = bodyHeight
        let r = min(params.cornerRadius, w / 2, h / 2)
        let path = UIBezierPath()
        path.move(to: CGPoint(x: r, y: 0))
        path.addLine(to: CGPoint(x: w - r, y: 0))
        path.addArc(
            withCenter: CGPoint(x: w - r, y: r),
            radius: r,
            startAngle: -.pi / 2,
            endAngle: 0,
            clockwise: true
        )
        path.addLine(to: CGPoint(x: w, y: h))
        path.addLine(to: CGPoint(x: r, y: h))
        path.addArc(
            withCenter: CGPoint(x: r, y: h - r),
            radius: r,
            startAngle: .pi / 2,
            endAngle: .pi,
            clockwise: true
        )
        path.addLine(to: CGPoint(x: 0, y: r))
        path.addArc(
            withCenter: CGPoint(x: r, y: r),
            radius: r,
            startAngle: .pi,
            endAngle: -.pi / 2,
            clockwise: true
        )
        path.close()
        return path
    }

    /// 真机 @3x 尾巴图内「尖」像素位置（`bubble_tail_true_alpha.png` 27×13）
    private static let referenceTailTipInAsset = CGPoint(x: 26.0 / 27.0, y: 10.0 / 13.0)

    /// 真机尾巴 PNG frame：尖对齐 `(bodyW + tailTipExtension, bodyH + tailTipDrop)`
    static func referenceTailImageFrame(
        bodyWidth: CGFloat,
        bodyHeight: CGFloat,
        params: IMessage1718BubbleTailParams
    ) -> CGRect {
        let imageSize = referenceTailImageSize(named: params.referenceTailImageName, params: params)
        let tipInImage = CGPoint(
            x: imageSize.width * referenceTailTipInAsset.x,
            y: imageSize.height * referenceTailTipInAsset.y
        )
        let tipWorld = CGPoint(
            x: bodyWidth + params.tailTipExtension,
            y: bodyHeight + params.tailTipDrop
        )
        return CGRect(
            x: tipWorld.x - tipInImage.x,
            y: tipWorld.y - tipInImage.y,
            width: imageSize.width,
            height: imageSize.height
        )
    }

    static func referenceTailImageSize(
        named imageName: String,
        params: IMessage1718BubbleTailParams
    ) -> CGSize {
        if let image = UIImage(named: imageName), image.size.width > 0, image.size.height > 0 {
            return image.size
        }
        return CGSize(width: params.referenceTailWidth, height: params.referenceTailHeight)
    }

    /// 按当前气泡色给尾巴 PNG 上色（与本体一致，深色模式也一致）
    static func referenceTailImage(named imageName: String, fill: UIColor) -> UIImage? {
        guard let source = UIImage(named: imageName) else { return nil }
        let format = UIGraphicsImageRendererFormat()
        format.scale = source.scale
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: source.size, format: format)
        return renderer.image { _ in
            fill.setFill()
            source.withRenderingMode(.alwaysTemplate)
                .draw(in: CGRect(origin: .zero, size: source.size))
        }
    }

    private static func sentBubblePathClassicHookCubic(
        bodyWidth: CGFloat,
        bodyHeight: CGFloat,
        params: IMessage1718BubbleTailParams,
        useQuad: Bool
    ) -> UIBezierPath {
        let r = min(params.cornerRadius, bodyWidth / 2, bodyHeight / 2)
        let w = bodyWidth
        let h = bodyHeight
        let tail = tailGeometry(bodyWidth: w, bodyHeight: h, params: params)

        let path = UIBezierPath()
        path.move(to: CGPoint(x: r, y: 0))
        path.addLine(to: CGPoint(x: w - r, y: 0))
        path.addArc(
            withCenter: CGPoint(x: w - r, y: r),
            radius: r,
            startAngle: -.pi / 2,
            endAngle: 0,
            clockwise: true
        )
        // iOS 16–18：右缘保持直线到 A（不做 ChatKit 右缘内收 cubic）
        path.addLine(to: tail.a)
        if useQuad {
            path.addQuadCurve(to: tail.b, controlPoint: tail.upperCP1)
            path.addQuadCurve(to: tail.c, controlPoint: tail.lowerCP1)
        } else {
            path.addCurve(to: tail.b, controlPoint1: tail.upperCP1, controlPoint2: tail.upperCP2)
            path.addCurve(to: tail.c, controlPoint1: tail.lowerCP1, controlPoint2: tail.lowerCP2)
        }
        path.addLine(to: CGPoint(x: r, y: h))
        path.addArc(
            withCenter: CGPoint(x: r, y: h - r),
            radius: r,
            startAngle: .pi / 2,
            endAngle: .pi,
            clockwise: true
        )
        path.addLine(to: CGPoint(x: 0, y: r))
        path.addArc(
            withCenter: CGPoint(x: r, y: r),
            radius: r,
            startAngle: .pi,
            endAngle: -.pi / 2,
            clockwise: true
        )
        path.close()
        return path
    }

    private static func sentBubblePathIOS26ChatKit(bodyWidth: CGFloat, bodyHeight: CGFloat) -> UIBezierPath {
        let shiftY: CGFloat = -4
        let flatBottom = max(34, bodyHeight - shiftY)
        return IOSOutgoingBubblePath.sentLastBubblePath(
            bodyWidth: bodyWidth,
            flatBottomY: flatBottom,
            tailScale: 1,
            tailShiftX: -0.7,
            tailOffsetY: shiftY
        )
    }

    /// iOS 16–18 hook：右缘直线 → 上弧(hook→尖) → 下弧(尖→hook) → 上接 BR
    struct TutorialHookLayout {
        let hookStart: CGPoint
        let tip: CGPoint
        let brArcTop: CGPoint
        let root: CGPoint
        let upperCP1: CGPoint
        let upperCP2: CGPoint
        let lowerCP1: CGPoint
        let lowerCP2: CGPoint
    }

    static func tutorialHookLayout(
        bodyWidth: CGFloat,
        bodyHeight: CGFloat,
        params: IMessage1718BubbleTailParams
    ) -> TutorialHookLayout {
        let w = bodyWidth
        let h = bodyHeight
        let r = min(params.cornerRadius, w / 2, h / 2)
        let hookStartY = h - r / 2
        let hookStart = CGPoint(x: w - params.tutorialRightLineInsetX, y: hookStartY)
        let tip = CGPoint(x: w + params.tailTipExtension, y: h)
        let brArcTop = CGPoint(x: w, y: h - r)
        let tipLeadX = w + max(2, params.tailTipExtension - 1.5)
        let lowerSpread = params.tutorialLowerArcCurvature
        let bulge = params.tutorialHookBulge
        let leftBulge = params.tutorialLowerLeftBulge
        return TutorialHookLayout(
            hookStart: hookStart,
            tip: tip,
            brArcTop: brArcTop,
            root: CGPoint(x: w - params.tailRootAlongBottom, y: h),
            upperCP1: CGPoint(x: hookStart.x, y: hookStart.y + params.tutorialUpperLeadY),
            upperCP2: CGPoint(x: tipLeadX, y: h),
            lowerCP1: CGPoint(x: tip.x - lowerSpread, y: h + bulge),
            lowerCP2: CGPoint(x: hookStart.x - leftBulge, y: hookStart.y - bulge * 0.6)
        )
    }

    /// 右缘直线 → 上弧 → 下弧回 hook（下弧 CP 左偏，避免与上弧重合成丝）→ BR
    private static func sentBubblePathMessageKitTutorial(
        bodyWidth: CGFloat,
        bodyHeight: CGFloat,
        params: IMessage1718BubbleTailParams
    ) -> UIBezierPath {
        let w = bodyWidth
        let h = bodyHeight
        let r = min(params.cornerRadius, w / 2, h / 2)
        let layout = tutorialHookLayout(bodyWidth: w, bodyHeight: h, params: params)

        let path = UIBezierPath()
        path.move(to: layout.root)
        append1718ShellFromRoot(to: path, bodyWidth: w, bodyHeight: h, cornerRadius: r)
        path.addLine(to: layout.hookStart)
        path.addCurve(
            to: layout.tip,
            controlPoint1: layout.upperCP1,
            controlPoint2: layout.upperCP2
        )
        path.addCurve(
            to: layout.hookStart,
            controlPoint1: layout.lowerCP1,
            controlPoint2: layout.lowerCP2
        )
        append1718TailRejoinAndBRCorner(
            to: path,
            bodyWidth: w,
            bodyHeight: h,
            cornerRadius: r,
            rootOnBottom: layout.root,
            rightEdgeJunctionY: layout.hookStart.y
        )
        path.close()
        return path
    }

    /// Tutorial 路径关键几何（图形探针 / 真机截图对照）
    struct TutorialProbeGeometry: Equatable {
        let rightEdgeTop: CGPoint
        let corner: CGPoint
        let tip: CGPoint
        let junction: CGPoint
        let root: CGPoint
        let upperCP1: CGPoint
        let upperCP2: CGPoint
        let lowerCP1: CGPoint
        let lowerCP2: CGPoint
        let rootCP1: CGPoint
        let rootCP2: CGPoint
    }

    static func tutorialProbeGeometry(
        bodyWidth: CGFloat,
        bodyHeight: CGFloat,
        params: IMessage1718BubbleTailParams
    ) -> TutorialProbeGeometry {
        let layout = tutorialHookLayout(bodyWidth: bodyWidth, bodyHeight: bodyHeight, params: params)
        return TutorialProbeGeometry(
            rightEdgeTop: layout.hookStart,
            corner: layout.brArcTop,
            tip: layout.tip,
            junction: layout.hookStart,
            root: layout.root,
            upperCP1: layout.upperCP1,
            upperCP2: layout.upperCP2,
            lowerCP1: layout.lowerCP1,
            lowerCP2: layout.lowerCP2,
            rootCP1: layout.root,
            rootCP2: layout.root
        )
    }

    /// MessageKit pointed / Medium 简线三角尾
    private static func sentBubblePathMessageKitPointed(
        bodyWidth: CGFloat,
        bodyHeight: CGFloat,
        params: IMessage1718BubbleTailParams
    ) -> UIBezierPath {
        let w = bodyWidth
        let h = bodyHeight
        let r = min(params.cornerRadius, w / 2, h / 2)
        let inset = params.tailRightEdgeInset
        let path = UIBezierPath()
        path.move(to: CGPoint(x: r, y: 0))
        path.addLine(to: CGPoint(x: w - r, y: 0))
        path.addArc(
            withCenter: CGPoint(x: w - r, y: r),
            radius: r,
            startAngle: -.pi / 2,
            endAngle: 0,
            clockwise: true
        )
        path.addLine(to: CGPoint(x: w, y: h - inset))
        path.addLine(to: CGPoint(x: w - 10, y: h))
        path.addLine(to: CGPoint(x: w - 10, y: h - 10))
        path.addLine(to: CGPoint(x: w, y: h - 10))
        path.addLine(to: CGPoint(x: r, y: h))
        path.addArc(
            withCenter: CGPoint(x: r, y: h - r),
            radius: r,
            startAngle: .pi / 2,
            endAngle: .pi,
            clockwise: true
        )
        path.addLine(to: CGPoint(x: 0, y: r))
        path.addArc(
            withCenter: CGPoint(x: r, y: r),
            radius: r,
            startAngle: .pi,
            endAngle: -.pi / 2,
            clockwise: true
        )
        path.close()
        return path
    }

    /// 不带尾巴的四角圆角本体（锚点编辑器）
    static func bodyOnlyRoundedRect(
        bodyWidth: CGFloat,
        bodyHeight: CGFloat,
        cornerRadius: CGFloat = IMessage1718DesignTokens.bubbleCornerRadius
    ) -> UIBezierPath {
        let w = bodyWidth
        let h = bodyHeight
        let r = min(cornerRadius, w / 2, h / 2)
        let path = UIBezierPath()
        appendBodyOnlyTopAndRight(to: path, bodyWidth: w, bodyHeight: h, cornerRadius: r)
        appendBodyOnlyBottomLeft(to: path, bodyWidth: w, bodyHeight: h, cornerRadius: r)
        path.close()
        return path
    }

    /// bodyOnly：顶边 + TR + 右缘到 brArcTop
    private static func appendBodyOnlyTopAndRight(
        to path: UIBezierPath,
        bodyWidth w: CGFloat,
        bodyHeight h: CGFloat,
        cornerRadius r: CGFloat
    ) {
        path.move(to: CGPoint(x: r, y: 0))
        path.addLine(to: CGPoint(x: w - r, y: 0))
        path.addArc(
            withCenter: CGPoint(x: w - r, y: r),
            radius: r,
            startAngle: -.pi / 2,
            endAngle: 0,
            clockwise: true
        )
        path.addLine(to: CGPoint(x: w, y: h - r))
    }

    /// bodyOnly：BR 弧 + 底边 + BL + 左 + TL（调用前 currentPoint 必须在 brArcTop）
    private static func appendBodyOnlyBottomLeft(
        to path: UIBezierPath,
        bodyWidth w: CGFloat,
        bodyHeight h: CGFloat,
        cornerRadius r: CGFloat
    ) {
        path.addArc(
            withCenter: CGPoint(x: w - r, y: h - r),
            radius: r,
            startAngle: 0,
            endAngle: .pi / 2,
            clockwise: true
        )
        appendBodyOnlyBottomLeftAfterCorner(to: path, bodyWidth: w, bodyHeight: h, cornerRadius: r)
    }

    /// bodyOnly：底边 + BL + 左 + TL（调用前 currentPoint 必须在 brCorner）
    private static func appendBodyOnlyBottomLeftAfterCorner(
        to path: UIBezierPath,
        bodyWidth w: CGFloat,
        bodyHeight h: CGFloat,
        cornerRadius r: CGFloat
    ) {
        path.addLine(to: CGPoint(x: r, y: h))
        path.addArc(
            withCenter: CGPoint(x: r, y: h - r),
            radius: r,
            startAngle: .pi / 2,
            endAngle: .pi,
            clockwise: true
        )
        path.addLine(to: CGPoint(x: 0, y: r))
        path.addArc(
            withCenter: CGPoint(x: r, y: r),
            radius: r,
            startAngle: .pi,
            endAngle: -.pi / 2,
            clockwise: true
        )
    }

    /// MessageKit / iOS26 同款：从底根逆时针画左下 → 左 → 顶 → TR（不含右缘下行与 BR）
    private static func append1718ShellFromRoot(
        to path: UIBezierPath,
        bodyWidth w: CGFloat,
        bodyHeight h: CGFloat,
        cornerRadius r: CGFloat
    ) {
        path.addLine(to: CGPoint(x: r, y: h))
        path.addArc(
            withCenter: CGPoint(x: r, y: h - r),
            radius: r,
            startAngle: .pi / 2,
            endAngle: .pi,
            clockwise: true
        )
        path.addLine(to: CGPoint(x: 0, y: r))
        path.addArc(
            withCenter: CGPoint(x: r, y: r),
            radius: r,
            startAngle: .pi,
            endAngle: -.pi / 2,
            clockwise: true
        )
        path.addLine(to: CGPoint(x: w - r, y: 0))
        path.addArc(
            withCenter: CGPoint(x: w - r, y: r),
            radius: r,
            startAngle: -.pi / 2,
            endAngle: 0,
            clockwise: true
        )
    }

    /// 尾巴结束后：落根 → 右缘 → brArcTop → **一次** BR 18pt 弧（与 MessageKit 322–330 相同）
    private static func append1718TailRejoinAndBRCorner(
        to path: UIBezierPath,
        bodyWidth w: CGFloat,
        bodyHeight h: CGFloat,
        cornerRadius r: CGFloat,
        rootOnBottom: CGPoint,
        rightEdgeJunctionY: CGFloat
    ) {
        let brArcTop = CGPoint(x: w, y: h - r)
        let junction = CGPoint(x: w, y: rightEdgeJunctionY)

        if abs(path.currentPoint.x - w) > 0.01 {
            if abs(path.currentPoint.y - h) > 0.01 || abs(path.currentPoint.x - rootOnBottom.x) > 0.01 {
                path.addLine(to: rootOnBottom)
            }
            path.addLine(to: CGPoint(x: w, y: h))
        }
        if abs(path.currentPoint.y - junction.y) > 0.01 {
            path.addLine(to: junction)
        }
        if abs(path.currentPoint.y - brArcTop.y) > 0.01 {
            path.addLine(to: brArcTop)
        }
        path.addArc(
            withCenter: CGPoint(x: w - r, y: h - r),
            radius: r,
            startAngle: 0,
            endAngle: .pi / 2,
            clockwise: true
        )
    }

    /// 描点尾巴填充：composite=本体+楔形；bodyOnly=仅本体（尾巴仅描边，便于自行填色）
    enum PlottedTailFillMode: String, Codable, Equatable {
        case composite
        case bodyOnly
    }

    /// A→B→C→D 曲线（不含落根与收口）
    private static func plottedAnchorTailCurvePath(
        bodyWidth w: CGFloat,
        bodyHeight h: CGFloat,
        cornerRadius r: CGFloat,
        model: BubbleTail1718AnchorModel
    ) -> UIBezierPath {
        let a = CGPoint(x: w, y: model.point(at: 0).y)
        let b = CGPoint(x: w, y: model.point(at: 1).y)
        let kinds = model.segmentKinds
        let curvatures = model.segmentCurvatures

        let path = UIBezierPath()
        path.move(to: a)
        if kinds.indices.contains(0), curvatures.indices.contains(0) {
            BubbleTail1718AnchorPathBuilder.appendSegment(
                to: path, from: a, to: b, kind: kinds[0], curvature: curvatures[0]
            )
        } else {
            path.addLine(to: b)
        }
        if kinds.indices.contains(1), curvatures.indices.contains(1) {
            BubbleTail1718AnchorPathBuilder.appendSegment(
                to: path, from: b, to: model.point(at: 2), kind: kinds[1], curvature: curvatures[1]
            )
        } else {
            path.addLine(to: model.point(at: 2))
        }
        if kinds.indices.contains(2), curvatures.indices.contains(2) {
            BubbleTail1718AnchorPathBuilder.appendSegment(
                to: path, from: model.point(at: 2), to: model.point(at: 3), kind: kinds[2], curvature: curvatures[2]
            )
        } else {
            path.addLine(to: model.point(at: 3))
        }
        return path
    }

    /// 尾巴 hook 楔形：A→曲线→D→落根 (D.x,h)→沿 D.x 上收到 A.y→横到右缘 A。
    /// 不走 y=h 底边横线（避免动 A 时蓝线钉在底边、曲线与底线之间误填）。
    private static func plottedAnchorTailProtrusionPath(
        bodyWidth w: CGFloat,
        bodyHeight h: CGFloat,
        cornerRadius r: CGFloat,
        model: BubbleTail1718AnchorModel,
        closed: Bool
    ) -> UIBezierPath {
        let a = CGPoint(x: w, y: model.point(at: 0).y)
        let rootOnBottom = CGPoint(x: model.point(at: 3).x, y: h)

        let path = plottedAnchorTailCurvePath(
            bodyWidth: w,
            bodyHeight: h,
            cornerRadius: r,
            model: model
        )

        if abs(path.currentPoint.y - h) > 0.01 || abs(path.currentPoint.x - rootOnBottom.x) > 0.01 {
            path.addLine(to: rootOnBottom)
        }

        guard closed else { return path }

        let rootX = path.currentPoint.x
        if abs(path.currentPoint.y - a.y) > 0.01 {
            path.addLine(to: CGPoint(x: rootX, y: a.y))
        }
        if abs(path.currentPoint.x - a.x) > 0.01 {
            path.addLine(to: a)
        }
        return path
    }

    /// 描点尾巴：bodyOnly（18pt 四角）+ 尾巴楔形；与 iOS26 同理分块拼合，不走自交单圈
    private static func sentBubblePathPlottedAnchor(
        bodyWidth: CGFloat,
        bodyHeight: CGFloat,
        params: IMessage1718BubbleTailParams,
        model: BubbleTail1718AnchorModel
    ) -> UIBezierPath {
        let r = min(params.cornerRadius, bodyWidth / 2, bodyHeight / 2)
        let body = bodyOnlyRoundedRect(
            bodyWidth: bodyWidth,
            bodyHeight: bodyHeight,
            cornerRadius: r
        )
        if params.plottedTailFillMode == .bodyOnly {
            return body
        }
        let wedge = plottedAnchorTailProtrusionFillPath(
            bodyWidth: bodyWidth,
            bodyHeight: bodyHeight,
            cornerRadius: r,
            model: model
        )
        body.append(wedge)
        return body
    }

    /// composite 填充楔形（右缘闭合，hook 内侧）
    private static func plottedAnchorTailProtrusionFillPath(
        bodyWidth w: CGFloat,
        bodyHeight h: CGFloat,
        cornerRadius r: CGFloat,
        model: BubbleTail1718AnchorModel
    ) -> UIBezierPath {
        plottedAnchorTailProtrusionPath(
            bodyWidth: w,
            bodyHeight: h,
            cornerRadius: r,
            model: model,
            closed: true
        )
    }

    /// 预览用：空尾巴模式描边（与 composite 填充楔形一致）
    static func plottedAnchorTailWedgePathForPreview(
        bodyWidth: CGFloat,
        bodyHeight: CGFloat,
        cornerRadius: CGFloat,
        model: BubbleTail1718AnchorModel
    ) -> UIBezierPath {
        let r = min(cornerRadius, bodyWidth / 2, bodyHeight / 2)
        return plottedAnchorTailProtrusionPath(
            bodyWidth: bodyWidth,
            bodyHeight: bodyHeight,
            cornerRadius: r,
            model: model,
            closed: true
        )
    }

    /// 描点编辑器预览：闭合气泡 + 尾巴填充路径
    static func plottedAnchorPreviewPath(
        bodyWidth: CGFloat,
        bodyHeight: CGFloat,
        cornerRadius: CGFloat,
        model: BubbleTail1718AnchorModel,
        fillMode: PlottedTailFillMode = .composite
    ) -> UIBezierPath {
        var params = IMessage1718BubbleTailParams.default
        params.cornerRadius = cornerRadius
        params.plottedTailFillMode = fillMode
        return sentBubblePathPlottedAnchor(
            bodyWidth: bodyWidth,
            bodyHeight: bodyHeight,
            params: params,
            model: model
        )
    }

    /// 描点尾巴路径实际外接框（含曲线外凸，避免 layout 仅看 A–D 锚点而裁切）
    static func plottedAnchorPathOverflow(
        bodyWidth: CGFloat,
        bodyHeight: CGFloat,
        params: IMessage1718BubbleTailParams,
        model: BubbleTail1718AnchorModel
    ) -> (width: CGFloat, height: CGFloat) {
        let path = plottedAnchorPreviewPath(
            bodyWidth: bodyWidth,
            bodyHeight: bodyHeight,
            cornerRadius: params.cornerRadius,
            model: model,
            fillMode: params.plottedTailFillMode
        )
        let box = path.cgPath.boundingBoxOfPath
        let curveSafety: CGFloat = 3
        return (
            max(0, box.maxX - bodyWidth) + curveSafety,
            max(0, box.maxY - bodyHeight) + curveSafety
        )
    }

    static func bubbleBodySize(for textSize: CGSize) -> CGSize {
        let hPad = IMessage1718DesignTokens.bubblePaddingH
        let vPad = IMessage1718DesignTokens.bubblePaddingV
        let minW = IMessage1718DesignTokens.bubbleMinWidth
        let minH = IMessage1718DesignTokens.bubbleMinHeight
        let width = max(minW, textSize.width + hPad * 2)
        let height = max(minH, textSize.height + vPad * 2)
        return CGSize(width: width, height: height)
    }

    static func layoutSize(bodySize: CGSize, params: IMessage1718BubbleTailParams) -> CGSize {
        if params.pathKind == .ios26ChatKit {
            let shiftY: CGFloat = -4
            let flatBottom = max(IMessage1718DesignTokens.bubbleMinHeight, bodySize.height - shiftY)
            let core = IOSOutgoingBubblePath.bubbleBounds(
                bodyWidth: bodySize.width,
                flatBottomY: flatBottom,
                tailScale: 1,
                tailShiftX: -0.7,
                tailOffsetY: shiftY
            )
            return CGSize(
                width: core.width + params.tailClipReserveRight,
                height: core.height + params.tailClipReserveBottom
            )
        }
        if params.usesPlottedAnchorTail,
           let model = params.resolvedPlottedAnchorTail(bodyWidth: bodySize.width, bodyHeight: bodySize.height) {
            let overflow = plottedAnchorPathOverflow(
                bodyWidth: bodySize.width,
                bodyHeight: bodySize.height,
                params: params,
                model: model
            )
            return CGSize(
                width: bodySize.width + overflow.width + params.tailClipReserveRight,
                height: bodySize.height + overflow.height + params.tailClipReserveBottom
            )
        }
        return CGSize(
            width: bodySize.width + params.tailHorizontalOverflow,
            height: bodySize.height + params.tailVerticalOverflow
        )
    }

    static func textLayoutMaxWidth(proposedWidth: CGFloat, params: IMessage1718BubbleTailParams) -> CGFloat {
        let cap = proposedWidth > 1 ? proposedWidth : .greatestFiniteMagnitude
        let hPad = IMessage1718DesignTokens.bubblePaddingH
        return max(8, cap - params.tailHorizontalOverflow - hPad * 2)
    }

    /// 「已送达」右缘对齐气泡本体右竖边（不含尾巴尖）
    static func tailAnchor(bodyWidth: CGFloat, bodyHeight: CGFloat) -> CGPoint {
        CGPoint(x: bodyWidth, y: bodyHeight)
    }

    static func tailTip(
        bodyWidth: CGFloat,
        bodyHeight: CGFloat,
        params: IMessage1718BubbleTailParams
    ) -> CGPoint {
        switch params.pathKind {
        case .ios26ChatKit:
            let shiftY: CGFloat = -4
            let flatBottom = max(IMessage1718DesignTokens.bubbleMinHeight, bodyHeight - shiftY)
            return IOSOutgoingBubblePath.tailTip(
                bodyWidth: bodyWidth,
                flatBottomY: flatBottom,
                tailScale: 1,
                tailShiftX: -0.7,
                tailOffsetY: shiftY
            )
        case .messageKitTutorial, .imsSendBubble, .tracedScreenshot:
            if let model = params.resolvedPlottedAnchorTail(bodyWidth: bodyWidth, bodyHeight: bodyHeight) {
                return model.point(at: 2)
            }
            return tutorialHookLayout(
                bodyWidth: bodyWidth,
                bodyHeight: bodyHeight,
                params: params
            ).tip
        case .referenceImageTail:
            let frame = referenceTailImageFrame(
                bodyWidth: bodyWidth,
                bodyHeight: bodyHeight,
                params: params
            )
            return CGPoint(x: frame.maxX, y: frame.maxY)
        case .messageKitPointed:
            return CGPoint(x: bodyWidth - 10, y: bodyHeight)
        default:
            return tailGeometry(bodyWidth: bodyWidth, bodyHeight: bodyHeight, params: params).b
        }
    }
}

final class IOSOutgoingChatBubbleView1718: UIView {
    let label = UILabel()
    private let shapeLayer = CAShapeLayer()
    private let tailImageView = UIImageView()
    private var laidOutBodyWidth: CGFloat = 0
    private var laidOutBodyHeight: CGFloat = 0
    private(set) var currentTailParams = IMessage1718BubbleTailParams.default
    private var bubbleFontSize: CGFloat = 17

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        clipsToBounds = false
        layer.addSublayer(shapeLayer)
        shapeLayer.fillColor = IMessage1718DesignTokens.bubbleFillUI.cgColor
        shapeLayer.strokeColor = nil
        shapeLayer.lineJoin = .round
        shapeLayer.lineCap = .round
        shapeLayer.contentsScale = UIScreen.main.scale
        shapeLayer.masksToBounds = false

        tailImageView.contentMode = .scaleToFill
        tailImageView.isUserInteractionEnabled = false
        tailImageView.isHidden = true
        addSubview(tailImageView)

        label.font = bubbleFontUI()
        label.textColor = .white
        label.numberOfLines = 0
        label.textAlignment = .left
        addSubview(label)
    }

    convenience init(tailParams: IMessage1718BubbleTailParams) {
        self.init(frame: .zero)
        currentTailParams = tailParams
    }

    func applyTailParams(_ params: IMessage1718BubbleTailParams) {
        guard currentTailParams != params else { return }
        currentTailParams = params
        setNeedsLayout()
    }

    func applyBubbleFontSize(_ size: CGFloat) {
        bubbleFontSize = size
        label.font = bubbleFontUI()
        if let text = label.attributedText?.string ?? label.text {
            setBubbleText(text)
        }
        setNeedsLayout()
        invalidateIntrinsicContentSize()
    }

    private func bubbleFontUI() -> UIFont {
        UIFont.systemFont(ofSize: bubbleFontSize, weight: .regular)
    }

    func setBubbleText(_ text: String) {
        label.attributedText = BubbleTextLinkFormatting.attributedString(
            for: text,
            font: bubbleFontUI(),
            textColor: .white,
            kern: -0.41
        )
        setNeedsLayout()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            shapeLayer.fillColor = IMessage1718DesignTokens.bubbleFillUI.cgColor
            if currentTailParams.pathKind == .referenceImageTail {
                tailImageView.image = IOSOutgoingBubblePath1718.referenceTailImage(
                    named: currentTailParams.referenceTailImageName,
                    fill: IMessage1718DesignTokens.bubbleFillUI
                )
            }
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    private func layoutMaxBodyWidth() -> CGFloat {
        let screenCap = UIScreen.main.bounds.width * IMessage1718DesignTokens.bubbleMaxWidthFraction
            - IMessage1718DesignTokens.layer2ThreadPaddingH * 2
            - currentTailParams.threadBubbleMaxWidthReduction
            + IMessage1718DesignTokens.bubbleMaxWidthExtra
            - currentTailParams.tailHorizontalOverflow
        return max(IMessage1718DesignTokens.bubbleMinWidth, screenCap)
    }

    private func resolvedMetrics(proposedWidth: CGFloat) -> (
        bodySize: CGSize,
        layoutSize: CGSize,
        textSize: CGSize
    ) {
        let totalCap = proposedWidth > 1
            ? min(proposedWidth, layoutMaxBodyWidth() + currentTailParams.tailHorizontalOverflow)
            : layoutMaxBodyWidth() + currentTailParams.tailHorizontalOverflow
        let innerMax = IOSOutgoingBubblePath1718.textLayoutMaxWidth(
            proposedWidth: totalCap,
            params: currentTailParams
        )
        let textSize = label.sizeThatFits(CGSize(width: innerMax, height: .greatestFiniteMagnitude))
        let bodySize = IOSOutgoingBubblePath1718.bubbleBodySize(for: textSize)
        let layoutSize = IOSOutgoingBubblePath1718.layoutSize(
            bodySize: bodySize,
            params: currentTailParams
        )
        return (bodySize, layoutSize, textSize)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let proposed = bounds.width > 1 ? bounds.width : layoutMaxBodyWidth() + currentTailParams.tailHorizontalOverflow
        let metrics = resolvedMetrics(proposedWidth: proposed)
        laidOutBodyWidth = metrics.bodySize.width
        laidOutBodyHeight = metrics.bodySize.height

        shapeLayer.frame = CGRect(origin: .zero, size: metrics.layoutSize)
        shapeLayer.path = IOSOutgoingBubblePath1718.sentBubblePath(
            bodyWidth: metrics.bodySize.width,
            bodyHeight: metrics.bodySize.height,
            params: currentTailParams
        ).cgPath

        if currentTailParams.pathKind == .referenceImageTail {
            let fill = IMessage1718DesignTokens.bubbleFillUI
            tailImageView.isHidden = false
            tailImageView.tintColor = nil
            tailImageView.image = IOSOutgoingBubblePath1718.referenceTailImage(
                named: currentTailParams.referenceTailImageName,
                fill: fill
            )
            tailImageView.frame = IOSOutgoingBubblePath1718.referenceTailImageFrame(
                bodyWidth: metrics.bodySize.width,
                bodyHeight: metrics.bodySize.height,
                params: currentTailParams
            )
            bringSubviewToFront(tailImageView)
        } else {
            tailImageView.isHidden = true
            tailImageView.image = nil
        }

        let hPad = IMessage1718DesignTokens.bubblePaddingH
        let vPad = IMessage1718DesignTokens.bubblePaddingV
        label.frame = CGRect(
            x: hPad,
            y: vPad,
            width: metrics.bodySize.width - hPad * 2,
            height: metrics.textSize.height
        )
        bringSubviewToFront(label)
        if currentTailParams.pathKind == .referenceImageTail {
            bringSubviewToFront(tailImageView)
        }
        BubbleTail1718ProbeRegistry.register(self)
    }

    func makeProbeSnapshot() -> BubbleTail1718ProbeSnapshot {
        let frame = convert(bounds, to: nil)
        let bodyW = laidOutBodyWidth
        let bodyH = laidOutBodyHeight
        let params = currentTailParams
        var anchors: [BubbleTail1718ProbeSnapshot.PointLabel] = []
        var controls: [BubbleTail1718ProbeSnapshot.PointLabel] = []
        var plottedSegments: [BubbleTail1718ProbeSnapshot.PlottedSegment] = []
        var measurements: [String] = [
            "body: \(fmt(bodyW))×\(fmt(bodyH)) layout: \(fmt(bounds.width))×\(fmt(bounds.height))",
            "preset: \(params.presetID)",
        ]

        if params.pathKind == .messageKitTutorial
            || params.pathKind == .tracedScreenshot
            || params.pathKind == .imsSendBubble {
            if params.usesPlottedAnchorTail,
               let stored = params.plottedAnchorTail,
               let model = params.resolvedPlottedAnchorTail(bodyWidth: bodyW, bodyHeight: bodyH) {
                let a = model.point(at: 0)
                let b = model.point(at: 1)
                let c = model.point(at: 2)
                let d = model.point(at: 3)
                anchors = [
                    .init(name: "A", point: a),
                    .init(name: "B", point: b),
                    .init(name: "C尖", point: c),
                    .init(name: "D底根", point: d),
                ]
                plottedSegments = (0 ..< stored.segmentCount).compactMap { index in
                    guard stored.segmentKinds.indices.contains(index) else { return nil }
                    return BubbleTail1718ProbeSnapshot.PlottedSegment(
                        from: model.point(at: index),
                        to: model.point(at: index + 1),
                        kind: stored.segmentKinds[index],
                        curvature: stored.segmentCurvatures.indices.contains(index)
                            ? stored.segmentCurvatures[index] : 0
                    )
                }
                measurements += [
                    "拓扑: 描点 A→B→C→D（已映射 \(fmt(bodyW))×\(fmt(bodyH))）",
                    "ref: \(fmt(params.tailAnchorReferenceSize.width))×\(fmt(params.tailAnchorReferenceSize.height))",
                    "A=\(fmtPt(a)) B=\(fmtPt(b)) C=\(fmtPt(c)) D=\(fmtPt(d))",
                ]
            } else {
                let g = IOSOutgoingBubblePath1718.tutorialProbeGeometry(
                    bodyWidth: bodyW,
                    bodyHeight: bodyH,
                    params: params
                )
                anchors = [
                    .init(name: "hook汇点", point: g.junction),
                    .init(name: "BR弧顶", point: g.corner),
                    .init(name: "尖", point: g.tip),
                    .init(name: "底根", point: g.root),
                ]
                controls = [
                    .init(name: "上CP1", point: g.upperCP1),
                    .init(name: "上CP2", point: g.upperCP2),
                    .init(name: "下CP1", point: g.lowerCP1),
                    .init(name: "下CP2", point: g.lowerCP2),
                ]
                measurements += [
                    "拓扑: 直线→上弧→下弧→BR",
                    "尖: (w+\(fmt(params.tailTipExtension)), h) hook: y=h−r/2",
                    "下弧 CP2 左偏 \(fmt(params.tutorialLowerLeftBulge))pt",
                ]
            }
        } else if params.pathKind == .referenceImageTail {
            let tailFrame = IOSOutgoingBubblePath1718.referenceTailImageFrame(
                bodyWidth: bodyW,
                bodyHeight: bodyH,
                params: params
            )
            anchors = [
                .init(name: "角点", point: CGPoint(x: bodyW, y: bodyH)),
                .init(name: "尖", point: CGPoint(x: tailFrame.maxX, y: tailFrame.maxY)),
            ]
            measurements += [
                "贴图: \(fmt(tailFrame.width))×\(fmt(tailFrame.height)) pt",
                "尖: \(fmt(params.tailTipExtension)), \(fmt(params.tailTipDrop))",
            ]
        } else {
            anchors = [
                .init(name: "锚", point: tailAnchorPointInSelf()),
                .init(name: "尖", point: tailTipPointInSelf()),
            ]
        }

        let export = (measurements + anchors.map { "\($0.name)=\(fmtPt($0.point))" })
            .joined(separator: "\n")

        return BubbleTail1718ProbeSnapshot(
            bubbleFrameInWindow: frame,
            bodySize: CGSize(width: bodyW, height: bodyH),
            layoutSize: bounds.size,
            presetID: params.presetID,
            pathKind: params.pathKind,
            anchors: anchors,
            controlPoints: controls,
            plottedSegments: plottedSegments,
            measurements: measurements,
            exportText: export
        )
    }

    private func fmt(_ v: CGFloat) -> String {
        String(format: "%.1f", v)
    }

    private func fmtPt(_ p: CGPoint) -> String {
        "\(fmt(p.x)),\(fmt(p.y))"
    }

    private func segmentLength(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        hypot(b.x - a.x, b.y - a.y)
    }

    func tailTipPointInSelf() -> CGPoint {
        IOSOutgoingBubblePath1718.tailTip(
            bodyWidth: laidOutBodyWidth,
            bodyHeight: laidOutBodyHeight,
            params: currentTailParams
        )
    }

    func tailAnchorPointInSelf() -> CGPoint {
        IOSOutgoingBubblePath1718.tailAnchor(
            bodyWidth: laidOutBodyWidth,
            bodyHeight: laidOutBodyHeight
        )
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let proposed = size.width > 1
            ? size.width
            : layoutMaxBodyWidth() + currentTailParams.tailHorizontalOverflow
        return resolvedMetrics(proposedWidth: proposed).layoutSize
    }

    override var intrinsicContentSize: CGSize {
        sizeThatFits(.zero)
    }
}

/// iOS 16–18 单图气泡：1718 尾巴几何 + 图片底部同色尾巴（与 26 单图衔接方式一致）
final class IOSOutgoingImageBubbleView1718: UIView {
    private let imageView = UIImageView()
    private let tailFillView = ImageBubbleTailFillView1718()
    private let tailImageView = UIImageView()
    private var laidOutBodyWidth: CGFloat = 0
    private var laidOutBodyHeight: CGFloat = 0
    private var sizingMaxLayoutWidth: CGFloat = 0
    private var tailFillColor: UIColor = .systemGray3
    private(set) var currentTailParams = IMessage1718BubbleTailParams.default

    var image: UIImage? {
        get { imageView.image }
        set {
            imageView.image = newValue
            tailFillColor = Self.tailAdjacentColor(from: newValue)
            setNeedsLayout()
            invalidateIntrinsicContentSize()
        }
    }

    init(image: UIImage, tailParams: IMessage1718BubbleTailParams) {
        super.init(frame: .zero)
        backgroundColor = .clear
        clipsToBounds = false
        isUserInteractionEnabled = false
        currentTailParams = tailParams

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.isUserInteractionEnabled = false

        tailImageView.contentMode = .scaleToFill
        tailImageView.isUserInteractionEnabled = false
        tailImageView.isHidden = true

        addSubview(tailFillView)
        addSubview(tailImageView)
        addSubview(imageView)

        self.image = image
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    func applyTailParams(_ params: IMessage1718BubbleTailParams) {
        guard currentTailParams != params else { return }
        currentTailParams = params
        setNeedsLayout()
        invalidateIntrinsicContentSize()
    }

    static func orientedPixelSize(for image: UIImage) -> CGSize {
        guard let cgImage = image.cgImage else { return image.size }
        let pixelW = CGFloat(cgImage.width)
        let pixelH = CGFloat(cgImage.height)
        switch image.imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            return CGSize(width: pixelH, height: pixelW)
        default:
            return CGSize(width: pixelW, height: pixelH)
        }
    }

    private func layoutMetrics(maxBodyLayoutWidth: CGFloat) -> (
        bodySize: CGSize,
        layoutSize: CGSize
    ) {
        guard let image = imageView.image,
              image.size.width > 0,
              image.size.height > 0,
              maxBodyLayoutWidth > 0 else {
            return (.zero, .zero)
        }

        let bodySize = IMessageDesignTokens.imageBubbleBodySize(
            imagePixelSize: Self.orientedPixelSize(for: image),
            maxLayoutWidth: maxBodyLayoutWidth
        )
        let layoutSize = IOSOutgoingBubblePath1718.layoutSize(
            bodySize: bodySize,
            params: currentTailParams
        )
        return (bodySize, layoutSize)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let tailReserve = currentTailParams.tailHorizontalOverflow
        let proposed = bounds.width > 1
            ? bounds.width
            : sizingMaxLayoutWidth + tailReserve
        let maxBodyWidth = max(1, proposed - tailReserve)
        let metrics = layoutMetrics(maxBodyLayoutWidth: maxBodyWidth)
        guard metrics.bodySize.width > 1, metrics.bodySize.height > 1 else { return }

        laidOutBodyWidth = metrics.bodySize.width
        laidOutBodyHeight = metrics.bodySize.height

        let bubblePath = IOSOutgoingBubblePath1718.sentBubblePath(
            bodyWidth: metrics.bodySize.width,
            bodyHeight: metrics.bodySize.height,
            params: currentTailParams
        )

        tailFillView.frame = CGRect(origin: .zero, size: metrics.layoutSize)
        tailFillView.fillColor = tailFillColor
        tailFillView.applyPath(bubblePath)

        if currentTailParams.pathKind == .referenceImageTail {
            tailImageView.isHidden = false
            tailImageView.tintColor = nil
            tailImageView.image = IOSOutgoingBubblePath1718.referenceTailImage(
                named: currentTailParams.referenceTailImageName,
                fill: tailFillColor
            )
            tailImageView.frame = IOSOutgoingBubblePath1718.referenceTailImageFrame(
                bodyWidth: metrics.bodySize.width,
                bodyHeight: metrics.bodySize.height,
                params: currentTailParams
            )
        } else {
            tailImageView.isHidden = true
            tailImageView.image = nil
        }

        let bodyW = metrics.bodySize.width
        let bodyH = metrics.bodySize.height
        imageView.frame = CGRect(x: 0, y: 0, width: bodyW, height: bodyH)
        let radius = min(currentTailParams.cornerRadius, bodyW * 0.5, bodyH * 0.5)
        imageView.layer.cornerRadius = radius
        imageView.layer.cornerCurve = .continuous

        bringSubviewToFront(imageView)
        if currentTailParams.pathKind == .referenceImageTail {
            bringSubviewToFront(tailImageView)
        }
    }

    func tailTipPointInSelf() -> CGPoint {
        IOSOutgoingBubblePath1718.tailTip(
            bodyWidth: laidOutBodyWidth,
            bodyHeight: laidOutBodyHeight,
            params: currentTailParams
        )
    }

    func tailAnchorPointInSelf() -> CGPoint {
        IOSOutgoingBubblePath1718.tailAnchor(
            bodyWidth: laidOutBodyWidth,
            bodyHeight: laidOutBodyHeight
        )
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        guard size.width.isFinite, size.width > 1 else { return .zero }
        sizingMaxLayoutWidth = size.width
        return layoutMetrics(maxBodyLayoutWidth: size.width).layoutSize
    }

    override var intrinsicContentSize: CGSize {
        .zero
    }

    /// 取图片右下区域平均色，供 1718 尾巴与图片衔接
    private static func tailAdjacentColor(from image: UIImage?) -> UIColor {
        guard let image,
              let cgImage = image.cgImage else {
            return UIColor.systemGray3
        }

        let width = cgImage.width
        let height = cgImage.height
        guard width > 0, height > 0 else { return UIColor.systemGray3 }

        let sampleW = max(1, width / 15)
        let sampleH = max(1, height / 15)
        let cropRect = CGRect(
            x: width - sampleW,
            y: height - sampleH,
            width: sampleW,
            height: sampleH
        )
        guard let cropped = cgImage.cropping(to: cropRect) else { return UIColor.systemGray3 }
        return averageColor(of: cropped) ?? UIColor.systemGray3
    }

    private static func averageColor(of cgImage: CGImage) -> UIColor? {
        let width = cgImage.width
        let height = cgImage.height
        guard width > 0, height > 0 else { return nil }

        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        var raw = [UInt8](repeating: 0, count: height * bytesPerRow)
        guard let context = CGContext(
            data: &raw,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        var totalR: CGFloat = 0
        var totalG: CGFloat = 0
        var totalB: CGFloat = 0
        var totalA: CGFloat = 0
        let pixelCount = width * height

        for index in 0..<pixelCount {
            let offset = index * bytesPerPixel
            let alpha = CGFloat(raw[offset + 3]) / 255
            guard alpha > 0.01 else { continue }
            totalR += CGFloat(raw[offset]) / 255
            totalG += CGFloat(raw[offset + 1]) / 255
            totalB += CGFloat(raw[offset + 2]) / 255
            totalA += 1
        }

        guard totalA > 0 else { return nil }
        return UIColor(
            red: totalR / totalA,
            green: totalG / totalA,
            blue: totalB / totalA,
            alpha: 1
        )
    }
}

private final class ImageBubbleTailFillView1718: UIView {
    private let shapeLayer = CAShapeLayer()

    var fillColor: UIColor = .clear {
        didSet {
            shapeLayer.fillColor = fillColor.cgColor
            shapeLayer.strokeColor = fillColor.cgColor
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = .clear
        clipsToBounds = false
        layer.addSublayer(shapeLayer)
        shapeLayer.fillColor = fillColor.cgColor
        shapeLayer.strokeColor = fillColor.cgColor
        shapeLayer.lineWidth = 1 / UIScreen.main.scale
        shapeLayer.lineJoin = .round
        shapeLayer.lineCap = .round
        shapeLayer.contentsScale = UIScreen.main.scale
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    func applyPath(_ path: UIBezierPath) {
        shapeLayer.frame = bounds
        shapeLayer.path = path.cgPath
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        shapeLayer.frame = bounds
    }
}
