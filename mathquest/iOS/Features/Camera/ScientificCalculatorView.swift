import SwiftUI
import UIKit
import Combine

// MARK: - Theme-adaptive color scheme

private struct CalcColors {
    let isDark: Bool

    var background: Color { isDark ? Color(red: 0.06, green: 0.09, blue: 0.14) : Color(red: 0.95, green: 0.95, blue: 0.97) }
    var surface: Color { isDark ? Color(red: 0.09, green: 0.11, blue: 0.18) : .white }
    var onSurface: Color { isDark ? .white : Color(red: 0.11, green: 0.11, blue: 0.12) }
    var hint: Color { isDark ? .white.opacity(0.3) : Color(red: 0.78, green: 0.78, blue: 0.80) }
    var divider: Color { isDark ? .white.opacity(0.06) : Color(red: 0.82, green: 0.82, blue: 0.84) }

    var toolbarBg: Color { isDark ? Color(red: 0.10, green: 0.13, blue: 0.22) : Color(red: 0.90, green: 0.90, blue: 0.93) }
    var toolbarFg: Color { isDark ? .white.opacity(0.7) : Color(red: 0.39, green: 0.39, blue: 0.40) }
    var toolbarActiveBg: Color { isDark ? .white : Color(red: 0.11, green: 0.11, blue: 0.12) }
    var toolbarActiveFg: Color { isDark ? .black : .white }

    var tabSelectedBg: Color { isDark ? Color(red: 0.49, green: 0.42, blue: 0.94) : Color(red: 0.11, green: 0.11, blue: 0.12) }
    var tabSelectedFg: Color { .white }
    var tabBg: Color { isDark ? Color(red: 0.12, green: 0.15, blue: 0.25) : Color(red: 0.90, green: 0.90, blue: 0.93) }
    var tabFg: Color { isDark ? .white.opacity(0.54) : Color(red: 0.39, green: 0.39, blue: 0.40) }
    var tabBorder: Color { isDark ? .white.opacity(0.06) : Color(red: 0.82, green: 0.82, blue: 0.84) }

    var digitBg: Color { isDark ? Color(red: 0.10, green: 0.13, blue: 0.22) : .white }
    var digitFg: Color { isDark ? .white : Color(red: 0.11, green: 0.11, blue: 0.12) }
    var funcBg: Color { isDark ? Color(red: 0.12, green: 0.15, blue: 0.25) : Color(red: 0.91, green: 0.91, blue: 0.93) }
    var funcFg: Color { isDark ? Color(red: 0.69, green: 0.75, blue: 0.88) : Color(red: 0.24, green: 0.24, blue: 0.26) }
    var operatorBg: Color { isDark ? Color(red: 0.16, green: 0.14, blue: 0.38) : Color(red: 0.91, green: 0.91, blue: 0.93) }
    var operatorFg: Color { isDark ? Color(red: 0.71, green: 0.65, blue: 1.0) : Color(red: 0.0, green: 0.48, blue: 1.0) }
    var accentBg: Color { isDark ? Color(red: 0.49, green: 0.42, blue: 0.94) : Color(red: 0.0, green: 0.48, blue: 1.0) }
    var accentFg: Color { .white }

    var popupBg: Color { isDark ? Color(red: 0.16, green: 0.20, blue: 0.31) : .white }
    var redDot: Color { Color(red: 1.0, green: 0.23, blue: 0.19) }
    var solveGrad1: Color { isDark ? Color(red: 0.49, green: 0.42, blue: 0.94) : Color(red: 0.0, green: 0.48, blue: 1.0) }
    var solveGrad2: Color { isDark ? Color(red: 0.36, green: 0.29, blue: 0.81) : Color(red: 0.0, green: 0.34, blue: 0.84) }
    var solveDisabled: Color { isDark ? Color(red: 0.10, green: 0.13, blue: 0.21) : Color(red: 0.82, green: 0.82, blue: 0.84) }
}

// MARK: - Button data

