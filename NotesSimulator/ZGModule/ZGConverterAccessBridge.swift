import UIKit

enum ZGConverterAccessBridge {
    static var canUse: () -> Bool = { true }
    static var deniedMessage: String = "当前不可用"
}
