import UIKit

/// 标准 iMessage 发送气泡：末条圆角 5/18/18/18 + ChatKit 风格右下尾巴（cubic）
enum IOSOutgoingBubblePath {
    /// CKColoredBalloonView 180×44.33 采样（探针 balloonStyle=0, cornerRadius=18）
    private static let ckRefWidth: CGFloat = 180
    private static let ckRefFlatY: CGFloat = 37.90
    private static let ckRefMaxY: CGFloat = 44.33
    private static let ckRightEdgeTop = CGPoint(x: 180, y: 18.95)
    private static let ckApproach = CGPoint(x: 6.89, y: 33.91)
    private static let ckTip = CGPoint(x: 8.81, y: 43.89)
    private static let ckJoin = CGPoint(x: 19.86, y: 37.90)

    private struct CKCubic {
        let end: CGPoint
        let c1: CGPoint
        let c2: CGPoint
    }

    /// 右缘自上而下（探针路径末段，填充右下圆角，x 保持贴右缘）
    private static let ckRightEdgeDown: [CKCubic] = [
        CKCubic(
            end: CGPoint(x: 178.72, y: 26.55),
            c1: CGPoint(x: 180, y: 21.79),
            c2: CGPoint(x: 179.61, y: 24.22)
        ),
        CKCubic(
            end: CGPoint(x: 168.63, y: 36.55),
            c1: CGPoint(x: 176.96, y: 31.15),
            c2: CGPoint(x: 173.29, y: 34.85)
        ),
    ]

    private static let ckTailCubics: [CKCubic] = [
        CKCubic(
            end: CGPoint(x: 9.38, y: 38.26),
            c1: CGPoint(x: 8.63, y: 35.26),
            c2: CGPoint(x: 9.38, y: 36.67)
        ),
        CKCubic(
            end: CGPoint(x: 7.66, y: 42.38),
            c1: CGPoint(x: 9.38, y: 39.32),
            c2: CGPoint(x: 9.19, y: 40.37)
        ),
        CKCubic(
            end: ckTip,
            c1: CGPoint(x: 6.93, y: 43.35),
            c2: CGPoint(x: 7.66, y: 44.33)
        ),
        CKCubic(
            end: CGPoint(x: 16.20, y: 39.63),
            c1: CGPoint(x: 11.17, y: 43.00),
            c2: CGPoint(x: 13.85, y: 41.37)
        ),
        CKCubic(
            end: ckJoin,
            c1: CGPoint(x: 18.31, y: 38.07),
            c2: CGPoint(x: 18.87, y: 37.91)
        ),
    ]

    private static func mapY(
        _ y: CGFloat,
        flatBottomY: CGFloat,
        tailDrop: CGFloat,
        shiftY: CGFloat
    ) -> CGFloat {
        let dy = y - ckRefFlatY
        if dy <= 0 {
            return flatBottomY + dy + shiftY
        }
        return flatBottomY + dy / (ckRefMaxY - ckRefFlatY) * tailDrop + shiftY
    }

    /// 右缘/右下点：保持距右缘偏移，不镜像到左侧
    private static func mapRightEdgePoint(
        _ point: CGPoint,
        bodyWidth: CGFloat,
        flatBottomY: CGFloat,
        tailDrop: CGFloat,
        shiftX: CGFloat,
        shiftY: CGFloat
    ) -> CGPoint {
        CGPoint(
            x: bodyWidth - (ckRefWidth - point.x) + shiftX,
            y: mapY(point.y, flatBottomY: flatBottomY, tailDrop: tailDrop, shiftY: shiftY)
        )
    }

    /// 尾巴区点：水平镜像到发送侧右下
    private static func mapCKPoint(
        _ point: CGPoint,
        bodyWidth: CGFloat,
        flatBottomY: CGFloat,
        tailDrop: CGFloat,
        shiftX: CGFloat,
        shiftY: CGFloat
    ) -> CGPoint {
        CGPoint(
            x: bodyWidth - point.x + shiftX,
            y: mapY(point.y, flatBottomY: flatBottomY, tailDrop: tailDrop, shiftY: shiftY)
        )
    }

