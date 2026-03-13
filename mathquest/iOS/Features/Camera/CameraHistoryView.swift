import SwiftUI
import UIKit

struct CameraHistoryView: View {
    let history: [HistoryItem]
    let loadDetailAction: (Int) async -> HistoryDetailResponse?
    let shareLinkAction: (HistoryDetailResponse) async -> URL?
    let deleteAction: (Int) async -> Bool
    @Environment(\.dismiss) private var dismiss
    @State private var selectedItem: HistoryDetailResponse?
    @State private var selectedItemIsSample = false
    @State private var isLoadingDetail = false
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    private static let sampleItem = HistoryItem(
        id: -1,
        problem: "x² − 5x + 6 = 0",
        solution: "x = 2, x = 3",
        difficultyLevel: "high_school",
        createdAt: Date()
    )

    private static let sampleDetail = HistoryDetailResponse(
        id: -1,
        problem: "x² − 5x + 6 = 0",
        solution: "x = 2, x = 3",
        steps: [
            "Identify a quadratic equation in standard form: x² − 5x + 6 = 0",
            "Find two numbers that multiply to 6 and add to −5: those are −2 and −3",
            "Factor the quadratic: (x − 2)(x − 3) = 0",
            "Apply the zero-product property: x − 2 = 0 or x − 3 = 0",
            "Solve each factor: x = 2 or x = 3"
        ],
        rawLatex: "x^{2} - 5x + 6 = 0 \\implies (x-2)(x-3) = 0 \\implies x = 2, \\; x = 3",
        difficultyLevel: "high_school",
        createdAt: Date()
    )

    /// Combined list: user history + sample at the end.
    private var displayItems: [HistoryItem] {
        let hasSample = history.contains { $0.id == Self.sampleItem.id }
        if hasSample { return history }
        return history + [Self.sampleItem]
    }

    var body: some View {
        NavigationStack {
            historyList
                .navigationTitle(L10n.historyTitle)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(L10n.done) {
                            dismiss()
                        }
                    }
                }
                .sheet(item: $selectedItem) { detail in
                    HistoryDetailView(
                        detail: detail,
                        shareLinkAction: selectedItemIsSample
                            ? nil
                            : {
                                await shareLinkAction(detail)
                            },
                        onDelete: selectedItemIsSample
                            ? nil
                            : {
                                await deleteAction(detail.id)
                            }
                    )
                }
        }
    }

    private var historyList: some View {
        List {
            if history.isEmpty {
                Section {
                    sampleRow
                } header: {
                    Text(L10n.historyExampleHeader)
                        .textCase(nil)
                }
            } else {
                Section {
                    ForEach(history) { item in
                        Button {
                            loadDetail(id: item.id)
                        } label: {
                            HistoryRowView(item: item, dateFormatter: dateFormatter)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Section {
                    sampleRow
                } header: {
                    Text(L10n.historyExampleHeader)
                        .textCase(nil)
                }
            }
        }
        .overlay {
            if isLoadingDetail {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.2))
            }
        }
    }

    private var sampleRow: some View {
        Button {
            selectedItemIsSample = true
            selectedItem = Self.sampleDetail
        } label: {
            HistoryRowView(item: Self.sampleItem, dateFormatter: dateFormatter)
        }
        .buttonStyle(.plain)
    }

    private func loadDetail(id: Int) {
        Task {
            isLoadingDetail = true
            if let detail = await loadDetailAction(id) {
                selectedItemIsSample = false
                selectedItem = detail
            }
            isLoadingDetail = false
        }
    }
}

struct HistoryRowView: View {
    let item: HistoryItem
    let dateFormatter: DateFormatter

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.problem)
                    .font(.headline)
                    .lineLimit(1)

                HStack {
                    Text("= \(item.solution)")
                        .font(.subheadline)
                        .foregroundColor(.green)

                    Spacer()

                    DifficultyBadge(level: item.difficultyLevel)
                }

                Text(formatDate(item.createdAt))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding(.vertical, 4)
    }

    private func formatDate(_ date: Date) -> String {
        dateFormatter.string(from: date)
    }
}

struct HistoryDetailView: View {
    let detail: HistoryDetailResponse
    let shareLinkAction: (() async -> URL?)?
    let onDelete: (() async -> Bool)?
    @Environment(\.dismiss) private var dismiss
    @State private var visibleSteps: Set<Int> = []
    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false
    @State private var isPreparingShare = false
    @State private var showDeleteFailed = false
    @State private var showShareFailed = false
    @State private var shareItems: [Any] = []
    @State private var showShareSheet = false
    
