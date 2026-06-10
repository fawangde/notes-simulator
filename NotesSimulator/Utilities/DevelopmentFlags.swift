import Foundation

/// 本地开发开关（不改 Firebase 后台）
enum DevelopmentFlags {
    /// 功能测试期间跳过激活校验；上架前改回 `false`
    static let bypassActivation = true
}
