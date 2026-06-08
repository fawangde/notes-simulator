import SwiftUI

struct ChineseKeyboardView: View {
    private let suggestions = ["我", "你", "信息", "好", "这", "是", "不", "这个", "没", "字"]

    var body: some View {
        VStack(spacing: 5) {
            HStack(spacing: 0) {
                ForEach(suggestions, id: \.self) { word in
                    Text(word)
                        .font(.system(size: 17))
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
            }
            .background(IOSTheme.keyboardBG)

            VStack(spacing: 5) {
                HStack(spacing: 5) {
                    key("，\n分词", small: true)
                    key("。!\nABC", small: true)
                    key("?\nDEF", small: true)
                    key("↵", gray: true, tall: true)
                }
                HStack(spacing: 5) {
                    key("A\nGHI")
                    key("B\nJKL")
                    key("C\nMNO")
                    Spacer(minLength: 52)
                }
                HStack(spacing: 5) {
                    key("D\nPQRS")
                    key("E\nTUV")
                    key("F\nWXYZ")
                    Spacer(minLength: 52)
                }
                HStack(spacing: 5) {
                    key("🌐", gray: true, compact: true)
                    key("选拼音", gray: true, wide: true)
                    key("空格", wide: true)
                    key("🎤", gray: true, compact: true)
                }
            }
            .padding(.horizontal, 3)
        }
        .padding(.bottom, 4)
        .background(IOSTheme.keyboardBG)
    }

    @ViewBuilder
    private func key(
        _ label: String,
        small: Bool = false,
        gray: Bool = false,
        tall: Bool = false,
        wide: Bool = false,
        compact: Bool = false
    ) -> some View {
        let parts = label.split(separator: "\n", omittingEmptySubsequences: false)
        VStack(spacing: 0) {
            Text(String(parts.first ?? ""))
                .font(.system(size: small ? 18 : 22, weight: .regular))
            if parts.count > 1, let sub = parts.last, !sub.isEmpty {
                Text(String(sub))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(
            maxWidth: wide ? .infinity : (compact ? 52 : .infinity),
            minHeight: tall ? 88 : 44
        )
        .background(gray ? Color(red: 172 / 255, green: 179 / 255, blue: 191 / 255) : Color(red: 252 / 255, green: 252 / 255, blue: 254 / 255))
        .clipShape(RoundedRectangle(cornerRadius: 5))
        .shadow(color: Color.black.opacity(0.12), radius: 0, y: 1)
    }
}
