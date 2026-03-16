import SwiftUI

struct ScientificCalculatorView: View {
    @ObservedObject var viewModel: CameraViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var expression = ""
    @State private var isSolving = false
    @State private var errorMessage: String?
    @State private var funcPage = 0 // 0=Basic, 1=Adv, 2=Sym

    private let appPurple = Color(red: 0.42, green: 0.36, blue: 0.91)
    private let pageTitles = ["Basic", "Adv", "Sym"]

    // MARK: - Button data

    private let funcPages: [[[CalcBtn]]] = [
        // Page 0 – Basic
        [
            [.fn("sin"), .fn("cos"), .fn("tan"), .op("("), .op(")")],
            [.fn("log"), .fn("ln"), .fn("\u{221A}"), .op("^"), .fn("n!")],
            [.op("\u{03C0}"), .op("e"), .fn("x\u{00B2}"), .fn("x\u{00B3}"), .fn("|x|")],
        ],
        // Page 1 – Advanced
        [
            [.fn("sin\u{207B}\u{00B9}"), .fn("cos\u{207B}\u{00B9}"), .fn("tan\u{207B}\u{00B9}"), .op("("), .op(")")],
            [.fn("sinh"), .fn("cosh"), .fn("tanh"), .fn("log\u{2082}"), .fn("10\u{02E3}")],
            [.fn("e\u{02E3}"), .fn("x\u{207B}\u{00B9}"), .fn("\u{00B3}\u{221A}"), .fn("\u{207F}\u{221A}"), .op("%")],
        ],
        // Page 2 – Symbols
        [
            [.op("\u{222B}"), .op("\u{03A3}"), .fn("lim"), .fn("d/dx"), .op("\u{2202}")],
            [.op("\u{221E}"), .op("\u{2264}"), .op("\u{2265}"), .op("\u{2260}"), .op("\u{2248}")],
            [.op("\u{00B1}"), .op("\u{00B0}"), .op("mod"), .op("\u{2192}"), .op("=")],
        ],
    ]

    private let digitRows: [[CalcBtn]] = [
        [.digit("7"), .digit("8"), .digit("9"), .op("\u{00F7}"), .backspace],
        [.digit("4"), .digit("5"), .digit("6"), .op("\u{00D7}"), .clear],
        [.digit("1"), .digit("2"), .digit("3"), .op("-"), .parens],
        [.digit("0"), .op("."), .op(","), .op("+"), .op("=")],
    ]

