import SwiftUI

private let appOrange = Color.orange

struct StreakCalendarView: View {
    @StateObject private var viewModel = StreakCalendarViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Streak hero
                VStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(viewModel.streakDays > 0 ? .orange : .gray)

                    Text("\(viewModel.streakDays)")
                        .font(.system(size: 48, weight: .bold))

                    Text(viewModel.streakDays == 1 ? "Day Streak" : "Day Streak")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(.secondary)

                    if viewModel.activeToday {
                        Label("Active today", systemImage: "checkmark.circle.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.green)
                    } else {
                        Label("Not active yet today", systemImage: "exclamationmark.circle")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.orange)
                    }
                }
                .padding(.top, 8)

                // Calendar
                VStack(spacing: 16) {
                    // Month navigation
                    HStack {
                        Button {
                            viewModel.previousMonth()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.primary)
                        }

                        Spacer()

                        Text(viewModel.monthYearString)
                            .font(.system(size: 17, weight: .semibold))

                        Spacer()

                        Button {
                            viewModel.nextMonth()
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.primary)
                        }
                        .disabled(viewModel.isCurrentMonth)
                    }
                    .padding(.horizontal, 4)

                    // Weekday headers
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                        ForEach(["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"], id: \.self) { day in
                            Text(day)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Days grid
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                        ForEach(viewModel.calendarDays, id: \.id) { day in
                            CalendarDayCell(day: day)
                        }
                    }
                }
                .padding(16)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
                .padding(.horizontal, 20)

                // Stats
                HStack(spacing: 12) {
                    StreakStatBox(
                        title: "This Month",
                        value: "\(viewModel.activeDaysThisMonth)",
                        subtitle: "active days"
                    )
                    StreakStatBox(
                        title: "Best Streak",
                        value: "\(viewModel.streakDays)",
                        subtitle: "days"
                    )
                }
                .padding(.horizontal, 20)

                #if DEBUG
                // Test Live Activity button
                VStack(spacing: 8) {
                    Button {
                        StreakActivityManager.shared.forceStart(
                            streakDays: max(viewModel.streakDays, 5)
                        )
                    } label: {
                        Label("Test Dynamic Island", systemImage: "livephoto")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color.orange)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Button {
                        StreakActivityManager.shared.stopActivity()
                    } label: {
                        Label("Stop Live Activity", systemImage: "xmark.circle")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color.red.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal, 20)
                #endif
            }
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Streak")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load()
        }
    }
}

private struct CalendarDayCell: View {
    let day: CalendarDay

    var body: some View {
        ZStack {
            if day.dayNumber > 0 {
                if day.isActive {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 36, height: 36)
                } else if day.isToday {
                    Circle()
                        .stroke(Color.orange, lineWidth: 2)
                        .frame(width: 36, height: 36)
                }

                Text("\(day.dayNumber)")
                    .font(.system(size: 14, weight: day.isToday ? .bold : .regular))
                    .foregroundStyle(day.isActive ? Color.white : day.isFuture ? Color.gray.opacity(0.4) : Color.primary)
            }
        }
        .frame(height: 40)
    }
}

private struct StreakStatBox: View {
    let title: String
    let value: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.system(size: 28, weight: .bold))

            Text(subtitle)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }
}

#Preview {
    NavigationStack {
        StreakCalendarView()
    }
}
