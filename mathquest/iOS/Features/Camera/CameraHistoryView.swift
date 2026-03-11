import SwiftUI

struct CameraHistoryView: View {
    let history: [HistoryItem]
    let loadDetailAction: (Int) async -> HistoryDetailResponse?
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
    let onDelete: (() async -> Bool)?
    @Environment(\.dismiss) private var dismiss
    @State private var visibleSteps: Set<Int> = []
    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false
    @State private var showDeleteFailed = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Problem
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.problem)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(detail.problem)
                            .font(.title3)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

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
                        Text(L10n.solutionSteps)
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
                    ShareLink(item: shareText) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .accessibilityLabel(L10n.share)
                }
                if onDelete != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showDeleteConfirmation = true
                        } label: {
                            if isDeleting {
                                ProgressView()
                            } else {
                                Image(systemName: "trash")
                            }
                        }
                        .tint(.red)
                        .disabled(isDeleting)
                        .accessibilityLabel(L10n.deleteSolution)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.done) {
                        dismiss()
                    }
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
            .task {
                await animateSteps()
            }
        }
    }

    private var shareText: String {
        var lines: [String] = [
            "\(L10n.problem): \(detail.problem)",
            "\(L10n.solution): \(detail.solution)",
        ]
        if !detail.steps.isEmpty {
            lines.append("\(L10n.solutionSteps):")
            lines.append(contentsOf: detail.steps.enumerated().map { "\($0.offset + 1). \($0.element)" })
        }
        return lines.joined(separator: "\n")
    }

    private func animateSteps() async {
        for i in 0..<detail.steps.count {
            try? await Task.sleep(nanoseconds: 200_000_000)
            visibleSteps.insert(i)
        }
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
        deleteAction: { _ in true }
    )
}
