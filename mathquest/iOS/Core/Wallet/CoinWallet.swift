import Foundation

extension Notification.Name {
    static let coinWalletDidChange = Notification.Name("coinWalletDidChange")
}

enum CoinWallet {
    private static let localBonusKey = "local_bonus_coins"
    private static let rewardedLessonsKey = "rewarded_lesson_ids"

    static func localBonus() -> Int {
        Swift.max(0, UserDefaults.standard.integer(forKey: localBonusKey))
    }

    static func addLocalBonus(_ coins: Int) {
        guard coins > 0 else {
            return
        }

        let updated = localBonus() + coins
        UserDefaults.standard.set(updated, forKey: localBonusKey)
        NotificationCenter.default.post(
            name: .coinWalletDidChange,
            object: nil,
            userInfo: ["localBonus": updated, "delta": coins]
        )
    }

    static func resetLocalBonus() {
        let previous = localBonus()
        UserDefaults.standard.removeObject(forKey: localBonusKey)
        NotificationCenter.default.post(
            name: .coinWalletDidChange,
            object: nil,
            userInfo: ["localBonus": 0, "delta": -previous]
        )
    }

    static func hasRewardedLesson(_ lessonId: String) -> Bool {
        rewardedLessonIDs().contains(lessonId)
    }

    static func markLessonRewarded(_ lessonId: String) {
        let trimmed = lessonId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var ids = rewardedLessonIDs()
        ids.insert(trimmed)
        UserDefaults.standard.set(Array(ids).sorted(), forKey: rewardedLessonsKey)
    }

    static func resetRewardedLessons() {
        UserDefaults.standard.removeObject(forKey: rewardedLessonsKey)
    }

    private static func rewardedLessonIDs() -> Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: rewardedLessonsKey) ?? [])
    }
}
