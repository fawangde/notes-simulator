import SwiftUI
import UIKit

/// 备忘录 → 新信息撰写页（短信 / iMessage 共用，对齐 iOS 26.2 Messages 参数）
enum IMessageDesignTokens {
    // MARK: - 一、第 1 层白底（真机校准冻结 2026-06-07）

    /// 顶留备忘录条（≈ 状态栏高度），白底圆角卡片从其下缘起绘
    static let layer1TopInset: CGFloat = 59
    static let layer1BottomInset: CGFloat = 0
    static let layer1LeadingInset: CGFloat = 0
    static let layer1TrailingInset: CGFloat = 0
    static let layer1OffsetX: CGFloat = 0
    static let layer1OffsetY: CGFloat = 0
    static let layer1CornerRadius: CGFloat = 35
    /// 顶部留白区备忘录压暗（非安全区遮罩，仅盖住漏出的备忘录层）
    static let composeBackdropDimOpacity: CGFloat = 0.28

    // MARK: - 二、第 2 层（真机校准冻结 2026-06-07）

    static let layer2TimeOffsetX: CGFloat = 0
    /// 时间小字及以下线程内容上移（负值向上）
    static let layer2TimeOffsetY: CGFloat = -10
    /// 时间小字距收发件人卡片底 5pt；气泡距时间小字 5pt
    static let threadTimestampBelowCard: CGFloat = 5
    static let threadBubbleBelowTimestamp: CGFloat = 5
    /// 「已送达」距输入框顶 5pt（气泡先向下长，触及后改为上滚）
    static let threadDeliveredAboveInput: CGFloat = 5
    /// 短文案也可上滑：栈底留白，撑出可滚区间
    static let threadManualScrollSlack: CGFloat = 520
    static let layer2BubbleOffsetX: CGFloat = 0
    static let layer2BubbleOffsetY: CGFloat = 0
    static let layer2ThreadPaddingH: CGFloat = 16
    /// 发送气泡/图片右缘与收发件人卡片右缘对齐（= 卡片水平外边距）
    static let threadBubbleTrailingInset: CGFloat = layer3AddressCardHPadding

    // MARK: - 三、第 3 层（真机校准冻结 2026-06-07）

    static let layer3NavOffsetX: CGFloat = 0
    static let layer3NavOffsetY: CGFloat = 8
    static let layer3NavHeight: CGFloat = 56
    static let layer3CloseSize: CGFloat = 48
    static let layer3CloseOffsetX: CGFloat = -25
    static let layer3CloseTrailingPadding: CGFloat = 8

    static let layer3AddressOffsetX: CGFloat = 0
    static let layer3AddressOffsetY: CGFloat = 0
    static let layer3AddressCardTop: CGFloat = 24
    static let layer3AddressCardHPadding: CGFloat = 20
    static let layer3AddressCardRadius: CGFloat = 27
    static let layer3AddressRowHeight: CGFloat = 32

    static let layer3PlusOffsetX: CGFloat = 0
    static let layer3PlusOffsetY: CGFloat = 0
    static let layer3PlusSize: CGFloat = 36

    static let layer3InputOffsetX: CGFloat = 0
    static let layer3InputOffsetY: CGFloat = 0
    static let layer3InputHeight: CGFloat = 42
    static let layer3MicSize: CGFloat = 18

    static let layer3ToolbarOffsetX: CGFloat = 0
    static let layer3ToolbarOffsetY: CGFloat = 0
    static let layer3ToolbarHeight: CGFloat = 54
    /// 底栏底边与系统键盘顶边的间距
    static let layer3KeyboardGap: CGFloat = 15
    static let layer3KeyboardOffsetY: CGFloat = 0

    // MARK: - 四、根视图 / 聊天背景

