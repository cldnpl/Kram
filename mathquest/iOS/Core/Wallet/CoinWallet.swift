import Foundation

enum CoinWallet {
    private static let localBonusKey = "local_bonus_coins"

    static func localBonus() -> Int {
        Swift.max(0, UserDefaults.standard.integer(forKey: localBonusKey))
    }

    static func addLocalBonus(_ coins: Int) {
        guard coins > 0 else {
            return
        }

        let updated = localBonus() + coins
        UserDefaults.standard.set(updated, forKey: localBonusKey)
    }

    static func resetLocalBonus() {
        UserDefaults.standard.removeObject(forKey: localBonusKey)
    }
}
