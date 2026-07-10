import SwiftUI

/// 圆形液态玻璃按钮（返回、右下角新建）
struct NotesGlassCircleButton: View {
    let systemName: String
    var iconSize: CGFloat = NotesDesignTokens.Official.Nav.iconSize
    var weight: Font.Weight = .regular
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: iconSize, weight: weight))
                .foregroundStyle(IOSTheme.navIcon)
                .frame(
                    width: NotesDesignTokens.Official.Nav.buttonSize,
                    height: NotesDesignTokens.Official.Nav.buttonSize
                )
                .background {
                    NotesFrostedBackground.navButtonGlass()
                        .allowsHitTesting(false)
                }
                .clipShape(Circle())
                .shadow(
                    color: NotesFrostedBackground.addressCardLiftShadow.color,
                    radius: NotesFrostedBackground.addressCardLiftShadow.radius,
                    y: NotesFrostedBackground.addressCardLiftShadow.y
                )
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

/// 胶囊内图标槽（无独立底板，共享一颗胶囊毛玻璃）
struct NotesGlassIconSlot: View {
    let systemName: String
    var iconSize: CGFloat
    var weight: Font.Weight = .regular
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: iconSize, weight: weight))
                .foregroundStyle(IOSTheme.navIcon)
                .frame(
                    width: NotesDesignTokens.Official.Nav.buttonSize,
                    height: NotesDesignTokens.Official.Nav.buttonSize
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// 胶囊液态玻璃按钮组（右上撤回+分享+更多 / 底部三图标）
struct NotesGlassCapsuleGroup: View {
    let icons: [String]
    var iconSize: CGFloat = NotesDesignTokens.Official.Nav.iconSize
    var weight: Font.Weight = .regular
    var onTap: ((Int) -> Void)?

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(icons.enumerated()), id: \.offset) { index, name in
                NotesGlassIconSlot(systemName: name, iconSize: iconSize, weight: weight) {
                    onTap?(index)
                }
            }
        }
        .frame(height: NotesDesignTokens.Official.Nav.buttonSize)
        .background {
            NotesFrostedBackground.toolbarGlass()
                .allowsHitTesting(false)
        }
        .clipShape(Capsule())
        .shadow(
            color: NotesFrostedBackground.addressCardLiftShadow.color,
            radius: NotesFrostedBackground.addressCardLiftShadow.radius,
            y: NotesFrostedBackground.addressCardLiftShadow.y
        )
    }
}
