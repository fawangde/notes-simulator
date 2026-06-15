import SwiftUI
import UIKit

/// 预览泡联系人占位：ContactAvatar1718 参考图裁圆（保留灰圆内白人形，裁掉方形白边）
enum ContactPlaceholderAvatar1718Style {
    static let diameter: CGFloat = PhoneMenu1718Layout.Design.defaultAvatarSize
    static let assetName = "ContactAvatar1718"
    /// 相对 `scaleAspectFill` 再放大，使灰圆贴齐圆形裁切（去掉 PNG 方形白边）
    static let imageFillScale: CGFloat = 1.20
}

struct ContactPlaceholderAvatar1718: UIViewRepresentable {
    var size: CGFloat = ContactPlaceholderAvatar1718Style.diameter
    var tuning: Notes1718TuningSettings = .default

    func makeUIView(context: Context) -> ContactPlaceholderAvatar1718UIView {
        let view = ContactPlaceholderAvatar1718UIView(size: size)
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ uiView: ContactPlaceholderAvatar1718UIView, context: Context) {
        uiView.apply(size: size)
    }
}

final class ContactPlaceholderAvatar1718UIView: UIView {
    private let imageView = UIImageView()

    init(size: CGFloat) {
        super.init(frame: CGRect(x: 0, y: 0, width: size, height: size))
        clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.image = UIImage(named: ContactPlaceholderAvatar1718Style.assetName)
        addSubview(imageView)
        apply(size: size)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    func apply(size: CGFloat) {
        frame.size = CGSize(width: size, height: size)
        layer.cornerRadius = size / 2

        let scale = ContactPlaceholderAvatar1718Style.imageFillScale
        let side = size * scale
        imageView.frame = CGRect(
            x: (size - side) / 2,
            y: (size - side) / 2,
            width: side,
            height: side
        )
    }
}
