import Foundation
import SwiftUI
import WebKit

struct StepCardView: View {
    let stepNumber: Int
    let content: String
    let isVisible: Bool
    private let appPurple = Color(red: 0.4, green: 0.3, blue: 0.9)
    @State private var isExpanded = false

    private var parsed: ParsedMathStep {
        ParsedMathStep.parse(from: content)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(appPurple.opacity(0.2))
                    .frame(width: 32, height: 32)

                Text("\(stepNumber)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(appPurple)
            }

            VStack(alignment: .leading, spacing: 10) {
                if parsed.hasExplanation {
                    HStack(spacing: 6) {
                        Spacer()

                        Image(systemName: "chevron.down")
                            .font(.caption2.weight(.semibold))
                        Text(L10n.expand)
                            .font(.caption2.weight(.semibold))
                    }
                    .foregroundStyle(appPurple)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(appPurple.opacity(0.18))
                    .clipShape(Capsule())
                    .contentShape(Capsule())
                    .onTapGesture {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                            isExpanded.toggle()
                        }
                    }
                }

                MathEquationBlock(
                    latex: parsed.latex,
                    fallbackText: parsed.formulaText,
                    isPrimary: false
                )

                if parsed.hasExplanation, isExpanded {
                    StepExplanationView(explanation: parsed.explanation)
                        .transition(.asymmetric(insertion: .opacity.combined(with: .move(edge: .top)), removal: .opacity))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                guard parsed.hasExplanation else { return }
                withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                    isExpanded.toggle()
                }
            }
        }
        .padding()
        .background(appPurple.opacity(0.10))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(appPurple.opacity(0.22), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 20)
    }
}

private struct StepExplanationView: View {
    let explanation: String

