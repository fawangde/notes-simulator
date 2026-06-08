import SwiftUI

/// CNCompose 分隔线（探针：separatorColor，高约 0.33pt，左右留白）
struct MessagesComposeHairline: View {
    var horizontalInset: CGFloat = IMessageDesignTokens.addressHairlineHorizontalInset

    var body: some View {
        Rectangle()
            .fill(Color(uiColor: .separator))
            .frame(height: IMessageDesignTokens.addressHairlineHeight)
            .padding(.horizontal, horizontalInset)
    }
}
