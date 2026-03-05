import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var showShop = false
    @State private var showCamera = false

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
                    .toolbar(.hidden, for: .tabBar)
            }
            .navigationTitle("Lessons")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showCamera = true
                    } label: {
                        Image(systemName: "camera.fill")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showShop = true
                    } label: {
                        CoinBadgeView(coins: viewModel.coinBalance)
                    }
                    .buttonStyle(.plain)
                }
            }
            .sheet(isPresented: $showShop) {
                StoreView()
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraView()
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
    @EnvironmentObject private var authManager: AuthManager
    @AppStorage("guest_lessons_opened_count") private var guestLessonsOpenedCount = 0
    @State private var selectedLesson: LessonItem?
    @State private var showLoginPrompt = false
    @State private var showLoginSheet = false

    var body: some View {
        List {
            ForEach(category.sections) { section in
                Section(header: Text(section.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)) {
                    ForEach(section.items) { item in
                        let lessonCost = lessonCostForSection(section.lessonId)
                        let lesson = LessonItem(
                            id: section.lessonId,
                            title: item.title,
                            description: "",
                            difficulty: 0,
                            coinCost: lessonCost
                        )

                        Button {
                            handleLessonTap(lesson)
                        } label: {
                            HStack {
                                Text(item.title)
                                    .font(.body)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationDestination(item: $selectedLesson) { lesson in
            LessonDetailView(lesson: lesson)
        }
        .navigationTitle(category.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .alert("Sign in required", isPresented: $showLoginPrompt) {
            Button("Not now", role: .cancel) {}
            Button("Sign In") {
                showLoginSheet = true
            }
        } message: {
            Text("Guests can open one lesson. Sign in to continue all lessons.")
        }
        .fullScreenCover(isPresented: $showLoginSheet) {
            LoginView(showCloseButton: true)
        }
        .onChange(of: authManager.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated {
                showLoginSheet = false
            }
        }
    }

    private func lessonCostForSection(_ lessonId: String) -> Int {
        let base = 20
        let increment = ((Int(lessonId) ?? 1) - 1) % 4
        return base + (increment * 5)
    }

    private func handleLessonTap(_ lesson: LessonItem) {
        if authManager.isAuthenticated {
            selectedLesson = lesson
            return
        }

        if guestLessonsOpenedCount < 1 {
            guestLessonsOpenedCount += 1
            selectedLesson = lesson
            return
        }

        showLoginPrompt = true
    }
}

#Preview {
    HomeView()
}
