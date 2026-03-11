import SwiftUI
import FirebaseAuth

private let appPurple = Color(red: 0.4, green: 0.3, blue: 0.9)

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @Environment(\.colorScheme) private var colorScheme
    @State private var showShop = false
    @State private var showStreak = false
    @AppStorage("profile_name") private var profileName = ""
    @AppStorage("settings_language") private var language = "en"
    @AppStorage("session_logged_in") private var sessionLoggedIn = false

    private var greetingName: String {
        (sessionLoggedIn || Auth.auth().currentUser != nil) ? profileName : L10n.userFallback
    }

    private var homeGradient: LinearGradient {
        if colorScheme == .dark {
            return LinearGradient(
                stops: [
                    .init(color: appPurple, location: 0),
                    .init(color: Color(red: 0.27, green: 0.22, blue: 0.42), location: 0.25),
                    .init(color: Color(red: 0.15, green: 0.14, blue: 0.2), location: 0.35),
                    .init(color: Color(red: 0.1, green: 0.1, blue: 0.12), location: 0.48),
                    .init(color: Color(.systemBackground), location: 0.62),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        return LinearGradient(
            stops: [
                .init(color: appPurple, location: 0),
                .init(color: Color(red: 0.85, green: 0.82, blue: 0.98), location: 0.25),
                .init(color: Color(red: 0.93, green: 0.91, blue: 0.99), location: 0.3),
                .init(color: Color(red: 0.97, green: 0.96, blue: 1.0), location: 0.4),
                .init(color: Color(.systemBackground), location: 0.55),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                homeGradient
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    HStack {
                        Text("\(L10n.greetingPrefix), \(greetingName.isEmpty ? L10n.hiThere : greetingName)!")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)

                        Spacer()

                        HStack(spacing: 8) {
                            // Streak badge (tap to open calendar)
                            Button {
                                showStreak = true
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "flame.fill")
                                        .foregroundStyle(viewModel.streakDays > 0 ? .orange : .gray)
                                        .font(.system(size: 18))

                                    Text("\(viewModel.streakDays)")
                                        .fontWeight(.semibold)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(.thinMaterial)
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)

                            // Coin badge
                            Button {
                                showShop = true
                            } label: {
                                HStack(spacing: 6) {
                                    Image("coin")
                                        .resizable()
                                        .renderingMode(.original)
                                        .scaledToFit()
                                        .frame(width: 24, height: 24)
                                        .scaleEffect(2.3)

                                    Text("\(viewModel.coinBalance)")
                                        .fontWeight(.semibold)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(.thinMaterial)
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 56)

                    if viewModel.isLoading {
                        VStack(spacing: 12) {
                            ProgressView()
                            Text(L10n.loading)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let msg = viewModel.errorMessage {
                        VStack(spacing: 8) {
                            Text("\(L10n.error): \(msg)")
                                .multilineTextAlignment(.center)
                                .padding()
                            Button(L10n.retry) { Task { await viewModel.load() } }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            LazyVGrid(
                                columns: [GridItem(.flexible()), GridItem(.flexible())],
                                spacing: 16
                            ) {
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
                            .padding(.horizontal, 25)
                            .padding(.top, 20)
                            .padding(.bottom, 24)
                        }
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                    }
                }
                .navigationDestination(for: LessonItem.self) { lesson in
                    LessonDetailView(lesson: lesson)
                }
                .navigationBarHidden(true)
                .sheet(isPresented: $showShop) {
                    StoreView()
                }
                .sheet(isPresented: $showStreak) {
                    NavigationStack {
                        StreakCalendarView()
                            .toolbar {
                                ToolbarItem(placement: .topBarTrailing) {
                                    Button {
                                        showStreak = false
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                    }
                }
                .task {
                    print("[Home] view appeared, loading data")
                    await viewModel.load()
                }
                .onChange(of: language) { _, _ in
                    Task { await viewModel.load() }
                }
            }
        }
    }
}

struct CategoryCardView: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    var completed: Int = 0
    var total: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            Text("\(completed)/\(total)")
                .font(.footnote)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
            ProgressView(value: total > 0 ? Double(completed) / Double(total) : 0)
                .tint(.green)
                .scaleEffect(x: 1, y: 1.5, anchor: .center)
        }
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
        .padding(12)
        .background(Color(colorScheme == .dark ? .secondarySystemBackground : .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(appPurple, lineWidth: 1)
        )
    }
}

struct CategorySubtopicsView: View {
    let category: CategoryItem
    @EnvironmentObject private var authManager: AuthManager
    @AppStorage("session_logged_in") private var sessionLoggedIn = false
    @State private var selectedLesson: LessonItem?
    @State private var showLoginPrompt = false
    @State private var showLoginSheet = false

    private var isLoggedIn: Bool {
        authManager.isAuthenticated || sessionLoggedIn
    }

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
                            id: item.id,
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
        .navigationTitle(category.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .navigationDestination(item: $selectedLesson) { lesson in
            LessonDetailView(lesson: lesson)
        }
        .alert(L10n.signInRequired, isPresented: $showLoginPrompt) {
            Button(L10n.notNow, role: .cancel) {}
            Button(L10n.signIn) {
                showLoginSheet = true
            }
        } message: {
            Text(L10n.guestLessonMessage)
        }
        .fullScreenCover(isPresented: $showLoginSheet) {
            LoginView(showCloseButton: true)
        }
        .onChange(of: isLoggedIn) { _, loggedIn in
            if loggedIn {
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
        if isLoggedIn {
            selectedLesson = lesson
        } else {
            showLoginPrompt = true
        }
    }
}

#Preview {
    HomeView()
}
