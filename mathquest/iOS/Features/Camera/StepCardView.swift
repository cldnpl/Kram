import SwiftUI
import WebKit

struct StepCardView: View {
    let stepNumber: Int
    let content: String
    let detail: String
    let isVisible: Bool
    @State private var isExpanded = false

    init(stepNumber: Int, content: String, detail: String = "", isVisible: Bool) {
        self.stepNumber = stepNumber
        self.content = content
        self.detail = detail
        self.isVisible = isVisible
    }

    private var hasExpandContent: Bool {
        !detail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var detailHasLatex: Bool {
        detail.contains("\\displaystyle") || detail.contains("\\frac") ||
        detail.contains("\\sqrt") || detail.contains("\\int") ||
        detail.contains("\\sum") || detail.contains("^{") ||
        detail.contains("$")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // COLLAPSED — Step number + pure LaTeX formula (single line, \small)
            Button {
                guard hasExpandContent else { return }
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(alignment: .center, spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color.purple.opacity(0.15))
                            .frame(width: 28, height: 28)
                        Text("\(stepNumber)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.purple)
                    }

                    // Formula rendered as single-line KaTeX
                    StepFormulaView(latex: content)
                        .frame(height: 36)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if hasExpandContent {
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)

            // EXPANDED — Full detailed explanation with all properties cited
            if isExpanded {
                Divider()
                    .padding(.horizontal)

                if detailHasLatex {
                    LaTeXView(content: detail)
                        .frame(minHeight: 80)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                } else {
                    RichTextView(content: detail)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                }
            }
        }
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 20)
    }
}

/// Renders a single-line compact LaTeX formula using KaTeX in a WKWebView.
private struct StepFormulaView: UIViewRepresentable {
    let latex: String

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let cleaned = latex
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "`", with: "\\`")
            .replacingOccurrences(of: "$", with: "\\$")

        let html = """
        <!DOCTYPE html>
        <html>
        <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/katex@0.16.9/dist/katex.min.css">
        <script src="https://cdn.jsdelivr.net/npm/katex@0.16.9/dist/katex.min.js"></script>
        <script src="https://cdn.jsdelivr.net/npm/katex@0.16.9/dist/contrib/auto-render.min.js"></script>
        <style>
            body {
                margin: 0; padding: 2px 0;
                font-family: -apple-system, sans-serif;
                font-size: 13px; line-height: 1.3;
                background: transparent;
                overflow: hidden;
                white-space: nowrap;
            }
            @media (prefers-color-scheme: dark) { body { color: #f4f7ff; } }
            @media (prefers-color-scheme: light) { body { color: #1a1a1a; } }
            .katex { font-size: 0.95em; }
        </style>
        </head>
        <body>
        <div id="content">\(cleaned)</div>
        <script>
        renderMathInElement(document.getElementById('content'), {
            delimiters: [
                {left: '$$', right: '$$', display: true},
                {left: '$', right: '$', display: false},
                {left: '\\\\(', right: '\\\\)', display: false},
                {left: '\\\\[', right: '\\\\]', display: true}
            ],
            throwOnError: false
        });
        </script>
        </body>
        </html>
        """
        webView.loadHTMLString(html, baseURL: nil)
    }
}

/// Renders LaTeX content with KaTeX for expanded detail sections.
struct LaTeXView: UIViewRepresentable {
    let content: String

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let escapedContent = content
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "`", with: "\\`")
            .replacingOccurrences(of: "$", with: "\\$")

        let html = """
        <!DOCTYPE html>
        <html>
        <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/katex@0.16.9/dist/katex.min.css">
        <script src="https://cdn.jsdelivr.net/npm/katex@0.16.9/dist/katex.min.js"></script>
        <script src="https://cdn.jsdelivr.net/npm/katex@0.16.9/dist/contrib/auto-render.min.js"></script>
        <style>
            body {
                margin: 0; padding: 8px;
                font-family: -apple-system, sans-serif;
                font-size: 15px; line-height: 1.6;
                background: transparent;
            }
            @media (prefers-color-scheme: dark) { body { color: #f4f7ff; } }
            @media (prefers-color-scheme: light) { body { color: #1a1a1a; } }
            .katex { font-size: 1.1em; }
            .katex-display { margin: 8px 0; overflow-x: auto; }
            strong, b { font-weight: 700; }
        </style>
        </head>
        <body>
        <div id="content">\(escapedContent)</div>
        <script>
        // Convert **bold** markers to <strong> tags
        var el = document.getElementById('content');
        el.innerHTML = el.innerHTML.replace(/\\*\\*([^*]+)\\*\\*/g, '<strong>$1</strong>');

        renderMathInElement(el, {
            delimiters: [
                {left: '$$', right: '$$', display: true},
                {left: '$', right: '$', display: false},
                {left: '\\\\(', right: '\\\\)', display: false},
                {left: '\\\\[', right: '\\\\]', display: true}
            ],
            throwOnError: false
        });
        </script>
        </body>
        </html>
        """
        webView.loadHTMLString(html, baseURL: nil)
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

/// Renders rich text with **bold** markers parsed into attributed text.
private struct RichTextView: View {
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(paragraphs.enumerated()), id: \.offset) { _, paragraph in
                parseBoldText(paragraph)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var paragraphs: [String] {
        content.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    private func parseBoldText(_ text: String) -> Text {
        var result = Text("")
        var remaining = text[...]

        while let boldStart = remaining.range(of: "**") {
            let before = remaining[..<boldStart.lowerBound]
            if !before.isEmpty {
                result = result + Text(String(before)).font(.body).foregroundColor(.primary)
            }
            remaining = remaining[boldStart.upperBound...]

            if let boldEnd = remaining.range(of: "**") {
                let boldContent = remaining[..<boldEnd.lowerBound]
                result = result + Text(String(boldContent)).font(.body).bold().foregroundColor(.primary)
                remaining = remaining[boldEnd.upperBound...]
            } else {
                result = result + Text(String(remaining)).font(.body).foregroundColor(.primary)
                remaining = remaining[remaining.endIndex...]
            }
        }

        if !remaining.isEmpty {
            result = result + Text(String(remaining)).font(.body).foregroundColor(.primary)
        }

        return result
    }
}

#Preview {
    VStack(spacing: 16) {
        AnswerCardView(answer: "42", isVisible: true)
        StepCardView(
            stepNumber: 1,
            content: "$\\small\\displaystyle \\frac{d}{dx}(x^2 + 3x) = 2x + 3$",
            detail: "**Regola di derivazione**: Applichiamo la regola delle potenze $\\displaystyle \\frac{d}{dx}(x^n) = nx^{n-1}$ a ciascun termine...",
            isVisible: true
        )
        StepCardView(
            stepNumber: 2,
            content: "$\\small\\displaystyle 2x + 3 = 0 \\implies x = -\\frac{3}{2}$",
            detail: "**Risoluzione dell'equazione**: Isoliamo la variabile $\\displaystyle x$ spostando il termine noto...",
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
