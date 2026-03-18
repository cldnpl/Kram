import Foundation
import FirebaseAuth

enum SubscriptionTier: String, CaseIterable, Codable {
    case free
    case premium

    static let userDefaultsKey = "subscription_tier"

    static let premiumProductID = "com.kram.mathquest.subscription.premium.monthly"

    // Legacy product IDs kept for migration of existing subscribers.
    static let legacyProProductID = "com.kram.mathquest.subscription.pro.monthly"
    static let legacyMaxProductID = "com.kram.mathquest.subscription.max.monthly"

    private static let developerAppleEmails: Set<String> = [
        "napolitano.claudia@icloud.com",
    ]

    static var paidProductIDs: [String] {
        [premiumProductID, legacyProProductID, legacyMaxProductID]
    }

    static var current: SubscriptionTier {
        if isDeveloperOverrideActive {
            return .premium
        }
        guard let raw = UserDefaults.standard.string(forKey: userDefaultsKey) else {
            return .free
        }
        // Migrate persisted legacy values on read.
        switch raw {
        case "pro", "max", "premium":
            return .premium
        default:
            return .free
        }
    }

    static var isDeveloperOverrideActive: Bool {
        guard UserDefaults.standard.bool(forKey: "session_logged_in") else {
            return false
        }
        guard let user = Auth.auth().currentUser else {
            return false
        }

        let hasAppleProvider = user.providerData.contains { $0.providerID == "apple.com" }
        guard hasAppleProvider else {
            return false
        }

        let email = (user.email ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        return developerAppleEmails.contains(email)
    }

    var displayName: String {
        let lang = UserDefaults.standard.string(forKey: "settings_language") ?? "en"
        switch self {
        case .free:
            switch lang {
            case "it": return "Gratis"
            case "fr": return "Gratuit"
            case "es": return "Gratis"
            case "uz": return "Bepul"
            default: return "Free"
            }
        case .premium:
            return "Premium"
        }
    }

    var storeKitProductID: String? {
        switch self {
        case .free:
            return nil
        case .premium:
            return Self.premiumProductID
        }
    }

    /// Guest (not logged in) daily camera limit.
    static let guestDailyLimit = 1

    // nil means unlimited
    var cameraDailyLimit: Int? {
        switch self {
        case .free:
            return 3
        case .premium:
            return nil
        }
    }

    var lessonRewardRate: Double {
        switch self {
        case .free:
            return 0.25
        case .premium:
            return 1.0
        }
    }

    var featureSummary: String {
        let lang = UserDefaults.standard.string(forKey: "settings_language") ?? "en"
        switch self {
        case .free:
            switch lang {
            case "it": return "3 scansioni camera/giorno e ricompense standard"
            case "fr": return "3 scans caméra/jour et récompenses standard"
            case "es": return "3 escaneos de cámara/día y recompensas estándar"
            case "uz": return "Kuniga 3 ta kamera skani va standart mukofotlar"
            default: return "3 camera scans/day and standard lesson rewards"
            }
        case .premium:
            switch lang {
            case "it": return "Scansioni camera illimitate e rimborso completo lezioni"
            case "fr": return "Scans caméra illimités et remboursement complet"
            case "es": return "Escaneos ilimitados y reembolso completo"
            case "uz": return "Cheksiz kamera skanlari va to'liq qaytarim"
            default: return "Unlimited camera scans and full lesson refunds"
            }
        }
    }

    func rewardForLesson(cost lessonCost: Int) -> Int {
        let normalizedCost = Swift.max(0, lessonCost)
        guard normalizedCost > 0 else {
            return 0
        }

        if self == .premium {
            // Premium always gives full refund, but never more than the lesson cost.
            return normalizedCost
        }

        let calculated = Int((Double(normalizedCost) * lessonRewardRate).rounded(.down))
        return Swift.max(0, Swift.min(normalizedCost, calculated))
    }

    func persistAsCurrent() {
        UserDefaults.standard.set(rawValue, forKey: Self.userDefaultsKey)
    }
}
