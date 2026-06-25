import Foundation

enum PurchaseOrderStore {
    private static let pendingOrderKey = "purchase.pendingOrderId"

    static var pendingOrderId: String? {
        get { UserDefaults.standard.string(forKey: pendingOrderKey) }
        set {
            if let newValue {
                UserDefaults.standard.set(newValue, forKey: pendingOrderKey)
            } else {
                UserDefaults.standard.removeObject(forKey: pendingOrderKey)
            }
        }
    }
}
