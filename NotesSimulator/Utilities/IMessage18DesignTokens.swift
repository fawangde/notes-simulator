import SwiftUI
import UIKit

/// iOS 18 撰写页（扁平材质，非 iOS 26 玻璃）
enum IMessage18DesignTokens {
    static let layer1CornerRadius: CGFloat = 12
    /// 状态栏下留给缩小后备忘录的条带
    static let notesRevealGap: CGFloat = 10
    static let composeBackdropDimOpacity: CGFloat = 0.28

    static let layer1BackgroundUI = UIColor.systemBackground
    static let layer1Background = Color(uiColor: layer1BackgroundUI)

    static let navBarBaseHeight: CGFloat = 44
    /// 顶部位置不变，仅向下加高（原 88 过高，现为 75）
    static let navBarHeight: CGFloat = 75
    /// 导航栏与收件人区分割线（不透明，避免被导航底色盖住后透光）
    static let navRecipientDividerColorUI = UIColor(red: 198 / 255, green: 198 / 255, blue: 200 / 255, alpha: 1)
    static let navRecipientDividerColor = Color(uiColor: navRecipientDividerColorUI)
    /// 标题与「取消」相对原垂直位置下移
    static let navBarContentOffsetY: CGFloat = 10
    static let navBarBackgroundUI = UIColor(red: 240 / 255, green: 240 / 255, blue: 242 / 255, alpha: 1)
    static let navBarBackground = Color(uiColor: navBarBackgroundUI)
    static let navTitleFont = Font.system(size: 17, weight: .semibold)
    static let navTitleTracking: CGFloat = -0.41
    static let navCancelFont = Font.system(size: 17, weight: .regular)
    static let navCancelColor = NotesDetectedLinkColor.color
    static let navCancelTrailingPadding: CGFloat = 16

    static let addressLabelFont = Font.system(size: 15, weight: .regular)
    static let addressLabelFontUI = UIFont.systemFont(ofSize: 15, weight: .regular)
    static let addressLabelColorUI = UIColor(red: 60 / 255, green: 60 / 255, blue: 67 / 255, alpha: 0.6)
    static let addressLabelColor = Color(uiColor: addressLabelColorUI)
    static let addressLeadingInset: CGFloat = 16
    static let addressContentOffsetX: CGFloat = 2
    static let addressRowHeight: CGFloat = 40
    static let addressBackground = Color(uiColor: .systemBackground)
    static let addressSeparatorHeight: CGFloat = 1
    static let addressSeparatorColor = Color(uiColor: UIColor.separator)

    static let recipientPhoneTint = Color(red: 0, green: 122 / 255, blue: 1)
    static let recipientPhoneTintUI = UIColor(red: 0, green: 122 / 255, blue: 1, alpha: 1)
    static let recipientCapsuleHPadding: CGFloat = 9
    static let recipientCapsuleVPadding: CGFloat = 4
    static let recipientCapsuleFill = Color(uiColor: UIColor.systemGray3).opacity(0.34)

    /// 与 iOS 26 发件人徽标/蓝字一致
    static let senderLineTint = Color(red: 0, green: 0x7A / 255, blue: 1)
    static let senderLineTintUI = UIColor(red: 0, green: 0x7A / 255, blue: 1, alpha: 1)
    static let senderBadgeBackground = senderLineTint
    static let senderBadgeTextColor = Color(red: 0.52, green: 0.76, blue: 1.0)
    static let senderBadgeFontSize: CGFloat = 8
    static let senderBadgeHPadding: CGFloat = 2
    static let senderBadgeVPadding: CGFloat = 1
    static let senderBadgeCornerRadius: CGFloat = 2

    /// 绿色 SMS 空白会话
    static let smsGreenTint = Color(red: 52 / 255, green: 199 / 255, blue: 89 / 255)
    static let smsGreenTintUI = UIColor(red: 52 / 255, green: 199 / 255, blue: 89 / 255, alpha: 1)
    static let smsRecipientCapsuleFill = Color(uiColor: UIColor.systemGray3).opacity(0.34)
    static let smsSenderBadgeTextColor = Color.white
    static let smsSenderBadgeBackground = smsGreenTint

    static let inputPlaceholderText = "iMessage 信息"

    static func makeSMSDotLabelAttributed(
        font: UIFont,
        color: UIColor,
        dotScale: CGFloat = 1.55
    ) -> NSAttributedString {
        let bodyAttrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
        ]

        let emWidth = ("信" as NSString).size(withAttributes: bodyAttrs).width
        let dotFont = UIFont(descriptor: font.fontDescriptor, size: font.pointSize * dotScale)
        let dotChar = "·"
        let dotWidth = (dotChar as NSString).size(withAttributes: [
            .font: dotFont,
            .foregroundColor: color,
        ]).width
        let sidePad = max(0, (emWidth - dotWidth) / 2)
        let baselineOffset = (font.capHeight - dotFont.capHeight) / 2

