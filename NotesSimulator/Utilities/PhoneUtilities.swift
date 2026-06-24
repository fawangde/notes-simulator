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

    static func formatSpacedMobile(_ phone: String) -> String {
        let digits = phone.filter(\.isNumber)
        guard digits.count == 11 else { return phone }
        let i = digits.index(digits.startIndex, offsetBy: 3)
        let j = digits.index(i, offsetBy: 4)
        return "\(digits[..<i]) \(digits[i..<j]) \(digits[j...])"
    }

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
        compatibleWith traitCollection: UITraitCollection = .current,
        tuning1718: Notes1718TuningSettings? = nil,
        tuning26: Notes26TuningSettings? = nil
    ) -> NSAttributedString {
        let bodyBaseSize: CGFloat
        let phoneBaseSize: CGFloat
        let textColor: UIColor
        let rowHeight: CGFloat
        let paragraphGap: CGFloat

        if let tuning1718 {
            bodyBaseSize = CGFloat(tuning1718.bodyFontSize)
            phoneBaseSize = CGFloat(tuning1718.phoneFontSize)
            textColor = tuning1718.themeTextUIColor()
            rowHeight = tuning1718.bodyPhoneLineHeight
            paragraphGap = tuning1718.bodyPhoneParagraphSpacing
        } else if let tuning26 {
            bodyBaseSize = CGFloat(tuning26.bodyFontSize)
            phoneBaseSize = CGFloat(tuning26.phoneFontSize)
            textColor = tuning26.bodyTextUIColor()
            rowHeight = tuning26.bodyPhoneLineHeight
            paragraphGap = tuning26.bodyPhoneParagraphSpacing
        } else {
            bodyBaseSize = NotesDesignTokens.Official.Body.fontSize
            phoneBaseSize = NotesDesignTokens.PhoneLink.fontSize
            textColor = NotesSemanticColor.labelUI
            let scale = CGFloat(1)
            rowHeight = NotesDesignTokens.Official.Body.phoneListRowHeight * scale
            paragraphGap = NotesDesignTokens.Official.Body.phoneListParagraphSpacing * scale
        }

        let bodyFont = IOSTheme.scaledUIFont(
            baseSize: bodyBaseSize,
            weight: NotesDesignTokens.Official.Body.weight,
            compatibleWith: traitCollection
        )
        let phoneFont = IOSTheme.phoneUIFont(
            baseSize: phoneBaseSize,
            compatibleWith: traitCollection
        )
        let indentWidth = NotesDesignTokens.oneDigitWidth(for: phoneBaseSize) * phoneLeadingDigitSpacing

        let baseStyle = NSMutableParagraphStyle()
        baseStyle.minimumLineHeight = rowHeight
        baseStyle.maximumLineHeight = rowHeight
        baseStyle.paragraphSpacing = paragraphGap
        baseStyle.lineBreakMode = .byWordWrapping

        let baseAttrs: [NSAttributedString.Key: Any] = [
            .font: bodyFont,
            .foregroundColor: textColor,
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

    /// 正文号码在 `textView` 坐标系下的字形包围盒
    static func rect(forPhone phone: String, in textView: UITextView) -> CGRect? {
        let storage = textView.textStorage
        var matchRange: NSRange?
        storage.enumerateAttribute(.phoneNumber, in: NSRange(location: 0, length: storage.length)) { value, range, stop in
            guard let matched = value as? String, matched == phone else { return }
            matchRange = range
            stop.pointee = true
        }
        guard let range = matchRange else { return nil }

        let glyphRange = textView.layoutManager.glyphRange(
            forCharacterRange: range,
            actualCharacterRange: nil
        )
        var rect = textView.layoutManager.boundingRect(
            forGlyphRange: glyphRange,
            in: textView.textContainer
        )
        rect.origin.x += textView.textContainerInset.left
        rect.origin.y += textView.textContainerInset.top
        return rect
    }
}

extension NSAttributedString.Key {
    static let phoneNumber = NSAttributedString.Key("NotesSimulatorPhoneNumber")
}

// MARK: - 信息气泡链接下划线

/// 信息气泡正文：识别链接（如 example.com），下划线与正文同色
enum BubbleTextLinkFormatting {
    static func attributedString(
        for text: String,
        font: UIFont,
        textColor: UIColor,
        kern: CGFloat = 0
    ) -> NSAttributedString {
        let baseAttrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor,
            .kern: kern,
        ]
        guard !text.isEmpty else {
            return NSAttributedString(string: text, attributes: baseAttrs)
        }

        let nsText = text as NSString
        let length = nsText.length
        guard length > 0 else {
            return NSAttributedString(string: text, attributes: baseAttrs)
        }

        let result = NSMutableAttributedString(string: text, attributes: baseAttrs)
        let fullRange = NSRange(location: 0, length: length)
        let linkAttrs = linkAttributes(textColor: textColor)

        for range in linkRanges(in: text, nsText: nsText, fullRange: fullRange) {
            result.addAttributes(linkAttrs, range: range)
        }
        return result
    }

    private static func linkAttributes(textColor: UIColor) -> [NSAttributedString.Key: Any] {
        [
            .foregroundColor: textColor,
            .underlineStyle: NSUnderlineStyle.single.rawValue,
            .underlineColor: textColor,
        ]
    }

    private static func linkRanges(
        in text: String,
        nsText: NSString,
        fullRange: NSRange
    ) -> [NSRange] {
        var ranges: [NSRange] = []
        ranges.append(contentsOf: detectorLinkRanges(in: text, maxLength: fullRange.length))
        ranges.append(contentsOf: bareDomainRanges(in: nsText, maxLength: fullRange.length, excluding: ranges))
        return mergedRanges(ranges, maxLength: fullRange.length)
    }

    private static func detectorLinkRanges(in text: String, maxLength: Int) -> [NSRange] {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return []
        }
        var ranges: [NSRange] = []
        let fullRange = NSRange(location: 0, length: maxLength)
        detector.enumerateMatches(in: text, options: [], range: fullRange) { match, _, _ in
            guard let match else { return }
            if match.url?.scheme?.lowercased() == "mailto" { return }
            if let safe = clippedRange(match.range, maxLength: maxLength) {
                ranges.append(safe)
            }
        }
        return ranges
    }

    private static func bareDomainRanges(
        in nsText: NSString,
        maxLength: Int,
        excluding existing: [NSRange]
    ) -> [NSRange] {
        var ranges: [NSRange] = []
        var index = 0

        while index < maxLength {
            guard isDomainBodyChar(nsText.character(at: index)) else {
                index += 1
                continue
            }
            if index > 0, isDomainBodyChar(nsText.character(at: index - 1)) {
                index += 1
                continue
            }

            var end = index
            var lastDot = -1
            while end < maxLength {
                let scalar = nsText.character(at: end)
                if scalar == 46 {
                    lastDot = end
                    end += 1
                    continue
                }
                if isDomainBodyChar(scalar) {
                    end += 1
                    continue
                }
                if scalar == 47, lastDot >= 0 {
                    end += 1
                    while end < maxLength, !isWhitespace(nsText.character(at: end)) {
                        end += 1
                    }
                }
                break
            }

            if lastDot >= 0 {
                let tldStart = lastDot + 1
                let tldLength = end - tldStart
                if tldLength >= 2, isLetterTLD(nsText, start: tldStart, length: tldLength) {
                    let candidate = NSRange(location: index, length: end - index)
                    if let safe = clippedRange(candidate, maxLength: maxLength),
                       !overlapsExisting(safe, existing),
                       !overlapsExisting(safe, ranges) {
                        ranges.append(safe)
                    }
                }
            }

            index = max(index + 1, end)
        }

        return ranges
    }

    private static func mergedRanges(_ ranges: [NSRange], maxLength: Int) -> [NSRange] {
        ranges
            .compactMap { clippedRange($0, maxLength: maxLength) }
            .sorted { $0.location < $1.location }
    }

    private static func clippedRange(_ range: NSRange, maxLength: Int) -> NSRange? {
        guard range.location != NSNotFound,
              range.length > 0,
              range.location >= 0,
              range.location < maxLength else {
            return nil
        }
        let end = min(range.location + range.length, maxLength)
        let length = end - range.location
        guard length > 0 else { return nil }
        return NSRange(location: range.location, length: length)
    }

    private static func overlapsExisting(_ range: NSRange, _ existing: [NSRange]) -> Bool {
        existing.contains { NSIntersectionRange($0, range).length > 0 }
    }

    private static func isDomainBodyChar(_ scalar: unichar) -> Bool {
        (48...57).contains(scalar)
            || (65...90).contains(scalar)
            || (97...122).contains(scalar)
            || scalar == 45
    }

    private static func isWhitespace(_ scalar: unichar) -> Bool {
        scalar == 32 || scalar == 9 || scalar == 10 || scalar == 13
    }

    private static func isLetterTLD(_ nsText: NSString, start: Int, length: Int) -> Bool {
        guard length >= 2 else { return false }
        for offset in 0..<length {
            let scalar = nsText.character(at: start + offset)
            guard (65...90).contains(scalar) || (97...122).contains(scalar) else {
                return false
            }
        }
        return true
    }
}