private let tabLabels = ["+\u{2212}\u{00D7}\u{00F7}", "f(x) e\nlog ln", "sin cos\ntan cot", "lim dx\n\u{222B} \u{03A3} \u{221E}"]

private let tab0: [[String]] = [
    ["( )", ">", "7", "8", "9", "\u{00F7}"],
    ["a/b", "\u{221A}", "4", "5", "6", "\u{00D7}"],
    ["x\u{207F}", "x", "1", "2", "3", "\u{2212}"],
    ["\u{03C0}", "%", "0", ".", "=", "+"],
]

private let tab1: [[String]] = [
    ["|x|", "n!", "log", "log\u{2082}", "log\u{2081}\u{2080}", "ln"],
    ["\u{230A}x\u{230B}", "\u{2308}x\u{2309}", "exp", "e\u{02E3}", "10\u{02E3}", "x\u{207B}\u{00B9}"],
    ["nPr", "nCr", "GCD", "LCM", "mod", "\u{00B1}"],
    ["min", "max", "sign", "\u{221E}", "i", "e"],
]

private let tab2: [[String]] = [
    ["rad", "sin", "cos", "tan", "cot", "sec", "csc"],
    ["\u{00B0}", "arcsin", "arccos", "arctan", "arccot", "arcsec", "arccsc"],
    ["\u{00B0}\u{2032}", "sinh", "cosh", "tanh", "coth", "sech", "csch"],
    ["\u{00B0}\u{2032}\u{2033}", "arsinh", "arcosh", "artanh", "arcoth", "arsech", "arcsch"],
]

private let tab3: [[String]] = [
    ["lim", "d/dx", "\u{222B}", "dy/dx", "a\u{2099}"],
    ["lim\u{207A}", "\u{2202}/\u{2202}x", "\u{222B}\u{222B}", "dx", "\u{03A3}"],
    ["lim\u{207B}", "d\u{00B2}/dx\u{00B2}", "\u{222E}", "dy", "\u{220F}"],
    ["\u{221E}", "\u{2207}", "\u{2202}", "y\u{2032}", "\u{2192}"],
]

private let abcGrid: [[String]] = [
    ["a", "b", "c", "d", "e", "f", "g", "h"],
    ["i", "j", "k", "l", "m", "n", "o", "p"],
    ["q", "r", "s", "t", "u", "v", "w", "x"],
    ["y", "z", "\u{03B1}", "\u{03B2}", "\u{03B8}", "\u{03B3}", "\u{03B4}", "\u{03C6}"],
]

private let longPressVariants: [String: [String]] = [
    "( )": ["(", ")", "[", "]", "{", "}"],
    ">": ["<", "\u{2265}", "\u{2264}", "\u{2260}", "\u{2248}", "\u{2261}"],
    "\u{221A}": ["\u{221A}", "\u{00B3}\u{221A}", "\u{2074}\u{221A}", "\u{207F}\u{221A}"],
    "x\u{207F}": ["^", "\u{00B2}", "\u{00B3}", "\u{2074}", "\u{207B}\u{00B9}"],
    "x": ["x", "y", "z", "t", "n", "k"],
    "\u{03C0}": ["\u{03C0}", "\u{03C4}", "\u{03C9}", "\u{03BB}", "\u{03BC}", "\u{03C3}"],
    "%": ["%", "mod"],
]

// MARK: - Insert-text mapping

