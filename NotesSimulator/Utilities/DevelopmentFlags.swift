import Foundation

/// 本地开发开关（不改 Firebase 后台）
enum DevelopmentFlags {
    /// 功能测试期间跳过激活校验；上架前改回 `false`
    static let bypassActivation = true
    /// 真机布局探针：长按菜单展开完成后显示框线 + JSON（对照系统备忘录截图用）
    static let showPhoneMenuLayoutProbe = false
    /// 1718 气泡尾巴图形探针（锚点/控制点/尺寸，对照真机截图用；不依赖 Frida）
    static let showBubbleTailLayoutProbe = true
}
