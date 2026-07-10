import UIKit

final class ZGDataManager {
    static let shared = ZGDataManager()
    private init() {}

    private let emailKey = "zg.savedEmails"
    private let boomKey = "zg.savedBoomNums"

    func saveEmails(_ arr: [String]) {
        UserDefaults.standard.set(arr, forKey: emailKey)
    }

    func getEmails() -> [String] {
        UserDefaults.standard.stringArray(forKey: emailKey) ?? []
    }

    func saveBoomNums(_ arr: [String]) {
        UserDefaults.standard.set(arr, forKey: boomKey)
    }

    func getBoomNums() -> [String] {
        UserDefaults.standard.stringArray(forKey: boomKey) ?? []
    }
}
