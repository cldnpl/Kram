import ActivityKit
import Foundation

/// Manages the streak warning Live Activity / Dynamic Island.
/// Activates after 21:00 if user hasn't been active today, showing a countdown to midnight.
/// When the user completes an activity, or at midnight, the Live Activity is dismissed.
@MainActor
final class StreakActivityManager: ObservableObject {
    static let shared = StreakActivityManager()

    private var currentActivity: Activity<StreakActivityAttributes>?
    private var updateTimer: Timer?

    private init() {}

    /// Call this whenever streak data is fetched (e.g., on app launch, after activity completion).
    /// - Parameters:
    ///   - streakDays: Current streak count
    ///   - activeToday: Whether user has been active today
    func evaluate(streakDays: Int, activeToday: Bool) {
        if activeToday || streakDays == 0 {
            // User already active today or no streak to protect — dismiss
            stopActivity()
            return
        }

        // Check if it's after 21:00 local time
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)

        if hour >= 21 {
            startOrUpdateActivity(streakDays: streakDays)
        } else {
            // Not yet 21:00 — schedule for later (handled by periodic check or background task)
            stopActivity()
        }
    }

    /// Force-start for testing. Ignores time-of-day and activeToday checks.
    func forceStart(streakDays: Int) {
        startOrUpdateActivity(streakDays: max(streakDays, 1))
    }

    func startOrUpdateActivity(streakDays: Int) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("[StreakActivity] Live Activities not enabled")
            return
        }

        let secondsRemaining = secondsUntilMidnight()
        if secondsRemaining <= 0 {
            stopActivity()
            return
        }

        let state = StreakActivityAttributes.ContentState(
            secondsRemaining: secondsRemaining,
            streakDays: streakDays
        )

        if let activity = currentActivity {
            // Update existing activity
            Task {
                await activity.update(
                    ActivityContent(state: state, staleDate: Date().addingTimeInterval(60))
                )
            }
        } else {
            // Start new activity
            let attributes = StreakActivityAttributes(streakDays: streakDays)
            let content = ActivityContent(state: state, staleDate: Date().addingTimeInterval(60))

            do {
                let activity = try Activity.request(
                    attributes: attributes,
                    content: content,
                    pushType: nil
                )
                currentActivity = activity
                print("[StreakActivity] Started live activity: \(activity.id)")
                startUpdateTimer(streakDays: streakDays)
            } catch {
                print("[StreakActivity] Failed to start: \(error)")
            }
        }
    }

    func stopActivity() {
        updateTimer?.invalidate()
        updateTimer = nil

        guard let activity = currentActivity else { return }
        currentActivity = nil

        Task {
            let finalState = StreakActivityAttributes.ContentState(
                secondsRemaining: 0,
                streakDays: 0
            )
            await activity.end(
                ActivityContent(state: finalState, staleDate: nil),
                dismissalPolicy: .immediate
            )
            print("[StreakActivity] Stopped live activity")
        }
    }

    /// Update the countdown every 60 seconds
    private func startUpdateTimer(streakDays: Int) {
        updateTimer?.invalidate()
        updateTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                let remaining = self.secondsUntilMidnight()
                if remaining <= 0 {
                    self.stopActivity()
                    return
                }
                let state = StreakActivityAttributes.ContentState(
                    secondsRemaining: remaining,
                    streakDays: streakDays
                )
                if let activity = self.currentActivity {
                    await activity.update(
                        ActivityContent(state: state, staleDate: Date().addingTimeInterval(60))
                    )
                }
            }
        }
    }

    private func secondsUntilMidnight() -> Int {
        let now = Date()
        let calendar = Calendar.current
        guard let midnight = calendar.nextDate(
            after: now,
            matching: DateComponents(hour: 0, minute: 0, second: 0),
            matchingPolicy: .strict
        ) else {
            return 0
        }
        return max(0, Int(midnight.timeIntervalSince(now)))
    }
}
