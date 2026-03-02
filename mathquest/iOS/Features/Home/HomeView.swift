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
                                        total: category.subtopics.count
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
            ForEach(category.subtopics) { lesson in
                NavigationLink(destination: LessonDetailView(lesson: lesson)) {
                    LessonRowView(lesson: lesson)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(category.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct LessonRowView: View {
    let lesson: LessonItem

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(lesson.title)
                .font(.subheadline)
                .fontWeight(.medium)
            if !lesson.description.isEmpty {
                Text(lesson.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            HStack {
                ForEach(0..<lesson.difficulty, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundStyle(.yellow)
                }
                Spacer()
                Text("\(lesson.coinCost) coins")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    HomeView()
}