private func mapInsert(_ label: String) -> String {
    switch label {
    case "( )": return "("
    case "\u{00F7}": return "\u{00F7}"
    case "\u{00D7}": return "\u{00D7}"
    case "\u{2212}": return "-"
    case "a/b": return "/"
    case "x\u{207F}": return "^"
    case "x\u{207B}\u{00B9}": return "\u{207B}\u{00B9}"
    case "\u{00B2}", "\u{00B3}", "\u{2074}", "\u{207B}\u{00B9}": return label
    case "\u{221A}": return "\u{221A}("
    case "\u{00B3}\u{221A}": return "\u{00B3}\u{221A}("
    case "\u{2074}\u{221A}": return "\u{2074}\u{221A}("
    case "\u{207F}\u{221A}": return "\u{207F}\u{221A}("
    case "sin", "cos", "tan", "cot", "sec", "csc",
         "arcsin", "arccos", "arctan", "arccot", "arcsec", "arccsc",
         "sinh", "cosh", "tanh", "coth", "sech", "csch",
         "arsinh", "arcosh", "artanh", "arcoth", "arsech", "arcsch",
         "log", "ln", "exp", "GCD", "LCM", "min", "max", "sign", "nPr", "nCr":
        return "\(label)("
    case "log\u{2082}": return "log\u{2082}("
    case "log\u{2081}\u{2080}": return "log\u{2081}\u{2080}("
    case "e\u{02E3}": return "e^("
    case "10\u{02E3}": return "10^("
    case "n!": return "!"
    case "|x|": return "|"
    case "\u{230A}x\u{230B}": return "\u{230A}"
    case "\u{2308}x\u{2309}": return "\u{2308}"
    case "mod": return " mod "
    case "\u{00B1}": return "\u{00B1}"
    case "lim": return "lim("
    case "lim\u{207A}": return "lim\u{207A}("
    case "lim\u{207B}": return "lim\u{207B}("
    case "d/dx": return "d/dx("
    case "\u{2202}/\u{2202}x": return "\u{2202}/\u{2202}x("
    case "d\u{00B2}/dx\u{00B2}": return "d\u{00B2}/dx\u{00B2}("
    case "\u{222B}": return "\u{222B}("
    case "\u{222B}\u{222B}": return "\u{222B}\u{222B}("
    case "\u{222E}": return "\u{222E}("
    case "\u{03A3}": return "\u{03A3}("
    case "\u{220F}": return "\u{220F}("
    case "a\u{2099}": return "a\u{2099}"
    case "dy/dx": return "dy/dx"
    case "y\u{2032}": return "y'"
    case "\u{2207}": return "\u{2207}"
    case "\u{2202}": return "\u{2202}"
    case "rad": return "rad"
    case "\u{00B0}": return "\u{00B0}"
    case "\u{00B0}\u{2032}": return "\u{00B0}\u{2032}"
    case "\u{00B0}\u{2032}\u{2033}": return "\u{00B0}\u{2032}\u{2033}"
    default: return label
    }
}

// MARK: - Main View

struct ScientificCalculatorView: View {
    @ObservedObject var viewModel: CameraViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var expression = ""
    @State private var cursorPos = 0
    @State private var isSolving = false
    @State private var errorMessage: String?
    @State private var selectedTab = 0
    @State private var abcMode = false
    @State private var showingLongPress = false
    @State private var longPressLabel = ""
    @State private var longPressAnchor = CGPoint.zero

    // Undo stack: each entry is (expression, cursorPos) before an edit
    @State private var undoStack: [(String, Int)] = []

