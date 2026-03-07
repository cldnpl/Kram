import Foundation

struct LessonItem: Identifiable, Hashable {
    let id: String
    let title: String
    let description: String
    let difficulty: Int
    let coinCost: Int
}

struct CategorySectionItem: Identifiable {
    let id: String
    let title: String
    let lessonId: String
    let items: [SubcategoryItem]
}

struct SubcategoryItem: Identifiable {
    let id: String
    let title: String
}

struct CategoryItem: Identifiable {
    let id: String
    let title: String
    let sections: [CategorySectionItem]
}

private struct ItemDTO: Decodable {
    let title: String
}

private struct SectionDTO: Decodable {
    let title: String
    let lesson_id: String
    let items: [ItemDTO]
}

private struct CategoryDTO: Decodable {
    let id: String
    let title: String
    let sections: [SectionDTO]

    var toItem: CategoryItem {
        CategoryItem(
            id: id,
            title: title,
            sections: sections.enumerated().map { idx, s in
                CategorySectionItem(
                    id: "\(id)-\(idx)",
                    title: s.title,
                    lessonId: s.lesson_id,
                    items: s.items.enumerated().map { i, it in
                        SubcategoryItem(id: "\(s.lesson_id)-\(i)", title: it.title)
                    }
                )
            }
        )
    }
}

private struct CategoriesResponse: Decodable {
    let categories: [CategoryDTO]
}

private struct BalanceResponse: Decodable {
    let balance: Int
}

private struct StreakResponse: Decodable {
    let streak_days: Int
    let active_today: Bool
}

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var categories: [CategoryItem] = []
    @Published var coinBalance = 0
    @Published var streakDays = 0
    @Published var activeToday = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let client = APIClient()

    func load() async {
        print("[Home] load() called")
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            await client.setToken("mock-dev-token")
            print("[Home] fetching lessons from: \(APIConfig.baseURLString)/lessons")
            let res: CategoriesResponse = try await client.request("lessons")
            categories = res.categories.map(\.toItem)
            print("[Home] got \(categories.count) categories")

            print("[Home] fetching balance...")
            let balanceRes: BalanceResponse = try await client.request("coins/balance")
            coinBalance = balanceRes.balance + CoinWallet.localBonus()
            print("[Home] balance = \(coinBalance)")

            print("[Home] fetching streak...")
            let streakRes: StreakResponse = try await client.request("streak")
            streakDays = streakRes.streak_days
            activeToday = streakRes.active_today
            print("[Home] streak = \(streakDays), activeToday = \(activeToday)")
        } catch {
            print("[Home] ERROR: \(error)")
            errorMessage = error.localizedDescription
        }
    }

    /// Total subcategory count for a category (for progress display).
    func totalItems(for category: CategoryItem) -> Int {
        category.sections.reduce(0) { $0 + $1.items.count }
    }
}
