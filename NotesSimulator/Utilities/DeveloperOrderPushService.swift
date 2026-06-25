import Foundation

/// 用户提交「我已支付」后，通过 Bark 向开发者 iPhone 推送新订单提醒（App 划掉也能收）。
enum DeveloperOrderPushService {
    static func notifyNewOrder(
        deviceKey: String,
        orderId: String,
        deviceMemo: String,
        product: PurchaseProduct,
        clickCount: Int?,
        paymentMethod: PurchasePaymentMethod
    ) {
        let key = deviceKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { return }

        var productLine = product.title
        if product.isClickBased, let clickCount {
            productLine += " × \(clickCount) 次"
        }

        let title = "备忘录 · 新订单待确认"
        let body = "设备 \(deviceMemo) · \(productLine) · \(paymentMethod.title) · \(product.priceText(clickCount: clickCount))"

        Task.detached(priority: .utility) {
            await send(deviceKey: key, title: title, body: body, orderId: orderId)
        }
    }

    private static func send(deviceKey: String, title: String, body: String, orderId: String) async {
        guard let url = URL(string: "https://api.day.app/\(deviceKey)") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 15

        let payload: [String: Any] = [
            "title": title,
            "body": body,
            "badge": 1,
            "group": "notes-purchase",
            "url": "purchase-order://\(orderId)",
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: payload) else { return }
        request.httpBody = data

        _ = try? await URLSession.shared.data(for: request)
    }
}
