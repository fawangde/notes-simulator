import Foundation

enum ActivationMode: String, Codable, Equatable {
    case time
    case clicks
}

struct ActivationOutcome: Equatable {
    let mode: ActivationMode
    let expiresAt: Date?
    let remainingClicks: Int?
}
