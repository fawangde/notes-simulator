import UIKit

enum PhoneUtilities {
    static let phonePattern = #/1[3-9]\d{9}/#

    // FROZEN — 预览泡布局字宽倍数已定型，勿改
    /// 正文号码首行缩进：1.5 个数字宽度
    static let phoneLeadingDigitSpacing: CGFloat = 1.5
    /// 预览泡左侧留白字宽数（与右侧对称，号码居中；含伸出主页号码左缘部分）
    static let previewBubbleLeftExtendDigits: CGFloat = 1.85
    /// 预览泡 / 长按菜单整体右移字宽数
    static let previewBubbleShiftRightDigits: CGFloat = 2.0
    /// 预览泡右侧留白字宽数（与左侧对称）
    static let previewBubbleRightExtendDigits: CGFloat = 1.85
    /// 预览泡内号码左移字宽数（泡左缘不动，右侧同比收窄以保持居中）
    static let previewBubbleNumberShiftLeftDigits: CGFloat = 0.5

    static func formatIMessage(_ phone: String) -> String {
        guard phone.count == 11 else { return phone }
        let a = phone.prefix(3)
        let b = phone.dropFirst(3).prefix(4)
        let c = phone.suffix(4)
        return "+86 \(a) \(b) \(c)"
    }

    /// 富文本与 plainText 字符一一对应，不插入附件/额外换行，保证可正常编辑
    @MainActor
    static func attributedBody(
        _ text: String,
        hiddenPhone: String? = nil,
        compatibleWith traitCollection: UITraitCollection = .current
    ) -> NSAttributedString {
        let bodyFont = IOSTheme.bodyUIFont(compatibleWith: traitCollection)
        let phoneFont = IOSTheme.phoneUIFont(
            baseSize: NotesDesignTokens.PhoneLink.fontSize,
            compatibleWith: traitCollection
        )
        let scale = phoneFont.pointSize / NotesDesignTokens.Official.Body.fontSize
        let rowHeight = NotesDesignTokens.Official.Body.phoneListRowHeight * scale
        let paragraphGap = NotesDesignTokens.Official.Body.phoneListParagraphSpacing * scale
        let indentWidth = NotesDesignTokens.oneDigitWidth(for: NotesDesignTokens.PhoneLink.fontSize) * phoneLeadingDigitSpacing

        let baseStyle = NSMutableParagraphStyle()
        baseStyle.minimumLineHeight = rowHeight
        baseStyle.maximumLineHeight = rowHeight
        baseStyle.paragraphSpacing = paragraphGap
        baseStyle.lineBreakMode = .byWordWrapping

        let baseAttrs: [NSAttributedString.Key: Any] = [
            .font: bodyFont,
            .foregroundColor: IOSTheme.labelPrimaryUI,
            .paragraphStyle: baseStyle,
        ]

        let result = NSMutableAttributedString(string: text, attributes: baseAttrs)
        let nsText = text as NSString

        for match in text.matches(of: phonePattern) {
            let phone = String(match.output)
            let range = NSRange(match.range, in: text)
            let paraRange = nsText.paragraphRange(for: range)

            let phoneStyle = (baseStyle.mutableCopy() as! NSMutableParagraphStyle)
            phoneStyle.firstLineHeadIndent = indentWidth

            var phoneAttrs: [NSAttributedString.Key: Any] = [
                .font: phoneFont,
                .paragraphStyle: phoneStyle,
                .phoneNumber: phone,
            ]

            if phone == hiddenPhone {
                phoneAttrs[.foregroundColor] = UIColor.clear
                phoneAttrs[.underlineStyle] = NSUnderlineStyle.single.rawValue
                phoneAttrs[.underlineColor] = UIColor.clear
            } else {
                phoneAttrs[.foregroundColor] = NotesDesignTokens.PhoneLink.uiColor
                phoneAttrs[.underlineStyle] = NSUnderlineStyle.single.rawValue
                phoneAttrs[.underlineColor] = NotesDesignTokens.PhoneLink.uiColor
            }

            result.addAttributes(phoneAttrs, range: range)
            result.addAttribute(.paragraphStyle, value: phoneStyle, range: paraRange)
        }

        return result
    }

    static func phone(at point: CGPoint, in textView: UITextView) -> (phone: String, rect: CGRect)? {
        var fraction: CGFloat = 0
        let index = textView.layoutManager.characterIndex(
            for: point,
            in: textView.textContainer,
            fractionOfDistanceBetweenInsertionPoints: &fraction
        )
        guard index < textView.textStorage.length else { return nil }

        var effective = NSRange(location: 0, length: 0)
        let attrs = textView.textStorage.attributes(at: index, effectiveRange: &effective)
        guard let phone = attrs[.phoneNumber] as? String else { return nil }

        let glyphRange = textView.layoutManager.glyphRange(
            forCharacterRange: effective,
            actualCharacterRange: nil
        )
        var rect = textView.layoutManager.boundingRect(
            forGlyphRange: glyphRange,
            in: textView.textContainer
        )
        rect.origin.x += textView.textContainerInset.left
        rect.origin.y += textView.textContainerInset.top
        rect = textView.convert(rect, to: textView.window)
        return (phone, rect)
    }
}

extension NSAttributedString.Key {
    static let phoneNumber = NSAttributedString.Key("NotesSimulatorPhoneNumber")
}
