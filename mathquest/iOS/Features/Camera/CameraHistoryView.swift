import SwiftUI

struct CameraHistoryView: View {
    let history: [HistoryItem]
    @Environment(\.dismiss) private var dismiss
    @State private var selectedItem: HistoryDetailResponse?
    @State private var isLoadingDetail = false

    private let client = APIClient()
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        NavigationStack {
            Group {
                if history.isEmpty {
                    emptyState
                } else {
                    historyList
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $selectedItem) { detail in
                HistoryDetailView(detail: detail)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No History Yet")
                .font(.title2.bold())

            Text("Your solved math problems will appear here")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private var historyList: some View {
        List(history) { item in
            Button {
                loadDetail(id: item.id)
            } label: {
                HistoryRowView(item: item, dateFormatter: dateFormatter)
            }
            .buttonStyle(.plain)
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

    private func loadDetail(id: Int) {
        Task {
            isLoadingDetail = true
            do {
                await client.setToken("mock-dev-token")
                let detail: HistoryDetailResponse = try await client.request("camera/history/\(id)")
                selectedItem = detail
            } catch {
                print("Failed to load detail: \(error)")
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
    @Environment(\.dismiss) private var dismiss
    @State private var visibleSteps: Set<Int> = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Problem
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Problem")
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
                        Text("Difficulty")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        DifficultyBadge(level: detail.difficultyLevel)
                    }

                    Divider()

                    // Steps
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Solution Steps")
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

                    // LaTeX if available
                    if !detail.rawLatex.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("LaTeX")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text(detail.rawLatex)
                                .font(.system(.caption, design: .monospaced))
                                .padding()
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
            }
            .navigationTitle("Solution")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await animateSteps()
            }
        }
    }

    private func animateSteps() async {
        for i in 0..<detail.steps.count {
            try? await Task.sleep(nanoseconds: 200_000_000)
            visibleSteps.insert(i)
        }
    }
}

#Preview {
    CameraHistoryView(history: [
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
    ])
}
