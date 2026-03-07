import ActivityKit
import SwiftUI
import WidgetKit

/// The Live Activity / Dynamic Island UI for streak warning.
/// Shows a countdown to midnight when the user risks losing their streak.
struct StreakLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: StreakActivityAttributes.self) { context in
            // Lock Screen / notification banner view
            StreakLockScreenView(state: context.state)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded view
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(.orange)
                            .font(.title2)
                        Text("\(context.state.streakDays)")
                            .font(.title2.bold())
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    Text(formattedTime(context.state.secondsRemaining))
                        .font(.title3.monospacedDigit().bold())
                        .foregroundStyle(.red)
                }

                DynamicIslandExpandedRegion(.center) {
                    Text("Streak at risk!")
                        .font(.headline)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    Text("Complete a lesson or solve a problem to keep your streak")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            } compactLeading: {
                // Compact leading (left pill)
                HStack(spacing: 2) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                        .font(.caption)
                    Text("\(context.state.streakDays)")
                        .font(.caption.bold())
                }
            } compactTrailing: {
                // Compact trailing (right pill)
                Text(formattedTimeShort(context.state.secondsRemaining))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.red)
            } minimal: {
                // Minimal (single icon when another Live Activity is also active)
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
            }
        }
    }

    private func formattedTime(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        return String(format: "%d:%02d", h, m)
    }

    private func formattedTimeShort(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        if h > 0 {
            return "\(h)h\(m)m"
        }
        return "\(m)m"
    }
}

/// Lock screen banner view for the Live Activity
private struct StreakLockScreenView: View {
    let state: StreakActivityAttributes.ContentState

    var body: some View {
        HStack(spacing: 16) {
            // Flame + streak count
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                    .font(.title2)
                Text("\(state.streakDays)")
                    .font(.title2.bold())
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Streak at risk!")
                    .font(.headline)
                Text("Complete an activity before midnight")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Countdown
            VStack(spacing: 2) {
                Text(formattedCountdown(state.secondsRemaining))
                    .font(.title3.monospacedDigit().bold())
                    .foregroundStyle(.red)
                Text("remaining")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
    }

    private func formattedCountdown(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        return String(format: "%d:%02d", h, m)
    }
}

