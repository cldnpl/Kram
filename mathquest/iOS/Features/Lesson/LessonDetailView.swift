import SwiftUI
import WebKit
import UIKit

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
                                    if isFormulaLine(paragraph) {
                                        FormulaFractionTextView(
                                            line: paragraph,
                                            color: UIColor(formulaBoxColor)
                                        )
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.bottom, 8)
                                    } else {
                                        renderInlineBold(paragraph)
                                            .font(.body)
                                            .padding(.bottom, 8)
                                    }
                                }
                            case .box(let content):
                                let boxIdx = boxIndices[idx] ?? 0
                                let isFormulaBox = boxStyleIsFormula(content: content, fallbackIndex: boxIdx)
                                let accentColor = isFormulaBox ? formulaBoxColor : exampleBoxColor

                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(boxLines(from: content), id: \.self) { line in
                                        if isFormulaLine(line) {
                                            FormulaFractionTextView(
                                                line: line,
                                                color: UIColor(accentColor)
                                            )
                                            .frame(maxWidth: .infinity, alignment: .leading)
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
        let diagramRange = remaining.range(of: "[DIAGRAM:")
        let boxRange = remaining.range(of: "[BOX]")

        if diagramRange == nil && boxRange == nil {
            let trimmed = remaining.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { result.append(.text(trimmed)) }
            break
        }

        let nextIsDiagram: Bool
        switch (diagramRange, boxRange) {
        case let (d?, b?):
            nextIsDiagram = d.lowerBound < b.lowerBound
        case (_?, nil):
            nextIsDiagram = true
        case (nil, _?):
            nextIsDiagram = false
        default:
            nextIsDiagram = false
        }

        if nextIsDiagram, let d = diagramRange {
            let textBefore = String(remaining[..<d.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !textBefore.isEmpty {
                result.append(.text(textBefore))
            }

            let afterPrefix = remaining[d.upperBound...]
            guard let bracket = afterPrefix.firstIndex(of: "]") else {
                let trailing = String(remaining).trimmingCharacters(in: .whitespacesAndNewlines)
                if !trailing.isEmpty { result.append(.text(trailing)) }
                break
            }

            let id = String(afterPrefix[..<bracket]).trimmingCharacters(in: .whitespaces)
            if !id.isEmpty { result.append(.diagram(id)) }

            let nextStart = afterPrefix.index(after: bracket)
            remaining = String(afterPrefix[nextStart...])
            continue
        }

        if let b = boxRange {
            let textPart = String(remaining[..<b.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !textPart.isEmpty { result.append(.text(textPart)) }

            let afterBoxStart = remaining[b.upperBound...]
            guard let endRange = afterBoxStart.range(of: "[/BOX]") else {
                let trailing = String(afterBoxStart).trimmingCharacters(in: .whitespacesAndNewlines)
                if !trailing.isEmpty { result.append(.text(trailing)) }
                break
            }

            let boxContent = String(afterBoxStart[..<endRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !boxContent.isEmpty { result.append(.box(boxContent)) }
            remaining = String(afterBoxStart[endRange.upperBound...])
            continue
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
    let normalized = text.replacingOccurrences(of: "\r\n", with: "\n")
    var out: [String] = []

    for rawLine in normalized.components(separatedBy: "\n") {
        let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
        if line.isEmpty { continue }

        if isBulletLikeLine(line) || isStandaloneHeading(line) {
            out.append(line)
            continue
        }

        let split = splitLeadingBoldHeading(line)
        if let heading = split.heading {
            out.append(heading)
            if let rest = split.rest, !rest.isEmpty {
                out.append(contentsOf: splitBySentence(rest))
            }
            continue
        }

        out.append(contentsOf: splitBySentence(line))
    }

    return out
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

private func isBulletLikeLine(_ line: String) -> Bool {
    let s = line.trimmingCharacters(in: .whitespaces)
    return s.hasPrefix("•") || s.hasPrefix("- ") || s.hasPrefix("* ")
}

private func isStandaloneHeading(_ line: String) -> Bool {
    let s = line.trimmingCharacters(in: .whitespacesAndNewlines)
    return s.hasPrefix("**") && s.hasSuffix("**") && s.count > 4
}

private func splitLeadingBoldHeading(_ line: String) -> (heading: String?, rest: String?) {
    let s = line.trimmingCharacters(in: .whitespacesAndNewlines)
    guard s.hasPrefix("**") else { return (nil, nil) }
    guard let start = s.range(of: "**")?.upperBound,
          let end = s[start...].range(of: "**")?.upperBound else {
        return (nil, nil)
    }

    let heading = String(s[..<end]).trimmingCharacters(in: .whitespacesAndNewlines)
    let rest = String(s[end...]).trimmingCharacters(in: .whitespacesAndNewlines)
    if heading.isEmpty { return (nil, nil) }
    return (heading, rest)
}

private func splitBySentence(_ text: String) -> [String] {
    var out: [String] = []
    var buffer = ""

    func flushBuffer() {
        let trimmed = buffer.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            out.append(trimmed)
        }
        buffer = ""
    }

    var idx = text.startIndex
    while idx < text.endIndex {
        let ch = text[idx]
        buffer.append(ch)

        if ch == "." || ch == "?" || ch == "!" {
            let next = text.index(after: idx)
            let atEnd = next >= text.endIndex
            let nextIsSpace = !atEnd && text[next].unicodeScalars.allSatisfy { $0.properties.isWhitespace }

            if atEnd || nextIsSpace {
                flushBuffer()
                var skip = next
                while skip < text.endIndex && text[skip].unicodeScalars.allSatisfy({ $0.properties.isWhitespace }) {
                    skip = text.index(after: skip)
                }
                idx = skip
                continue
            }
        }

        idx = text.index(after: idx)
    }

    flushBuffer()
    return out
}

private func boxStyleIsFormula(content: String, fallbackIndex: Int) -> Bool {
    let lines = boxLines(from: content)
    let cleaned = lines
        .map { $0.replacingOccurrences(of: "**", with: "").lowercased() }
        .filter { !$0.isEmpty }

    if let header = cleaned.first {
        let exampleHints = ["example", "examples", "esempio", "esempi", "exemple", "exemples", "ejemplo", "ejemplos", "misol", "misollar"]
        if exampleHints.contains(where: { header.contains($0) }) {
            return false
        }

        let formulaHints = ["formula", "formulas", "formule", "fórmulas", "formullar", "equation", "equazioni", "équation", "ecuación", "tenglama"]
        if formulaHints.contains(where: { header.contains($0) }) {
            return true
        }
    }

    let formulaLines = lines.filter { isFormulaLine($0) }.count
    let textLines = max(0, lines.count - formulaLines)
    if formulaLines > textLines { return true }
    if textLines > formulaLines { return false }

    return fallbackIndex % 2 == 0
}

private struct FormulaFractionTextView: UIViewRepresentable {
    let line: String
    let color: UIColor

    func makeUIView(context: Context) -> UILabel {
        let label = UILabel()
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.setContentHuggingPriority(.required, for: .vertical)
        return label
    }

    func updateUIView(_ uiView: UILabel, context: Context) {
        uiView.attributedText = buildFractionAttributedLine(line: line, color: color)
    }
}

private let fractionRegex: NSRegularExpression = {
    // Simple algebraic fraction tokens (e.g. 1/2, a/b, x2/y3)
    return try! NSRegularExpression(pattern: #"([A-Za-z0-9]+)\s*/\s*([A-Za-z0-9]+)"#)
}()

private func buildFractionAttributedLine(line: String, color: UIColor) -> NSAttributedString {
    let formulaFont = UIFont.monospacedSystemFont(ofSize: 18, weight: .semibold)
    let attrs: [NSAttributedString.Key: Any] = [
        .font: formulaFont,
        .foregroundColor: color
    ]

    let result = NSMutableAttributedString()
    let nsLine = line as NSString
    let fullRange = NSRange(location: 0, length: nsLine.length)
    let matches = fractionRegex.matches(in: line, options: [], range: fullRange)

    var cursor = 0
    for m in matches {
        if m.range.location > cursor {
            let plain = nsLine.substring(with: NSRange(location: cursor, length: m.range.location - cursor))
            result.append(NSAttributedString(string: plain, attributes: attrs))
        }

        let numerator = nsLine.substring(with: m.range(at: 1))
        let denominator = nsLine.substring(with: m.range(at: 2))
        let attachment = fractionAttachment(numerator: numerator, denominator: denominator, color: color)
        result.append(NSAttributedString(attachment: attachment))
        cursor = m.range.location + m.range.length
    }

    if cursor < nsLine.length {
        let tail = nsLine.substring(from: cursor)
        result.append(NSAttributedString(string: tail, attributes: attrs))
    }

    if result.length == 0 {
        return NSAttributedString(string: line, attributes: attrs)
    }
    return result
}

private func fractionAttachment(numerator: String, denominator: String, color: UIColor) -> NSTextAttachment {
    let topFont = UIFont.monospacedSystemFont(ofSize: 12, weight: .bold)
    let bottomFont = UIFont.monospacedSystemFont(ofSize: 12, weight: .bold)
    let textAttrsTop: [NSAttributedString.Key: Any] = [.font: topFont, .foregroundColor: color]
    let textAttrsBottom: [NSAttributedString.Key: Any] = [.font: bottomFont, .foregroundColor: color]

    let numSize = (numerator as NSString).size(withAttributes: textAttrsTop)
    let denSize = (denominator as NSString).size(withAttributes: textAttrsBottom)
    let width = ceil(max(numSize.width, denSize.width)) + 6
    let lineHeight: CGFloat = 1.2
    let height = ceil(numSize.height + denSize.height + 4 + lineHeight)

    let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height))
    let image = renderer.image { _ in
        let numRect = CGRect(
            x: (width - numSize.width) / 2,
            y: 0,
            width: numSize.width,
            height: numSize.height
        )
        (numerator as NSString).draw(in: numRect, withAttributes: textAttrsTop)

        let yLine = numSize.height + 1
        color.setFill()
        UIRectFill(CGRect(x: 1, y: yLine, width: width - 2, height: lineHeight))

        let denRect = CGRect(
            x: (width - denSize.width) / 2,
            y: yLine + 2,
            width: denSize.width,
            height: denSize.height
        )
        (denominator as NSString).draw(in: denRect, withAttributes: textAttrsBottom)
    }

    let attachment = NSTextAttachment()
    attachment.image = image
    // Baseline alignment with surrounding 18pt formula text.
    attachment.bounds = CGRect(x: 0, y: -3, width: width, height: height)
    return attachment
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
