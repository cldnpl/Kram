import SwiftUI

struct LessonDetailView: View {
    let lesson: LessonItem
    @StateObject private var viewModel = LessonDetailViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let detail = viewModel.lessonDetail {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Lesson")
                            .font(.headline)
                        ForEach(Array(parseContentBlocks(detail.intro).enumerated()), id: \.offset) { _, block in
                            switch block {
                            case .text(let text):
                                ForEach(paragraphs(from: text), id: \.self) { paragraph in
                                    renderInlineBold(paragraph)
                                        .font(.body)
                                        .padding(.bottom, 8)
                                }
                            case .box(let content):
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(boxLines(from: content), id: \.self) { line in
                                        if isFormulaLine(line) {
                                            Text(line)
                                                .font(.system(size: 18, weight: .semibold, design: .monospaced))
                                        } else {
                                            renderInlineBold(line)
                                                .font(.body)
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(14)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(.separator).opacity(0.5), lineWidth: 1)
                                )
                                .padding(.vertical, 4)
                            }
                        }
                        Button(action: {}) {
                            Text("Practice")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.top, 24)
                    }
                    .padding()
                }
            } else if let error = viewModel.errorMessage {
                VStack(spacing: 8) {
                    Text("Error: \(error)")
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Button("Retry") { Task { await viewModel.load(lessonId: lesson.id) } }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 12) {
                    Text("Contenuto non disponibile")
                        .font(.headline)
                    Text("Assicurati che il server sia avviato e riprova.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Riprova") { Task { await viewModel.load(lessonId: lesson.id) } }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle(lesson.title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load(lessonId: lesson.id)
        }
    }
}

struct LessonDetailExercise: Identifiable {
    let id: String
    let question: String
    let options: [String]
}

@MainActor
final class LessonDetailViewModel: ObservableObject {
    @Published var lessonDetail: (intro: String, exercises: [LessonDetailExercise])?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let client = APIClient()

    func load(lessonId: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            await client.setToken("mock-dev-token")
            let response: LessonDetailResponse = try await client.request("lessons/\(lessonId)")
            let exercises = (response.exercises ?? []).map { ex in
                LessonDetailExercise(
                    id: ex.id ?? "",
                    question: ex.question ?? "",
                    options: ex.options ?? []
                )
            }
            lessonDetail = (intro: response.contentIntro, exercises: exercises)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct LessonDetailResponse: Decodable {
    let id: String?
    let title: String?
    let content_json: ContentJSON?
    let exercises: [ExerciseDTO]?

    var contentIntro: String {
        content_json?.intro ?? "Learn and practice."
    }

    struct ContentJSON: Decodable {
        let intro: String?
    }
}

private struct ExerciseDTO: Decodable {
    let id: String?
    let question: String?
    let options: [String]?
}

private enum ContentBlock {
    case text(String)
    case box(String)
}

private func parseContentBlocks(_ intro: String) -> [ContentBlock] {
    var result: [ContentBlock] = []
    var remaining = intro
    while true {
        guard let range = remaining.range(of: "[BOX]") else {
            let trimmed = remaining.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { result.append(.text(trimmed)) }
            break
        }
        let textPart = String(remaining[..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        if !textPart.isEmpty { result.append(.text(textPart)) }
        remaining = String(remaining[range.upperBound...])
        if let endRange = remaining.range(of: "[/BOX]") {
            let boxContent = String(remaining[..<endRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !boxContent.isEmpty { result.append(.box(boxContent)) }
            remaining = String(remaining[endRange.upperBound...])
        } else {
            let trimmed = remaining.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { result.append(.text(trimmed)) }
            break
        }
    }
    return result
}

private func boxLines(from content: String) -> [String] {
    content.components(separatedBy: .newlines)
        .map { $0.trimmingCharacters(in: .whitespaces) }
        .filter { !$0.isEmpty }
}

private func paragraphs(from text: String) -> [String] {
    text.components(separatedBy: "\n\n")
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
}

private func renderInlineBold(_ text: String) -> Text {
    let parts = text.components(separatedBy: "**")
    var out = Text("")
    for (idx, part) in parts.enumerated() {
        if part.isEmpty { continue }
        if idx % 2 == 1 {
            out = out + Text(part).bold()
        } else {
            out = out + Text(part)
        }
    }
    return out
}

private func isFormulaLine(_ line: String) -> Bool {
    let s = line.trimmingCharacters(in: .whitespacesAndNewlines)
    if s.isEmpty { return false }

    if s.contains("=") { return true }
    if s.contains("→") || s.contains("±") { return true }
    if s.contains("√") || s.contains("∫") || s.contains("Δ") { return true }
    if s.contains("^") { return true }

    let lower = s.lowercased()
    if lower.contains("lim") { return true }
    if lower.contains("sin") || lower.contains("cos") || lower.contains("tan") { return true }
    if lower.contains("ln") || lower.contains("log") || lower.contains("e^") { return true }

    return false
}

#Preview {
    NavigationStack {
        LessonDetailView(lesson: LessonItem(id: "1", title: "Addition", description: "PEMDAS, Long Division", difficulty: 1, coinCost: 10))
    }
}