        let result = NSMutableAttributedString(string: "信息", attributes: bodyAttrs)
        result.addAttribute(.kern, value: sidePad, range: NSRange(location: result.length - 1, length: 1))
        result.append(NSAttributedString(
            string: dotChar,
            attributes: [
                .font: dotFont,
                .foregroundColor: color,
                .baselineOffset: baselineOffset,
            ]
        ))
        result.addAttribute(.kern, value: sidePad, range: NSRange(location: result.length - 1, length: 1))
        result.append(NSAttributedString(string: "短信", attributes: bodyAttrs))
        return result
    }

    static func makeIMessageInputPlaceholderAttributed() -> NSAttributedString {
        NSAttributedString(
            string: inputPlaceholderText,
            attributes: [
                .font: UIFont.systemFont(ofSize: inputFontSize),
                .foregroundColor: inputPlaceholderColorUI,
            ]
        )
    }

    static func makeSMSInputPlaceholderAttributed() -> NSAttributedString {
        makeSMSDotLabelAttributed(
            font: .systemFont(ofSize: inputFontSize),
            color: inputPlaceholderColorUI
        )
    }

    static let layer3NavOffsetY: CGFloat = 0
    static let layer3ToolbarHeight: CGFloat = 54
    static let layer3ToolbarOffsetY: CGFloat = 5
    static let layer3KeyboardGap: CGFloat = 15
    static let layer3KeyboardOffsetY: CGFloat = 0
    static let layer3PlusSize: CGFloat = 36
    static let layer3InputHeight: CGFloat = 36
    static let layer3MicSize: CGFloat = 18

    /// 已送达底边与输入框上缘间距（非底栏/底缘）
    static let threadDeliveredAboveInput: CGFloat = 15
    /// 底栏在 contentInset 里占高（与 NewIMessageView1718.composerBottomReserve 一致，不含 keyboard/safe）
    static var composerToolbarReserveBlock: CGFloat {
        layer3ToolbarHeight
            + layer3ToolbarOffsetY
            + layer3KeyboardOffsetY
            + 12
    }
    /// 钉住线：已送达底边距 scroll 底（不含 keyboard/safe）= 输入框上缘 + threadDeliveredAboveInput
    static var threadDeliveredPinInsetFromScrollBottom: CGFloat {
        layer3ToolbarHeight
            - layer3ToolbarOffsetY
            - toolbarVerticalPadding
            + threadDeliveredAboveInput
    }
    static let layer2TimeOffsetY: CGFloat = 0
    static let threadTimestampBelowCard: CGFloat = 10
    static let threadBubbleBelowTimestamp: CGFloat = 5
    static let layer2ThreadPaddingH: CGFloat = 16
    /// 线程区气泡右缘距屏幕；尾巴伸出单独预留，此处仅管气泡本体对齐
    static let threadBubbleTrailingInset: CGFloat = 3
    static let threadBubbleMaxWidthReduction: CGFloat = 10
    /// 撰写页气泡最大宽度在屏宽比例基础上额外加宽
    static let bubbleMaxWidthExtra: CGFloat = 30
    /// 布局时为尾巴尖伸出额外留空，避免 scrollView 裁切
    static let bubbleTailClipReserveRight: CGFloat = 10
    static let bubbleTailClipReserveBottom: CGFloat = 6
    static let layer3AddressCardHPadding: CGFloat = 0

    static let threadMetaFontUI = UIFont.systemFont(ofSize: 12, weight: .medium)
    static let deliveredFontUI = UIFont.systemFont(ofSize: 11, weight: .medium)
    static let threadMetaTextUI = UIColor(red: 60 / 255, green: 60 / 255, blue: 67 / 255, alpha: 0.6)
    static let timestampLineSpacing: CGFloat = 2
    static let deliveredOffsetBelowTailBottom: CGFloat = 21

    static let bubblePaddingH: CGFloat = 11
    static let bubblePaddingV: CGFloat = 11
    static let bubbleMinWidth: CGFloat = 44
    static let bubbleMaxWidthFraction: CGFloat = 0.80
    static let bubbleFillLightUI = UIColor(red: 0, green: 122 / 255, blue: 1, alpha: 1)
    static let bubbleFillDarkUI = UIColor(red: 10 / 255, green: 132 / 255, blue: 1, alpha: 1)
    static var bubbleFillUI: UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark ? bubbleFillDarkUI : bubbleFillLightUI
        }
    }
    static let bubbleFontUI = UIFont.systemFont(ofSize: 17, weight: .regular)
    static let bubbleCornerRadius: CGFloat = 18
    static let bubbleMinHeight: CGFloat = 34

    // MARK: - 尾巴（iOS 16–18 经典 hook：右缘直线 → 上凹 cubic → 尖 → 下凸 cubic → 底边 C）
    static let bubbleTailRightEdgeInset: CGFloat = 15
    static let bubbleTailTipExtension: CGFloat = 6
    static let bubbleTailTipDrop: CGFloat = 3
    static let bubbleTailRootAlongBottom: CGFloat = 17
    /// 上弧 A→B 内凹 scooped（CP 相对 A）
    static let bubbleTailUpperCP1X: CGFloat = -3
    static let bubbleTailUpperCP1Y: CGFloat = 4
    static let bubbleTailUpperCP2X: CGFloat = 4
    static let bubbleTailUpperCP2Y: CGFloat = 10
    /// 下弧 B→C 外凸 hook（CP 相对 B）
    static let bubbleTailLowerCP1X: CGFloat = 4
    static let bubbleTailLowerCP1Y: CGFloat = 5
    static let bubbleTailLowerCP2X: CGFloat = -14
    static let bubbleTailLowerCP2Y: CGFloat = -1
    /// 仅 iOS 26 ChatKit 对照预设使用
    static let bubbleTailDropIOS26: CGFloat = 6.11

    static let toolbarHorizontalPadding: CGFloat = 12
    static let toolbarItemSpacing: CGFloat = 10
    static let toolbarVerticalPadding: CGFloat = 8
    static let plusIcon = "plus"
    static let plusIconSize: CGFloat = 15
    static let plusIconTintUI = UIColor.placeholderText
    static let plusButtonBackgroundUI = UIColor.systemGray6
    static let inputCornerRadius: CGFloat = 18
    static let inputFontSize: CGFloat = 17
    static let inputFieldHorizontalInset: CGFloat = 12
    static let inputBorderWidth: CGFloat = 1
    static let inputBorderColorUI = UIColor.separator
    static let inputBackgroundUI = UIColor.systemBackground
    static let inputPlaceholderColorUI = UIColor.placeholderText
    static let cursorColorUI = NotesDetectedLinkColor.uiColor
    static let micIcon = "mic.fill"
    static let micIconSize: CGFloat = 18

    // MARK: - iOS 18 转场（固定方案，勿改回 progress offset / scroll 冻结）
    /// 信息页打开：整页 `.move(edge: .bottom)` 一体上滑（与 iOS 26 同路径）
    static let messagesPresentDuration: CGFloat = 0.40
    /// 信息页关闭上滑
    static let messagesDismissDuration: CGFloat = 0.40
    /// 备忘录 FromVC 打开（缩小下沉，与信息页并行、各自动画）
    static let systemModalDuration: CGFloat = 0.30
    /// 点「取消」关闭时备忘录恢复速度
    static let fromViewDismissDuration: CGFloat = 0.30
    /// 保留供其它 spring 场景；信息页上滑已改用 messagesPresentDuration
    static let systemModalSpringResponse: CGFloat = 0.40
    static let systemModalSpringDamping: CGFloat = 0.82
    /// FromVC（备忘录）：均匀缩小 + 下沉 + 变暗，easeOut
    static let fromViewEndScale: CGFloat = 0.92
    static let fromViewEndAlpha: CGFloat = 0.85
    static let fromViewEndBlur: CGFloat = 12
    static let fromViewOffsetY: CGFloat = 36
    /// FromVC 顶边圆角（UIKit layer，随 transform 缩小）
    static let fromViewTopCornerRadius: CGFloat = 12
    /// ToVC（信息）：自底上滑 + 放大 + 淡入，spring
    static let toViewStartScale: CGFloat = 0.95
    /// 点「信息」时长按菜单淡出
    static let phoneMenuFadeOutDuration: CGFloat = 0.15
    static let dismissSpringResponse: CGFloat = 0.45
    static let dismissSpringDamping: CGFloat = 0.86

    static func addressChromeBottom(showsSenderRow: Bool) -> CGFloat {
        let nav = navBarHeight + layer3NavOffsetY + addressSeparatorHeight
        if showsSenderRow {
            return nav + addressRowHeight + addressSeparatorHeight + addressRowHeight + addressSeparatorHeight
        }
        return nav + addressRowHeight + addressSeparatorHeight
    }

    /// 安全区顶 + notesRevealGap 留给缩小的备忘录
    static func composeSheetTopInset(safeAreaTop: CGFloat) -> CGFloat {
        safeAreaTop + notesRevealGap
    }

}
