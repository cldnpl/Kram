import Foundation
import FirebaseAuth

enum SubscriptionTier: String, CaseIterable, Codable {
    case free
    case premium

    static let userDefaultsKey = "subscription_tier"

    static let premiumProductID = "com.kram.premium.monthly"

    private static let developerAppleEmails: Set<String> = [
        "napolitano.claudia@icloud.com",
    ]

    static var paidProductIDs: [String] {
        [premiumProductID]
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

    var featureSummary: String {
        let lang = UserDefaults.standard.string(forKey: "settings_language") ?? "en"
        switch self {
        case .free:
            switch lang {
            case "it": return "3 scansioni camera/giorno. Lezioni sempre gratuite"
            case "fr": return "3 scans caméra/jour. Leçons toujours gratuites"
            case "es": return "3 escaneos de cámara/día. Lecciones siempre gratis"
            case "uz": return "Kuniga 3 ta kamera skani. Darslar doim bepul"
            default: return "3 camera scans/day. Lessons always free"
            }
        case .premium:
            switch lang {
            case "it": return "Scansioni camera illimitate. Lezioni sempre gratuite"
            case "fr": return "Scans caméra illimités. Leçons toujours gratuites"
            case "es": return "Escaneos ilimitados. Lecciones siempre gratis"
            case "uz": return "Cheksiz kamera skanlari. Darslar doim bepul"
            default: return "Unlimited camera scans. Lessons always free"
            }
        }
    }

    func rewardForLesson(cost lessonCost: Int) -> Int {
        let normalizedCost = Swift.max(0, lessonCost)
        // Lessons are always free: everyone gets full refund on completion.
        return normalizedCost
    }

    func persistAsCurrent() {
        UserDefaults.standard.set(rawValue, forKey: Self.userDefaultsKey)
    }
}