    private var hasShareAction: Bool {
        shareLinkAction != nil
    }
    
    private var hasAnyBottomAction: Bool {
        hasShareAction || onDelete != nil
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Answer
                    AnswerCardView(answer: detail.solution, isVisible: true)

                    // Difficulty
                    HStack {
                        Text(L10n.difficulty)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        DifficultyBadge(level: detail.difficultyLevel)
                    }

                    Divider()

                    // Steps
                    VStack(alignment: .leading, spacing: 8) {
                        Label(L10n.stepByStep, systemImage: "list.number")
                            .font(.headline)

                        ForEach(Array(detail.steps.enumerated()), id: \.offset) { index, step in
                            StepCardView(
                                stepNumber: index + 1,
                                content: step,
                                isVisible: visibleSteps.contains(index)
                            )
                            .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(Double(index) * 0.15), value: visibleSteps.contains(index))
                        }
                    }

                }
                .padding()
            }
            .navigationTitle(L10n.solution)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.done) {
                        dismiss()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if hasAnyBottomAction {
                    actionBar
                }
            }
            .alert(L10n.deleteSolution, isPresented: $showDeleteConfirmation) {
                Button(L10n.cancel, role: .cancel) {}
                Button(L10n.deleteSolution, role: .destructive) {
                    Task {
                        await deleteSolution()
                    }
                }
            } message: {
                Text(L10n.deleteSolutionMessage)
            }
            .alert(L10n.error, isPresented: $showDeleteFailed) {
                Button(L10n.ok, role: .cancel) {}
            } message: {
                Text(L10n.deleteSolutionFailed)
            }
            .alert(L10n.error, isPresented: $showShareFailed) {
                Button(L10n.ok, role: .cancel) {}
            } message: {
                Text(L10n.shareLinkFailed)
            }
            .sheet(isPresented: $showShareSheet) {
                ActivityShareSheet(items: shareItems)
            }
            .task {
                await animateSteps()
            }
        }
    }

    private var actionBar: some View {
        VStack(spacing: 10) {
            if hasShareAction {
                Button {
                    Task {
                        await shareSolution()
                    }
                } label: {
                    HStack(spacing: 10) {
                        if isPreparingShare {
                            ProgressView()
                                .tint(.white)
                            Text(L10n.preparingShare)
                        } else {
                            Label(L10n.share, systemImage: "square.and.arrow.up")
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(isPreparingShare || isDeleting)
            }

            if onDelete != nil {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label(L10n.deleteSolution, systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(isPreparingShare || isDeleting)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(.ultraThinMaterial)
    }

    private func animateSteps() async {
        visibleSteps.removeAll()
        for i in 0..<detail.steps.count {
            try? await Task.sleep(nanoseconds: 200_000_000)
            visibleSteps.insert(i)
        }
    }

    private func shareSolution() async {
        guard !isPreparingShare else { return }
        isPreparingShare = true
        let shareURL = await resolvedShareURL()
        isPreparingShare = false

        guard let shareURL, isTokenShareURL(shareURL) else {
            if let shareURL {
                print("[ShareLink] Rejected URL in history detail: \(shareURL.absoluteString)")
            } else {
                print("[ShareLink] No URL returned in history detail")
            }
            showShareFailed = true
            return
        }

        print("[ShareLink] Presenting share sheet URL: \(shareURL.absoluteString)")
        shareItems = [shareURL]
        showShareSheet = true
    }

    private func resolvedShareURL() async -> URL? {
        guard let shareLinkAction else { return nil }
        return await shareLinkAction()
    }

    private func isTokenShareURL(_ url: URL) -> Bool {
        let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return path.starts(with: "s/")
    }

    private func deleteSolution() async {
        guard let onDelete else { return }
        isDeleting = true
        let success = await onDelete()
        isDeleting = false
        if success {
            dismiss()
        } else {
            showDeleteFailed = true
        }
    }
}

#Preview {
    CameraHistoryView(
        history: [
            HistoryItem(
                id: 1,
                problem: "7 + 5",
                solution: "12",
                difficultyLevel: "elementary",
                createdAt: Date()
            ),
            HistoryItem(
                id: 2,
                problem: "x^2 + 2x + 1 = 0",
                solution: "x = -1",
                difficultyLevel: "high_school",
                createdAt: Date().addingTimeInterval(-3600)
            )
        ],
        loadDetailAction: { _ in nil },
        shareLinkAction: { _ in nil },
        deleteAction: { _ in true }
    )
}

struct ActivityShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
    }
}