    static func sentLastBubblePath(
        bodyWidth: CGFloat,
        flatBottomY: CGFloat,
        tailScale: CGFloat,
        tailShiftX: CGFloat,
        tailOffsetY: CGFloat,
        groupedLastInThread: Bool = false
    ) -> UIBezierPath {
        let tl = groupedLastInThread
            ? IMessageDesignTokens.bubbleCornerTLGroupedLast
            : IMessageDesignTokens.bubbleCornerTLCompose
        let tr = IMessageDesignTokens.bubbleCornerTR
        let bl = IMessageDesignTokens.bubbleCornerBL
        let tailDrop = IMessageDesignTokens.bubbleTailDrop * tailScale
        let W = bodyWidth

        func mapTail(_ p: CGPoint) -> CGPoint {
            mapCKPoint(
                p,
                bodyWidth: W,
                flatBottomY: flatBottomY,
                tailDrop: tailDrop,
                shiftX: tailShiftX,
                shiftY: tailOffsetY
            )
        }

        func mapRight(_ p: CGPoint) -> CGPoint {
            mapRightEdgePoint(
                p,
                bodyWidth: W,
                flatBottomY: flatBottomY,
                tailDrop: tailDrop,
                shiftX: tailShiftX,
                shiftY: tailOffsetY
            )
        }

        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: tl))
        path.addArc(
            withCenter: CGPoint(x: tl, y: tl),
            radius: tl,
            startAngle: .pi,
            endAngle: -.pi / 2,
            clockwise: true
        )
        path.addLine(to: CGPoint(x: W - tr, y: 0))
        path.addArc(
            withCenter: CGPoint(x: W - tr, y: tr),
            radius: tr,
            startAngle: -.pi / 2,
            endAngle: 0,
            clockwise: true
        )

        // ChatKit 右缘 cubic 下落（内收圆角，避免 (W,flatY) 缺角）
        path.addLine(to: mapRight(ckRightEdgeTop))
        for cubic in ckRightEdgeDown {
            path.addCurve(
                to: mapRight(cubic.end),
                controlPoint1: mapRight(cubic.c1),
                controlPoint2: mapRight(cubic.c2)
            )
        }

        // 右缘终点 (≈W-11pt) → 尾巴入口 (≈W-7pt)：用 tail 坐标系插值，避免 mapRight/mapTail 接缝露白
        let rightCorner = mapRight(ckRightEdgeDown.last!.end)
        let tailEntry = mapTail(ckApproach)
        let bridgeMid = mapTail(
            CGPoint(
                x: (ckRightEdgeDown.last!.end.x + ckApproach.x) * 0.5,
                y: (ckRightEdgeDown.last!.end.y + ckApproach.y) * 0.5
            )
        )
        path.addCurve(
            to: tailEntry,
            controlPoint1: CGPoint(
                x: rightCorner.x + (bridgeMid.x - rightCorner.x) * 0.65,
                y: rightCorner.y
            ),
            controlPoint2: CGPoint(
                x: tailEntry.x - (tailEntry.x - bridgeMid.x) * 0.35,
                y: bridgeMid.y
            )
        )

        for cubic in ckTailCubics {
            path.addCurve(
                to: mapTail(cubic.end),
                controlPoint1: mapTail(cubic.c1),
                controlPoint2: mapTail(cubic.c2)
            )
        }

        let join = mapTail(ckJoin)
        path.addLine(to: CGPoint(x: bl, y: join.y))
        path.addArc(
            withCenter: CGPoint(x: bl, y: join.y - bl),
            radius: bl,
            startAngle: .pi / 2,
            endAngle: .pi,
            clockwise: true
        )
        path.addLine(to: CGPoint(x: 0, y: tl))
        path.close()
        return path
    }

    static func bubbleBounds(
        bodyWidth: CGFloat,
        flatBottomY: CGFloat,
        tailScale: CGFloat,
        tailShiftX: CGFloat,
        tailOffsetY: CGFloat
    ) -> CGSize {
        _ = tailShiftX
        _ = tailOffsetY
        let tailDrop = IMessageDesignTokens.bubbleTailDrop * tailScale
        return CGSize(width: bodyWidth, height: flatBottomY + tailDrop)
    }

    static func tailTip(
        bodyWidth: CGFloat,
        flatBottomY: CGFloat,
        tailScale: CGFloat,
        tailShiftX: CGFloat,
        tailOffsetY: CGFloat
    ) -> CGPoint {
        let tailDrop = IMessageDesignTokens.bubbleTailDrop * tailScale
        return mapCKPoint(
            ckTip,
            bodyWidth: bodyWidth,
            flatBottomY: flatBottomY,
            tailDrop: tailDrop,
            shiftX: tailShiftX,
            shiftY: tailOffsetY
        )
    }

    static func tailAnchor(
        bodyWidth: CGFloat,
        flatBottomY: CGFloat,
        tailScale: CGFloat,
        tailShiftX: CGFloat,
        tailOffsetY: CGFloat
    ) -> CGPoint {
        let tailDrop = IMessageDesignTokens.bubbleTailDrop * tailScale
        return mapCKPoint(
            ckJoin,
            bodyWidth: bodyWidth,
            flatBottomY: flatBottomY,
            tailDrop: tailDrop,
            shiftX: tailShiftX,
            shiftY: tailOffsetY
        )
    }
}

private final class BubbleFillView: UIView {
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
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func applyPath(_ path: UIBezierPath) {
        shapeLayer.frame = bounds
        shapeLayer.path = path.cgPath
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        shapeLayer.frame = bounds
    }
}

final class IOSOutgoingChatBubbleView: UIView {
    let label = UILabel()

    private let fillView = BubbleFillView()
    private var laidOutBodyWidth: CGFloat = 0
    private var laidOutFlatBottomY: CGFloat = 0

    var renderParams: BubbleTailRenderParams?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        clipsToBounds = false
        isUserInteractionEnabled = true

        addSubview(fillView)
        label.font = .systemFont(ofSize: 17)
        label.textColor = .white
        label.numberOfLines = 0
        label.isUserInteractionEnabled = false
        addSubview(label)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func applyRenderParams(_ params: BubbleTailRenderParams) {
        renderParams = params
        setNeedsLayout()
        invalidateIntrinsicContentSize()
    }

