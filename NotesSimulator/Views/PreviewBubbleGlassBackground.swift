import SwiftUI

/// 号码预览泡：固定完美参数（仅底色/描边可调，玻璃折射写死）
struct PreviewBubbleGlassBackground: View {
    var cornerRadius: CGFloat
    var tint: Color
    var border: Color

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        ZStack {
            shape.fill(.regularMaterial)

            shape.fill(tint)

            shape.fill(
                LinearGradient(
                    stops: [
                        .init(color: .white.opacity(0.58), location: 0),
                        .init(color: .white.opacity(0.22), location: 0.35),
                        .init(color: .white.opacity(0.04), location: 0.62),
                        .init(color: .clear, location: 1),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )

            shape.fill(
                LinearGradient(
                    colors: [.clear, .black.opacity(0.05)],
                    startPoint: .center,
                    endPoint: .bottom
                )
            )

            shape.stroke(border, lineWidth: 0.5)

            shape
                .inset(by: 0.6)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.75), .white.opacity(0.15), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.8
                )
        }
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
    }
}

/// 长按菜单栏：手搓毛玻璃（模糊度 / 透光度独立）
struct MenuPanelGlassBackground: View {
    var cornerRadius: CGFloat
    var tint: Color
    var border: Color
    /// 模糊度：虚化强度
    var blur: Double
    /// 透光度：0=厚实遮盖，1=几乎全透
    var translucency: Double
    var refractionTop: Double
    var refractionMid: Double
    var specularStrength: Double
    var innerShadow: Double

    private var frost: Double { max(0.04, min(0.98, 1.0 - translucency)) }

