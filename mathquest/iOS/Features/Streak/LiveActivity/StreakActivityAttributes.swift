import ActivityKit
import Foundation

struct StreakActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        /// Unix timestamp for local midnight. The widget derives its own countdown from this.
        var deadlineTimestamp: Int
        /// Current streak that's at risk
        var streakDays: Int
    }

    /// Static data that doesn't change during the activity
    var streakDays: Int
}