    private func activeParams() -> BubbleTailRenderParams {
        renderParams ?? .frozenDefault
    }

    private func tailShiftX(bodyWidth: CGFloat, params: BubbleTailRenderParams) -> CGFloat {
        let anchorShift = (CGFloat(params.anchorXFraction) - 0.92) * bodyWidth
        return anchorShift + CGFloat(params.offsetX)
    }

    private func layoutMaxWidth() -> CGFloat {
        UIScreen.main.bounds.width * IMessageDesignTokens.bubbleMaxWidthFraction
            - IMessageDesignTokens.layer2ThreadPaddingH
            - IMessageDesignTokens.threadBubbleTrailingInset
    }

    func layoutMetrics(maxWidth: CGFloat, params: BubbleTailRenderParams) -> (
        bodyWidth: CGFloat,
        flatBottomY: CGFloat,
        tailShiftX: CGFloat,
        tailOffsetY: CGFloat,
        bubbleSize: CGSize
    ) {
        let hPad = IMessageDesignTokens.bubbleHPadding
        let vPad = IMessageDesignTokens.bubbleVPadding
        let labelMax = max(44, maxWidth - hPad * 2)
        let textSize = label.sizeThatFits(CGSize(width: labelMax, height: .greatestFiniteMagnitude))
        let bodyW = max(IMessageDesignTokens.bubbleMinWidth, textSize.width + hPad * 2)
        let shiftX = tailShiftX(bodyWidth: bodyW, params: params)
        let shiftY = CGFloat(params.offsetY)
        // 尾巴纵向偏移会抬高可视底边，补偿后保证文案上下留白一致
        let flatBottom = max(
            IMessageDesignTokens.bubbleMinHeight,
            textSize.height + vPad * 2 - shiftY
        )
        let size = IOSOutgoingBubblePath.bubbleBounds(
            bodyWidth: bodyW,
            flatBottomY: flatBottom,
            tailScale: CGFloat(params.scale),
            tailShiftX: shiftX,
            tailOffsetY: shiftY
        )
        return (bodyW, flatBottom, shiftX, shiftY, size)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let params = activeParams()
        let cap = bounds.width > 1 ? min(bounds.width, layoutMaxWidth()) : layoutMaxWidth()
        let metrics = layoutMetrics(maxWidth: cap, params: params)
        laidOutBodyWidth = metrics.bodyWidth
        laidOutFlatBottomY = metrics.flatBottomY

        fillView.frame = bounds
        fillView.fillColor = params.fillUIColor
        fillView.applyPath(
            IOSOutgoingBubblePath.sentLastBubblePath(
                bodyWidth: metrics.bodyWidth,
                flatBottomY: metrics.flatBottomY,
                tailScale: CGFloat(params.scale),
                tailShiftX: metrics.tailShiftX,
                tailOffsetY: metrics.tailOffsetY
            )
        )

        let hPad = IMessageDesignTokens.bubbleHPadding
        let vPad = IMessageDesignTokens.bubbleVPadding
        let innerWidth = metrics.bodyWidth - hPad * 2
        let textSize = label.sizeThatFits(
            CGSize(width: innerWidth, height: .greatestFiniteMagnitude)
        )
        label.frame = CGRect(
            x: hPad,
            y: vPad,
            width: innerWidth,
            height: textSize.height
        )
    }

    func tailTipPointInSelf() -> CGPoint {
        let params = activeParams()
        let metrics = layoutMetrics(maxWidth: layoutMaxWidth(), params: params)
        return IOSOutgoingBubblePath.tailTip(
            bodyWidth: metrics.bodyWidth,
            flatBottomY: metrics.flatBottomY,
            tailScale: CGFloat(params.scale),
            tailShiftX: metrics.tailShiftX,
            tailOffsetY: metrics.tailOffsetY
        )
    }

    func tailAnchorPointInSelf() -> CGPoint {
        let params = activeParams()
        let metrics = layoutMetrics(maxWidth: layoutMaxWidth(), params: params)
        return IOSOutgoingBubblePath.tailAnchor(
            bodyWidth: metrics.bodyWidth,
            flatBottomY: metrics.flatBottomY,
            tailScale: CGFloat(params.scale),
            tailShiftX: metrics.tailShiftX,
            tailOffsetY: metrics.tailOffsetY
        )
    }

    func bodyWidthForLayout() -> CGFloat {
        if laidOutBodyWidth > 0 { return laidOutBodyWidth }
        return layoutMetrics(maxWidth: layoutMaxWidth(), params: activeParams()).bodyWidth
    }

    func bodyTrailingXInSelf() -> CGFloat {
        bodyWidthForLayout()
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let cap = size.width > 1 ? min(size.width, layoutMaxWidth()) : layoutMaxWidth()
        return layoutMetrics(maxWidth: cap, params: activeParams()).bubbleSize
    }

    override var intrinsicContentSize: CGSize {
        sizeThatFits(.zero)
    }
}