    private var colors: CalcColors { CalcColors(isDark: colorScheme == .dark) }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                expressionArea
                statusArea
                toolbar
                    .padding(.top, 4)
                if !abcMode {
                    categoryTabs
                        .padding(.top, 6)
                }
                buttonGrid
                    .padding(.top, 6)
                solveButton
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(colors.background)
            .navigationTitle("Calculator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                    }
                }
            }
            .toolbarColorScheme(colorScheme == .dark ? .dark : .light, for: .navigationBar)
            .onChange(of: viewModel.state) { _, newState in
                guard case .success = newState else { return }
                isSolving = false
                dismiss()
            }
            .overlay { if showingLongPress { longPressOverlay } }
        }
    }

    // MARK: - Expression area

    @State private var cursorVisible = true

    private var expressionArea: some View {
        VStack(alignment: .trailing, spacing: 0) {
            Spacer(minLength: 0)
            ScrollView(.horizontal, showsIndicators: false) {
                if expression.isEmpty {
                    HStack(spacing: 0) {
                        CursorView(color: colors.accentBg, visible: cursorVisible)
                        Text("Type a math problem...")
                            .font(.system(size: 24, weight: .light))
                            .foregroundColor(colors.hint)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    let pos = min(cursorPos, expression.count)
                    let before = String(expression.prefix(pos))
                    let after = String(expression.suffix(expression.count - pos))
                    let charBefore: Character? = pos > 0 ? expression[expression.index(expression.startIndex, offsetBy: pos - 1)] : nil
                    let charAfter: Character? = pos < expression.count ? expression[expression.index(expression.startIndex, offsetBy: pos)] : nil
                    let small = (charBefore.map(isSmallChar) ?? false) || (charAfter.map(isSmallChar) ?? false)
                    HStack(spacing: 0) {
                        Text(before)
                            .font(.system(size: 24, weight: .light))
                            .foregroundColor(colors.onSurface)
                        CursorView(color: colors.accentBg, visible: cursorVisible, small: small)
                        Text(after)
                            .font(.system(size: 24, weight: .light))
                            .foregroundColor(colors.onSurface)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .defaultScrollAnchor(.trailing)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 80)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colors.surface)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(colors.divider, lineWidth: 0.5))
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .onReceive(Timer.publish(every: 0.53, on: .main, in: .common).autoconnect()) { _ in
            cursorVisible.toggle()
        }
    }

    // MARK: - Status

    private var statusArea: some View {
        VStack(spacing: 4) {
            if isSolving {
                ProgressView().tint(colors.accentBg).scaleEffect(0.8)
                    .padding(.bottom, 6)
            }
            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 4)
            }
        }
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack(spacing: 0) {
            // ABC toggle
            Button {
                withAnimation(.easeInOut(duration: 0.15)) { abcMode.toggle() }
                haptic(.light)
            } label: {
                Text("abc")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(abcMode ? colors.toolbarActiveFg : colors.toolbarFg)
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(abcMode ? colors.toolbarActiveBg : .clear)
                    )
            }
            .buttonStyle(.plain)

            toolbarButton(icon: "clock.arrow.circlepath") { undo(); haptic(.light) }
            toolbarButton(icon: "arrow.left") { cursorLeft(); haptic(.light) }
            toolbarButton(icon: "arrow.right") { cursorRight(); haptic(.light) }
            toolbarButton(icon: "return", tint: colors.accentBg) { solve() }
            toolbarButton(icon: "delete.backward") { backspace(); haptic(.light) }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(RoundedRectangle(cornerRadius: 12).fill(colors.toolbarBg))
        .padding(.horizontal, 12)
    }

    private func toolbarButton(icon: String, tint: Color? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(tint ?? colors.toolbarFg)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Category tabs

    private var categoryTabs: some View {
        HStack(spacing: 6) {
            ForEach(0..<4, id: \.self) { i in
                let sel = selectedTab == i
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) { selectedTab = i }
                    haptic(.light)
                } label: {
                    Text(tabLabels[i])
                        .font(.system(size: 11, weight: sel ? .bold : .medium))
                        .foregroundColor(sel ? colors.tabSelectedFg : colors.tabFg)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity)
                        .frame(height: 42)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(sel ? colors.tabSelectedBg : colors.tabBg)
                        )
                        .overlay(
                            sel ? nil : RoundedRectangle(cornerRadius: 10)
                                .stroke(colors.tabBorder, lineWidth: 0.5)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
    }

    // MARK: - Button grid

    @ViewBuilder
    private var buttonGrid: some View {
        if abcMode {
            standardGrid(abcGrid, type: .digit)
        } else {
            switch selectedTab {
            case 0: standardGrid(tab0, tabIndex: 0)
            case 1: standardGrid(tab1, type: .func)
            case 2: trigGrid
            case 3: standardGrid(tab3, type: .func)
            default: EmptyView()
            }
        }
    }

    private func standardGrid(_ rows: [[String]], type: BtnType? = nil, tabIndex: Int = -1) -> some View {
        VStack(spacing: 6) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 6) {
                    ForEach(row, id: \.self) { label in
                        let t = type ?? btnType(label, tab: tabIndex)
                        gridButton(label: label, type: t)
                    }
                }
            }
        }
        .padding(.horizontal, 8)
    }

    private var trigGrid: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            VStack(spacing: 6) {
                ForEach(Array(tab2.enumerated()), id: \.offset) { _, row in
                    HStack(spacing: 6) {
                        ForEach(row, id: \.self) { label in
                            gridButton(label: label, type: .func)
                                .frame(width: 78)
                        }
                    }
                }
            }
            .padding(.horizontal, 8)
        }
        .padding(.top, 4)
        .frame(height: CGFloat(tab2.count) * 50 + 4)
    }

    private func gridButton(label: String, type: BtnType) -> some View {
        let hasLP = longPressVariants[label] != nil
        return GeometryReader { geo in
            Button {
                handleTap(label)
            } label: {
                ZStack {
                    mathLabel(label, fg: fgColor(type), size: fontSize(label: label, type: type))
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(RoundedRectangle(cornerRadius: 10).fill(bgColor(type)))

                    if hasLP {
                        VStack {
                            Spacer()
                            HStack {
                                Circle()
                                    .fill(colors.redDot)
                                    .frame(width: 5, height: 5)
                                    .padding(.leading, 5)
                                    .padding(.bottom, 5)
                                Spacer()
                            }
                        }
                    }
                }
            }
            .buttonStyle(.plain)
            .frame(height: 48)
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0.4)
                    .onEnded { _ in
                        guard hasLP else { return }
                        let pos = geo.frame(in: .global)
                        longPressLabel = label
                        longPressAnchor = CGPoint(x: pos.midX, y: pos.minY)
                        showingLongPress = true
                        haptic(.medium)
                    }
            )
        }
        .frame(height: 48)
    }

    // MARK: - Solve button

    private var solveButton: some View {
        let enabled = !expression.trimmingCharacters(in: .whitespaces).isEmpty && !isSolving
        return Button { solve() } label: {
            HStack(spacing: 8) {
                if isSolving { ProgressView().tint(.white).scaleEffect(0.8) }
                Text("Solve").font(.body.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        enabled
                            ? LinearGradient(colors: [colors.solveGrad1, colors.solveGrad2], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [colors.solveDisabled], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            )
            .foregroundColor(enabled ? .white : colors.hint)
        }
        .disabled(!enabled)
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    // MARK: - Long-press overlay

    @ViewBuilder
    private var longPressOverlay: some View {
        let variants = longPressVariants[longPressLabel] ?? []
        let popupWidth = CGFloat(variants.count) * 50 + 8
        let screenWidth = UIScreen.main.bounds.width
        let clampedX = min(max(longPressAnchor.x - popupWidth / 2, 8), screenWidth - popupWidth - 8)

        ZStack {
            Color.black.opacity(0.1)
                .ignoresSafeArea()
                .onTapGesture { showingLongPress = false }

            VStack(spacing: 0) {
                HStack(spacing: 2) {
                    ForEach(variants, id: \.self) { v in
                        Button {
                            showingLongPress = false
                            handleTap(v)
                        } label: {
                            Text(v)
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(colors.onSurface)
                                .frame(width: 48, height: 44)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(4)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(colors.popupBg)
                        .shadow(color: .black.opacity(0.2), radius: 12, y: 4)
                )
            }
            .position(x: clampedX + popupWidth / 2, y: longPressAnchor.y - 32)
        }
    }

    // MARK: - Input handling

    private func handleTap(_ label: String) {
        haptic(.light)
        if label == "( )" {
            insertParens()
        } else if label == "=" {
            solve()
        } else {
            insert(mapInsert(label))
        }
    }

    private func pushUndo() {
        undoStack.append((expression, cursorPos))
        if undoStack.count > 100 { undoStack.removeFirst() }
    }

    private func undo() {
        guard let (prevExpr, prevPos) = undoStack.popLast() else { return }
        expression = prevExpr
        cursorPos = min(prevPos, prevExpr.count)
    }

    private func insert(_ text: String) {
        pushUndo()
        let pos = min(cursorPos, expression.count)
        let idx = expression.index(expression.startIndex, offsetBy: pos)
        expression.insert(contentsOf: text, at: idx)
        cursorPos = pos + text.count
    }

    private func backspace() {
        pushUndo()
        let pos = min(cursorPos, expression.count)
        guard pos > 0 else { return }
        let idx = expression.index(expression.startIndex, offsetBy: pos - 1)
        expression.remove(at: idx)
        cursorPos = pos - 1
    }

    private func cursorLeft() {
        if cursorPos > 0 { cursorPos -= 1 }
    }

    private func cursorRight() {
        if cursorPos < expression.count { cursorPos += 1 }
    }

    private func insertParens() {
        let opens = expression.filter { $0 == "(" }.count
        let closes = expression.filter { $0 == ")" }.count
        insert(opens > closes ? ")" : "(")
    }

    private func solve() {
        let trimmed = expression.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !isSolving else { return }
        haptic(.medium)
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

    // MARK: - Helpers

    private func btnType(_ label: String, tab: Int) -> BtnType {
        if label.count == 1, label.first?.isNumber == true || label == "." { return .digit }
        if tab == 0 && ["+", "\u{2212}", "\u{00D7}", "\u{00F7}"].contains(label) { return .operator_ }
        if label == "=" { return .accent }
        return .func
    }

    private func bgColor(_ type: BtnType) -> Color {
        switch type {
        case .digit: return colors.digitBg
        case .operator_: return colors.operatorBg
        case .func: return colors.funcBg
        case .accent: return colors.accentBg
        }
    }

    private func fgColor(_ type: BtnType) -> Color {
        switch type {
        case .digit: return colors.digitFg
        case .operator_: return colors.operatorFg
        case .func: return colors.funcFg
        case .accent: return colors.accentFg
        }
    }

    private func fontSize(label: String, type: BtnType) -> CGFloat {
        switch type {
        case .digit, .operator_, .accent: return 22
        case .func: return label.count > 5 ? 12 : 15
        }
    }

    // MARK: - Math label rendering

    @ViewBuilder
    private func mathLabel(_ label: String, fg: Color, size: CGFloat) -> some View {
        switch label {
        // Fractions
        case "a/b": fracLabel("a", "b", fg: fg, size: size)
        case "d/dx": fracLabel("d", "dx", fg: fg, size: size)
        case "\u{2202}/\u{2202}x": fracLabel("\u{2202}", "\u{2202}x", fg: fg, size: size)
        case "d\u{00B2}/dx\u{00B2}": fracLabel("d\u{00B2}", "dx\u{00B2}", fg: fg, size: size)
        case "dy/dx": fracLabel("dy", "dx", fg: fg, size: size)
        // Limits
        case "lim": limLabel("\u{25A1}\u{2192}\u{25A1}", fg: fg, size: size)
        case "lim\u{207A}": limLabel("\u{25A1}\u{2192}\u{25A1}\u{207A}", fg: fg, size: size)
        case "lim\u{207B}": limLabel("\u{25A1}\u{2192}\u{25A1}\u{207B}", fg: fg, size: size)
        // Subscripts
        case "log\u{2082}": subLabel("log", "2", fg: fg, size: size)
        case "log\u{2081}\u{2080}": subLabel("log", "10", fg: fg, size: size)
        case "a\u{2099}": subLabel("a", "n", fg: fg, size: size)
        case "nPr": nprLabel("n", "P", "r", fg: fg, size: size)
        case "nCr": nprLabel("n", "C", "r", fg: fg, size: size)
        // Superscripts
        case "x\u{207F}": supLabel("x", "n", fg: fg, size: size)
        case "e\u{02E3}": supLabel("e", "x", fg: fg, size: size)
        case "10\u{02E3}": supLabel("10", "x", fg: fg, size: size)
        case "x\u{207B}\u{00B9}": supLabel("x", "-1", fg: fg, size: size)
        // Integral with dx
        case "\u{222B}":
            HStack(spacing: 1) {
                Text("\u{222B}").font(.system(size: size * 0.95, weight: .regular))
                Text("dx").font(.system(size: size * 0.55, weight: .medium))
            }.foregroundColor(fg)
        // Square root with placeholder
        case "\u{221A}":
            HStack(spacing: 0) {
                Text("\u{221A}").font(.system(size: size * 0.9, weight: .regular))
                RoundedRectangle(cornerRadius: 1)
                    .stroke(fg.opacity(0.5), style: StrokeStyle(lineWidth: 0.8, dash: [2]))
                    .frame(width: size * 0.45, height: size * 0.45)
            }.foregroundColor(fg)
        // Floor / Ceil
        case "\u{230A}x\u{230B}":
            Text("\u{230A}x\u{230B}").font(.system(size: size * 0.85, weight: .medium)).foregroundColor(fg)
        case "\u{2308}x\u{2309}":
            Text("\u{2308}x\u{2309}").font(.system(size: size * 0.85, weight: .medium)).foregroundColor(fg)
        // Default
        default:
            Text(label)
                .font(.system(size: size, weight: .medium))
                .foregroundColor(fg)
        }
    }

    private func fracLabel(_ num: String, _ den: String, fg: Color, size: CGFloat) -> some View {
        VStack(spacing: 0) {
            Text(num).font(.system(size: size * 0.6, weight: .medium))
            Rectangle().frame(height: 0.8).padding(.horizontal, 4)
            Text(den).font(.system(size: size * 0.6, weight: .medium))
        }
        .foregroundColor(fg)
    }

    private func limLabel(_ sub: String, fg: Color, size: CGFloat) -> some View {
        VStack(spacing: 0) {
            Text("lim").font(.system(size: size * 0.75, weight: .medium))
            Text(sub).font(.system(size: size * 0.45, weight: .regular))
        }
        .foregroundColor(fg)
    }

    private func subLabel(_ base: String, _ sub: String, fg: Color, size: CGFloat) -> some View {
        HStack(alignment: .bottom, spacing: 0) {
            Text(base).font(.system(size: size * 0.8, weight: .medium))
            Text(sub).font(.system(size: size * 0.5, weight: .medium))
                .offset(y: 2)
        }
        .foregroundColor(fg)
    }

    private func supLabel(_ base: String, _ sup: String, fg: Color, size: CGFloat) -> some View {
        HStack(alignment: .top, spacing: 0) {
            Text(base).font(.system(size: size * 0.8, weight: .medium))
            Text(sup).font(.system(size: size * 0.5, weight: .medium))
                .offset(y: -2)
        }
        .foregroundColor(fg)
    }

    private func nprLabel(_ n: String, _ op: String, _ r: String, fg: Color, size: CGFloat) -> some View {
        HStack(alignment: .center, spacing: 0) {
            Text(n).font(.system(size: size * 0.5, weight: .medium)).offset(y: 3)
            Text(op).font(.system(size: size * 0.75, weight: .medium))
            Text(r).font(.system(size: size * 0.5, weight: .medium)).offset(y: 3)
        }
        .foregroundColor(fg)
    }

    private func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

}

// MARK: - Blinking cursor

private struct CursorView: View {
    let color: Color
    let visible: Bool
    var small: Bool = false

    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: 2, height: small ? 16 : 26)
            .opacity(visible ? 1 : 0)
    }
}

private func isSmallChar(_ c: Character) -> Bool {
    guard let v = c.unicodeScalars.first?.value else { return false }
    if v >= 0x2070 && v <= 0x207F { return true } // superscript block
    if v >= 0x2080 && v <= 0x209F { return true } // subscript block
    if v == 0x00B2 || v == 0x00B3 || v == 0x00B9 { return true } // ¹²³
    if v == 0x2032 || v == 0x2033 { return true } // prime ′ ″
    if v == 0x00B0 { return true } // degree °
    if v >= 0x02B0 && v <= 0x02FF { return true } // modifier letters (ˣ etc.)
    return false
}

// MARK: - Button type

private enum BtnType {
    case digit, operator_, `func`, accent
}