    /// 第 1 层白底：比纯白暗 2%（0.98 灰阶）
    static let layer1BackgroundUI = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 0.10, alpha: 1)
            : UIColor(white: 0.98, alpha: 1)
    }
    static let layer1Background = Color(uiColor: layer1BackgroundUI)
    static let chatBackgroundLight = layer1Background
    static let chatBackgroundDark = Color(red: 0x1C / 255, green: 0x1C / 255, blue: 0x1E / 255)
    static let materialPlusOpacity: CGFloat = 0.66
    static let threadHorizontalPadding: CGFloat = layer2ThreadPaddingH

    // MARK: - 五、导航栏

    static let navBarHeight: CGFloat = layer3NavHeight
    static let navBarMaterialOpacity: CGFloat = 0.70
    /// 顶栏滚过采样：静止融底板，内容上穿时加深
    static let topNavGlassExtendBelow: CGFloat = 15
    static let topNavGlassHeight: CGFloat = layer3NavOffsetY + layer3NavHeight + topNavGlassExtendBelow
    /// 顶栏穿透：仅渐变模糊（不压暗、不叠色罩）
    static let topNavPenetrateBlurStrength: CGFloat = 1.0
    /// 顶栏材质层（上重下轻）
    static let topNavPenetrateMaterialOpacity: CGFloat = 0.84
    static let navTitleFont = Font.system(size: 17, weight: .bold)
    static let navControlSize: CGFloat = layer3CloseSize
    static let navCloseIconSize: CGFloat = 18
    static let navTint = Color(red: 0, green: 0x7A / 255, blue: 1)
    /// 收件人号码蓝（比 navTint 略淡）
    static let recipientPhoneTint = Color(red: 0.15, green: 0.58, blue: 1.0)
    static let recipientPhoneTintUI = UIColor(red: 0.15, green: 0.58, blue: 1, alpha: 1)

    // MARK: - 六、收发件人（CNCompose 卡片，浮在根材质之上）

    static let addressCardFill = Color(uiColor: .systemBackground)
    static let addressCardRadius: CGFloat = layer3AddressCardRadius
    static let addressCardOuterHPadding: CGFloat = layer3AddressCardHPadding
    static let addressCardTopSpacing: CGFloat = layer3AddressCardTop
    static let addressCardShadowColor = Color.black.opacity(0.12)
    static let addressCardShadowRadius: CGFloat = 8
    static let addressCardShadowY: CGFloat = 2
    // MARK: - 收发件人玻璃（对齐备忘录长按菜单 MenuPanelGlassBackground）

    /// 透光度：越低越厚实、越少透底
    static let addressGlassTranslucency: CGFloat = 0.9
    static let addressGlassBlur: CGFloat = 0.98
    static let addressGlassRefractionTop: CGFloat = 0.62
    static let addressGlassRefractionMid: CGFloat = 0.34
    static let addressGlassSpecularStrength: CGFloat = 0.74
    static let addressGlassInnerShadow: CGFloat = 0.09
    /// 比底色略白一层（叠在材质之上，拉开与 0.98 背景的色差）
    static let addressGlassWhiten: CGFloat = 0.52
    /// 磨砂雾面材质层（叠在白罩之上）
    static let addressGlassFrostMaterial: CGFloat = 0.46
    /// 哑光乳白 veil（减弱镜面感、偏磨砂）
    static let addressGlassMatteVeil: CGFloat = 0.12
    /// 卡片浮起阴影（强调在背景上层）
    static let addressGlassLiftShadowOpacity: CGFloat = 0.07
    static let addressGlassLiftShadowRadius: CGFloat = 14
    static let addressGlassLiftShadowY: CGFloat = 5
    /// 纯白高光外圈极淡灰边（肉眼几乎不可辨）
    static let addressGlassOuterGrayOpacity: CGFloat = 0.07
    static let addressGlassTint = Color(red: 1, green: 1, blue: 1)
    static let addressGlassBorder = Color.white
    static let addressRowHeight: CGFloat = layer3AddressRowHeight
    static let addressLeadingInset: CGFloat = 13
    static let addressLabelTopInset: CGFloat = 15
    /// 单卡模式卡片内容区高度（收件人垂直居中）
    static var singleCardAddressInnerHeight: CGFloat {
        layer3AddressRowHeight + addressLabelTopInset
    }
    static let addressHairlineHeight: CGFloat = 1.0 / 3.0
    /// 收发件人中间分隔线左右留白（不贴边）
    static let addressHairlineHorizontalInset: CGFloat = 18
    static let addressLabelFont = Font.system(size: 15, weight: .regular)
    /// 「收件人」「发件人」及冒号（比 secondaryLabel 略深一丁点）
    static let addressLabelColor = Color(uiColor: NotesSemanticColor.labelUI.withAlphaComponent(0.58))
    static let recipientCapsuleHPadding: CGFloat = 9
    static let recipientCapsuleVPadding: CGFloat = 4
    static let recipientCapsuleFill = Color(uiColor: UIColor.systemGray3).opacity(0.34)

    /// 发件人旁蓝色矩形徽标（内嵌小字「副号」）
    static let senderBadgeBackground = navTint
    static let senderBadgeTextColor = Color(red: 0.52, green: 0.76, blue: 1.0)
    static let senderBadgeFontSize: CGFloat = 8
    static let senderBadgeHPadding: CGFloat = 2
    static let senderBadgeVPadding: CGFloat = 1
    static let senderBadgeCornerRadius: CGFloat = 2
    /// 小控件玻璃高光/描边加强（加号、输入框）
    static let chromeControlBorderEmphasis: CGFloat = 1.68
    /// 关闭钮：更白磨砂、更强高光、明显浮起
    static let chromeCloseBorderEmphasis: CGFloat = 3.35
    static let chromeCloseMaterialWhiten: CGFloat = 1.0
    static let chromeCloseSolidWhiten: CGFloat = 0.99
    static let chromeCloseFrostOpacity: CGFloat = 1.0
    static let chromeCloseSpecularStrength: CGFloat = 1.0
    static let chromeCloseBaseMaterialOpacity: CGFloat = 0
    static let chromeCloseTopHighlight: CGFloat = 0.96
    static let chromeCloseLiftShadowOpacity: CGFloat = 0.11
    static let chromeCloseLiftShadowRadius: CGFloat = 10
    static let chromeCloseLiftShadowY: CGFloat = 4
    static let chromeControlMaterialWhiten: CGFloat = 0.66
    static let chromeControlSpecularAlpha: CGFloat = 0.84
    /// 小控件阴影（偏小、偏下，避免圆角顶部溢出糊团）
    static let chromeControlShadowOpacity: CGFloat = 0.05
    static let chromeControlShadowRadius: CGFloat = 5
    static let chromeControlShadowY: CGFloat = 2

    // MARK: - 四、气泡（发送 / iMessage 蓝）

    static let bubbleMaxWidthFraction: CGFloat = 0.80
    static let bubbleMinWidth: CGFloat = 44
    static let bubbleMinHeight: CGFloat = 34
    /// 四边与气泡内边距一致（与上边距相同）
    static let bubbleHPadding: CGFloat = 10
    static let bubbleVPadding: CGFloat = 10
    /// 标准圆角 22pt
    static let bubbleBodyCornerRadius: CGFloat = 22
    /// 同组末条（带尾巴）发送气泡：TL TR BR BL
    static let bubbleCornerTLGroupedLast: CGFloat = 5
    /// 撰写页单条发送（四角同半径）
    static let bubbleCornerTLCompose: CGFloat = 22
    static let bubbleCornerTR: CGFloat = 22
    static let bubbleCornerBR: CGFloat = 22
    static let bubbleCornerBL: CGFloat = 22
    /// 默认撰写页
    static var bubbleCornerTL: CGFloat { bubbleCornerTLCompose }
    /// 泪滴尾巴（发送右下）— ChatKit tailInsets.bottom ≈ 6.11
    static let bubbleTailDrop: CGFloat = 6.11
    static let bubbleTailWidth: CGFloat = 12
    static let bubbleTailHeight: CGFloat = 8
    static let bubbleTailTipRadius: CGFloat = 2
    static let bubbleTailInnerInset: CGFloat = 6
    /// 尾巴在宽度内下垂，不额外撑宽（对齐 CKBalloonView boundingBox）
    static let bubbleTailOuterInset: CGFloat = 0
    /// 遗留别名（布局兼容）
    static let bubbleTailColorWidth: CGFloat = bubbleTailWidth
    static let bubbleTailOverhang: CGFloat = bubbleTailOuterInset
    /// 「已送达」右缘对齐尾巴与气泡拼接点（tailAnchor）；垂直对齐尾巴最底点
    static let deliveredTrailingInset: CGFloat = 0
    /// 「已送达」相对尾巴最底点再下移
    static let deliveredOffsetBelowTailBottom: CGFloat = 10
    static let bubbleFont = Font.system(size: 17, weight: .regular)
    static let bubbleLineHeight: CGFloat = 22
    static let bubbleTextColor = Color.white
    /// 发送气泡蓝（基于收件人号码蓝略调淡）
    static let bubbleBlueFill: UIColor = {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        guard recipientPhoneTintUI.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        else {
            return recipientPhoneTintUI
        }
        return UIColor(
            hue: hue,
            saturation: min(1, saturation * 0.88),
            brightness: min(1, brightness + 0.02),
            alpha: alpha
        )
    }()
    static let bubbleTailAnchorXFraction: CGFloat = 0.920
    static let bubbleTailOffsetX: CGFloat = -0.7
    static let bubbleTailOffsetY: CGFloat = -4.0
    static let bubbleTailScale: CGFloat = 1.00
    static let bubbleBlueTop = bubbleBlueFill
    static let bubbleBlueBottom = bubbleBlueFill
    static let bubbleShadowColor = UIColor.clear
    static let bubbleShadowOffset = CGSize.zero
    static let bubbleShadowRadius: CGFloat = 0
    static let imageBubbleMaxWidth: CGFloat = 220

    // MARK: - 五、时间戳 / 状态

    static let timestampFont = Font.system(size: 12, weight: .medium)
    static let threadMetaFontUI = UIFont.systemFont(ofSize: 12, weight: .medium)
    static let deliveredFontUI = UIFont.systemFont(ofSize: 11, weight: .medium)
    static let timestampLineSpacing: CGFloat = 2
    /// 26.4 三行时间小字样式：「已加密」与「今天 HH:mm」间距
    static let thread264EncryptedToDateSpacing: CGFloat = 15
    /// Messages 线程头「已加密」锁标（SF Symbols）
    static let threadEncryptedLockSymbol = "lock.fill"
    static let threadEncryptedLockPointSize: CGFloat = 11
    static let threadEncryptedLockSpacing: CGFloat = 2
    /// 时间戳 / 已送达统一色（比 tertiaryLabel 略深）
    static let threadMetaTextUI = UIColor(red: 60 / 255, green: 60 / 255, blue: 67 / 255, alpha: 0.62)
    static let threadMetaText = Color(uiColor: threadMetaTextUI)
    static let statusOpacity: CGFloat = 1
    static let statusOuterSpacing: CGFloat = 2
    static let bubbleGroupSpacing: CGFloat = 10

    // MARK: - 六、输入栏

    static let toolbarInteractiveHeight: CGFloat = layer3ToolbarHeight
    static let toolbarMaterialOpacity: CGFloat = 0.74
    /// 加号左侧边距（与加号↔输入框间距相同）
    static let toolbarHorizontalPadding: CGFloat = 13
    static let toolbarItemSpacing: CGFloat = toolbarHorizontalPadding
    static let toolbarVerticalPadding: CGFloat = 6
    static let plusIcon = "plus"
    static let plusButtonSize: CGFloat = layer3PlusSize
    static let plusIconSize: CGFloat = 18
    static let inputCornerRadius: CGFloat = 22
    static let inputMinHeight: CGFloat = layer3InputHeight
    static let inputFontSize: CGFloat = 17
    /// 输入框内左右留白（对称）
    static let inputFieldHorizontalInset: CGFloat = 12
    static let inputBackgroundLight = UIColor.white.withAlphaComponent(0.9)
    static let inputBackgroundDark = UIColor(red: 0x48 / 255, green: 0x48 / 255, blue: 0x4A / 255, alpha: 0.8)
    /// 镂空麦克风（更大一号）
    static let micIcon = "mic"
    static let micIconSize: CGFloat = layer3MicSize

    // MARK: - 七、转场（菜单 → 信息）

    /// 上弹：匀速线性（当前）
    static let presentLinearDuration: CGFloat = 0.24
    /// 上弹：上一轮速度（0.32s）
    static let presentLinearDurationPreviousRound: CGFloat = 0.32
    /// 下收：弹簧（勿改）
    static let dismissSpringResponse: CGFloat = 0.45
    static let dismissSpringDamping: CGFloat = 0.86

    // 兼容旧引用
    static var bubbleCornerRadius: CGFloat { bubbleCornerTL }
    static var bubbleTailRadius: CGFloat { bubbleCornerBR }
    static var pageBackground: Color { chatBackgroundLight }
    static var deliveredFont: Font { timestampFont }
    static var deliveredSpacing: CGFloat { statusOuterSpacing }
    static var threadVerticalPadding: CGFloat { 14 }

    /// 导航 + 收发件人卡片底边（相对撰写页白底顶）
    static var addressChromeBottom: CGFloat {
        addressChromeBottom(showsSenderRow: true)
    }

    static func addressChromeBottom(showsSenderRow: Bool) -> CGFloat {
        let nav = layer3NavHeight + layer3NavOffsetY
        let addressTop = layer3AddressCardTop + layer3AddressOffsetY
        let rowBlock = layer3AddressRowHeight + addressLabelTopInset
        let hairline = addressHairlineHeight
        if showsSenderRow {
            return nav + addressTop + rowBlock + hairline + rowBlock + 6
        }
        return nav + addressTop + rowBlock + 6
    }
    static var inputBackground: Color { Color(uiColor: inputBackgroundLight) }
    static var navCloseButtonSize: CGFloat { 30 }
}