    // MARK: - Body

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                let compact = proxy.size.height < 760 || proxy.size.width < 370
                calcContent(compact: compact)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .background(Color(red: 0.04, green: 0.07, blue: 0.13))
                    .navigationTitle("Scientific Calculator")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") { dismiss() }
                        }
                    }
                    .onChange(of: viewModel.state) { _, newState in
                        guard case .success = newState else { return }
                        isSolving = false
                        dismiss()
                    }
            }
        }
    }

    // MARK: - Calculator content

    private func calcContent(compact: Bool) -> some View {
        VStack(spacing: 0) {
            expressionDisplay(compact: compact)
            statusArea(compact: compact)
            pageSelector(compact: compact)
            funcButtonGrid(compact: compact)
            Spacer().frame(height: compact ? 1 : 2)
            digitButtonGrid(compact: compact)
            solveButton(compact: compact)
        }
    }

    // MARK: - Sub-views

    private func expressionDisplay(compact: Bool) -> some View {
        VStack(alignment: .trailing) {
            Spacer()
            ScrollView(.horizontal, showsIndicators: false) {
                Text(expression.isEmpty ? "0" : expression)
                    .font(.system(size: compact ? 26 : 30, weight: .light, design: .monospaced))
                    .foregroundColor(expression.isEmpty ? .gray : .white)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .defaultScrollAnchor(.trailing)
        }
        .padding(.horizontal, compact ? 12 : 16)
        .frame(height: compact ? 70 : 80)
    }

    private func statusArea(compact: Bool) -> some View {
        VStack(spacing: compact ? 3 : 4) {
            if isSolving {
                ProgressView().tint(.white).scaleEffect(0.8)
            }
            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 16)
            }
        }
        .frame(minHeight: isSolving || errorMessage != nil ? (compact ? 20 : 24) : 0)
    }

    private func pageSelector(compact: Bool) -> some View {
        HStack(spacing: compact ? 4 : 6) {
            ForEach(0..<pageTitles.count, id: \.self) { i in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) { funcPage = i }
                } label: {
                    Text(pageTitles[i])
                        .font(.system(size: compact ? 12 : 13, weight: funcPage == i ? .semibold : .regular))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, compact ? 6 : 7)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(funcPage == i ? appPurple : Color(red: 0.1, green: 0.14, blue: 0.22))
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, compact ? 6 : 8)
        .padding(.vertical, 4)
    }

    private func funcButtonGrid(compact: Bool) -> some View {
        VStack(spacing: compact ? 3 : 4) {
            ForEach(Array(funcPages[funcPage].enumerated()), id: \.offset) { _, row in
                buttonRow(row, isFunc: true, compact: compact)
            }
        }
        .padding(.horizontal, compact ? 4 : 6)
    }

    private func digitButtonGrid(compact: Bool) -> some View {
        VStack(spacing: compact ? 3 : 4) {
            ForEach(Array(digitRows.enumerated()), id: \.offset) { _, row in
                buttonRow(row, isFunc: false, compact: compact)
            }
        }
        .padding(.horizontal, compact ? 4 : 6)
    }

    private func buttonRow(_ buttons: [CalcBtn], isFunc: Bool, compact: Bool) -> some View {
        HStack(spacing: compact ? 3 : 4) {
            ForEach(buttons, id: \.id) { btn in
                CalcBtnView(button: btn, isFunc: isFunc, compact: compact, appPurple: appPurple) {
                    handleTap(btn)
                }
            }
        }
    }

    private func solveButton(compact: Bool) -> some View {
        Button { solve() } label: {
            HStack(spacing: compact ? 6 : 8) {
                if isSolving { ProgressView().tint(.white).scaleEffect(0.8) }
                Text("Solve").font(.body.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, compact ? 11 : 13)
        }
        .buttonStyle(.borderedProminent)
        .tint(appPurple)
        .clipShape(RoundedRectangle(cornerRadius: compact ? 12 : 14))
        .disabled(expression.trimmingCharacters(in: .whitespaces).isEmpty || isSolving)
        .padding(.horizontal, compact ? 10 : 12)
        .padding(.top, compact ? 4 : 6)
        .padding(.bottom, compact ? 14 : 20)
    }

    // MARK: - Input handling

    private func handleTap(_ btn: CalcBtn) {
        switch btn {
        case .clear:
            expression = ""
            errorMessage = nil
        case .backspace:
            if !expression.isEmpty { expression.removeLast() }
        case .parens:
            let opens = expression.filter { $0 == "(" }.count
            let closes = expression.filter { $0 == ")" }.count
            expression += opens > closes ? ")" : "("
        case .fn(let name):
            expression += mapFunction(name)
        case .op(let op):
            if op == "=" { solve() } else { expression += op }
        case .digit(let d):
            expression += d
        }
    }

    private func mapFunction(_ name: String) -> String {
        switch name {
        case "sin", "cos", "tan", "sinh", "cosh", "tanh", "log", "ln":
            return "\(name)("
        case "sin\u{207B}\u{00B9}": return "arcsin("
        case "cos\u{207B}\u{00B9}": return "arccos("
        case "tan\u{207B}\u{00B9}": return "arctan("
        case "log\u{2082}": return "log\u{2082}("
        case "10\u{02E3}": return "10^("
        case "e\u{02E3}": return "e^("
        case "x\u{207B}\u{00B9}": return "\u{207B}\u{00B9}"
        case "\u{221A}": return "\u{221A}("
        case "\u{00B3}\u{221A}": return "\u{00B3}\u{221A}("
        case "\u{207F}\u{221A}": return "\u{207F}\u{221A}("
        case "x\u{00B2}": return "\u{00B2}"
        case "x\u{00B3}": return "\u{00B3}"
        case "n!": return "!"
        case "|x|": return "|"
        case "d/dx": return "d/dx("
        case "lim": return "lim("
        default: return name
        }
    }

    private func solve() {
        let trimmed = expression.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !isSolving else { return }
        isSolving = true
        errorMessage = nil
        Task {
            await viewModel.solveFromText(trimmed)
            await MainActor.run {
                isSolving = false
                if case .error(let msg) = viewModel.state {
                    errorMessage = msg
                }
            }
        }
    }
}

// MARK: - Button model

private enum CalcBtn: Identifiable {
    case digit(String)
    case op(String)
    case fn(String)
    case clear
    case backspace
    case parens

    var id: String {
        switch self {
        case .digit(let d): return "d_\(d)"
        case .op(let o): return "o_\(o)"
        case .fn(let f): return "f_\(f)"
        case .clear: return "clear"
        case .backspace: return "backspace"
        case .parens: return "parens"
        }
    }

    var label: String {
        switch self {
        case .digit(let d): return d
        case .op(let o): return o
        case .fn(let f): return f
        case .clear: return "AC"
        case .backspace: return "\u{232B}"
        case .parens: return "( )"
        }
    }

    var isOperator: Bool {
        if case .op = self { return true }
        return false
    }

    var isDeleteAction: Bool {
        switch self {
        case .clear, .backspace: return true
        default: return false
        }
    }
}

// MARK: - Button view

private struct CalcBtnView: View {
    let button: CalcBtn
    let isFunc: Bool
    let compact: Bool
    let appPurple: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(button.label)
                .font(.system(size: fontSize, weight: .medium))
                .foregroundColor(fgColor)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(bgColor)
                .clipShape(RoundedRectangle(cornerRadius: compact ? 8 : 10))
        }
        .buttonStyle(.plain)
        .frame(height: compact ? 36 : 42)
    }

    private var fontSize: CGFloat {
        let scale: CGFloat = compact ? 0.9 : 1
        if button.isDeleteAction { return 14 * scale }
        if isFunc { return 13 * scale }
        return 18 * scale
    }

    private var bgColor: Color {
        if button.isDeleteAction {
            return Color(red: 0.18, green: 0.12, blue: 0.12)
        }
        if button.label == "=" || (!isFunc && button.isOperator && ![".", ",", "%"].contains(button.label)) {
            return appPurple
        }
        if isFunc {
            return Color(red: 0.1, green: 0.14, blue: 0.22)
        }
        return Color(red: 0.08, green: 0.12, blue: 0.21)
    }

    private var fgColor: Color {
        if button.isDeleteAction { return Color.red.opacity(0.85) }
        return .white
    }
}
