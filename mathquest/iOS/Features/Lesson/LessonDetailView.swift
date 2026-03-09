import SwiftUI
import WebKit

// Dark purple (same as app gradient) for formula boxes (1st, 3rd, …)
private let formulaBoxColor = Color(red: 102/255, green: 80/255, blue: 164/255)  // #6650A4
// Light purple for example boxes (2nd, 4th, …)
private let exampleBoxColor = Color(red: 153/255, green: 128/255, blue: 240/255) // #9980F0

struct LessonDetailView: View {
    let lesson: LessonItem
    @StateObject private var viewModel = LessonDetailViewModel()
    @State private var feedbackMessage = ""
    @State private var showFeedbackAlert = false

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView(L10n.loading)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let detail = viewModel.lessonDetail {
                let currentTier = SubscriptionTier.current
                let projectedReward = currentTier.rewardForLesson(cost: lesson.coinCost)

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(L10n.lesson)
                            .font(.headline)

                        let blocks = parseContentBlocks(detail.intro)
                        let boxIndices = computeBoxIndices(blocks)

                        ForEach(Array(blocks.enumerated()), id: \.offset) { idx, block in
                            switch block {
                            case .text(let text):
                                ForEach(paragraphs(from: text), id: \.self) { paragraph in
                                    renderInlineBold(paragraph)
                                        .font(.body)
                                        .padding(.bottom, 8)
                                }
                            case .box(let content):
                                let boxIdx = boxIndices[idx] ?? 0
                                let isFormulaBox = boxIdx % 2 == 0
                                let accentColor = isFormulaBox ? formulaBoxColor : exampleBoxColor

                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(boxLines(from: content), id: \.self) { line in
                                        if isFormulaLine(line) {
                                            Text(line)
                                                .font(.system(size: 18, weight: .semibold, design: .monospaced))
                                                .foregroundColor(accentColor)
                                        } else {
                                            renderInlineBold(line)
                                                .font(.body)
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(14)
                                .background(accentColor.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(accentColor.opacity(0.5), lineWidth: 1.2)
                                )
                                .padding(.vertical, 4)
                            case .diagram(let diagramID):
                                LessonDiagramView(diagramID: diagramID)
                                    .padding(.vertical, 8)
                            }
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(L10n.lessonCost(lesson.coinCost))
                            Text("\(L10n.planLabel): \(currentTier.displayName)")
                            Text(L10n.completionReward(projectedReward))
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.top, 12)

                        Button {
                            Task {
                                await completeLesson()
                            }
                        } label: {
                            HStack {
                                if viewModel.isCompleting {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                }
                                Text(viewModel.isCompleting
                                     ? L10n.completing
                                     : L10n.completeLessonBtn(projectedReward))
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(viewModel.isCompleting)
                        .padding(.top, 24)
                    }
                    .padding()
                }
            } else if let error = viewModel.errorMessage {
                VStack(spacing: 8) {
                    Text("\(L10n.error): \(error)")
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Button(L10n.retry) { Task { await viewModel.load(lessonId: lesson.id) } }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 12) {
                    Text(L10n.contentNotAvailable)
                        .font(.headline)
                    Text(L10n.serverRetryMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button(L10n.retry) { Task { await viewModel.load(lessonId: lesson.id) } }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle(lesson.title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load(lessonId: lesson.id)
        }
        .alert(L10n.lesson, isPresented: $showFeedbackAlert) {
            Button(L10n.ok, role: .cancel) {}
        } message: {
            Text(feedbackMessage)
        }
    }

    private func completeLesson() async {
        do {
            let coinsEarned = try await viewModel.completeLesson(
                lessonId: lesson.id,
                lessonCost: lesson.coinCost
            )
            feedbackMessage = "Completed. You earned \(coinsEarned) coins."
        } catch {
            feedbackMessage = error.localizedDescription
        }

        showFeedbackAlert = true
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
    @Published var isCompleting = false
    @Published var errorMessage: String?

    private let client = APIClient()

    func load(lessonId: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            await client.setToken("mock-dev-token")
            let lang = UserDefaults.standard.string(forKey: "settings_language") ?? "en"
            let response: LessonDetailResponse = try await client.request("lessons/\(lessonId)?lang=\(lang)")
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

    func completeLesson(lessonId: String, lessonCost: Int) async throws -> Int {
        isCompleting = true
        defer { isCompleting = false }

        await client.setToken("mock-dev-token")
        let request = LessonCompleteRequest(lessonCost: Swift.max(0, lessonCost))
        let body = try JSONEncoder().encode(request)
        let response: LessonCompleteResponse = try await client.request(
            "lessons/\(lessonId)/complete",
            method: "POST",
            body: body
        )

        let normalizedCost = Swift.max(0, response.lessonCost ?? lessonCost)
        let safeReward = Swift.max(0, Swift.min(normalizedCost, response.coinsEarned))
        CoinWallet.addLocalBonus(safeReward)
        return safeReward
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

private struct LessonCompleteRequest: Encodable {
    let lessonCost: Int

    enum CodingKeys: String, CodingKey {
        case lessonCost = "lesson_cost"
    }
}

private struct LessonCompleteResponse: Decodable {
    let coinsEarned: Int
    let lessonCost: Int?

    enum CodingKeys: String, CodingKey {
        case coinsEarned = "coins_earned"
        case lessonCost = "lesson_cost"
    }
}

private enum ContentBlock {
    case text(String)
    case box(String)
    case diagram(String)
}

private func parseContentBlocks(_ intro: String) -> [ContentBlock] {
    var result: [ContentBlock] = []
    var remaining = intro
    while true {
        let diagramPrefix = "[DIAGRAM:"
        if let ds = remaining.range(of: diagramPrefix) {
            let afterPrefix = remaining[ds.upperBound...]
            if let bracket = afterPrefix.firstIndex(of: "]") {
                let id = String(afterPrefix[..<bracket]).trimmingCharacters(in: .whitespaces)
                let textBefore = String(remaining[..<ds.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                if !textBefore.isEmpty { result.append(.text(textBefore)) }
                if !id.isEmpty { result.append(.diagram(id)) }
                remaining = String(afterPrefix[afterPrefix.index(after: bracket)...])
                continue
            }
        }

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

/// Maps each block's position to a zero-based box counter (only for .box entries).
/// Even counter = formula box (dark purple), odd = example box (light purple).
private func computeBoxIndices(_ blocks: [ContentBlock]) -> [Int: Int] {
    var map: [Int: Int] = [:]
    var boxCounter = 0
    for (idx, block) in blocks.enumerated() {
        if case .box = block {
            map[idx] = boxCounter
            boxCounter += 1
        }
    }
    return map
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

// MARK: - Diagram view (SVG: fetch then load as data to avoid encoding/load errors and red box)
struct LessonDiagramView: View {
    let diagramID: String
    @State private var svgData: Data?
    @State private var loadFailed = false

    private var diagramURL: URL? {
        let base = APIConfig.serverBaseURLString
        let path = base.hasSuffix("/") ? base + "diagrams/" + diagramID : base + "/diagrams/" + diagramID
        return URL(string: path)
    }

    var body: some View {
        Group {
            if loadFailed {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.red.opacity(0.5), lineWidth: 1)
                    .frame(minHeight: 80, maxHeight: 120)
                    .overlay(Text(L10n.diagramNotAvailable).font(.caption).foregroundColor(.secondary))
            } else if let data = svgData {
                DiagramWebView(svgData: data)
                    .frame(minHeight: 120, maxHeight: 280)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.separator).opacity(0.5), lineWidth: 1)
                    )
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.separator).opacity(0.5), lineWidth: 1)
                    .frame(minHeight: 120, maxHeight: 280)
                    .overlay(ProgressView())
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Diagram: \(diagramID)")
        .task {
            guard let url = diagramURL else { loadFailed = true; return }
            do {
                let (data, resp) = try await URLSession.shared.data(from: url)
                if (resp as? HTTPURLResponse)?.statusCode == 200 {
                    svgData = data
                } else {
                    loadFailed = true
                }
            } catch {
                loadFailed = true
            }
        }
    }
}

private struct DiagramWebView: UIViewRepresentable {
    let svgData: Data

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.dataDetectorTypes = []
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.load(svgData, mimeType: "image/svg+xml", characterEncodingName: "UTF-8", baseURL: URL(string: "about:blank")!)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

#Preview {
    NavigationStack {
        LessonDetailView(lesson: LessonItem(id: "1", title: "Addition", description: "PEMDAS, Long Division", difficulty: 1, coinCost: 10))
    }
}
