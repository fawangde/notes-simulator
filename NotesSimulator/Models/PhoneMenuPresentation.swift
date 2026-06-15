import Foundation

/// 号码菜单触发方式（iOS 17–18 与 iOS 26 共用传参）
enum PhoneMenuPresentation: Equatable {
    case tap
    case longPress
}
