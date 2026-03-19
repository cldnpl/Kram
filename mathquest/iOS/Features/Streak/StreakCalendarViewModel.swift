import Foundation
import FirebaseAuth

struct CalendarDay: Identifiable {
    let id: String
    let dayNumber: Int
    let isActive: Bool
    let isToday: Bool
    let isFuture: Bool
}

private struct StreakResponse: Decodable {
    let streak_days: Int
    let active_today: Bool
}

private struct CalendarResponse: Decodable {
    let active_dates: [String]
    let year: Int
    let month: Int
}

@MainActor
final class StreakCalendarViewModel: ObservableObject {
    @Published var streakDays = 0
    @Published var activeToday = false
    @Published var calendarDays: [CalendarDay] = []
    @Published var activeDaysThisMonth = 0
    @Published var displayYear: Int
    @Published var displayMonth: Int

    private let client = APIClient()
    private var activeDates: Set<String> = []
    private let calendar = Calendar.current

    var monthYearString: String {
        let dateComponents = DateComponents(year: displayYear, month: displayMonth)
        guard let date = calendar.date(from: dateComponents) else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    var isCurrentMonth: Bool {
        let now = Date()
        return calendar.component(.year, from: now) == displayYear &&
               calendar.component(.month, from: now) == displayMonth
    }

    init() {
        let now = Date()
        let cal = Calendar.current
        displayYear = cal.component(.year, from: now)
        displayMonth = cal.component(.month, from: now)
    }

    func load() async {
        await client.setToken(Auth.auth().currentUser?.uid)

        // Fetch streak
        do {
            let res: StreakResponse = try await client.request("streak")
            streakDays = res.streak_days
            activeToday = res.active_today
        } catch {
            print("[StreakCalendar] streak error: \(error)")
        }

        // Fetch calendar
        await fetchCalendar()
    }

    func previousMonth() {
        if displayMonth == 1 {
            displayMonth = 12
            displayYear -= 1
        } else {
            displayMonth -= 1
        }
        Task { await fetchCalendar() }
    }

    func nextMonth() {
        guard !isCurrentMonth else { return }
        if displayMonth == 12 {
            displayMonth = 1
            displayYear += 1
        } else {
            displayMonth += 1
        }
        Task { await fetchCalendar() }
    }

    private func fetchCalendar() async {
        do {
            let res: CalendarResponse = try await client.request(
                "streak/calendar?year=\(displayYear)&month=\(displayMonth)"
            )
            activeDates = Set(res.active_dates)
            activeDaysThisMonth = activeDates.count
            buildCalendarDays()
        } catch {
            print("[StreakCalendar] calendar error: \(error)")
            activeDates = []
            activeDaysThisMonth = 0
            buildCalendarDays()
        }
    }

    private func buildCalendarDays() {
        var days: [CalendarDay] = []

        guard let firstOfMonth = calendar.date(from: DateComponents(year: displayYear, month: displayMonth, day: 1)) else {
            calendarDays = []
            return
        }

        // Monday = 1, Sunday = 7 (ISO)
        var weekday = calendar.component(.weekday, from: firstOfMonth)
        // Convert from Sunday=1 system to Monday=1
        weekday = weekday == 1 ? 7 : weekday - 1

        let daysInMonth = calendar.range(of: .day, in: .month, for: firstOfMonth)?.count ?? 30

        let today = Date()
        let todayDay = calendar.component(.day, from: today)
        let todayMonth = calendar.component(.month, from: today)
        let todayYear = calendar.component(.year, from: today)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        // Leading empty cells
        for i in 0..<(weekday - 1) {
            days.append(CalendarDay(id: "empty-\(i)", dayNumber: 0, isActive: false, isToday: false, isFuture: false))
        }

        // Day cells
        for day in 1...daysInMonth {
            let dateString = String(format: "%04d-%02d-%02d", displayYear, displayMonth, day)
            let isActive = activeDates.contains(dateString)
            let isToday = day == todayDay && displayMonth == todayMonth && displayYear == todayYear

            var isFuture = false
            if displayYear > todayYear {
                isFuture = true
            } else if displayYear == todayYear {
                if displayMonth > todayMonth {
                    isFuture = true
                } else if displayMonth == todayMonth && day > todayDay {
                    isFuture = true
                }
            }

            days.append(CalendarDay(
                id: dateString,
                dayNumber: day,
                isActive: isActive,
                isToday: isToday,
                isFuture: isFuture
            ))
        }

        calendarDays = days
    }
}
