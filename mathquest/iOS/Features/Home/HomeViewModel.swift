import Foundation

struct LessonItem: Identifiable, Hashable {
    let id: String
    let title: String
    let description: String
    let difficulty: Int
    let coinCost: Int
}

struct CategoryItem: Identifiable {
    let id: String
    let title: String
    let subtopics: [LessonItem]
}

private struct SubtopicDTO: Decodable {
    let id: String
    let title: String
    let description: String?
    let difficulty: Int
    let coin_cost: Int

    var toItem: LessonItem {
        LessonItem(id: id, title: title, description: description ?? "", difficulty: difficulty, coinCost: coin_cost)
    }
}

private struct CategoryDTO: Decodable {
    let id: String
    let title: String
    let subtopics: [SubtopicDTO]

    var toItem: CategoryItem {
        CategoryItem(id: id, title: title, subtopics: subtopics.map(\.toItem))
    }
}

private struct CategoriesResponse: Decodable {
    let categories: [CategoryDTO]
}

private struct BalanceResponse: Decodable {
    let balance: Int
}

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var categories: [CategoryItem] = []
    @Published var coinBalance = 0
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
            print("[Home] fetching lessons...")
            let res: CategoriesResponse = try await client.request("lessons")
            categories = res.categories.map(\.toItem)
            print("[Home] got \(categories.count) categories")

            print("[Home] fetching balance...")
            let balanceRes: BalanceResponse = try await client.request("coins/balance")
            coinBalance = balanceRes.balance
            print("[Home] balance = \(coinBalance)")
        } catch {
            print("[Home] ERROR: \(error)")
            errorMessage = error.localizedDescription
        }
    }
}
