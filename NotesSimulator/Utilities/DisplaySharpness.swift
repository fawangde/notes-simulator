import UIKit

enum KeyboardDismiss {
    static func resign() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}

enum DisplaySharpness {
    static var nativeScale: CGFloat {
        UIScreen.main.nativeScale
    }

    /// 让 UIKit 文本按设备物理像素栅格化，避免模拟器缩放发糊
    static func apply(to textView: UITextView) {
        let scale = textView.window?.screen.nativeScale ?? nativeScale
        textView.contentScaleFactor = scale
        textView.layer.contentsScale = scale
        textView.adjustsFontForContentSizeCategory = true
        textView.layoutManager.allowsNonContiguousLayout = false
        textView.clipsToBounds = false
    }
}
