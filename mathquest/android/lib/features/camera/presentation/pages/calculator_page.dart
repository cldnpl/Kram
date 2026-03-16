import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/camera_models.dart';
import '../providers/camera_provider.dart';
import '../widgets/solution_panel.dart';

// ═══════════════════════════════════════════════════════════════════════
// Theme-adaptive color scheme
// ═══════════════════════════════════════════════════════════════════════

class _CalcColors {
  final bool isDark;
  const _CalcColors(this.isDark);

  Color get background => isDark ? const Color(0xFF101624) : const Color(0xFFF2F2F7);
  Color get surface => isDark ? const Color(0xFF161D2E) : Colors.white;
  Color get onSurface => isDark ? Colors.white : const Color(0xFF1C1C1E);
  Color get hint => isDark ? Colors.white30 : const Color(0xFFC7C7CC);
  Color get divider => isDark ? Colors.white10 : const Color(0xFFD1D1D6);

  // Toolbar
  Color get toolbarBg => isDark ? const Color(0xFF1A2238) : const Color(0xFFE5E5EA);
  Color get toolbarFg => isDark ? Colors.white70 : const Color(0xFF636366);
  Color get toolbarActiveBg => isDark ? Colors.white : const Color(0xFF1C1C1E);
  Color get toolbarActiveFg => isDark ? Colors.black : Colors.white;

  // Tabs
  Color get tabSelectedBg => isDark ? const Color(0xFF7C6BF0) : const Color(0xFF1C1C1E);
  Color get tabSelectedFg => Colors.white;
  Color get tabBg => isDark ? const Color(0xFF1E2740) : const Color(0xFFE5E5EA);
  Color get tabFg => isDark ? Colors.white54 : const Color(0xFF636366);
  Color get tabBorder => isDark ? Colors.white.withAlpha(15) : const Color(0xFFD1D1D6);

  // Grid buttons
  Color get digitBg => isDark ? const Color(0xFF1A2238) : Colors.white;
  Color get digitFg => isDark ? Colors.white : const Color(0xFF1C1C1E);
  Color get funcBg => isDark ? const Color(0xFF1E2740) : const Color(0xFFE8E8ED);
  Color get funcFg => isDark ? const Color(0xFFB0BFE0) : const Color(0xFF3C3C43);
  Color get operatorBg => isDark ? const Color(0xFF2A2460) : const Color(0xFFE8E8ED);
  Color get operatorFg => isDark ? const Color(0xFFB4A7FF) : const Color(0xFF007AFF);
  Color get destructiveBg => isDark ? const Color(0xFF2D1C1C) : const Color(0xFFFFF0F0);
  Color get destructiveFg => isDark ? const Color(0xFFFF6B6B) : const Color(0xFFFF3B30);
  Color get accentBg => isDark ? const Color(0xFF7C6BF0) : const Color(0xFF007AFF);
  Color get accentFg => Colors.white;

  // Popup
  Color get popupBg => isDark ? const Color(0xFF2A3350) : Colors.white;
  Color get popupBorder => isDark ? Colors.white12 : const Color(0xFFD1D1D6);

  // Red dot
  Color get redDot => const Color(0xFFFF3B30);

  // Solve button
  Color get solveGrad1 => isDark ? const Color(0xFF7C6BF0) : const Color(0xFF007AFF);
  Color get solveGrad2 => isDark ? const Color(0xFF5B4ACF) : const Color(0xFF0056D6);
  Color get solveDisabled => isDark ? const Color(0xFF1A2035) : const Color(0xFFD1D1D6);
}

// ═══════════════════════════════════════════════════════════════════════
// Button grid data
// ═══════════════════════════════════════════════════════════════════════

const _tabLabels = ['+−×÷', 'f(x) e\nlog ln', 'sin cos\ntan cot', 'lim dx\n∫ Σ ∞'];

// Tab 0: Numbers & Operators  (6 cols × 4 rows)
const _tab0 = [
  ['( )', '>', '7', '8', '9', '÷'],
  ['a/b', '√', '4', '5', '6', '×'],
  ['xⁿ', 'x', '1', '2', '3', '−'],
  ['π', '%', '0', '.', '=', '+'],
];

// Tab 1: Functions  (6 cols × 4 rows)
const _tab1 = [
  ['|x|', 'n!', 'log', 'log₂', 'log₁₀', 'ln'],
  ['⌊x⌋', '⌈x⌉', 'exp', 'eˣ', '10ˣ', 'x⁻¹'],
  ['nPr', 'nCr', 'GCD', 'LCM', 'mod', '±'],
  ['min', 'max', 'sign', '∞', 'i', 'e'],
];