    var body: some View {
        if #available(iOS 26, *) {
            SystemPopoverGlassView(cornerRadius: cornerRadius)
        } else {
            legacyHandcraftedBody
        }
    }

    private var legacyHandcraftedBody: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        return ZStack {
            shape.fill(.thinMaterial)
                .opacity(blur)

            shape.fill(tint)

            shape.fill(
                LinearGradient(
                    stops: [
                        .init(color: .white.opacity(refractionTop * frost), location: 0),
                        .init(color: .white.opacity(refractionMid * frost), location: 0.38),
                        .init(color: .white.opacity(refractionMid * 0.15 * frost), location: 0.7),
                        .init(color: .clear, location: 1),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )

            shape.fill(
                LinearGradient(
                    colors: [.clear, .black.opacity(innerShadow * frost)],
                    startPoint: .center,
                    endPoint: .bottom
                )
            )

            shape.stroke(border.opacity(0.5 + frost * 0.5), lineWidth: 0.5)

            shape
                .inset(by: 0.8)
                .stroke(
                    LinearGradient(
                        colors: [
                            .white.opacity(specularStrength * frost),
                            .white.opacity(specularStrength * 0.18 * frost),
                            .clear,
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
        .shadow(color: .black.opacity(innerShadow * 2.2 * frost), radius: 13, y: 4)
    }
}

/// 撰写页玻璃渲染模式
enum ComposeGlassRenderMode {
    /// 收发件人大卡片：iOS 26 走系统 Popover 玻璃
    case addressCard
    /// 导航栏底：仅系统玻璃采样，无白罩叠层（静止近乎不可见，滚过时有折射）
    case navigationBar
    /// 顶栏穿透：底板 + 系统玻璃 + 压暗（穿过变深，非镜面）
    case topPenetrate
    /// 加号 / 输入框：手搓材质 + 强描边（白底上始终可见，不依赖背后采样）
    case chromeControl
    /// 关闭钮：更白磨砂 + 强高光 + 浮起阴影
    case chromeClose
}

/// 撰写页收发件人卡片：菜单同款玻璃 + 更低透光 + 纯白高光边
struct ComposeAddressGlassBackground: View {
    var cornerRadius: CGFloat
    var renderMode: ComposeGlassRenderMode = .addressCard
    /// 小控件描边/高光加强倍数
    var borderEmphasis: CGFloat = 1
    /// 是否叠加浮起阴影（卡片外层已有阴影时可关）
    var showsLiftShadow: Bool = false
    /// 小控件白罩强度（关闭钮更白更实）
    var materialWhiten: CGFloat = IMessageDesignTokens.chromeControlMaterialWhiten

    private var frost: Double {
        max(0.04, min(0.98, 1.0 - Double(IMessageDesignTokens.addressGlassTranslucency)))
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }

    private var closeLiftShadowColor: Color {
        if renderMode == .chromeClose {
            return .black.opacity(IMessageDesignTokens.chromeCloseLiftShadowOpacity)
        }
        return showsLiftShadow
            ? .black.opacity(IMessageDesignTokens.addressGlassLiftShadowOpacity)
            : .clear
    }

    private var closeLiftShadowRadius: CGFloat {
        if renderMode == .chromeClose {
            return IMessageDesignTokens.chromeCloseLiftShadowRadius
        }
        return showsLiftShadow ? IMessageDesignTokens.addressGlassLiftShadowRadius : 0
    }

    private var closeLiftShadowY: CGFloat {
        if renderMode == .chromeClose {
            return IMessageDesignTokens.chromeCloseLiftShadowY
        }
        return showsLiftShadow ? IMessageDesignTokens.addressGlassLiftShadowY : 0
    }

    var body: some View {
        ZStack {
            systemChromeBase
            switch renderMode {
            case .navigationBar:
                EmptyView()
            case .topPenetrate:
                topPenetrateOverlays
            case .chromeClose:
                chromeCloseEdgeOverlays
            default:
                menuMatchedOverlays
            }
        }
        .compositingGroup()
        .shadow(
            color: (renderMode == .navigationBar || renderMode == .topPenetrate) ? .clear : closeLiftShadowColor,
            radius: (renderMode == .navigationBar || renderMode == .topPenetrate) ? 0 : closeLiftShadowRadius,
            y: (renderMode == .navigationBar || renderMode == .topPenetrate) ? 0 : closeLiftShadowY
        )
    }

    @ViewBuilder
    private var systemChromeBase: some View {
        switch renderMode {
        case .addressCard:
            if #available(iOS 26, *) {
                SystemPopoverGlassView(cornerRadius: cornerRadius)
            } else {
                MenuPanelGlassBackground(
                    cornerRadius: cornerRadius,
                    tint: IMessageDesignTokens.addressGlassTint.opacity(frost * 0.82),
                    border: IMessageDesignTokens.addressGlassBorder,
                    blur: Double(IMessageDesignTokens.addressGlassBlur),
                    translucency: Double(IMessageDesignTokens.addressGlassTranslucency),
                    refractionTop: Double(IMessageDesignTokens.addressGlassRefractionTop),
                    refractionMid: Double(IMessageDesignTokens.addressGlassRefractionMid),
                    specularStrength: Double(IMessageDesignTokens.addressGlassSpecularStrength),
                    innerShadow: Double(IMessageDesignTokens.addressGlassInnerShadow)
                )
            }
        case .topPenetrate:
            ZStack {
                shape
                    .fill(.thickMaterial)
                    .opacity(Double(IMessageDesignTokens.topNavPenetrateMaterialOpacity) * 0.72)
                    .mask(topPenetrateBlurGradient)
                shape
                    .fill(.regularMaterial)
                    .opacity(Double(IMessageDesignTokens.topNavPenetrateMaterialOpacity))
                    .mask(topPenetrateBlurGradient)
            }
        case .navigationBar:
            if #available(iOS 26, *) {
                SystemPopoverGlassView(cornerRadius: cornerRadius)
            } else {
                MenuPanelGlassBackground(
                    cornerRadius: cornerRadius,
                    tint: .clear,
                    border: .clear,
                    blur: Double(IMessageDesignTokens.addressGlassBlur),
                    translucency: 1,
                    refractionTop: 0,
                    refractionMid: 0,
                    specularStrength: 0,
                    innerShadow: 0
                )
            }
        case .chromeControl:
            ZStack {
                shape.fill(.regularMaterial).opacity(0.96)
                shape.fill(Color.white.opacity(materialWhiten))
            }
        case .chromeClose:
            ZStack {
                shape.fill(Color.white)
                shape.fill(Color.white.opacity(IMessageDesignTokens.chromeCloseSolidWhiten))
                shape.fill(Color.white.opacity(IMessageDesignTokens.chromeCloseMaterialWhiten))
                shape.fill(.regularMaterial).opacity(IMessageDesignTokens.chromeCloseBaseMaterialOpacity)
                shape.fill(Color.white.opacity(IMessageDesignTokens.chromeCloseSolidWhiten))
                shape.fill(Color.white.opacity(0.97))
                shape.fill(.thinMaterial).opacity(IMessageDesignTokens.chromeCloseFrostOpacity)
                shape.fill(.regularMaterial).opacity(0.22)
                shape.fill(
                    LinearGradient(
                        stops: [
                            .init(color: .white, location: 0),
                            .init(color: .white.opacity(0.82), location: 0.24),
                            .init(color: .white.opacity(0.38), location: 0.55),
                            .init(color: .clear, location: 1),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                shape.fill(
                    RadialGradient(
                        colors: [
                            .white.opacity(IMessageDesignTokens.chromeCloseSpecularStrength),
                            .white.opacity(0.42),
                            .clear,
                        ],
                        center: .init(x: 0.28, y: 0.16),
                        startRadius: 1,
                        endRadius: 30
                    )
                )
            }
        }
    }

    /// 关闭钮专用高光边（不走收发件人卡片叠层，避免发灰）
    private var chromeCloseEdgeOverlays: some View {
        let edgeBoost = Double(borderEmphasis)

        return ZStack {
            shape
                .inset(by: -0.55)
                .stroke(
                    Color(white: 0.58).opacity(Double(IMessageDesignTokens.addressGlassOuterGrayOpacity) * edgeBoost),
                    lineWidth: 0.5
                )

            shape.stroke(Color.white.opacity(min(1, 0.99 * edgeBoost)), lineWidth: 0.85)

            shape
                .inset(by: 0.8)
                .stroke(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.98 * edgeBoost),
                            .white.opacity(0.52 * edgeBoost),
                            .clear,
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.05
                )

            shape.fill(
                LinearGradient(
                    stops: [
                        .init(color: .white.opacity(Double(IMessageDesignTokens.chromeCloseTopHighlight) * edgeBoost), location: 0),
                        .init(color: .white.opacity(0.42 * edgeBoost), location: 0.3),
                        .init(color: .clear, location: 0.62),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }

    private var overlayFrost: Double {
        switch renderMode {
        case .chromeClose:
            return 0.38
        case .chromeControl:
            return frost * 0.42
        case .addressCard:
            return frost
        case .navigationBar:
            return 0
        case .topPenetrate:
            return frost
        }
    }

    /// 顶栏：上重下轻渐变雾（越靠顶越糊）
    private var topPenetrateBlurGradient: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: .black, location: 0),
                .init(color: .black.opacity(0.88), location: 0.28),
                .init(color: .black.opacity(0.52), location: 0.58),
                .init(color: .black.opacity(0.18), location: 0.82),
                .init(color: .clear, location: 1),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// 顶栏叠加：仅磨砂材质，零压暗
    private var topPenetrateOverlays: some View {
        let blurBoost = Double(IMessageDesignTokens.topNavPenetrateBlurStrength)
        return ZStack {
            shape
                .fill(.thickMaterial)
                .opacity(min(0.96, 0.44 + blurBoost * 0.52))
                .mask(topPenetrateBlurGradient)
            shape
                .fill(.regularMaterial)
                .opacity(min(0.92, 0.40 + blurBoost * 0.52))
                .mask(topPenetrateBlurGradient)
            shape
                .fill(.thinMaterial)
                .opacity(min(0.82, 0.30 + blurBoost * 0.52))
                .mask(topPenetrateBlurGradient)
        }
    }

    /// 菜单同款纯白折射/描边（略白于底色、低透光）
    private var menuMatchedOverlays: some View {
        ZStack {
            shape.fill(Color.white.opacity(Double(IMessageDesignTokens.addressGlassWhiten) * overlayFrost))

            shape.fill(Color.white.opacity(0.06 * overlayFrost))

            shape
                .fill(.thinMaterial)
                .opacity(Double(IMessageDesignTokens.addressGlassFrostMaterial) * overlayFrost)

            shape.fill(
                Color(white: 0.99).opacity(Double(IMessageDesignTokens.addressGlassMatteVeil) * overlayFrost)
            )

            shape.fill(
                LinearGradient(
                    stops: [
                        .init(color: .white.opacity(Double(IMessageDesignTokens.addressGlassRefractionTop) * overlayFrost), location: 0),
                        .init(color: .white.opacity(Double(IMessageDesignTokens.addressGlassRefractionMid) * overlayFrost), location: 0.38),
                        .init(color: .white.opacity(Double(IMessageDesignTokens.addressGlassRefractionMid) * 0.12 * overlayFrost), location: 0.72),
                        .init(color: .clear, location: 1),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )

            shape.fill(
                LinearGradient(
                    colors: [.clear, .black.opacity(Double(IMessageDesignTokens.addressGlassInnerShadow) * overlayFrost)],
                    startPoint: .center,
                    endPoint: .bottom
                )
            )

            let edgeBoost = Double(borderEmphasis)

            shape
                .inset(by: -0.55)
                .stroke(
                    Color(white: 0.58).opacity(Double(IMessageDesignTokens.addressGlassOuterGrayOpacity) * edgeBoost),
                    lineWidth: 0.5
                )

            shape.stroke(
                IMessageDesignTokens.addressGlassBorder.opacity((0.45 + overlayFrost * 0.45) * edgeBoost),
                lineWidth: 0.5
            )

            shape
                .inset(by: 0.8)
                .stroke(
                    LinearGradient(
                        colors: [
                            .white.opacity(Double(IMessageDesignTokens.addressGlassSpecularStrength) * overlayFrost * edgeBoost),
                            .white.opacity(Double(IMessageDesignTokens.addressGlassSpecularStrength) * 0.2 * overlayFrost * edgeBoost),
                            .clear,
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.8
                )
        }
    }
}
