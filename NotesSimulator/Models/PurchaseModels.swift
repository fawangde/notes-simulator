import Foundation

/// 收款码图片资源名（位于 Assets.xcassets）。
enum PurchaseConfig {
    static let wechatQRAssetName = "WeChatPayQR"
    static let alipayQRAssetName = "AlipayQR"
    static let pricePerClick = 6
    static let minClickCount = 1
    static let maxClickCount = 100

    /// Bark 设备 Key：在 Bark App 首页复制；留空则不推送。
    static let barkDeviceKey = "fYgztjBs5oPcoo75owCw5F"
}

enum PurchaseProduct: String, CaseIterable, Identifiable, Codable {
    case oneDay = "1day"
    case threeDays = "3days"
    case thirtyDays = "30days"
    case clicks = "clicks"

    var id: String { rawValue }

    static func from(stored raw: String) -> PurchaseProduct? {
        if raw == "1click" { return .clicks }
        return PurchaseProduct(rawValue: raw)
    }

    var isClickBased: Bool { self == .clicks }

    var title: String {
        switch self {
        case .oneDay: return "1 天"
        case .threeDays: return "3 天"
        case .thirtyDays: return "30 天（1 个月）"
        case .clicks: return "按次数"
        }
    }

    var listSubtitle: String {
        switch self {
        case .oneDay: return "¥50"
        case .threeDays: return "¥100"
        case .thirtyDays: return "¥700"
        case .clicks: return "¥\(PurchaseConfig.pricePerClick)/次，滑动选择 1～100 次"
        }
    }

    func amountYuan(clickCount: Int? = nil) -> Int {
        switch self {
        case .oneDay: return 50
        case .threeDays: return 100
        case .thirtyDays: return 700
        case .clicks:
            let count = clickCount ?? PurchaseConfig.minClickCount
            return count * PurchaseConfig.pricePerClick
        }
    }

    func priceText(clickCount: Int? = nil) -> String {
        "¥\(amountYuan(clickCount: clickCount))"
    }
}

enum PurchasePaymentMethod: String, CaseIterable, Identifiable, Codable {
    case wechat
    case alipay
    case faceToFace

    var id: String { rawValue }

    var title: String {
        switch self {
        case .wechat: return "微信"
        case .alipay: return "支付宝"
        case .faceToFace: return "面子支付"
        }
    }

    var showsQRCode: Bool {
        switch self {
        case .wechat, .alipay: return true
        case .faceToFace: return false
        }
    }
}

enum PurchaseOrderStatus: String, Codable {
    case userClaimedPaid
    case fulfilled
    case rejected
}

struct PurchaseOrder: Identifiable, Equatable {
    let id: String
    let deviceId: String
    let deviceMemo: String
    let product: PurchaseProduct
    let clickCount: Int?
    let amount: Int
    let paymentMethod: PurchasePaymentMethod
    let status: PurchaseOrderStatus
    let createdAt: TimeInterval
    let updatedAt: TimeInterval
    let activationCode: String?

    init?(id: String, data: [String: Any]) {
        guard
            let deviceId = data["deviceId"] as? String,
            let deviceMemo = data["deviceMemo"] as? String,
            let productRaw = data["product"] as? String,
            let product = PurchaseProduct.from(stored: productRaw),
            let amount = RTDBValue.int(from: data["amount"]),
            let paymentRaw = data["paymentMethod"] as? String,
            let paymentMethod = PurchasePaymentMethod(rawValue: paymentRaw),
            let statusRaw = data["status"] as? String,
            let status = PurchaseOrderStatus(rawValue: statusRaw),
            let createdAt = RTDBValue.double(from: data["createdAt"]),
            let updatedAt = RTDBValue.double(from: data["updatedAt"])
        else {
            return nil
        }

        self.id = id
        self.deviceId = deviceId
        self.deviceMemo = deviceMemo
        self.product = product
        self.clickCount = RTDBValue.int(from: data["clickCount"])
        self.amount = amount
        self.paymentMethod = paymentMethod
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.activationCode = data["activationCode"] as? String
    }
}
