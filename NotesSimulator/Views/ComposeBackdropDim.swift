import SwiftUI

/// 已迁移至 `NotesView.notesLayer`：点「信息」后压暗备忘录主页，关闭信息页恢复。
/// 撰写页顶区保持透明，透过顶缝看到已压暗的备忘录（不再在撰写页内叠压暗层）。
enum ComposeBackdropDimming {
    static var opacity: CGFloat { IMessageDesignTokens.composeBackdropDimOpacity }
}
