import Foundation

enum SubscriptionTier: String, CaseIterable, Codable {
    case free
    case pro
    case max

    static let userDefaultsKey = "subscription_tier"

    static let proProductID = "com.kram.mathquest.subscription.pro.monthly"
    static let maxProductID = "com.kram.mathquest.subscription.max.monthly"

    static var paidProductIDs: [String] {
        [proProductID, maxProductID]
    }

    static var current: SubscriptionTier {
        guard let raw = UserDefaults.standard.string(forKey: userDefaultsKey),
              let tier = SubscriptionTier(rawValue: raw) else {
            return .free
        }
        return tier
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
        case .pro:
            return "Pro"
        case .max:
            return "Max"
        }
    }

    var storeKitProductID: String? {
        switch self {
        case .free:
            return nil
        case .pro:
            return Self.proProductID
        case .max:
            return Self.maxProductID
        }
    }

    // nil means unlimited
    var cameraDailyLimit: Int? {
        switch self {
        case .free:
            return 5
        case .pro:
            return 10
        case .max:
            return nil
        }
    }

    var lessonRewardRate: Double {
        switch self {
        case .free:
            return 0.25
        case .pro:
            return 0.60
        case .max:
            return 1.0
        }
    }

    var featureSummary: String {
        let lang = UserDefaults.standard.string(forKey: "settings_language") ?? "en"
        switch self {
        case .free:
            switch lang {
            case "it": return "5 scansioni camera/giorno e ricompense standard"
            case "fr": return "5 scans caméra/jour et récompenses standard"
            case "es": return "5 escaneos de cámara/día y recompensas estándar"
            case "uz": return "Kuniga 5 ta kamera skani va standart mukofotlar"
            default: return "5 camera scans/day and standard lesson rewards"
            }
        case .pro:
            switch lang {
            case "it": return "10 scansioni camera/giorno e ricompense aumentate"
            case "fr": return "10 scans caméra/jour et récompenses augmentées"
            case "es": return "10 escaneos de cámara/día y recompensas mejoradas"
            case "uz": return "Kuniga 10 ta kamera skani va oshirilgan mukofotlar"
            default: return "10 camera scans/day and boosted lesson rewards"
            }
        case .max:
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

        if self == .max {
            // Max always gives full refund, but never more than the lesson cost.
            return normalizedCost
        }

        let calculated = Int((Double(normalizedCost) * lessonRewardRate).rounded(.down))
        return Swift.max(0, Swift.min(normalizedCost, calculated))
    }

    func persistAsCurrent() {
        UserDefaults.standard.set(rawValue, forKey: Self.userDefaultsKey)
    }
}
