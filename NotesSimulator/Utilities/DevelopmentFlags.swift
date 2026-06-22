import Foundation

/// 本地开发开关（不改 Firebase 后台）
enum DevelopmentFlags {
    /// 指定硬件 UDID 永久免激活；其余设备仍走正常激活流程
    private static let permanentBypassHardwareUDIDs: Set<String> = [
        DeviceIdentity.normalizedHardwareUDID("00008130-0002094936E0001C"),
    ]

    static var bypassActivation: Bool {
        guard let hardwareUDID = DeviceIdentity.hardwareUDID else { return false }
        return permanentBypassHardwareUDIDs.contains(
            DeviceIdentity.normalizedHardwareUDID(hardwareUDID)
        )
    }
    /// 真机布局探针：长按菜单展开完成后显示框线 + JSON（对照系统备忘录截图用）
    static let showPhoneMenuLayoutProbe = false
    /// 1718 气泡尾巴图形探针（锚点/控制点/尺寸，对照真机截图用；不依赖 Frida）
    static let showBubbleTailLayoutProbe = true
}
