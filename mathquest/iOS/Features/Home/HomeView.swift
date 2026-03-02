import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Loading...")
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let msg = viewModel.errorMessage {
                    VStack(spacing: 8) {
                        Text("Error: \(msg)")
                            .multilineTextAlignment(.center)
                            .padding()
                        Button("Retry") { Task { await viewModel.load() } }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 175))], spacing: 14) {
                            ForEach(viewModel.categories) { category in
                                NavigationLink(destination: CategorySubtopicsView(category: category)) {
                                    CategoryCardView(
                                        title: category.title,
                                        completed: 0,
                                        total: viewModel.totalItems(for: category)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationDestination(for: LessonItem.self) { lesson in
                LessonDetailView(lesson: lesson)
            }
            .navigationTitle("Lessons")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    CoinBadgeView(coins: viewModel.coinBalance)
                }
            }
            .task {
                print("[Home] view appeared, loading data")
                await viewModel.load()
            }
        }
    }
}

struct CategoryCardView: View {
    let title: String
    var completed: Int = 0
    var total: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
                .multilineTextAlignment(.leading)
                .lineLimit(3)
            Spacer(minLength: 6)
            Text("\(completed)/\(total)")
                .font(.subheadline)
                .fontWeight(.semibold)
            ProgressView(value: total > 0 ? Double(completed) / Double(total) : 0)
                .tint(.red)
                .scaleEffect(x: 1, y: 1.8, anchor: .center)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct CategorySubtopicsView: View {
    let category: CategoryItem

    var body: some View {
        List {
            ForEach(category.sections) { section in
                Section(header: Text(section.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)) {
                    ForEach(section.items) { item in
                        NavigationLink(destination: LessonDetailView(lesson: LessonItem(
                            id: section.lessonId,
                            title: item.title,
                            description: "",
                            difficulty: 0,
                            coinCost: 0
                        ))) {
                            Text(item.title)
                                .font(.body)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(category.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    HomeView()
}