// Tab 2: Trig  (7 cols × 4 rows — horizontally scrollable)
const _tab2 = [
  ['rad', 'sin', 'cos', 'tan', 'cot', 'sec', 'csc'],
  ['°', 'arcsin', 'arccos', 'arctan', 'arccot', 'arcsec', 'arccsc'],
  ['°′', 'sinh', 'cosh', 'tanh', 'coth', 'sech', 'csch'],
  ['°′″', 'arsinh', 'arcosh', 'artanh', 'arcoth', 'arsech', 'arcsch'],
];

// Tab 3: Calculus  (5 cols × 4 rows)
const _tab3 = [
  ['lim', 'd/dx', '∫', 'dy/dx', 'aₙ'],
  ['lim⁺', '∂/∂x', '∫∫', 'dx', 'Σ'],
  ['lim⁻', 'd²/dx²', '∮', 'dy', '∏'],
  ['∞', '∇', '∂', 'y′', '→'],
];

// ABC mode  (8 cols × 4 rows)
const _abcGrid = [
  ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'],
  ['i', 'j', 'k', 'l', 'm', 'n', 'o', 'p'],
  ['q', 'r', 's', 't', 'u', 'v', 'w', 'x'],
  ['y', 'z', 'α', 'β', 'θ', 'γ', 'δ', 'φ'],
];

// Long-press variants (buttons with red dot)
const _longPress = <String, List<String>>{
  '( )': ['(', ')', '[', ']', '{', '}'],
  '>': ['<', '≥', '≤', '≠', '≈', '≡'],
  '√': ['√', '³√', '⁴√', 'ⁿ√'],
  'xⁿ': ['^', '²', '³', '⁴', '⁻¹'],
  'x': ['x', 'y', 'z', 't', 'n', 'k'],
  'π': ['π', 'τ', 'ω', 'λ', 'μ', 'σ'],
  '%': ['%', 'mod'],
};

