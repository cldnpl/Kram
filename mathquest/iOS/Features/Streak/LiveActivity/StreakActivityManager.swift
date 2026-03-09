import ActivityKit
import Foundation
import UIKit
import UserNotifications

/// Manages the streak warning Live Activity / Dynamic Island.
/// Activates during the final 4 hours before local midnight if the user hasn't been active today.
/// When the user completes an activity, or at midnight, the Live Activity is dismissed.
@MainActor
final class StreakActivityManager: ObservableObject {
    static let shared = StreakActivityManager()

    private let deviceIDDefaultsKey = "streak_live_activity_device_id"
    private var currentActivity: Activity<StreakActivityAttributes>?
    private var isObservingPushToStartTokens = false

    private init() {}

    func refreshRemoteStartSupport() async {
        guard #available(iOS 17.2, *) else {
            await syncPushToStartRegistration(token: nil, enabled: false)
            return
        }

        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        let isAuthorized: Bool
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            isAuthorized = true
        case .notDetermined:
            do {
                isAuthorized = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            } catch {
                print("[StreakActivity] Notification authorization failed: \(error)")
                isAuthorized = false
            }
        default:
            isAuthorized = false
        }

        guard isAuthorized else {
            await syncPushToStartRegistration(token: nil, enabled: false)
            return
        }

        UIApplication.shared.registerForRemoteNotifications()
        startPushToStartObservationIfNeeded()

        if let tokenData = Activity<StreakActivityAttributes>.pushToStartToken {
            await syncPushToStartRegistration(
                token: Self.hexString(from: tokenData),
                enabled: true
            )
        }
    }

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

        let deadline = nextMidnight()
        let remaining = deadline.timeIntervalSinceNow

        if remaining > 0 && remaining <= 4 * 60 * 60 {
            startOrUpdateActivity(streakDays: streakDays)
        } else {
            // Not yet inside the warning window.
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

        let deadline = nextMidnight()
        if deadline.timeIntervalSinceNow <= 0 {
            stopActivity()
            return
        }

        let state = StreakActivityAttributes.ContentState(
            deadlineTimestamp: Int(deadline.timeIntervalSince1970),
            streakDays: streakDays
        )

        if let activity = activeActivities().first {
            currentActivity = activity
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
            } catch {
                print("[StreakActivity] Failed to start: \(error)")
            }
        }
    }

    func stopActivity() {
        let activities = activeActivities()
        currentActivity = nil
        guard !activities.isEmpty else { return }

        Task {
            let finalState = StreakActivityAttributes.ContentState(
                deadlineTimestamp: Int(Date().timeIntervalSince1970),
                streakDays: 0
            )
            for activity in activities {
                await activity.end(
                    ActivityContent(state: finalState, staleDate: nil),
                    dismissalPolicy: .immediate
                )
            }
            print("[StreakActivity] Stopped live activity")
        }
    }

    private func activeActivities() -> [Activity<StreakActivityAttributes>] {
        let activities = Activity<StreakActivityAttributes>.activities
        currentActivity = activities.first
        return activities
    }

    private func nextMidnight() -> Date {
        let now = Date()
        let calendar = Calendar.current
        return calendar.nextDate(
            after: now,
            matching: DateComponents(hour: 0, minute: 0, second: 0),
            matchingPolicy: .nextTime
        ) ?? now
    }

    @available(iOS 17.2, *)
    private func startPushToStartObservationIfNeeded() {
        guard !isObservingPushToStartTokens else { return }
        isObservingPushToStartTokens = true

        Task { [weak self] in
            guard let self else { return }
            for await tokenData in Activity<StreakActivityAttributes>.pushToStartTokenUpdates {
                await self.syncPushToStartRegistration(
                    token: Self.hexString(from: tokenData),
                    enabled: true
                )
            }
        }
    }

    private func syncPushToStartRegistration(token: String?, enabled: Bool) async {
        guard let url = URL(string: "\(APIConfig.baseURLString)/streak/live-activity/device") else {
            return
        }

        let payload: [String: Any] = [
            "device_id": deviceID(),
            "push_to_start_token": token ?? "",
            "timezone": TimeZone.current.identifier,
            "enabled": enabled
        ]

        guard JSONSerialization.isValidJSONObject(payload),
              let body = try? JSONSerialization.data(withJSONObject: payload) else {
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer mock-dev-token", forHTTPHeaderField: "Authorization")
        request.httpBody = body

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                print("[StreakActivity] push token sync failed with status \(http.statusCode)")
            }
        } catch {
            print("[StreakActivity] push token sync failed: \(error)")
        }
    }

    private func deviceID() -> String {
        if let existing = UserDefaults.standard.string(forKey: deviceIDDefaultsKey),
           !existing.isEmpty {
            return existing
        }

        let generated = UUID().uuidString.lowercased()
        UserDefaults.standard.set(generated, forKey: deviceIDDefaultsKey)
        return generated
    }

    private static func hexString(from data: Data) -> String {
        data.map { String(format: "%02x", $0) }.joined()
    }
}
