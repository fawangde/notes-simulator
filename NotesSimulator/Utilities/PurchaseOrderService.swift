import FirebaseDatabase
import Foundation

enum PurchaseOrderError: LocalizedError {
    case firebaseUnavailable
    case networkUnavailable
    case invalidSelection
    case invalidClickCount
    case duplicatePendingOrder
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .firebaseUnavailable:
            return "无法连接 Firebase，请稍后重试"
        case .networkUnavailable:
            return "请先连接网络"
        case .invalidSelection:
            return "请选择套餐与收款方式"
        case .invalidClickCount:
            return "次数须在 \(PurchaseConfig.minClickCount)～\(PurchaseConfig.maxClickCount) 之间"
        case .duplicatePendingOrder:
            return "已有待确认订单，请等待开发者处理"
        case .permissionDenied:
            return "提交订单失败，请检查网络或稍后重试"
        }
    }
}

@MainActor
final class PurchaseOrderService {
    static let shared = PurchaseOrderService()

    private let ordersPath = "purchaseOrders"
    private var orderObserver: DatabaseHandle?
    private var observedOrderId: String?

    private var root: DatabaseReference? {
        FirebaseDatabaseConfig.reference()
    }

    private init() {}

    func deviceMemo() -> String {
        let id = DeviceIdentity.id.replacingOccurrences(of: "-", with: "").uppercased()
        return String(id.suffix(6))
    }

    func submitPaidOrder(
        product: PurchaseProduct,
        paymentMethod: PurchasePaymentMethod,
        clickCount: Int? = nil
    ) async throws -> String {
        guard root != nil else { throw PurchaseOrderError.firebaseUnavailable }
        guard NetworkMonitor.shared.isConnected else { throw PurchaseOrderError.networkUnavailable }

        let resolvedClickCount: Int?
        if product.isClickBased {
            guard let count = clickCount,
                  count >= PurchaseConfig.minClickCount,
                  count <= PurchaseConfig.maxClickCount else {
                throw PurchaseOrderError.invalidClickCount
            }
            resolvedClickCount = count
        } else {
            resolvedClickCount = nil
        }

        if let pendingId = PurchaseOrderStore.pendingOrderId {
            let existing = try await fetchOrder(id: pendingId)
            if existing?.status == .userClaimedPaid {
                throw PurchaseOrderError.duplicatePendingOrder
            }
            PurchaseOrderStore.pendingOrderId = nil
        }

        guard let ordersRef = root?.child(ordersPath) else {
            throw PurchaseOrderError.firebaseUnavailable
        }
        guard let orderId = ordersRef.childByAutoId().key else {
            throw PurchaseOrderError.firebaseUnavailable
        }

        let deviceId = DeviceIdentity.id
        let now = Date().timeIntervalSince1970 * 1000
        var payload: [String: Any] = [
            "deviceId": deviceId,
            "deviceMemo": deviceMemo(),
            "product": product.rawValue,
            "amount": product.amountYuan(clickCount: resolvedClickCount),
            "paymentMethod": paymentMethod.rawValue,
            "status": PurchaseOrderStatus.userClaimedPaid.rawValue,
            "createdAt": now,
            "updatedAt": now,
        ]
        if let resolvedClickCount {
            payload["clickCount"] = resolvedClickCount
        }

        try await setValue(at: ordersRef.child(orderId), payload)
        PurchaseOrderStore.pendingOrderId = orderId
        DeveloperOrderPushService.notifyNewOrder(
            deviceKey: PurchaseConfig.barkDeviceKey,
            orderId: orderId,
            deviceMemo: deviceMemo(),
            product: product,
            clickCount: resolvedClickCount,
            paymentMethod: paymentMethod
        )
        return orderId
    }

    /// 用户退出/后台后再打开时：拉取订单状态并继续监听，确保开发者确认后能自动激活。
    func reconcilePendingOrder(app: AppState) async {
        guard !app.isActivated, !DevelopmentFlags.bypassActivation else { return }
        guard PurchaseOrderStore.pendingOrderId != nil else { return }
        guard NetworkMonitor.shared.isConnected else { return }

        guard let orderId = PurchaseOrderStore.pendingOrderId else { return }

        observePendingOrder(orderId: orderId) { order in
            Task { @MainActor in
                guard let order else { return }
                await self.applyOrderOutcome(order, app: app)
            }
        }

        do {
            if let order = try await fetchOrder(id: orderId) {
                await applyOrderOutcome(order, app: app)
            }
        } catch {
            // 网络暂时失败时保留 pending，下次回到前台再试
        }
    }

