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

                        let normalizedIntro = normalizeLegacyDiagramReplacements(
                            intro: detail.intro,
                            lessonId: lesson.id
                        )
                        let blocks = parseContentBlocks(normalizedIntro)
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
                                let isFormulaBox = boxStyleIsFormula(content: content, fallbackIndex: boxIdx)
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
                            case .image(let imageName):
                                LessonImageView(imageName: imageName)
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
    case image(String)
}

private let legacyLessonImages: [String: [String]] = [
    "1": ["naturalNumbers.png"],
    "1-0": ["naturalNumbers.png"],
    "1-1": ["integersNumbers.png"],
    "1-2": ["rationalNumbers.jpg"],
    "2": ["powerProperties.png"],
    "2-0": ["pedmas.png"],
    "2-1": ["powerProperties.png"],
    "2-2": ["sqrtProperties.png"],
    "3": ["bodmas.jpg"],
    "3-0": ["pedmas.png", "bodmas.jpg"],
    "4": ["divisors.svg"],
    "4-0": ["multiples.jpg"],
    "4-1": ["divisors.svg"],
    "4-2": ["gcd.png"],
    "4-3": ["multiples.jpg"],
    "5": ["equivalentFractions.png"],
    "5-0": ["equivalentFractions.png"],
    "5-1": ["fractionOperations.jpg"],
    "5-2": ["fractionToPercent.png"],
    "5-3": ["proportions.png"],
    "6": ["operationsPolynomials.png"],
    "6-0": ["operationsPolynomials.png"],
    "6-1": ["degreeOfAPolynomial.jpg"],
    "6-2": ["specialProductsPolynomials.jpg"],
    "7": ["greatestCommonFactoring.jpg"],
    "7-0": ["greatestCommonFactoring.jpg"],
    "7-1": ["ruffiniRule.jpg"],
    "7-2": ["specialProductsPolynomials.jpg"],
    "8": ["firstDegreeEquations.gif"],
    "8-0": ["firstDegreeEquations.gif"],
    "8-1": ["firstDegreeEquations.gif"],
    "9": ["completeAndIncompleteQuadratics.webp"],
    "9-0": ["completeAndIncompleteQuadratics.webp"],
    "9-1": ["discriminant.png"],
    "9-2": ["completeAndIncompleteQuadratics.webp"],
    "10": ["substitutionSystems.jpg"],
    "10-0": ["substitutionSystems.jpg"],
    "10-1": ["comparisonSystems.jpg"],
    "10-2": ["cramerSystems.jpg"],
    "11": ["triangles.png"],
    "11-0": ["segment.png"],
    "11-1": ["angles.png"],
    "11-2": ["triangles.png"],
    "11-3": ["quadrilaters.png"],
    "11-4": ["polygons.png"],
    "12": ["criteriaForTriangles.png"],
    "12-0": ["criteriaForTriangles.png"],
    "12-1": ["pythagoraTheorems.png", "euclidTheorem.gif"],
    "13": ["circumference.png"],
    "13-0": ["circumference.png"],
    "13-1": ["area.png"],
    "13-2": ["tangents.png"],
    "13-3": ["secants.png"],
    "14": ["prisms.jpg"],
    "14-0": ["prisms.jpg"],
    "14-1": ["pyramids.jpg"],
    "14-2": ["cylinders.png"],
    "14-3": ["cones.png"],
    "14-4": ["spheres.jpg"],
    "15": ["unitCircle.webp"],
    "15-0": ["unitCircle.webp"],
    "15-1": ["sineCosineTangent.avif"],
    "15-2": ["lawOfSinesCosines.jpeg"],
]

private func normalizeLegacyDiagramReplacements(intro: String, lessonId: String) -> String {
    guard intro.contains("[DIAGRAM:"),
          let imageNames = legacyLessonImages[lessonId],
          !imageNames.isEmpty else {
        return intro
    }

    let replacement = imageNames
        .map { "[IMAGE:\($0)]" }
        .joined(separator: "\n\n")

    let pattern = #"\[DIAGRAM:[^\]]+\]"#
    guard let regex = try? NSRegularExpression(pattern: pattern) else {
        return intro
    }

    let range = NSRange(intro.startIndex..<intro.endIndex, in: intro)
    return regex.stringByReplacingMatches(in: intro, options: [], range: range, withTemplate: replacement)
}

