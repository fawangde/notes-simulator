import SwiftUI

struct NotesClassicIconButton: View {
    let systemName: String
    var iconSize: CGFloat = NotesStyle1718Tokens.navIconSize
    var enabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: iconSize, weight: .regular))
                .foregroundStyle(NotesStyle1718Tokens.iconColor.opacity(enabled ? 1 : 0.35))
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}

struct NotesClassicBackButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: NotesStyle1718Tokens.navBackIcon)
                    .font(.system(size: 20, weight: .semibold))
                Text(NotesStyle1718Tokens.navBackTitle)
                    .font(NotesStyle1718Tokens.navBackFont)
            }
            .foregroundStyle(NotesStyle1718Tokens.iconColor)
            .frame(minHeight: 44, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
