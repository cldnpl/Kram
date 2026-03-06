import SwiftUI

/// Viola usato in auth e nel resto dell'app (stesso colore).
private let appPurple = Color(red: 0.4, green: 0.3, blue: 0.9)

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var showShop = false
    @AppStorage("profile_name") private var profileName = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Gradiente su tutto lo sfondo, ignora safe area
                LinearGradient(
                    stops: [
                        .init(color: appPurple, location: 0),
                        .init(color: Color(red: 0.85, green: 0.82, blue: 0.98), location: 0.25),
                        .init(color: Color(red: 0.93, green: 0.91, blue: 0.99), location: 0.3),
                        .init(color: Color(red: 0.97, green: 0.96, blue: 1.0), location: 0.4),
                        .init(color: Color.white, location: 0.55)  // bianco solo dal 90% in giù
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    ZStack(alignment: .topTrailing) {
                        Text("Hi, \(profileName.isEmpty ? L10n.hiThere : profileName)!")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 20)
                            .padding(.top, 56)
                        
                        Button {
                            showShop = true
                        } label: {
                            HStack(spacing: 6) {
                                Image("coin")
                                    .resizable()
                                    .renderingMode(.original)
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)   // layout “base”
                                    .scaleEffect(2.3)               // ingrandisce SOLO la moneta
                                
                                Text("\(viewModel.coinBalance)")
                                    .fontWeight(.semibold)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(.thinMaterial)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 52)
                        .padding(.trailing, 16)
                        
                        Group {
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
                                // Sfondo trasparente così si vede il gradiente dietro
                                .scrollContentBackground(.hidden)
                                .background(Color.clear)
                            }
                        }
                    }
                }
                .navigationDestination(for: LessonItem.self) { lesson in
                    LessonDetailView(lesson: lesson)
                }
                .navigationBarHidden(true)
                .sheet(isPresented: $showShop) {
                    StoreView()
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
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(.black)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                Text("\(completed)/\(total)")
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .foregroundStyle(.black)
                ProgressView(value: total > 0 ? Double(completed) / Double(total) : 0)
                    .tint(.green)
                    .scaleEffect(x: 1, y: 1.5, anchor: .center)
            }
            .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
            .padding(12)
            .background(Color.white)
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
}
#Preview {
    HomeView()
}