private func parseContentBlocks(_ intro: String) -> [ContentBlock] {
    var result: [ContentBlock] = []
    var remaining = normalizeIntroImagePlacement(intro)

    while true {
        let diagramRange = remaining.range(of: "[DIAGRAM:")
        let imageRange = remaining.range(of: "[IMAGE:")
        let boxRange = remaining.range(of: "[BOX]")

        if diagramRange == nil && imageRange == nil && boxRange == nil {
            let trimmed = remaining.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { result.append(.text(trimmed)) }
            break
        }

        var nextToken: String?
        var nextRange: Range<String.Index>?
        for (token, range) in [("diagram", diagramRange), ("image", imageRange), ("box", boxRange)] {
            guard let range else { continue }
            if let current = nextRange {
                if range.lowerBound < current.lowerBound {
                    nextRange = range
                    nextToken = token
                }
            } else {
                nextRange = range
                nextToken = token
            }
        }

        if let token = nextToken, let markerRange = nextRange, token == "diagram" || token == "image" {
            let textBefore = String(remaining[..<markerRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !textBefore.isEmpty {
                result.append(.text(textBefore))
            }

            let afterPrefix = remaining[markerRange.upperBound...]
            guard let bracket = afterPrefix.firstIndex(of: "]") else {
                let trailing = String(remaining).trimmingCharacters(in: .whitespacesAndNewlines)
                if !trailing.isEmpty { result.append(.text(trailing)) }
                break
            }

            let id = String(afterPrefix[..<bracket]).trimmingCharacters(in: .whitespaces)
            if !id.isEmpty {
                if token == "diagram" {
                    result.append(.diagram(id))
                } else {
                    result.append(.image(id))
                }
            }

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

private func normalizeIntroImagePlacement(_ intro: String) -> String {
    let normalized = intro.replacingOccurrences(of: "\r\n", with: "\n")
    let lines = normalized.components(separatedBy: "\n")

    var images: [String] = []
    var remaining: [String] = []

    for line in lines {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("[IMAGE:") && trimmed.hasSuffix("]") {
            images.append(trimmed)
        } else {
            remaining.append(line)
        }
    }

    guard !images.isEmpty,
          let boxIndex = remaining.firstIndex(where: { $0.trimmingCharacters(in: .whitespacesAndNewlines) == "[BOX]" }) else {
        return intro
    }

    var before = Array(remaining[..<boxIndex])
    let after = Array(remaining[boxIndex...])

    while let last = before.last, last.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        before.removeLast()
    }

    var rebuilt = before
    if !rebuilt.isEmpty {
        rebuilt.append("")
    }

    for (index, image) in images.enumerated() {
        rebuilt.append(image)
        if index < images.count - 1 {
            rebuilt.append("")
        }
    }

    if !after.isEmpty {
        rebuilt.append("")
        rebuilt.append(contentsOf: after)
    }

    return collapseBlankLines(rebuilt)
}

private func collapseBlankLines(_ lines: [String]) -> String {
    var result: [String] = []
    var previousWasBlank = false

    for line in lines {
        let isBlank = line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        if isBlank && previousWasBlank {
            continue
        }
        result.append(line)
        previousWasBlank = isBlank
    }

    return result.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
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

struct LessonImageView: View {
    let imageName: String
    @State private var svgData: Data?
    @State private var loadFailed = false

    private var imageURL: URL? {
        let base = APIConfig.serverBaseURLString
        let encodedName = imageName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? imageName
        let path = base.hasSuffix("/") ? base + "lesson-images/" + encodedName : base + "/lesson-images/" + encodedName
        return URL(string: path)
    }

    private var isSVG: Bool {
        imageName.lowercased().hasSuffix(".svg")
    }

    private var usesWebView: Bool {
        let lower = imageName.lowercased()
        return lower.hasSuffix(".svg") || lower.hasSuffix(".gif") || lower.hasSuffix(".webp") || lower.hasSuffix(".avif")
    }

    var body: some View {
        Group {
            if isSVG {
                if loadFailed {
                    mediaFailureView
                } else if let data = svgData {
                    DiagramWebView(svgData: data)
                        .frame(minHeight: 120, maxHeight: 280)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.separator).opacity(0.5), lineWidth: 1)
                        )
                } else {
                    mediaLoadingView
                }
            } else if usesWebView, let url = imageURL {
                RemoteImageWebView(url: url)
                    .frame(minHeight: 120, maxHeight: 280)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.separator).opacity(0.5), lineWidth: 1)
                    )
            } else if let url = imageURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        mediaLoadingView
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(.separator).opacity(0.5), lineWidth: 1)
                            )
                    case .failure:
                        mediaFailureView
                    @unknown default:
                        mediaFailureView
                    }
                }
            } else {
                mediaFailureView
            }
        }
        .task(id: imageName) {
            guard isSVG, let url = imageURL else { return }
            do {
                let (data, resp) = try await URLSession.shared.data(from: url)
                if (resp as? HTTPURLResponse)?.statusCode == 200 {
                    svgData = data
                    loadFailed = false
                } else {
                    loadFailed = true
                }
            } catch {
                loadFailed = true
            }
        }
    }

    private var mediaLoadingView: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(Color(.separator).opacity(0.5), lineWidth: 1)
            .frame(minHeight: 120, maxHeight: 280)
            .overlay(ProgressView())
    }

    private var mediaFailureView: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(Color.red.opacity(0.5), lineWidth: 1)
            .frame(minHeight: 80, maxHeight: 120)
            .overlay(Text(L10n.diagramNotAvailable).font(.caption).foregroundColor(.secondary))
    }
}

private struct RemoteImageWebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.dataDetectorTypes = []
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.load(URLRequest(url: url))
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