    private var paragraphs: [String] {
        ExplanationFormatter.paragraphs(from: explanation)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(Array(paragraphs.enumerated()), id: \.offset) { _, paragraph in
                ExplanationParagraphView(paragraph: paragraph)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ExplanationParagraphView: View {
    let paragraph: String

    private var segments: [ExplanationFormatter.Segment] {
        ExplanationFormatter.segments(from: paragraph)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(segments.enumerated()), id: \.offset) { _, segment in
                switch segment {
                case .text(let text):
                    if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(ExplanationFormatter.attributed(from: text))
                            .font(.body)
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                case .inlineMath(let latex):
                    MathLatexView(latex: MathTextFormatter.displayReadyLatex(latex), displayMode: false)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(minHeight: 34)
                case .displayMath(let latex):
                    MathLatexView(latex: MathTextFormatter.displayReadyLatex(latex), displayMode: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(minHeight: 110)
                }
            }
        }
    }
}

struct PrimaryEquationCardView: View {
    let title: String
    let latex: String
    let fallbackText: String
    private let appPurple = Color(red: 0.4, green: 0.3, blue: 0.9)

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            MathEquationBlock(
                latex: latex,
                fallbackText: fallbackText,
                isPrimary: true
            )
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(appPurple.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(appPurple.opacity(0.24), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct AnswerCardView: View {
    let answer: String
    let isVisible: Bool
    @State private var scale: CGFloat = 0.8

    var body: some View {
        VStack(spacing: 8) {
            Text(L10n.answer)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text(answer)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.green)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.green.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .scaleEffect(isVisible ? 1.0 : 0.8)
        .opacity(isVisible ? 1 : 0)
        .onChange(of: isVisible) { _, visible in
            if visible {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    scale = 1.0
                }
            }
        }
    }
}

struct DifficultyBadge: View {
    let level: String

    private var color: Color {
        switch level.lowercased() {
        case "elementary":
            return .green
        case "middle_school":
            return .blue
        case "high_school":
            return .orange
        case "college":
            return .red
        default:
            return .gray
        }
    }

    private var displayText: String {
        switch level.lowercased() {
        case "elementary":
            return L10n.difficultyElementary
        case "middle_school":
            return L10n.difficultyMiddleSchool
        case "high_school":
            return L10n.difficultyHighSchool
        case "college":
            return L10n.difficultyCollege
        default:
            return level.capitalized
        }
    }

    var body: some View {
        Text(displayText)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .clipShape(Capsule())
    }
}

private struct MathEquationBlock: View {
    let latex: String
    let fallbackText: String
    let isPrimary: Bool

    private var renderedLatex: String {
        let explicit = latex.trimmingCharacters(in: .whitespacesAndNewlines)
        if !explicit.isEmpty {
            return MathTextFormatter.displayReadyLatex(explicit)
        }
        return MathTextFormatter.displayReadyLatex(MathTextFormatter.normalizeToLatex(fallbackText))
    }

    var body: some View {
        Group {
            if renderedLatex.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                if isPrimary {
                    Text(MathTextFormatter.prettifyInlineMath(in: fallbackText))
                        .font(.title3.weight(.semibold))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                } else {
                    MathLatexView(
                        latex: MathTextFormatter.displayReadyLatex(
                            MathTextFormatter.normalizeToLatex(
                                MathTextFormatter.stripProseKeepingMath(fallbackText)
                            )
                        ),
                        displayMode: true
                    )
                    .padding(.horizontal, 4)
                    .padding(.vertical, 4)
                }
            } else {
                MathLatexView(latex: renderedLatex, displayMode: true)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: isPrimary ? 176 : 146)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(MathTextFormatter.prettifyInlineMath(in: fallbackText))
    }
}

private struct MathLatexView: UIViewRepresentable {
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
        let html = htmlTemplate(for: latex, displayMode: displayMode)
        if context.coordinator.lastHTML != html {
            uiView.loadHTMLString(html, baseURL: nil)
            context.coordinator.lastHTML = html
        }
    }

    private func htmlTemplate(for latex: String, displayMode: Bool) -> String {
        let escaped = MathTextFormatter.escapeHTML(latex)
        let math = displayMode ? "\\[\(escaped)\\]" : "\\(\(escaped)\\)"
        let horizontalOverflow = displayMode ? "auto" : "visible"
        let whiteSpace = displayMode ? "nowrap" : "normal"
        let displayContainer = displayMode ? "inline-block" : "inline"
        let containerWidth = displayMode ? "max-content" : "auto"
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
              padding: 8px 14px;
              font-size: \(displayMode ? "1.78rem" : "1.32rem");
              line-height: 1.4;
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

    final class Coordinator {
        var lastHTML: String?
    }
}

private struct ParsedMathStep {
    let latex: String
    let formulaText: String
    let explanation: String

    var hasExplanation: Bool {
        !explanation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    static func parse(from raw: String) -> ParsedMathStep {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty {
            return ParsedMathStep(latex: "", formulaText: "", explanation: "")
        }

        if let delimiter = text.range(of: "||") {
            let formulaPart = String(text[..<delimiter.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            let explanationPart = String(text[delimiter.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
            let formula = MathTextFormatter.stripProseKeepingMath(formulaPart)
            return ParsedMathStep(
                latex: MathTextFormatter.normalizeToLatex(formula),
                formulaText: MathTextFormatter.prettifyInlineMath(in: formula),
                explanation: explanationPart
            )
        }

        if let split = splitFormulaAndExplanation(text) {
            let formula = MathTextFormatter.stripProseKeepingMath(split.formula)
            return ParsedMathStep(
                latex: MathTextFormatter.normalizeToLatex(formula),
                formulaText: MathTextFormatter.prettifyInlineMath(in: formula),
                explanation: split.explanation
            )
        }

        let formulaOnly = MathTextFormatter.stripProseKeepingMath(text)
        return ParsedMathStep(
            latex: MathTextFormatter.normalizeToLatex(formulaOnly),
            formulaText: MathTextFormatter.prettifyInlineMath(in: formulaOnly),
            explanation: MathTextFormatter.defaultDetailedExplanation(for: formulaOnly)
        )
    }

    private static func splitFormulaAndExplanation(_ text: String) -> (formula: String, explanation: String)? {
        let separators = [":", " -> ", " => ", " — ", " – "]
        for separator in separators {
            guard let range = text.range(of: separator) else { continue }
            let left = String(text[..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            let right = String(text[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !left.isEmpty, !right.isEmpty else { continue }

            let leftMath = MathTextFormatter.looksLikeMath(left)
            let rightMath = MathTextFormatter.looksLikeMath(right)

            if rightMath && !leftMath {
                return (formula: right, explanation: left)
            }
            if leftMath && !rightMath {
                return (formula: left, explanation: right)
            }
        }
        return nil
    }
}

private enum MathTextFormatter {
    static func normalizeToLatex(_ raw: String) -> String {
        var value = stripDisplayDelimiters(from: raw)
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
        value = replacingRegex(#"\bpi\b"#, in: value, with: "\\\\pi")
        value = replacingRegex(#"√\s*([A-Za-z0-9]+)"#, in: value, with: "\\\\sqrt{$1}")

        // Force vertical fractions (no linear slash notation) where possible.
        value = replacingRegex(
            #"(?i)\\pi\s*/\s*([A-Za-z0-9]+)"#,
            in: value,
            with: "\\\\frac{\\\\pi}{$1}"
        )
        value = replacingRegex(
            #"(?i)([A-Za-z0-9]+)\s*/\s*\\pi"#,
            in: value,
            with: "\\\\frac{$1}{\\\\pi}"
        )
        value = replacingRegex(
            #"(\([^()]+\)|\{[^{}]+\}|[A-Za-z0-9]+)\s*/\s*(\([^()]+\)|\{[^{}]+\}|[A-Za-z0-9]+)"#,
            in: value,
            with: "\\\\frac{$1}{$2}"
        )
        for _ in 0..<2 {
            let updated = replacingRegex(
                #"(?<!\\)\b([A-Za-z0-9]+)\s*/\s*([A-Za-z0-9]+)\b"#,
                in: value,
                with: "\\\\frac{$1}{$2}"
            )
            if updated == value { break }
            value = updated
        }

        return value
    }

    static func prettifyInlineMath(in raw: String) -> String {
        var value = raw
        value = value.replacingOccurrences(of: "pi", with: "π")
        value = value.replacingOccurrences(of: "*", with: "×")
        value = value.replacingOccurrences(of: "-", with: "−")
        return value
    }

    static func looksLikeMath(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return false }
        let hasMathSymbol = trimmed.range(of: #"[=+\-*/^(){}\[\]≤≥≠±√π]"#, options: .regularExpression) != nil
        let hasDigits = trimmed.range(of: #"\d"#, options: .regularExpression) != nil
        return hasMathSymbol || hasDigits
    }

    static func stripProseKeepingMath(_ raw: String) -> String {
        let normalized = raw
            .replacingOccurrences(of: ":", with: " ")
            .replacingOccurrences(of: ";", with: " ")
            .replacingOccurrences(of: ",", with: " ")
        let tokens = normalized.split { $0.isWhitespace }
        var kept: [String] = []

        for tokenSub in tokens {
            let token = String(tokenSub).trimmingCharacters(in: CharacterSet(charactersIn: ".,;:"))
            guard !token.isEmpty else { continue }
            let lower = token.lowercased()

            // Suppress common OCR noise unless explicitly part of LaTeX command.
            if (token == "i" || token == "I"), !token.contains("\\") {
                continue
            }

            if lower == "or" || lower == "o" || lower == "and" || lower == "e" {
                kept.append(",")
                continue
            }
            if tokenLooksMath(token) {
                kept.append(token)
            }
        }

        let joined = kept.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        if !joined.isEmpty {
            return joined
        }
        return extractMathCharacters(from: raw)
    }

    static func tokenLooksMath(_ token: String) -> Bool {
        let lower = token.lowercased()
        if token.contains("\\") { return true }
        if token.range(of: #"\d"#, options: .regularExpression) != nil { return true }
        if token.range(of: #"[=+\-*/^(){}\[\]<>≤≥≠±√π]"#, options: .regularExpression) != nil { return true }
        if token.count == 1, token.range(of: #"[A-Za-z]"#, options: .regularExpression) != nil {
            return token != "i" && token != "I"
        }
        let mathWords: Set<String> = ["sin", "cos", "tan", "log", "ln", "pi", "theta", "alpha", "beta", "gamma", "sqrt"]
        return mathWords.contains(lower)
    }

    static func extractMathCharacters(from raw: String) -> String {
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789=+-*/^(){}[]\\.,_ ")
        let filteredScalars = raw.unicodeScalars.filter { allowed.contains($0) }
        return String(String.UnicodeScalarView(filteredScalars))
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func defaultDetailedExplanation(for formula: String) -> String {
        let trimmed = formula.trimmingCharacters(in: .whitespacesAndNewlines)
        return localizedFallbackExplanation(for: trimmed)
    }

    static func displayReadyLatex(_ raw: String) -> String {
        let value = stripDisplayDelimiters(from: raw)
        if value.isEmpty { return "" }
        var formatted = value

        formatted = replacingRegex(
            #"\\(?:tiny|scriptsize|footnotesize|small|normalsize|large|Large|LARGE|huge|Huge|textstyle|scriptstyle|scriptscriptstyle)\b"#,
            in: formatted,
            with: ""
        )
        formatted = replacingRegex(#"\\displaystyle\b"#, in: formatted, with: "")
        formatted = replacingRegex(#"\s{2,}"#, in: formatted, with: " ")
        formatted = formatted.trimmingCharacters(in: .whitespacesAndNewlines)

        if !(formatted.contains("\\begin{aligned}") || formatted.contains("\\\\")) {
            if formatted.count >= 70 {
                if formatted.contains("\\implies") {
                    let parts = formatted.components(separatedBy: "\\implies")
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                        .filter { !$0.isEmpty }
                    if parts.count > 1 {
                        var lines: [String] = [parts[0]]
                        for part in parts.dropFirst() {
                            lines.append("\\implies " + part)
                        }
                        formatted = "\\begin{aligned}" + lines.joined(separator: " \\\\ ") + "\\end{aligned}"
                    }
                }

                let eqParts = formatted.components(separatedBy: "=")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                if eqParts.count > 2 {
                    var lines: [String] = ["\(eqParts[0]) &= \(eqParts[1])"]
                    for part in eqParts.dropFirst(2) {
                        lines.append("&= \(part)")
                    }
                    formatted = "\\begin{aligned}" + lines.joined(separator: " \\\\ ") + "\\end{aligned}"
                } else if eqParts.count == 2 {
                    formatted = "\\begin{aligned}" + eqParts[0] + " &= " + eqParts[1] + "\\end{aligned}"
                }
            }
        }

        if !formatted.contains("\\displaystyle") {
            formatted = "\\displaystyle \\large " + formatted
        }

        return formatted
    }

    static func localizedFallbackExplanation(for formula: String) -> String {
        let hasFormula = !formula.isEmpty
        let inline = hasFormula ? "$\(formula)$" : ""
        if hasFormula {
            return "**Sostituzione.** In questo passaggio riscriviamo \(inline) con regole algebriche equivalenti.\n\n**Proprietà.** Le operazioni applicate mantengono invariata l'equazione.\n\n**Risultato parziale.** L'insieme delle soluzioni rimane lo stesso."
        }
        return "**Semplificazione.** In questo passaggio applichiamo una trasformazione algebrica valida.\n\n**Proprietà.** L'equazione resta equivalente.\n\n**Risultato parziale.** La procedura conserva lo stesso insieme di soluzioni."
    }

    static func stripDisplayDelimiters(from raw: String) -> String {
        var value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return "" }

        if value.hasPrefix("$$"), value.hasSuffix("$$"), value.count >= 4 {
            value = String(value.dropFirst(2).dropLast(2)).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if value.hasPrefix("\\["), value.hasSuffix("\\]"), value.count >= 4 {
            value = String(value.dropFirst(2).dropLast(2)).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if value.hasPrefix("\\("), value.hasSuffix("\\)"), value.count >= 4 {
            value = String(value.dropFirst(2).dropLast(2)).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if value.hasPrefix("$"), value.hasSuffix("$"), value.count >= 2 {
            value = String(value.dropFirst().dropLast()).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return value
    }

    static func escapeHTML(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }

    static func replacingRegex(_ pattern: String, in string: String, with template: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return string
        }
        let range = NSRange(string.startIndex..<string.endIndex, in: string)
        return regex.stringByReplacingMatches(in: string, options: [], range: range, withTemplate: template)
    }
}

private enum ExplanationFormatter {
    enum Segment {
        case text(String)
        case inlineMath(String)
        case displayMath(String)
    }

    private static let emphasisKeywords: [String] = [
        "sostituzione", "sostituiamo", "identita", "identità", "proprieta", "proprietà",
        "regola", "teorema", "semplificazione", "semplifichiamo", "trasformazione", "passaggio",
        "risultato", "integrale", "frazione", "equazione", "denominatore", "numeratore",
        "substitution", "identity", "property", "rule", "theorem", "simplification",
        "transformation", "step", "result", "integral", "fraction", "equation",
        "substitution", "identite", "identité", "propriete", "propriété",
        "regle", "règle", "theoreme", "théorème", "resultat", "résultat",
        "sustitucion", "sustitución", "identidad", "propiedad", "regla", "teorema",
        "simplificacion", "simplificación", "transformacion", "transformación", "resultado"
    ]

    static func paragraphs(from raw: String) -> [String] {
        let normalized = raw
            .replacingOccurrences(of: "\r\n", with: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return [] }

        let explicitParagraphs = normalized
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let explicitBlocks = explicitParagraphs.isEmpty
            ? normalized
                .split(separator: "\n")
                .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            : explicitParagraphs

        var result: [String] = []
        for block in (explicitBlocks.isEmpty ? [normalized] : explicitBlocks) {
            let sentences = splitSentences(block)
            if sentences.count <= 2 {
                result.append(sentences.joined(separator: " "))
                continue
            }

            var index = 0
            while index < sentences.count {
                let end = min(index + 2, sentences.count)
                result.append(sentences[index..<end].joined(separator: " "))
                index = end
            }
        }
        return result
    }

    static func segments(from paragraph: String) -> [Segment] {
        let normalized = normalizeMathMentions(in: paragraph)
        guard let regex = try? NSRegularExpression(
            pattern: #"\\\((.+?)\\\)|\\\[(.+?)\\\]|\$\$(.+?)\$\$|\$(.+?)\$"#,
            options: [.dotMatchesLineSeparators]
        ) else {
            return [.text(normalized)]
        }

        let nsRange = NSRange(normalized.startIndex..<normalized.endIndex, in: normalized)
        let matches = regex.matches(in: normalized, options: [], range: nsRange)
        if matches.isEmpty {
            return [.text(normalized)]
        }

        var output: [Segment] = []
        var cursor = normalized.startIndex

        for match in matches {
            guard let fullRange = Range(match.range, in: normalized) else { continue }
            if cursor < fullRange.lowerBound {
                let text = String(normalized[cursor..<fullRange.lowerBound])
                if !text.isEmpty {
                    output.append(.text(text))
                }
            }

            let mathText: String
            let isDisplay: Bool
            if let latexRange = Range(match.range(at: 1), in: normalized), !latexRange.isEmpty {
                mathText = String(normalized[latexRange])
                isDisplay = false
            } else if let latexRange = Range(match.range(at: 2), in: normalized), !latexRange.isEmpty {
                mathText = String(normalized[latexRange])
                isDisplay = true
            } else if let latexRange = Range(match.range(at: 3), in: normalized), !latexRange.isEmpty {
                mathText = String(normalized[latexRange])
                isDisplay = true
            } else if let latexRange = Range(match.range(at: 4), in: normalized), !latexRange.isEmpty {
                mathText = String(normalized[latexRange])
                isDisplay = false
            } else {
                mathText = ""
                isDisplay = false
            }
            if !mathText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                output.append(isDisplay ? .displayMath(mathText) : .inlineMath(mathText))
            }
            cursor = fullRange.upperBound
        }

        if cursor < normalized.endIndex {
            let tail = String(normalized[cursor...])
            if !tail.isEmpty {
                output.append(.text(tail))
            }
        }

        return output
    }

    static func attributed(from text: String) -> AttributedString {
        let markdown = emphasizedMarkdown(in: text)
        if let attributed = try? AttributedString(
            markdown: markdown,
            options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        ) {
            return attributed
        }
        return AttributedString(text)
    }

    private static func splitSentences(_ text: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: #"(?<=[.!?])\s+"#, options: []) else {
            return [text]
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        var sentences: [String] = []
        var sentenceStart = text.startIndex

        regex.enumerateMatches(in: text, options: [], range: range) { match, _, _ in
            guard let match, let splitRange = Range(match.range, in: text) else { return }
            let sentence = String(text[sentenceStart..<splitRange.lowerBound])
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !sentence.isEmpty {
                sentences.append(sentence)
            }
            sentenceStart = splitRange.upperBound
        }

        let tail = String(text[sentenceStart...]).trimmingCharacters(in: .whitespacesAndNewlines)
        if !tail.isEmpty {
            sentences.append(tail)
        }

        return sentences.isEmpty ? [text] : sentences
    }

    private static func normalizeMathMentions(in text: String) -> String {
        var value = text
        // Convert common linear math notation in prose to LaTeX inline form.
        value = MathTextFormatter.replacingRegex(#"(?<!\*)\*(?!\*)"#, in: value, with: " \\\\times ")
        value = value.replacingOccurrences(of: "π", with: "\\pi")
        value = MathTextFormatter.replacingRegex(#"(?i)\bpi\b"#, in: value, with: "\\\\pi")
        value = MathTextFormatter.replacingRegex(
            #"(?i)\\pi\s*/\s*([0-9]+(?:\.[0-9]+)?)"#,
            in: value,
            with: "\\\\frac{\\\\pi}{$1}"
        )
        value = MathTextFormatter.replacingRegex(
            #"(?i)([0-9]+(?:\.[0-9]+)?)\s*/\s*\\pi"#,
            in: value,
            with: "\\\\frac{$1}{\\\\pi}"
        )
        value = MathTextFormatter.replacingRegex(
            #"(?<!\\)\b([A-Za-z0-9]+)\s*/\s*([A-Za-z0-9]+)\b"#,
            in: value,
            with: "\\\\frac{$1}{$2}"
        )
        value = MathTextFormatter.replacingRegex(
            #"(?<!\\)\b([A-Za-z])\s*\^\s*([0-9]+)\b"#,
            in: value,
            with: "$1^{$2}"
        )
        value = MathTextFormatter.replacingRegex(
            #"(?<!\\)\b([A-Za-z])\s*\^\s*([A-Za-z]+)\b"#,
            in: value,
            with: "$1^{$2}"
        )
        value = MathTextFormatter.replacingRegex(
            #"\b([A-Za-z0-9\\\}\)]+)\s*\\times\s*([A-Za-z0-9\\\{\(]+)\b"#,
            in: value,
            with: "$1 \\\\times $2"
        )

        // Ensure converted math fragments are wrapped as inline LaTeX with $...$.
        value = MathTextFormatter.replacingRegex(
            #"(?<!\$)(\\frac\{[^{}]+\}\{[^{}]+\}|\\pi|\\sqrt\{[^{}]+\}|\\int(?:_[^[:space:]]+)?(?:\^[^[:space:]]+)?|[A-Za-z]\^\{[^{}]+\}|[A-Za-z0-9]+\s*\\times\s*[A-Za-z0-9]+)(?!\$)"#,
            in: value,
            with: "\\$$1\\$"
        )
        value = MathTextFormatter.replacingRegex(
            #"(?<!\$)([A-Za-z0-9\\\{\}\^\+\-\(\)\s]+=[A-Za-z0-9\\\{\}\^\+\-\(\)\s]+)(?!\$)"#,
            in: value,
            with: "\\$$1\\$"
        )

        // Normalize accidental double-dollar inline wrappers to single-dollar inline.
        value = MathTextFormatter.replacingRegex(
            #"\$\$([^\$]+)\$\$"#,
            in: value,
            with: "\\$$1\\$"
        )
        value = MathTextFormatter.replacingRegex(
            #"\$([^\$]+?)\s+\$"#,
            in: value,
            with: "\\$$1\\$"
        )
        return value
    }

    private static func emphasizedMarkdown(in text: String) -> String {
        var emphasized = text
        for keyword in emphasisKeywords {
            let escaped = NSRegularExpression.escapedPattern(for: keyword)
            emphasized = MathTextFormatter.replacingRegex(
                "(?i)\\b(\(escaped))\\b",
                in: emphasized,
                with: "**$1**"
            )
        }
        return emphasized
    }
}

#Preview {
    VStack(spacing: 16) {
        AnswerCardView(answer: "42", isVisible: true)
        PrimaryEquationCardView(
            title: L10n.problem,
            latex: "x^2 - 5x + 6 = 0",
            fallbackText: "x² - 5x + 6 = 0"
        )
        StepCardView(
            stepNumber: 1,
            content: "(x - 2)(x - 3)=0 || Scomponiamo il trinomio cercando due numeri con prodotto 6 e somma -5, quindi otteniamo la fattorizzazione corretta.",
            isVisible: true
        )
        StepCardView(
            stepNumber: 2,
            content: "x=2 \\text{ or } x=3 || Applichiamo la proprietà del prodotto nullo: se il prodotto è zero, almeno uno dei fattori deve essere zero.",
            isVisible: true
        )

        HStack {
            DifficultyBadge(level: "elementary")
            DifficultyBadge(level: "middle_school")
            DifficultyBadge(level: "high_school")
            DifficultyBadge(level: "college")
        }
    }
    .padding()
}