// Insert-text mapping (label → text to insert)
String _mapInsert(String label) {
  switch (label) {
    // Auto-balance handled separately
    case '( )':
      return '('; // fallback; real logic in _insertParens
    // Operators
    case '÷': return '÷';
    case '×': return '×';
    case '−': return '-';
    case 'a/b': return '/';
    // Powers / roots
    case 'xⁿ': return '^';
    case 'x⁻¹': return '⁻¹';
    case '²': return '²';
    case '³': return '³';
    case '⁴': return '⁴';
    case '⁻¹': return '⁻¹';
    case '√': return '√(';
    case '³√': return '³√(';
    case '⁴√': return '⁴√(';
    case 'ⁿ√': return 'ⁿ√(';
    // Functions (append '(')
    case 'sin': case 'cos': case 'tan': case 'cot': case 'sec': case 'csc':
    case 'arcsin': case 'arccos': case 'arctan': case 'arccot': case 'arcsec': case 'arccsc':
    case 'sinh': case 'cosh': case 'tanh': case 'coth': case 'sech': case 'csch':
    case 'arsinh': case 'arcosh': case 'artanh': case 'arcoth': case 'arsech': case 'arcsch':
    case 'log': case 'ln': case 'log₂': case 'log₁₀': case 'exp':
    case 'GCD': case 'LCM': case 'min': case 'max': case 'sign':
    case 'nPr': case 'nCr':
      return '$label(';
    case 'eˣ': return 'e^(';
    case '10ˣ': return '10^(';
    case 'n!': return '!';
    case '|x|': return '|';
    case '⌊x⌋': return '⌊';
    case '⌈x⌉': return '⌈';
    case 'mod': return ' mod ';
    case '±': return '±';
    // Calculus
    case 'lim': return 'lim(';
    case 'lim⁺': return 'lim⁺(';
    case 'lim⁻': return 'lim⁻(';
    case 'd/dx': return 'd/dx(';
    case '∂/∂x': return '∂/∂x(';
    case 'd²/dx²': return 'd²/dx²(';
    case '∫': return '∫(';
    case '∫∫': return '∫∫(';
    case '∮': return '∮(';
    case 'Σ': return 'Σ(';
    case '∏': return '∏(';
    case 'aₙ': return 'aₙ';
    case 'dy/dx': return 'dy/dx';
    case 'y′': return "y'";
    case '∇': return '∇';
    case '∂': return '∂';
    case 'rad': return 'rad';
    case '°': return '°';
    case '°′': return '°′';
    case '°′″': return '°′″';
    default:
      return label;
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Calculator Page
// ═══════════════════════════════════════════════════════════════════════

class CalculatorPage extends StatefulWidget {
  final CameraProvider provider;
  const CalculatorPage({super.key, required this.provider});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  bool _isSolving = false;
  int _selectedTab = 0;
  bool _abcMode = false;

  // Undo stack: each entry is a snapshot of (text, cursorPos) before an edit
  final List<(String, int)> _undoStack = [];

  CameraProvider get _provider => widget.provider;

  @override
  void initState() {
    super.initState();
    _provider.addListener(_onProviderChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _provider.removeListener(_onProviderChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onProviderChanged() {
    if (mounted) setState(() {});
  }

  // ── Text manipulation ──────────────────────────────────────────────

  void _pushUndo() {
    final sel = _controller.selection;
    final pos = (sel.isValid && sel.baseOffset >= 0)
        ? sel.baseOffset
        : _controller.text.length;
    _undoStack.add((_controller.text, pos));
    // Keep stack bounded
    if (_undoStack.length > 100) _undoStack.removeAt(0);
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    final (text, pos) = _undoStack.removeLast();
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: pos.clamp(0, text.length)),
    );
    _focusNode.requestFocus();
  }

  void _insert(String text) {
    _pushUndo();
    final sel = _controller.selection;
    final pos = (sel.isValid && sel.baseOffset >= 0)
        ? sel.baseOffset
        : _controller.text.length;
    final cur = _controller.text;
    _controller.value = TextEditingValue(
      text: cur.substring(0, pos) + text + cur.substring(pos),
      selection: TextSelection.collapsed(offset: pos + text.length),
    );
    _focusNode.requestFocus();
  }

  void _backspace() {
    _pushUndo();
    final sel = _controller.selection;
    final pos = (sel.isValid && sel.baseOffset >= 0)
        ? sel.baseOffset
        : _controller.text.length;
    if (pos > 0) {
      final cur = _controller.text;
      _controller.value = TextEditingValue(
        text: cur.substring(0, pos - 1) + cur.substring(pos),
        selection: TextSelection.collapsed(offset: pos - 1),
      );
    }
    _focusNode.requestFocus();
  }

  void _cursorLeft() {
    final pos = _controller.selection.isValid
        ? _controller.selection.baseOffset
        : _controller.text.length;
    if (pos > 0) {
      _controller.selection = TextSelection.collapsed(offset: pos - 1);
    }
    _focusNode.requestFocus();
  }

  void _cursorRight() {
    final pos = _controller.selection.isValid
        ? _controller.selection.baseOffset
        : _controller.text.length;
    if (pos < _controller.text.length) {
      _controller.selection = TextSelection.collapsed(offset: pos + 1);
    }
    _focusNode.requestFocus();
  }

  void _insertParens() {
    final text = _controller.text;
    final opens = '('.allMatches(text).length;
    final closes = ')'.allMatches(text).length;
    _insert(opens > closes ? ')' : '(');
  }

  void _clear() {
    _controller.clear();
    _focusNode.requestFocus();
  }

  // ── Button tap handler ─────────────────────────────────────────────

  void _handleTap(String label) {
    HapticFeedback.lightImpact();
    if (label == '( )') {
      _insertParens();
    } else if (label == '=') {
      _solve();
    } else {
      _insert(_mapInsert(label));
    }
  }

  // ── Solve ──────────────────────────────────────────────────────────

  Future<void> _solve() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSolving) return;
    HapticFeedback.mediumImpact();
    setState(() => _isSolving = true);
    try {
      await _provider.solveFromText(text);
    } finally {
      if (mounted) setState(() => _isSolving = false);
    }
  }

  // ── Long-press popup ───────────────────────────────────────────────

  void _showLongPressPopup(
      BuildContext btnContext, String label, List<String> variants) {
    final box = btnContext.findRenderObject() as RenderBox?;
    if (box == null) return;
    final pos = box.localToGlobal(Offset.zero);
    final size = box.size;
    final colors = _CalcColors(Theme.of(context).brightness == Brightness.dark);
    HapticFeedback.mediumImpact();

    final screenWidth = MediaQuery.sizeOf(context).width;
    final popupWidth = variants.length * 50.0 + 8;
    var left = pos.dx + size.width / 2 - popupWidth / 2;
    left = left.clamp(8.0, screenWidth - popupWidth - 8);

    showDialog(
      context: context,
      barrierColor: Colors.black12,
      builder: (dCtx) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.pop(dCtx),
              behavior: HitTestBehavior.opaque,
            ),
          ),
          Positioned(
            left: left,
            top: pos.dy - 56,
            child: Material(
              elevation: 12,
              borderRadius: BorderRadius.circular(12),
              color: colors.popupBg,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.popupBorder, width: 0.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: variants.map((v) {
                    return InkWell(
                      onTap: () {
                        Navigator.pop(dCtx);
                        _handleTap(v);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 48,
                        height: 44,
                        alignment: Alignment.center,
                        child: Text(
                          v,
                          style: TextStyle(
                            color: colors.onSurface,
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = _CalcColors(isDark);
    final showSolution =
        _provider.state == CameraState.success && _provider.solution != null;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: colors.onSurface,
        systemOverlayStyle:
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        title: Text('Calculator',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: colors.onSurface)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, size: 22),
          onPressed: () {
            if (showSolution) _provider.reset();
            Navigator.pop(context);
          },
        ),
      ),
      body: showSolution
          ? SolutionPanel(
              response: _provider.solution!,
              visibleSteps: _provider.visibleSteps,
              onClose: () {
                _provider.reset();
                setState(() {});
              },
            )
          : SafeArea(child: _buildCalculator(colors)),
    );
  }

  Widget _buildCalculator(_CalcColors c) {
    return Column(
      children: [
        // ── Expression area ──
        Expanded(child: _buildExpression(c)),
        // ── Status ──
        _buildStatus(c),
        // ── Toolbar ──
        _buildToolbar(c),
        const SizedBox(height: 6),
        // ── Category tabs ──
        if (!_abcMode) _buildTabs(c),
        if (!_abcMode) const SizedBox(height: 6),
        // ── Button grid ──
        _buildGrid(c),
        // ── Solve button ──
        _buildSolveButton(c),
      ],
    );
  }

  // ── Expression ─────────────────────────────────────────────────────

  Widget _buildExpression(_CalcColors c) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.divider, width: 0.5),
      ),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        readOnly: true,
        showCursor: true,
        cursorColor: c.accentBg,
        maxLines: null,
        style: TextStyle(
          color: c.onSurface,
          fontSize: 24,
          fontWeight: FontWeight.w300,
          height: 1.4,
        ),
        decoration: InputDecoration(
          hintText: 'Type a math problem...',
          hintStyle: TextStyle(color: c.hint, fontSize: 20, fontWeight: FontWeight.w300),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  // ── Status ─────────────────────────────────────────────────────────

  Widget _buildStatus(_CalcColors c) {
    if (_isSolving || _provider.state == CameraState.processing) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(color: c.accentBg, strokeWidth: 2),
        ),
      );
    }
    if (_provider.state == CameraState.error &&
        _provider.errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
        child: Text(
          _provider.errorMessage!,
          style: TextStyle(color: c.destructiveFg, fontSize: 13),
          textAlign: TextAlign.center,
        ),
      );
    }
    return const SizedBox.shrink();
  }

  // ── Toolbar ────────────────────────────────────────────────────────

  Widget _buildToolbar(_CalcColors c) {
    Widget toolBtn(IconData icon, VoidCallback onTap, {bool active = false}) {
      return Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: 40,
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 20,
              color: active ? c.toolbarActiveBg : c.toolbarFg,
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: c.toolbarBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // ABC toggle
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _abcMode = !_abcMode),
              child: Container(
                height: 36,
                margin: const EdgeInsets.symmetric(vertical: 2),
                decoration: BoxDecoration(
                  color: _abcMode ? c.toolbarActiveBg : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  'abc',
                  style: TextStyle(
                    color: _abcMode ? c.toolbarActiveFg : c.toolbarFg,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          toolBtn(Icons.history, _undo),
          toolBtn(Icons.arrow_back, _cursorLeft),
          toolBtn(Icons.arrow_forward, _cursorRight),
          // Solve icon
          Expanded(
            child: GestureDetector(
              onTap: _solve,
              child: Container(
                height: 40,
                alignment: Alignment.center,
                child: Icon(Icons.subdirectory_arrow_left, size: 20, color: c.accentBg),
              ),
            ),
          ),
          // Backspace (long-press to clear all)
          Expanded(
            child: GestureDetector(
              onTap: _backspace,
              onLongPress: _clear,
              child: Container(
                height: 40,
                alignment: Alignment.center,
                child: Icon(Icons.backspace_outlined, size: 20, color: c.toolbarFg),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Category tabs ──────────────────────────────────────────────────

  Widget _buildTabs(_CalcColors c) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: List.generate(4, (i) {
          final sel = _selectedTab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = i),
              child: Container(
                height: 42,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: sel ? c.tabSelectedBg : c.tabBg,
                  borderRadius: BorderRadius.circular(10),
                  border: sel ? null : Border.all(color: c.tabBorder, width: 0.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  _tabLabels[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: sel ? c.tabSelectedFg : c.tabFg,
                    fontSize: 11,
                    fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Button grid ────────────────────────────────────────────────────

  Widget _buildGrid(_CalcColors c) {
    if (_abcMode) return _buildAbcGrid(c);
    switch (_selectedTab) {
      case 0:
        return _buildStandardGrid(_tab0, c, cols: 6);
      case 1:
        return _buildStandardGrid(_tab1, c, cols: 6);
      case 2:
        return _buildTrigGrid(c);
      case 3:
        return _buildStandardGrid(_tab3, c, cols: 5);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStandardGrid(List<List<String>> rows, _CalcColors c,
      {required int cols}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: rows.map((row) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: row.map((label) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: _GridButton(
                      label: label,
                      type: _btnType(label, _selectedTab),
                      colors: c,
                      hasLongPress: _longPress.containsKey(label),
                      onTap: () => _handleTap(label),
                      onLongPress: _longPress.containsKey(label)
                          ? (ctx) => _showLongPressPopup(
                              ctx, label, _longPress[label]!)
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTrigGrid(_CalcColors c) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: SizedBox(
        height: _tab2.length * 50.0,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _tab2.map((row) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: row.map((label) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: SizedBox(
                      width: 78,
                      child: _GridButton(
                        label: label,
                        type: _BtnType.func,
                        colors: c,
                        hasLongPress: false,
                        onTap: () => _handleTap(label),
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          }).toList(),
        ),
      ),
      ),
    );
  }

  Widget _buildAbcGrid(_CalcColors c) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: _abcGrid.map((row) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: row.map((label) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: _GridButton(
                      label: label,
                      type: _BtnType.digit,
                      colors: c,
                      hasLongPress: false,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _insert(label);
                      },
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Solve button ───────────────────────────────────────────────────

  Widget _buildSolveButton(_CalcColors c) {
    final enabled = _controller.text.trim().isNotEmpty && !_isSolving;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: enabled
                ? LinearGradient(colors: [c.solveGrad1, c.solveGrad2])
                : null,
            color: enabled ? null : c.solveDisabled,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: enabled ? _solve : null,
              borderRadius: BorderRadius.circular(14),
              child: Center(
                child: _isSolving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : Text(
                        'Solve',
                        style: TextStyle(
                          color: enabled ? Colors.white : c.hint,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Button type classification ─────────────────────────────────────

  _BtnType _btnType(String label, int tab) {
    // Digits
    if (RegExp(r'^[0-9.]$').hasMatch(label)) return _BtnType.digit;
    // Operators on tab 0
    if (tab == 0 && ['+', '−', '×', '÷'].contains(label)) {
      return _BtnType.operator;
    }
    // Equals
    if (label == '=') return _BtnType.accent;
    // Everything else is a function key
    return _BtnType.func;
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Button types
// ═══════════════════════════════════════════════════════════════════════

enum _BtnType { digit, operator, func, accent }

// ═══════════════════════════════════════════════════════════════════════
// Grid Button Widget
// ═══════════════════════════════════════════════════════════════════════

class _GridButton extends StatelessWidget {
  final String label;
  final _BtnType type;
  final _CalcColors colors;
  final bool hasLongPress;
  final VoidCallback onTap;
  final void Function(BuildContext)? onLongPress;

  const _GridButton({
    required this.label,
    required this.type,
    required this.colors,
    required this.hasLongPress,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress != null ? () => onLongPress!(context) : null,
      child: Material(
        color: _bg,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: _fg,
                    fontSize: _fontSize,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                // Red dot indicator for long-press buttons
                if (hasLongPress)
                  Positioned(
                    left: 5,
                    bottom: 5,
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: colors.redDot,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color get _bg {
    switch (type) {
      case _BtnType.digit:
        return colors.digitBg;
      case _BtnType.operator:
        return colors.operatorBg;
      case _BtnType.func:
        return colors.funcBg;
      case _BtnType.accent:
        return colors.accentBg;
    }
  }

  Color get _fg {
    switch (type) {
      case _BtnType.digit:
        return colors.digitFg;
      case _BtnType.operator:
        return colors.operatorFg;
      case _BtnType.func:
        return colors.funcFg;
      case _BtnType.accent:
        return colors.accentFg;
    }
  }

  double get _fontSize {
    switch (type) {
      case _BtnType.digit:
        return 22;
      case _BtnType.operator:
        return 22;
      case _BtnType.accent:
        return 22;
      case _BtnType.func:
        return label.length > 5 ? 12 : 15;
    }
  }
}