    func applyOrderOutcome(_ order: PurchaseOrder, app: AppState) async {
        clearPendingIfTerminal(order)
        switch order.status {
        case .userClaimedPaid:
            return
        case .fulfilled:
            guard let code = order.activationCode, !code.isEmpty else { return }
            guard !app.isActivated else {
                stopObserving()
                return
            }
            do {
                try await app.activate(with: code)
                stopObserving()
                app.purchaseActivationErrorMessage = nil
                app.showPurchaseActivationSuccessAlert = true
            } catch {
                app.purchaseActivationErrorMessage = ActivationErrorMapper.message(for: error)
            }
        case .rejected:
            stopObserving()
            app.showPurchasePaymentRejectedAlert = true
        }
    }

    func fetchOrder(id: String) async throws -> PurchaseOrder? {
        guard let ref = root?.child(ordersPath).child(id) else {
            throw PurchaseOrderError.firebaseUnavailable
        }
        let data = try await fetchData(at: ref)
        guard !data.isEmpty else { return nil }
        return PurchaseOrder(id: id, data: data)
    }

    func observePendingOrder(
        orderId: String,
        onUpdate: @escaping (PurchaseOrder?) -> Void
    ) {
        stopObserving()
        guard let ref = root?.child(ordersPath).child(orderId) else {
            onUpdate(nil)
            return
        }

        observedOrderId = orderId
        orderObserver = ref.observe(.value) { snapshot in
            Task { @MainActor in
                guard snapshot.exists(),
                      let dict = Self.dictionary(from: snapshot.value),
                      let order = PurchaseOrder(id: orderId, data: dict) else {
                    onUpdate(nil)
                    return
                }
                onUpdate(order)
            }
        }
    }

    func stopObserving() {
        if let observer = orderObserver, let orderId = observedOrderId,
           let ref = root?.child(ordersPath).child(orderId) {
            ref.removeObserver(withHandle: observer)
        }
        orderObserver = nil
        observedOrderId = nil
    }

    func clearPendingIfTerminal(_ order: PurchaseOrder) {
        guard order.status == .fulfilled || order.status == .rejected else { return }
        if PurchaseOrderStore.pendingOrderId == order.id {
            PurchaseOrderStore.pendingOrderId = nil
        }
    }

    private func setValue(at ref: DatabaseReference, _ values: [String: Any]) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            ref.setValue(values) { error, _ in
                if let error {
                    continuation.resume(throwing: Self.mapFirebaseError(error))
                } else {
                    continuation.resume()
                }
            }
        }
    }

    private func fetchData(at ref: DatabaseReference) async throws -> [String: Any] {
        try await withCheckedThrowingContinuation { continuation in
            ref.getData { error, snapshot in
                if let error {
                    continuation.resume(throwing: Self.mapFirebaseError(error))
                    return
                }
                guard let snapshot, snapshot.exists() else {
                    continuation.resume(returning: [:])
                    return
                }
                continuation.resume(returning: Self.dictionary(from: snapshot.value) ?? [:])
            }
        }
    }

    private static func dictionary(from value: Any?) -> [String: Any]? {
        if let dict = value as? [String: Any] { return dict }
        if let dict = value as? [String: NSObject] {
            return dict.reduce(into: [String: Any]()) { $0[$1.key] = $1.value }
        }
        if let dict = value as? NSDictionary {
            var result: [String: Any] = [:]
            for case let key as String in dict.allKeys {
                result[key] = dict[key]
            }
            return result
        }
        return nil
    }

    private static func mapFirebaseError(_ error: Error) -> Error {
        let ns = error as NSError
        let message = ns.localizedDescription.lowercased()
        if ns.domain == "com.firebase",
           message.contains("permission") || message.contains("denied") || ns.code == 1 {
            return PurchaseOrderError.permissionDenied
        }
        return error
    }
}
