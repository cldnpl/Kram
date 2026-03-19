import SwiftUI
import UIKit
import WebKit
import FirebaseAuth

// Dark purple (same as app gradient) for formula boxes (1st, 3rd, …)
private let formulaBoxColor = Color(red: 102/255, green: 80/255, blue: 164/255)  // #6650A4
// Light purple for example boxes (2nd, 4th, …)
private let exampleBoxColor = Color(red: 153/255, green: 128/255, blue: 240/255) // #9980F0
private let lessonAccentColor = Color(red: 102/255, green: 80/255, blue: 164/255)

struct LessonDetailView: View {
    let lesson: LessonItem
    @StateObject private var viewModel = LessonDetailViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView(L10n.loading)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let detail = viewModel.lessonDetail {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
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
                                    LessonParagraphView(text: paragraph)
                                        .padding(.bottom, 8)
                                }
                            case .box(let content):
                                let boxIdx = boxIndices[idx] ?? 0
                                let isFormulaBox = boxStyleIsFormula(content: content, fallbackIndex: boxIdx)
                                let accentColor = isFormulaBox ? formulaBoxColor : exampleBoxColor

                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(boxLines(from: content), id: \.self) { line in
                                        if isFormulaLine(line) {
                                            LessonFormulaLineView(text: line, accentColor: accentColor)
                                        } else {
                                            LessonPracticeContentView(
                                                text: line,
                                                textStyle: .body,
                                                textSize: 17,
                                                textWeight: .regular,
                                                textColor: .primary,
                                                centered: true
                                            )
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

                        NavigationLink {
                            LessonPracticeView(
                                lesson: lesson,
                                exercises: detail.exercises,
                                completeLessonAction: {
                                    try await viewModel.completeLesson(
                                        lessonId: lesson.id,
                                        lessonCost: 0
                                    )
                                }
                            )
                        } label: {
                            HStack {
                                Text(L10n.practice)
                                    .font(.headline)
                            }
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
    }
}

struct LessonDetailExercise: Identifiable {
    let id: String
    let question: String
    let options: [String]
    let correctAnswer: String
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
            await client.setToken(Auth.auth().currentUser?.uid)
            let lang = UserDefaults.standard.string(forKey: "settings_language") ?? "en"
            let response: LessonDetailResponse = try await client.request("lessons/\(lessonId)?lang=\(lang)")
            let exercises = (response.exercises ?? []).map { ex in
                LessonDetailExercise(
                    id: ex.id ?? "",
                    question: ex.question ?? "",
                    options: ex.options ?? [],
                    correctAnswer: ex.correctAnswer ?? ex.options?.first ?? ""
                )
            }
            lessonDetail = (intro: response.contentIntro, exercises: exercises)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func completeLesson(lessonId: String, lessonCost: Int) async throws -> Int {
        if CoinWallet.hasRewardedLesson(lessonId) {
            return 0
        }

        isCompleting = true
        defer { isCompleting = false }

        await client.setToken(Auth.auth().currentUser?.uid)
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
        CoinWallet.markLessonRewarded(lessonId)
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
    let correctAnswer: String?

    enum CodingKeys: String, CodingKey {
        case id
        case question
        case options
        case correctAnswer = "correct_answer"
    }
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

private struct LessonParagraphView: View {
    let text: String

    var body: some View {
        renderLessonParagraphText(text)
            .font(.body)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, alignment: .center)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct LessonFormulaLineView: View {
    let text: String
    let accentColor: Color

    private var split: (label: String?, formula: String?, note: String?) {
        splitLessonFormulaLineWithEquationFallback(text)
    }

    var body: some View {
        if split.formula == nil, split.label == nil, let note = split.note {
            if isLessonFormulaHeading(note), let attributed = attributedLessonText(from: note) {
                Text(attributed)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(lessonAccentColor)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            } else if practiceContentNeedsMathRendering(note) {
                LessonMixedMathView(
                    html: lessonMixedMathHTML(
                        content: note,
                        centered: true,
                        fontSize: 16,
                        fontWeight: 500
                    )
                )
                .frame(minHeight: 40, maxHeight: 96)
            } else if let attributed = attributedLessonText(from: note) {
                Text(attributed)
                    .font(.caption)
                    .foregroundStyle(exampleBoxColor)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
        } else {
        VStack(alignment: .center, spacing: 6) {
            if let label = split.label, let attributed = attributedLessonText(from: label) {
                Text(attributed)
                    .font(.body)
                    .foregroundStyle(lessonAccentColor)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }

            if let formula = split.formula {
                LessonMathView(latex: normalizeLessonLatex(formula), displayMode: true)
                    .frame(minHeight: 64, maxHeight: 168)
            }

            if let note = split.note, let attributed = attributedLessonText(from: note) {
                Text(attributed)
                    .font(.caption)
                    .foregroundStyle(exampleBoxColor)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
        }
        .foregroundStyle(accentColor)
        }
    }
}

private struct LessonMathView: UIViewRepresentable {
    let latex: String
    let displayMode: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = displayMode
        webView.scrollView.bounces = displayMode
        webView.scrollView.alwaysBounceHorizontal = displayMode
        webView.scrollView.alwaysBounceVertical = false
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.scrollView.showsHorizontalScrollIndicator = displayMode
        webView.isUserInteractionEnabled = displayMode
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        let html = lessonMathHTML(latex: latex, displayMode: displayMode)
        if context.coordinator.lastHTML != html {
            uiView.loadHTMLString(html, baseURL: nil)
            context.coordinator.lastHTML = html
        }
    }

    final class Coordinator {
        var lastHTML: String?
    }
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
    "16": ["domain.png"],
    "16-0": ["realFunctionsofArEALvARIABLE.gif"],
    "16-2": ["domain.png"],
    "18-0": ["equationsAndInequalitiesvithExandLogx.png"],
    "17-0": ["symmetriesEvenOdd.jpg"],
    "17-1": ["intercepts.jpg"],
    "17-2": ["signStudy.png"],
    "19-0": ["theLine.svg"],
    "19-1": ["theCircle.png"],
    "19-2": ["theParabola.jpg"],
    "19-3": ["theEllipse.png"],
    "19-4": ["theHyperbola.png"],
    "20-0": ["finiteAndInfiniteLimits.png"],
    "20-1": ["indeterminateForms.png"],
    "20-2": ["asymptotes.png"],
    "21-0": ["differenceQuotient.jpg"],
    "21-1": ["geometricMeaning.png"],
    "22-0": ["powerRule.png"],
    "22-1": ["productRule.png"],
    "22-2": ["quotientRule.webp"],
    "22-3": ["chainRule.png"],
    "23-0": ["maximaAndMinima.png"],
    "23-1": ["pointsOfInflections.png"],
    "24-0": ["primitiveFunctions.svg"],
    "24-1": ["integrationRules.png"],
    "25-0": ["integrationSubstitution.jpg"],
    "25-1": ["integrationParts.png"],
    "26-0": ["areaUnderACurve.jpg"],
    "26-1": ["fundamentalTheoremsofCalculus.png"],
    "27-0": ["calculationOfVolumes.jpg"],
    "27-1": ["areasOfPlaneFigures.jpg"],
]

private let lessonsWithoutReplacementImages: Set<String> = [
    "16-1", "17", "18", "19", "20", "21", "22", "23", "24", "25", "26", "27",
]

private func normalizeLegacyDiagramReplacements(intro: String, lessonId: String) -> String {
    let desiredImages = legacyLessonImages[lessonId]
    let shouldStripOnly = lessonsWithoutReplacementImages.contains(lessonId)

    guard shouldStripOnly || (desiredImages?.isEmpty == false) else {
        return intro
    }

    let stripped = stripLessonMediaMarkers(intro)
    if shouldStripOnly {
        return stripped
    }

    let replacement = desiredImages!
        .map { "[IMAGE:\($0)]" }
        .joined(separator: "\n\n")

    if let boxRange = stripped.range(of: "[BOX]") {
        let beforeBox = stripped[..<boxRange.lowerBound].trimmingCharacters(in: .whitespacesAndNewlines)
        let afterBox = stripped[boxRange.lowerBound...]
        if beforeBox.isEmpty {
            return "\(replacement)\n\n\(afterBox)"
        }
        return "\(beforeBox)\n\n\(replacement)\n\n\(afterBox)"
    }

    let trimmed = stripped.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? replacement : "\(trimmed)\n\n\(replacement)"
}

private func stripLessonMediaMarkers(_ intro: String) -> String {
    let pattern = #"\n?\n?\[(?:IMAGE|DIAGRAM):[^\]]+\]"#
    guard let regex = try? NSRegularExpression(pattern: pattern) else {
        return intro
    }
    let range = NSRange(intro.startIndex..<intro.endIndex, in: intro)
    let stripped = regex.stringByReplacingMatches(in: intro, options: [], range: range, withTemplate: "")
    return stripped.replacingOccurrences(of: #"\n{3,}"#, with: "\n\n", options: .regularExpression)
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
    normalizeLessonDisplayText(content)
        .components(separatedBy: .newlines)
        .map { $0.trimmingCharacters(in: .whitespaces) }
        .filter { !$0.isEmpty }
        .flatMap(splitCompoundLessonLine)
}

private func paragraphs(from text: String) -> [String] {
    let blocks = normalizeLessonDisplayText(text)
        .components(separatedBy: "\n\n")
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
    var out: [String] = []

    for block in blocks {
        let lines = block
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !lines.isEmpty else { continue }

        var current: [String] = []
        func flushCurrent() {
            let joined = current.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
            if !joined.isEmpty {
                out.append(joined)
            }
            current.removeAll(keepingCapacity: true)
        }

        for line in lines {
            if isBulletLikeLine(line) || isStandaloneHeading(line) {
                flushCurrent()
                out.append(line)
                continue
            }

            if let heading = splitLeadingBoldHeading(line).heading {
                flushCurrent()
                let rest = splitLeadingBoldHeading(line).rest?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                out.append(rest.isEmpty ? heading : "\(heading) \(rest)")
                continue
            }

            current.append(line)
        }

        flushCurrent()
    }

    return out
}

private func normalizeLessonDisplayText(_ text: String) -> String {
    var normalized = text
        .replacingOccurrences(of: "\r\n", with: "\n")
        .replacingOccurrences(of: "(BOX)", with: "")
        .replacingOccurrences(of: "(/BOX)", with: "")
    normalized = normalized.replacingOccurrences(
        of: #"(^|[ \t])(\\n|/n)(?=[ \t]*$)"#,
        with: "$1\n",
        options: .regularExpression
    )
    normalized = normalized.replacingOccurrences(
        of: #"\s+\*\*([^*\n]{1,80}:\s*)\*\*"#,
        with: "\n\n**$1**",
        options: .regularExpression
    )
    normalized = normalized.replacingOccurrences(
        of: #"\s+(\(?\d+\))\s+"#,
        with: "\n$1 ",
        options: .regularExpression
    )
    return normalized.replacingOccurrences(of: "\n{3,}", with: "\n\n", options: .regularExpression)
}

private func splitCompoundLessonLine(_ line: String) -> [String] {
    let pieces = line.components(separatedBy: ". ")
    guard pieces.count > 1 else { return [line] }

    var result: [String] = []
    var current = pieces[0].trimmingCharacters(in: .whitespacesAndNewlines)

    for piece in pieces.dropFirst() {
        let trimmed = piece.trimmingCharacters(in: .whitespacesAndNewlines)
        if !current.isEmpty, looksLikeInlineMath(current), looksLikeInlineMath(trimmed) {
            result.append(current.hasSuffix(".") ? current : current + ".")
            current = trimmed
        } else if current.isEmpty {
            current = trimmed
        } else {
            current += ". " + trimmed
        }
    }

    if !current.isEmpty {
        result.append(current)
    }

    return result
}

private func attributedLessonText(from text: String) -> AttributedString? {
    let normalized = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !normalized.isEmpty else { return nil }

    if let attributed = try? AttributedString(
        markdown: normalized,
        options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
    ) {
        return attributed
    }

    return AttributedString(normalized.replacingOccurrences(of: "**", with: ""))
}

private func renderLessonParagraphText(_ text: String) -> Text {
    let normalized = normalizeLessonDisplayText(text)
    let parts = normalized.components(separatedBy: "**")
    var out = Text("")

    for (index, part) in parts.enumerated() {
        let trimmed = part.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !part.isEmpty else { continue }

        let piece: Text
        if !trimmed.isEmpty, looksLikeInlineMath(trimmed) {
            piece = Text(part.replacingOccurrences(of: trimmed, with: prettifyLessonInlineMath(trimmed)))
        } else {
            piece = Text(prettifyLessonTextContent(part))
        }

        out = out + (index % 2 == 1 ? piece.bold().foregroundColor(lessonAccentColor) : piece)
    }

    return out
}

private func prettifyLessonInlineMath(_ text: String) -> String {
    prettifyLessonTextContent(text)
        .replacingOccurrences(of: "*", with: "×")
}

private func prettifyLessonTextContent(_ text: String) -> String {
    var value = text
        .replacingOccurrences(of: "\\pi", with: "π")
        .replacingOccurrences(of: "∫_", with: "∫")

    value = value.replacingOccurrences(
        of: #"\bpi\b"#,
        with: "π",
        options: .regularExpression
    )

    value = replacingLessonBounds(pattern: #"∫([A-Za-z0-9+\-]+)\^([A-Za-z0-9+\-]+)"#, in: value, prefix: "∫")
    value = replacingLessonBounds(pattern: #"\]_([A-Za-z0-9+\-]+)\^([A-Za-z0-9+\-]+)"#, in: value, prefix: "]")

    value = value.replacingOccurrences(of: " e^x", with: " eˣ")
    return value
}

private func replacingLessonBounds(pattern: String, in text: String, prefix: String) -> String {
    guard let regex = try? NSRegularExpression(pattern: pattern) else {
        return text
    }
    let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)
    let matches = regex.matches(in: text, range: nsRange).reversed()
    var value = text

    for match in matches {
        guard match.numberOfRanges >= 3,
              let fullRange = Range(match.range(at: 0), in: value),
              let lowerRange = Range(match.range(at: 1), in: value),
              let upperRange = Range(match.range(at: 2), in: value) else {
            continue
        }
        let lower = String(value[lowerRange])
        let upper = String(value[upperRange])
        let replacement = prefix + lessonSubscript(lower) + lessonSuperscript(upper)
        value.replaceSubrange(fullRange, with: replacement)
    }

    return value
}

private func lessonSubscript(_ text: String) -> String {
    let map: [Character: Character] = [
        "0":"₀","1":"₁","2":"₂","3":"₃","4":"₄","5":"₅","6":"₆","7":"₇","8":"₈","9":"₉",
        "a":"ₐ","e":"ₑ","h":"ₕ","i":"ᵢ","j":"ⱼ","k":"ₖ","l":"ₗ","m":"ₘ","n":"ₙ","o":"ₒ","p":"ₚ",
        "r":"ᵣ","s":"ₛ","t":"ₜ","u":"ᵤ","v":"ᵥ","x":"ₓ","+":"₊","-":"₋","=":"₌"
    ]
    return String(text.compactMap { map[$0] ?? $0 })
}

private func lessonSuperscript(_ text: String) -> String {
    let map: [Character: Character] = [
        "0":"⁰","1":"¹","2":"²","3":"³","4":"⁴","5":"⁵","6":"⁶","7":"⁷","8":"⁸","9":"⁹",
        "a":"ᵃ","b":"ᵇ","c":"ᶜ","d":"ᵈ","e":"ᵉ","f":"ᶠ","g":"ᵍ","h":"ʰ","i":"ⁱ","j":"ʲ","k":"ᵏ",
        "l":"ˡ","m":"ᵐ","n":"ⁿ","o":"ᵒ","p":"ᵖ","r":"ʳ","s":"ˢ","t":"ᵗ","u":"ᵘ","v":"ᵛ","w":"ʷ","x":"ˣ",
        "+":"⁺","-":"⁻","=":"⁼","(":"⁽",")":"⁾"
    ]
    return String(text.compactMap { map[$0] ?? $0 })
}

private func looksLikeInlineMath(_ text: String) -> Bool {
    let candidate = text.trimmingCharacters(in: .whitespacesAndNewlines)
    if candidate.isEmpty { return false }
    if candidate.range(of: #"[=+\-*/^(){}\[\]≤≥≠±√∫π∞\\]"#, options: .regularExpression) != nil {
        return true
    }
    let lower = candidate.lowercased()
    return lower.contains("lim") || lower.contains("int_") || lower.contains(#"\int"#)
        || lower.contains("frac") || lower.contains("left") || lower.contains("right")
        || lower.contains("sin") || lower.contains("cos")
        || lower.contains("tan") || lower.contains("ln") || lower.contains("log")
}

private func splitLessonFormulaLine(_ line: String) -> (label: String?, formula: String?, note: String?) {
    let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
    let splitSource = sanitizeLessonFormulaContent(trimmed)

    guard let range = splitSource.formula.range(of: ":") else {
        if containsProseWords(splitSource.formula) {
            return (nil, nil, splitSource.note.map { splitSource.formula + " " + $0 } ?? splitSource.formula)
        }
        return (nil, splitSource.formula, splitSource.note)
    }

    let left = String(splitSource.formula[..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
    let right = String(splitSource.formula[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
    guard !left.isEmpty, !right.isEmpty, looksLikeInlineMath(right) else {
        if containsProseWords(splitSource.formula) {
            return (nil, nil, splitSource.note.map { splitSource.formula + " " + $0 } ?? splitSource.formula)
        }
        return (nil, splitSource.formula, splitSource.note)
    }

    if containsProseWords(right) {
        return (left + ":", nil, splitSource.note.map { right + " " + $0 } ?? right)
    }

    return (left + ":", right, splitSource.note)
}

private func splitLessonFormulaLineWithEquationFallback(_ line: String) -> (label: String?, formula: String?, note: String?) {
    let base = splitLessonFormulaLine(line)
    if base.label != nil || base.formula != nil {
        return base
    }

    let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
    guard let eqIndex = trimmed.firstIndex(of: "="), eqIndex > trimmed.startIndex else {
        return base
    }

    let next = trimmed.index(after: eqIndex)
    guard next < trimmed.endIndex else {
        return base
    }

    let left = String(trimmed[..<eqIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
    let right = String(trimmed[next...]).trimmingCharacters(in: .whitespacesAndNewlines)
    guard !left.isEmpty, !right.isEmpty else {
        return base
    }

    if containsProseWords(left) && looksLikeInlineMath(right) {
        return (left, right, nil)
    }

    return base
}

private func isLessonFormulaHeading(_ text: String) -> Bool {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty, trimmed.hasSuffix(":") else { return false }
    return trimmed.count <= 48
}

private func sanitizeLessonFormulaContent(_ text: String) -> (formula: String, note: String?) {
    var formula = text.trimmingCharacters(in: .whitespacesAndNewlines)
    var notes: [String] = []

    if let range = formula.range(of: #"\s*(?:→|⇒|->)\s*([A-Za-z][A-Za-z \-]+\.?)$"#, options: .regularExpression) {
        let note = String(formula[range.lowerBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
        if !note.isEmpty {
            notes.append(note)
        }
        formula = String(formula[..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    if let range = formula.range(of: #"\(([A-Za-z][A-Za-z \-]+)\)\s*$"#, options: .regularExpression) {
        let note = String(formula[range.lowerBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
        if !note.isEmpty {
            notes.append(note)
        }
        formula = String(formula[..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    let note = notes.isEmpty ? nil : notes.joined(separator: " ")
    return (formula.isEmpty ? text : formula, note)
}

private func containsProseWords(_ text: String) -> Bool {
    let lower = text.lowercased()
    guard let regex = try? NSRegularExpression(pattern: #"\b[a-z]{3,}\b"#) else {
        return false
    }
    let range = NSRange(lower.startIndex..<lower.endIndex, in: lower)
    let matches = regex.matches(in: lower, range: range).compactMap { match -> String? in
        guard let matchRange = Range(match.range, in: lower) else { return nil }
        return String(lower[matchRange])
    }
    let allowed: Set<String> = [
        "sin", "cos", "tan", "log", "lim", "mod", "gcd", "lcm",
        "int", "frac", "left", "right"
    ]
    return matches.contains { !allowed.contains($0) }
}

private func normalizeLessonLatex(_ raw: String) -> String {
    var value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    if value.isEmpty { return "" }

    value = value.replacingOccurrences(of: "−", with: "-")
    value = value.replacingOccurrences(of: "×", with: " \\times ")
    value = value.replacingOccurrences(of: "÷", with: " \\div ")
    value = value.replacingOccurrences(of: "π", with: "\\pi")
    value = value.replacingOccurrences(of: "²", with: "^2")
    value = value.replacingOccurrences(of: "³", with: "^3")
    value = value.replacingOccurrences(of: "≤", with: "\\le")
    value = value.replacingOccurrences(of: "≥", with: "\\ge")
    value = value.replacingOccurrences(of: "≠", with: "\\ne")
    value = value.replacingOccurrences(of: "±", with: "\\pm")
    value = value.replacingOccurrences(of: "∞", with: "\\infty")
    value = value.replacingOccurrences(of: "ℝ", with: "\\mathbb{R}")
    value = value.replacingOccurrences(of: "ℤ", with: "\\mathbb{Z}")
    value = value.replacingOccurrences(of: "ℚ", with: "\\mathbb{Q}")
    value = value.replacingOccurrences(of: "ℕ", with: "\\mathbb{N}")
    value = value.replacingOccurrences(of: "⇔", with: "\\Leftrightarrow")
    value = value.replacingOccurrences(of: "⇒", with: "\\Rightarrow")
    value = value.replacingOccurrences(of: "→", with: "\\to")
    value = value.replacingOccurrences(of: "∈", with: "\\in")
    value = value.replacingOccurrences(of: "∉", with: "\\notin")
    value = value.replacingOccurrences(of: "∫", with: "\\int")

    value = value.replacingOccurrences(of: #"\bpi\b"#, with: "\\pi", options: .regularExpression)
    value = value.replacingOccurrences(of: #"(?<!\\)\bint(?=_|\^|\s|$)"#, with: "\\int", options: .regularExpression)
    value = value.replacingOccurrences(of: #"(?<!\\)\bleft\s*([\[\(\{])"#, with: "\\left$1", options: .regularExpression)
    value = value.replacingOccurrences(of: #"(?<!\\)\bright\s*([\]\)\}])"#, with: "\\right$1", options: .regularExpression)
    value = value.replacingOccurrences(of: #"√\s*([A-Za-z0-9\(\)\+\-]+)"#, with: "\\sqrt{$1}", options: .regularExpression)
    value = replacingLessonLatexFractions(in: value)
    value = value.replacingOccurrences(of: #"\\int_([^\s\^=]+)\^([^\s=]+)"#, with: "\\int_{$1}^{$2}", options: .regularExpression)
    value = value.replacingOccurrences(of: #"\[([^\[\]]+)\]_([^\s\^=]+)\^([^\s=]+)"#, with: "\\left[$1\\right]_{$2}^{$3}", options: .regularExpression)
    value = value.replacingOccurrences(of: #"(?<!\\)\b([A-Za-z])\s*\^\s*\(([^()]+)\)"#, with: "$1^{$2}", options: .regularExpression)
    value = value.replacingOccurrences(of: #"(?<!\\)\b([A-Za-z])\s*\^\s*([0-9A-Za-z\+\-]+)\b"#, with: "$1^{$2}", options: .regularExpression)
    value = value.replacingOccurrences(of: #"(?<!\\)\b(e)\^([A-Za-z0-9\(\)\+\-]+)"#, with: "$1^{$2}", options: .regularExpression)
    value = value.replacingOccurrences(of: #"\\pi(?=[A-Za-z0-9])"#, with: "\\pi ", options: .regularExpression)
    value = value.replacingOccurrences(of: #"\\sin(?=[A-Za-z0-9])"#, with: "\\sin ", options: .regularExpression)
    value = value.replacingOccurrences(of: #"\\cos(?=[A-Za-z0-9])"#, with: "\\cos ", options: .regularExpression)
    value = value.replacingOccurrences(of: #"\\tan(?=[A-Za-z0-9])"#, with: "\\tan ", options: .regularExpression)
    value = value.replacingOccurrences(of: #"\\ln(?=[A-Za-z0-9])"#, with: "\\ln ", options: .regularExpression)
    value = value.replacingOccurrences(of: #"\\log(?=[A-Za-z0-9])"#, with: "\\log ", options: .regularExpression)
    value = value.replacingOccurrences(of: #"(\\[A-Za-z]+)(?=\\[A-Za-z])"#, with: "$1 ", options: .regularExpression)
    value = value.replacingOccurrences(of: #"\s{2,}"#, with: " ", options: .regularExpression)
    value = value.trimmingCharacters(in: .whitespacesAndNewlines)

    if !value.contains("\\displaystyle") {
        value = "\\displaystyle \\large " + value
    }

    return value
}

private func replacingLessonLatexFractions(in text: String) -> String {
    guard let regex = try? NSRegularExpression(
        pattern: #"(?<!\\)(\[[^\]]+\]_[A-Za-z0-9{}]+|\([^()]+\)|[A-Za-z0-9]+(?:\^\{[^}]+\}|\^[A-Za-z0-9+\-]+)?)\s*/\s*(\([^()]+\)|\{[^{}]+\}|[A-Za-z0-9]+(?:\^\{[^}]+\}|\^[A-Za-z0-9+\-]+)?)"#
    ) else {
        return text
    }

    var value = text
    let fullRange = NSRange(value.startIndex..<value.endIndex, in: value)
    let matches = regex.matches(in: value, range: fullRange).reversed()

    for match in matches {
        guard match.numberOfRanges >= 3,
              let matchRange = Range(match.range(at: 0), in: value),
              let numeratorRange = Range(match.range(at: 1), in: value),
              let denominatorRange = Range(match.range(at: 2), in: value) else {
            continue
        }

        let numerator = String(value[numeratorRange]).trimmingCharacters(in: .whitespacesAndNewlines)
        let denominator = String(value[denominatorRange]).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !numerator.isEmpty, !denominator.isEmpty else {
            continue
        }

        value.replaceSubrange(matchRange, with: #"\frac{\#(numerator)}{\#(denominator)}"#)
    }

    return value
}

private func lessonMathHTML(latex: String, displayMode: Bool) -> String {
    let escaped = escapeLessonHTML(latex)
    let math = displayMode ? "\\[\(escaped)\\]" : "\\(\(escaped)\\)"
    let horizontalOverflow = displayMode ? "auto" : "visible"
    let whiteSpace = "normal"
    let displayContainer = "block"
    let containerWidth = "100%"

    return """
    <html>
    <head>
      <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
      <script>
        window.MathJax = {
          tex: { inlineMath: [['\\\\(', '\\\\)']], displayMath: [['\\\\[', '\\\\]']] },
          svg: { fontCache: 'none', linebreaks: { automatic: true, width: 'container' } }
        };
      </script>
      <script src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-svg.js"></script>
      <style>
        html, body {
          margin: 0;
          padding: 0;
          width: 100%;
          height: 100%;
          background: transparent;
          overflow: visible;
        }
        body {
          text-align: center;
          display: flex;
          align-items: center;
          justify-content: center;
        }
        .math-wrap {
          display: block;
          width: 100%;
          text-align: center;
          padding: 6px 0;
          font-size: \(displayMode ? "1.26rem" : "1.02rem");
          line-height: 1.35;
          overflow-x: \(horizontalOverflow);
          overflow-y: hidden;
          box-sizing: border-box;
          white-space: \(whiteSpace);
        }
        mjx-container {
          margin: 0 !important;
          overflow: visible !important;
        }
        mjx-container[display="true"] {
          display: \(displayContainer) !important;
          width: \(containerWidth) !important;
          min-width: \(containerWidth) !important;
          text-align: center !important;
        }
        svg {
          max-width: none !important;
          height: auto !important;
          overflow: visible !important;
        }
      </style>
    </head>
    <body>
      <div class="math-wrap">\(math)</div>
    </body>
    </html>
    """
}

private func escapeLessonHTML(_ string: String) -> String {
    string
        .replacingOccurrences(of: "&", with: "&amp;")
        .replacingOccurrences(of: "<", with: "&lt;")
        .replacingOccurrences(of: ">", with: "&gt;")
        .replacingOccurrences(of: "\"", with: "&quot;")
        .replacingOccurrences(of: "'", with: "&#39;")
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
    if s.contains("√") || s.contains("∫") || s.contains(#"\int"#) || s.contains(#"\frac"#) || s.contains(#"\left"#) || s.contains(#"\right"#) || s.contains("Δ") { return true }
    if s.contains("^") { return true }

    let lower = s.lowercased()
    if lower.contains("lim") || lower.contains("int_") || lower.contains("int ") || lower.contains("frac") || lower.contains("left") || lower.contains("right") { return true }
    if lower.contains("sin") || lower.contains("cos") || lower.contains("tan") { return true }
    if lower.contains("ln") || lower.contains("log") || lower.contains("e^") { return true }

    return false
}

private func isBulletLikeLine(_ line: String) -> Bool {
    let s = line.trimmingCharacters(in: .whitespaces)
    return s.hasPrefix("•")
        || s.hasPrefix("- ")
        || s.hasPrefix("* ")
        || s.range(of: #"^\(?\d+\)"#, options: .regularExpression) != nil
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
    @State private var imageData: Data?
    @State private var loadFailed = false

    private var candidateImageURLs: [URL] {
        let encodedName = imageName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? imageName
        let primaryBase = APIConfig.serverBaseURLString
        let primaryPath = primaryBase.hasSuffix("/") ? primaryBase + "lesson-images/" + encodedName : primaryBase + "/lesson-images/" + encodedName
        let fallbackPath = "https://raw.githubusercontent.com/cldnpl/Kram/main/mathquest/backend/static/imagesLessons/\(encodedName)"
        return [primaryPath, fallbackPath].compactMap(URL.init(string:))
    }

    private var isSVG: Bool {
        imageName.lowercased().hasSuffix(".svg")
    }

    private var usesWebView: Bool {
        let lower = imageName.lowercased()
        return lower.hasSuffix(".svg") || lower.hasSuffix(".gif") || lower.hasSuffix(".webp") || lower.hasSuffix(".avif")
    }

    private var mimeType: String {
        switch imageName.lowercased() {
        case let name where name.hasSuffix(".svg"):
            return "image/svg+xml"
        case let name where name.hasSuffix(".gif"):
            return "image/gif"
        case let name where name.hasSuffix(".webp"):
            return "image/webp"
        case let name where name.hasSuffix(".avif"):
            return "image/avif"
        case let name where name.hasSuffix(".jpg"), let name where name.hasSuffix(".jpeg"):
            return "image/jpeg"
        default:
            return "image/png"
        }
    }

    private var bundledImageData: Data? {
        if let url = Bundle.main.url(forResource: imageName, withExtension: nil, subdirectory: "LessonImages") {
            return try? Data(contentsOf: url)
        }
        return nil
    }

    var body: some View {
        Group {
            if isSVG {
                if loadFailed {
                    mediaFailureView
                } else if let data = imageData {
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
            } else if usesWebView, let data = imageData {
                BinaryImageWebView(data: data, mimeType: mimeType)
                    .frame(minHeight: 120, maxHeight: 280)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.separator).opacity(0.5), lineWidth: 1)
                    )
            } else if loadFailed {
                mediaFailureView
            } else if let data = imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.separator).opacity(0.5), lineWidth: 1)
                    )
            } else if let data = imageData {
                BinaryImageWebView(data: data, mimeType: mimeType)
                    .frame(minHeight: 120, maxHeight: 280)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.separator).opacity(0.5), lineWidth: 1)
                    )
            } else {
                mediaLoadingView
            }
        }
        .task(id: imageName) {
            imageData = nil
            loadFailed = false
            if let localData = bundledImageData, !localData.isEmpty {
                imageData = localData
                return
            }
            for url in candidateImageURLs {
                do {
                    let (data, resp) = try await URLSession.shared.data(from: url)
                    if (resp as? HTTPURLResponse)?.statusCode == 200, !data.isEmpty {
                        imageData = data
                        loadFailed = false
                        return
                    }
                } catch {
                    continue
                }
            }
            loadFailed = true
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

private struct BinaryImageWebView: UIViewRepresentable {
    let data: Data
    let mimeType: String

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.dataDetectorTypes = []
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.load(data, mimeType: mimeType, characterEncodingName: "UTF-8", baseURL: URL(string: "about:blank")!)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.load(data, mimeType: mimeType, characterEncodingName: "UTF-8", baseURL: URL(string: "about:blank")!)
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

private struct LessonPracticeQuestion: Identifiable {
    let id: String
    let question: String
    let options: [String]
    let correctAnswer: String
}

private struct LessonPracticeContentView: View {
    let text: String
    let textStyle: Font
    let textSize: Int
    let textWeight: Font.Weight
    let textColor: Color
    let centered: Bool

    var body: some View {
        if practiceContentNeedsMathRendering(text) {
            LessonMixedMathView(
                html: lessonMixedMathHTML(
                    content: text,
                    centered: centered,
                    fontSize: textSize,
                    fontWeight: mixedMathFontWeight(for: textWeight)
                )
            )
            .frame(
                minHeight: practiceContentMinimumHeight(for: text),
                maxHeight: practiceContentMaximumHeight(for: text)
            )
        } else {
            Text(prettifyLessonTextContent(text))
                .font(textStyle.weight(textWeight))
                .foregroundStyle(textColor)
                .multilineTextAlignment(centered ? .center : .leading)
                .frame(maxWidth: .infinity, alignment: centered ? .center : .leading)
        }
    }
}

private struct LessonPracticeView: View {
    let lesson: LessonItem
    let questions: [LessonPracticeQuestion]
    let completeLessonAction: () async throws -> Int

    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex = 0
    @State private var selectedAnswer: String?
    @State private var answerIsCorrect: Bool?
    @State private var isCompleting = false
    @State private var alertMessage = ""
    @State private var showAlert = false
    @State private var completionCoins = 0
    @State private var showCompletionPopup = false

    init(lesson: LessonItem, exercises: [LessonDetailExercise], completeLessonAction: @escaping () async throws -> Int) {
        self.lesson = lesson
        self.questions = buildPracticeQuestions(from: exercises)
        self.completeLessonAction = completeLessonAction
    }

    var body: some View {
        ZStack {
            Group {
                if questions.isEmpty {
                    VStack(spacing: 12) {
                        Text(L10n.contentNotAvailable)
                            .font(.headline)
                        Text(L10n.serverRetryMessage)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    let question = questions[currentIndex]

                    VStack(spacing: 20) {
                        ProgressView(value: Double(currentIndex + (answerIsCorrect == true ? 1 : 0)), total: Double(questions.count))
                            .tint(lessonAccentColor)

                        Text(L10n.practiceQuestion(currentIndex + 1, questions.count))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(lessonAccentColor)

                        Text(L10n.practicePickAnswer)
                            .font(.headline)
                            .multilineTextAlignment(.center)

                        LessonPracticeContentView(
                            text: question.question,
                            textStyle: .title3,
                            textSize: 18,
                            textWeight: .semibold,
                            textColor: .primary,
                            centered: true
                        )

                        VStack(spacing: 12) {
                            ForEach(question.options, id: \.self) { option in
                                Button {
                                    handleSelection(option, for: question)
                                } label: {
                                    HStack(spacing: 12) {
                                        LessonPracticeContentView(
                                            text: option,
                                            textStyle: .body,
                                            textSize: 16,
                                            textWeight: .medium,
                                            textColor: optionForeground(option, correctAnswer: question.correctAnswer),
                                            centered: false
                                        )
                                        Spacer()
                                        if selectedAnswer == option {
                                            Image(systemName: answerIsCorrect == true ? "checkmark.circle.fill" : "xmark.circle.fill")
                                                .foregroundStyle(answerIsCorrect == true ? .green : .red)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 18)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(optionBackground(option, correctAnswer: question.correctAnswer))
                                    .clipShape(RoundedRectangle(cornerRadius: 18))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18)
                                            .stroke(optionBorder(option, correctAnswer: question.correctAnswer), lineWidth: 2)
                                    )
                                }
                                .buttonStyle(.plain)
                                .disabled(isCompleting || answerIsCorrect == true)
                            }
                        }

                        if let answerIsCorrect {
                            Text(answerIsCorrect ? L10n.practiceCorrect : L10n.tryAgain)
                                .font(.headline)
                                .foregroundStyle(answerIsCorrect ? .green : .red)
                        }

                        Spacer(minLength: 0)

                        if answerIsCorrect == true {
                            Button {
                                Task {
                                    await advanceOrComplete()
                                }
                            } label: {
                                HStack {
                                    if isCompleting {
                                        ProgressView()
                                            .progressViewStyle(.circular)
                                    }
                                    Text(currentIndex == questions.count - 1 ? L10n.practiceFinish : L10n.next)
                                        .font(.headline)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(isCompleting)
                        }
                    }
                    .padding()
                }
            }

            if showCompletionPopup {
                Color.black.opacity(0.16)
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    Image(systemName: "star.circle")
                        .font(.system(size: 56, weight: .regular))
                        .foregroundStyle(lessonAccentColor)

                    Text(L10n.practiceCompletedTitle)
                        .font(.title3.weight(.bold))
                        .multilineTextAlignment(.center)

                    if completionCoins > 0 {
                        HStack(spacing: 10) {
                            Text(L10n.practiceYouEarned)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Image("coin", bundle: .main)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 42, height: 42)
                            Text("\(completionCoins)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                    }

                    Button {
                        showCompletionPopup = false
                        dismiss()
                    } label: {
                        Text(L10n.back)
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 28)
                .frame(maxWidth: 300)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .shadow(color: .black.opacity(0.08), radius: 24, y: 10)
            }
        }
        .navigationTitle(L10n.practice)
        .navigationBarTitleDisplayMode(.inline)
        .alert(L10n.practice, isPresented: $showAlert) {
            Button(L10n.ok) {
                dismiss()
            }
        } message: {
            Text(alertMessage)
        }
    }

    private func handleSelection(_ option: String, for question: LessonPracticeQuestion) {
        selectedAnswer = option
        answerIsCorrect = (option == question.correctAnswer)
    }

    private func advanceOrComplete() async {
        if currentIndex < questions.count - 1 {
            currentIndex += 1
            selectedAnswer = nil
            answerIsCorrect = nil
            return
        }

        isCompleting = true
        defer { isCompleting = false }

        do {
            let coins = try await completeLessonAction()
            completionCoins = coins
            showCompletionPopup = true
        } catch {
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }

    private func optionBackground(_ option: String, correctAnswer: String) -> Color {
        guard let selectedAnswer else { return Color.black.opacity(0.035) }
        if selectedAnswer != option { return Color.black.opacity(0.035) }
        return selectedAnswer == correctAnswer ? Color.green.opacity(0.16) : Color.red.opacity(0.12)
    }

    private func optionBorder(_ option: String, correctAnswer: String) -> Color {
        guard let selectedAnswer else { return Color.black.opacity(0.06) }
        if selectedAnswer != option { return Color.black.opacity(0.06) }
        return selectedAnswer == correctAnswer ? .green : .red
    }

    private func optionForeground(_ option: String, correctAnswer: String) -> Color {
        guard let selectedAnswer, selectedAnswer == option else { return .primary }
        return selectedAnswer == correctAnswer ? .green : .red
    }
}

private func buildPracticeQuestions(from exercises: [LessonDetailExercise]) -> [LessonPracticeQuestion] {
    let cleaned = exercises.compactMap { exercise -> LessonPracticeQuestion? in
        let question = exercise.question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty else { return nil }

        var options = exercise.options
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let correctAnswer = exercise.correctAnswer.trimmingCharacters(in: .whitespacesAndNewlines)
        if !correctAnswer.isEmpty && !options.contains(correctAnswer) {
            options.insert(correctAnswer, at: 0)
        }
        guard !options.isEmpty else { return nil }

        return LessonPracticeQuestion(
            id: exercise.id,
            question: question,
            options: options,
            correctAnswer: correctAnswer.isEmpty ? options[0] : correctAnswer
        )
    }

    guard !cleaned.isEmpty else { return [] }
    let randomized = cleaned.shuffled()

    let targetCount: Int
    switch randomized.count {
    case ..<15:
        targetCount = 15
    case 15...20:
        targetCount = randomized.count
    default:
        targetCount = 20
    }
    var result: [LessonPracticeQuestion] = []
    result.reserveCapacity(targetCount)

    for index in 0..<targetCount {
        let base = randomized[index % randomized.count]
        let rotation = base.options.isEmpty ? 0 : index % base.options.count
        result.append(
            LessonPracticeQuestion(
                id: "\(base.id)-q\(index)",
                question: base.question,
                options: rotatePracticeOptions(base.options, by: rotation),
                correctAnswer: base.correctAnswer
            )
        )
    }

    return result
}

private func rotatePracticeOptions(_ options: [String], by offset: Int) -> [String] {
    guard !options.isEmpty else { return [] }
    let normalized = offset % options.count
    guard normalized != 0 else { return options }
    return Array(options[normalized...]) + Array(options[..<normalized])
}

private struct LessonMixedMathView: UIViewRepresentable {
    let html: String

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = true
        webView.scrollView.bounces = false
        webView.scrollView.alwaysBounceHorizontal = false
        webView.scrollView.alwaysBounceVertical = false
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.scrollView.showsHorizontalScrollIndicator = false
        webView.isUserInteractionEnabled = false
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        if context.coordinator.lastHTML != html {
            uiView.loadHTMLString(html, baseURL: nil)
            context.coordinator.lastHTML = html
        }
    }

    final class Coordinator {
        var lastHTML: String?
    }
}

private enum PracticeRichSegment {
    case text(String)
    case math(String, display: Bool)
}

private func practiceContentNeedsMathRendering(_ text: String) -> Bool {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.isEmpty {
        return false
    }
    if looksLikeInlineMath(trimmed) && !containsProseWords(trimmed) {
        return true
    }
    return practiceLineContainsRenderableMath(trimmed)
}

private func lessonMixedMathHTML(content: String, centered: Bool, fontSize: Int, fontWeight: Int) -> String {
    let body = practiceRichSegments(from: content).map { segment -> String in
        switch segment {
        case .text(let text):
            return "<span class=\"text\">\(escapeLessonHTML(prettifyLessonTextContent(text)))</span>"
        case .math(let latex, let display):
            let escaped = escapeLessonHTML(normalizeLessonLatex(latex))
            if display {
                return "<div class=\"display\">\\[\(escaped)\\]</div>"
            }
            return "<span class=\"inline\">\\(\(escaped)\\)</span>"
        }
    }.joined(separator: "")

    let alignment = centered ? "center" : "left"

    return """
    <html>
    <head>
      <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
      <script>
        window.MathJax = {
          tex: { inlineMath: [['\\\\(', '\\\\)']], displayMath: [['\\\\[', '\\\\]']] },
          svg: { fontCache: 'none', linebreaks: { automatic: true, width: 'container' } }
        };
      </script>
      <script src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-svg.js"></script>
      <style>
        html, body {
          margin: 0;
          padding: 0;
          width: 100%;
          height: 100%;
          background: transparent;
          overflow: hidden;
        }
        body {
          font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Text', sans-serif;
          font-size: \(fontSize)px;
          font-weight: \(fontWeight);
          line-height: 1.35;
          color: #111111;
          text-align: \(alignment);
          display: block;
        }
        .wrap {
          width: 100%;
          box-sizing: border-box;
          text-align: \(alignment);
          word-break: break-word;
        }
        .display {
          width: 100%;
          margin: 6px 0;
          overflow-x: auto;
          overflow-y: hidden;
        }
        .inline {
          display: inline;
        }
        mjx-container {
          max-width: 100% !important;
        }
      </style>
    </head>
    <body>
      <div class="wrap">\(body)</div>
    </body>
    </html>
    """
}

private func practiceRichSegments(from text: String) -> [PracticeRichSegment] {
    let normalized = text
        .replacingOccurrences(of: "\r\n", with: "\n")
        .trimmingCharacters(in: .whitespacesAndNewlines)

    guard !normalized.isEmpty else { return [] }

    let lines = normalized
        .components(separatedBy: "\n")
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }

    if lines.isEmpty {
        return [.text(normalized)]
    }

    var segments: [PracticeRichSegment] = []
    for (index, line) in lines.enumerated() {
        if index > 0 {
            segments.append(.text(" "))
        }
        segments.append(contentsOf: practiceSegmentsForLine(line))
    }
    return segments
}

private func practiceSegmentsForLine(_ line: String) -> [PracticeRichSegment] {
    if let split = practiceSplitTextConnector(line) {
        var segments = practiceSegmentsForLine(split.before)
        segments.append(.text(split.connector))
        segments.append(contentsOf: practiceSegmentsForLine(split.after))
        return segments
    }

    if looksLikeInlineMath(line) && !containsProseWords(line) {
        return [.math(line, display: true)]
    }

    let pattern = #"((?:∫|\\int|int(?=[_\^\s]|$))[^,;\n]+?(?=(?:\s+(?:where|equals|is|are|so|since|then)\b|$))|[A-Za-z]'\([^)]+\)|[A-Za-z]\([^)]+\)|[A-Za-z0-9\\\]\)]+\s*[=≠≤≥]\s*[^,;\n]+?(?=(?:\s+(?:where|equals|is|are|so|since|then)\b|$))|d[A-Za-z]\/d[A-Za-z]|[A-Za-z0-9]+\^\(?[A-Za-z0-9+\-]+\)?)"#
    guard let regex = try? NSRegularExpression(pattern: pattern) else {
        return [.text(line)]
    }

    let range = NSRange(line.startIndex..<line.endIndex, in: line)
    let matches = regex.matches(in: line, range: range)
    if matches.isEmpty {
        return [.text(line)]
    }

    var result: [PracticeRichSegment] = []
    var currentLocation = line.startIndex
    for match in matches {
        guard let matchRange = Range(match.range, in: line) else { continue }
        if currentLocation < matchRange.lowerBound {
            result.append(.text(String(line[currentLocation..<matchRange.lowerBound])))
        }
        let candidate = String(line[matchRange])
        if looksLikeInlineMath(candidate) && !containsProseWords(candidate) {
            result.append(.math(candidate, display: false))
        } else {
            result.append(.text(candidate))
        }
        currentLocation = matchRange.upperBound
    }
    if currentLocation < line.endIndex {
        result.append(.text(String(line[currentLocation..<line.endIndex])))
    }
    return result
}

private func practiceLineContainsRenderableMath(_ line: String) -> Bool {
    if let split = practiceSplitTextConnector(line) {
        return practiceLineContainsRenderableMath(split.before) || practiceLineContainsRenderableMath(split.after)
    }
    guard let regex = try? NSRegularExpression(pattern: #"((?:∫|\\int|int(?=[_\^\s]|$))[^,;\n]+?(?=(?:\s+(?:where|equals|is|are|so|since|then)\b|$))|[A-Za-z]'\([^)]+\)|[A-Za-z]\([^)]+\)|[A-Za-z0-9\\\]\)]+\s*[=≠≤≥]\s*[^,;\n]+?(?=(?:\s+(?:where|equals|is|are|so|since|then)\b|$))|d[A-Za-z]\/d[A-Za-z]|[A-Za-z0-9]+\^\(?[A-Za-z0-9+\-]+\)?)"#) else {
        return false
    }
    let range = NSRange(line.startIndex..<line.endIndex, in: line)
    for match in regex.matches(in: line, range: range) {
        guard let matchRange = Range(match.range, in: line) else { continue }
        let candidate = String(line[matchRange])
        if looksLikeInlineMath(candidate) && !containsProseWords(candidate) {
            return true
        }
    }
    return false
}

private func practiceSplitTextConnector(_ line: String) -> (before: String, connector: String, after: String)? {
    let connectors = [" where ", " equals ", " is ", " are ", " so ", " since ", " then "]
    for connector in connectors {
        guard let range = line.range(of: connector, options: .caseInsensitive) else { continue }
        let before = String(line[..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        let after = String(line[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !before.isEmpty, !after.isEmpty else { continue }
        if practiceLineContainsRenderableMath(before) || (looksLikeInlineMath(before) && !containsProseWords(before)) {
            return (before, connector, after)
        }
    }
    return nil
}

private func practiceContentMinimumHeight(for text: String) -> CGFloat {
    let length = text.count
    if length > 180 { return 120 }
    if length > 90 { return 88 }
    return 56
}

private func practiceContentMaximumHeight(for text: String) -> CGFloat {
    let length = text.count
    if length > 220 { return 220 }
    if length > 140 { return 180 }
    return 120
}

private func mixedMathFontWeight(for weight: Font.Weight) -> Int {
    switch weight {
    case .semibold:
        return 600
    case .medium:
        return 500
    case .bold:
        return 700
    default:
        return 400
    }
}

#Preview {
    NavigationStack {
        LessonDetailView(lesson: LessonItem(id: "1", title: "Addition", description: "PEMDAS, Long Division", difficulty: 1, coinCost: 10))
    }
}
