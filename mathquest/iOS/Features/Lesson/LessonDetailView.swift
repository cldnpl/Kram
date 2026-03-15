import SwiftUI
import WebKit

// Dark purple (same as app gradient) for formula boxes (1st, 3rd, …)
private let formulaBoxColor = Color(red: 102/255, green: 80/255, blue: 164/255)  // #6650A4
// Light purple for example boxes (2nd, 4th, …)
private let exampleBoxColor = Color(red: 153/255, green: 128/255, blue: 240/255) // #9980F0
private let lessonAccentColor = Color(red: 102/255, green: 80/255, blue: 164/255)

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
                                            LessonParagraphView(text: line)
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
        splitLessonFormulaLine(text)
    }

    var body: some View {
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
                    .frame(minHeight: 64, maxHeight: 132)
            }

            if let note = split.note, let attributed = attributedLessonText(from: note) {
                Text(attributed)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
        }
        .foregroundStyle(accentColor)
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
    return normalized.replacingOccurrences(of: "\n{3,}", with: "\n\n", options: .regularExpression)
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
        .replacingOccurrences(of: "pi", with: "π")
        .replacingOccurrences(of: "\\pi", with: "π")
        .replacingOccurrences(of: "∫_", with: "∫")

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
    if candidate.range(of: #"[=+\-*/^(){}\[\]≤≥≠±√∫π∞]"#, options: .regularExpression) != nil {
        return true
    }
    let lower = candidate.lowercased()
    return lower.contains("lim") || lower.contains("sin") || lower.contains("cos")
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
        "sin", "cos", "tan", "log", "lim", "mod", "gcd", "lcm"
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

    value = value.replacingOccurrences(of: #"\bpi\b"#, with: "\\pi", options: .regularExpression)
    value = value.replacingOccurrences(of: #"√\s*([A-Za-z0-9\(\)\+\-]+)"#, with: "\\sqrt{$1}", options: .regularExpression)
    value = value.replacingOccurrences(of: #"(?<!\\)\b([A-Za-z0-9]+)\s*/\s*([A-Za-z0-9]+)\b"#, with: "\\frac{$1}{$2}", options: .regularExpression)
    value = value.replacingOccurrences(of: #"(?<!\\)\b([A-Za-z])\s*\^\s*([0-9A-Za-z\+\-]+)\b"#, with: "$1^{$2}", options: .regularExpression)
    value = value.replacingOccurrences(of: #"\s{2,}"#, with: " ", options: .regularExpression)
    value = value.trimmingCharacters(in: .whitespacesAndNewlines)

    if !value.contains("\\displaystyle") {
        value = "\\displaystyle \\large " + value
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
