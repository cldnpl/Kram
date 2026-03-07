import ActivityKit
import Foundation

struct StreakActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        /// Seconds remaining until midnight
        var secondsRemaining: Int
        /// Current streak that's at risk
        var streakDays: Int
    }

    /// Static data that doesn't change during the activity
    var streakDays: Int
}
