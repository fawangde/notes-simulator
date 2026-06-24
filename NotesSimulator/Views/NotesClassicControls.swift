import SwiftUI

struct NotesClassicIconButton: View {
    let systemName: String
    var iconSize: CGFloat = NotesStyle1718Tokens.navIconSize
    var iconColor: Color = NotesStyle1718Tokens.iconColor
    var enabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: iconSize, weight: .regular))
                .foregroundStyle(iconColor.opacity(enabled ? 1 : 0.35))
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}

struct NotesClassicBackButton: View {
    var iconColor: Color = NotesStyle1718Tokens.iconColor
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: NotesStyle1718Tokens.navBackIcon)
                    .font(.system(size: 20, weight: .semibold))
                Text(NotesStyle1718Tokens.navBackTitle)
                    .font(NotesStyle1718Tokens.navBackFont)
            }
            .foregroundStyle(iconColor)
            .frame(minHeight: 44, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
