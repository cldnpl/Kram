import 'package:flutter/material.dart';
import '../../data/camera_models.dart';
import '../providers/camera_provider.dart';
import '../widgets/solution_panel.dart';

class CalculatorPage extends StatefulWidget {
  final CameraProvider provider;

  const CalculatorPage({super.key, required this.provider});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  String _expression = '';
  bool _isSolving = false;
  int _funcPage = 0; // 0 = basic, 1 = advanced, 2 = symbols

  CameraProvider get _provider => widget.provider;

  @override
  void initState() {
    super.initState();
    _provider.addListener(_onProviderChanged);
  }

  // ── Function button pages ──────────────────────────────────────────
  static const _pageLabels = ['Basic', 'Adv', 'Sym'];

  static const _funcPages = <List<List<String>>>[
    // Page 0 – Basic
    [
      ['sin', 'cos', 'tan', '(', ')'],
      ['log', 'ln', '√', '^', 'n!'],
      ['π', 'e', 'x²', 'x³', '|x|'],
    ],
    // Page 1 – Advanced
    [
      ['sin⁻¹', 'cos⁻¹', 'tan⁻¹', '(', ')'],
      ['sinh', 'cosh', 'tanh', 'log₂', '10ˣ'],
      ['eˣ', 'x⁻¹', '³√', 'ⁿ√', '%'],
    ],
    // Page 2 – Symbols
    [
      ['∫', 'Σ', 'lim', 'd/dx', '∂'],
      ['∞', '≤', '≥', '≠', '≈'],
      ['±', '°', 'mod', '→', '='],
    ],
  ];

  // ── Digit pad (always visible) ────────────────────────────────────
  static const _digitRows = <List<String>>[
    ['7', '8', '9', '÷', '⌫'],
    ['4', '5', '6', '×', 'AC'],
    ['1', '2', '3', '-', '(  )'],
    ['0', '.', ',', '+', '='],
  ];

  // ── Input mapping ─────────────────────────────────────────────────
  String _mapInput(String label) {
    switch (label) {
      case 'sin':
      case 'cos':
      case 'tan':
      case 'sinh':
      case 'cosh':
      case 'tanh':
      case 'log':
      case 'ln':
        return '$label(';
      case 'sin⁻¹':
        return 'arcsin(';
      case 'cos⁻¹':
        return 'arccos(';
      case 'tan⁻¹':
        return 'arctan(';
      case 'log₂':
        return 'log₂(';
      case '10ˣ':
        return '10^(';
      case 'eˣ':
        return 'e^(';
      case 'x⁻¹':
        return '⁻¹';
      case '√':
        return '√(';
      case '³√':
        return '³√(';
      case 'ⁿ√':
        return 'ⁿ√(';
      case 'x²':
        return '²';
      case 'x³':
        return '³';
      case 'n!':
        return '!';
      case '|x|':
        return '|';
      case 'd/dx':
        return 'd/dx(';
      case '∫':
        return '∫(';
      case 'Σ':
        return 'Σ(';
      case 'lim':
        return 'lim(';
      case '÷':
        return '÷';
      case '×':
        return '×';
      default:
        return label;
    }
  }

  // ── Actions ───────────────────────────────────────────────────────
  void _onTap(String label) {
    if (label == 'AC') {
      setState(() => _expression = '');
      return;
    }
    if (label == '⌫') {
      if (_expression.isNotEmpty) {
        setState(() =>
            _expression = _expression.substring(0, _expression.length - 1));
      }
      return;
    }
    if (label == '=') {
      _solve();
      return;
    }
    if (label == '(  )') {
      final opens = _expression.split('(').length - 1;
      final closes = _expression.split(')').length - 1;
      setState(() => _expression += opens > closes ? ')' : '(');
      return;
    }
    setState(() => _expression += _mapInput(label));
  }

  Future<void> _solve() async {
    if (_expression.trim().isEmpty || _isSolving) return;
    setState(() => _isSolving = true);
    try {
      await _provider.solveFromText(_expression.trim());
    } finally {
      if (mounted) setState(() => _isSolving = false);
    }
  }

  void _onProviderChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _provider.removeListener(_onProviderChanged);
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final showSolution =
        _provider.state == CameraState.success && _provider.solution != null;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1220),
        foregroundColor: Colors.white,
        title: const Text('Scientific Calculator'),
        leading: IconButton(
          icon: const Icon(Icons.close),
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
          : _buildCalculator(context),
    );
  }

  Widget _buildCalculator(BuildContext context) {
    final metrics = _CalcLayoutMetrics.fromContext(context);
    return Column(
      children: [
        // ── Expression display ──
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: metrics.compact ? 16 : 20,
            vertical: metrics.compact ? 10 : 12,
          ),
          constraints: BoxConstraints(minHeight: metrics.expressionMinHeight),
          child: Align(
            alignment: Alignment.bottomRight,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: Text(
                _expression.isEmpty ? '0' : _expression,
                style: TextStyle(
                  color: _expression.isEmpty ? Colors.white38 : Colors.white,
                  fontSize: metrics.expressionFontSize,
                  fontWeight: FontWeight.w300,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ),

        // ── Status ──
        if (_isSolving || _provider.state == CameraState.processing)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            ),
          ),
        if (_provider.state == CameraState.error &&
            _provider.errorMessage != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              _provider.errorMessage!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),

        // ── Page tabs ──
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: metrics.compact ? 6 : 8,
            vertical: 4,
          ),
          child: Row(
            children: List.generate(_pageLabels.length, (i) {
              final selected = _funcPage == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _funcPage = i),
                  child: Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: metrics.compact ? 2 : 3,
                    ),
                    padding: EdgeInsets.symmetric(
                      vertical: metrics.compact ? 6 : 7,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFF6B5CE7)
                          : const Color(0xFF1A2438),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _pageLabels[i],
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: metrics.tabFontSize,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),

        // ── Function rows (swappable) ──
        ..._funcPages[_funcPage].map(
          (row) => _buildButtonRow(row, isFunc: true, metrics: metrics),
        ),

        SizedBox(height: metrics.compact ? 1 : 2),

        // ── Digit rows (fixed) ──
        ..._digitRows.map(
          (row) => _buildButtonRow(row, isFunc: false, metrics: metrics),
        ),

        // ── Solve button ──
        Padding(
          padding: EdgeInsets.fromLTRB(
            metrics.compact ? 10 : 12,
            6,
            metrics.compact ? 10 : 12,
            metrics.compact ? 14 : 20,
          ),
          child: SizedBox(
            width: double.infinity,
            height: metrics.solveButtonHeight,
            child: FilledButton(
              onPressed:
                  (_expression.trim().isNotEmpty && !_isSolving) ? _solve : null,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF6B5CE7),
                disabledBackgroundColor: const Color(0xFF2A2450),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _isSolving
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text(
                      'Solve',
                      style: TextStyle(
                        fontSize: metrics.solveFontSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Row builder ───────────────────────────────────────────────────
  Widget _buildButtonRow(
    List<String> labels, {
    required bool isFunc,
    required _CalcLayoutMetrics metrics,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: metrics.rowHorizontalPadding,
        vertical: metrics.rowVerticalPadding,
      ),
      child: Row(
        children: labels.map((label) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.all(metrics.cellPadding),
              child: _CalcButton(
                label: label,
                onTap: () => _onTap(label),
                style: _buttonStyle(label, isFunc),
                fontScale: metrics.buttonFontScale,
                height: metrics.buttonHeight,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  _ButtonStyle _buttonStyle(String label, bool isFunc) {
    if (label == 'AC' || label == '⌫') {
      return const _ButtonStyle(Color(0xFF2D1F1F), Colors.redAccent, 14);
    }
    if (label == '=') {
      return const _ButtonStyle(Color(0xFF6B5CE7), Colors.white, 20);
    }
    if (['÷', '×', '-', '+', '^'].contains(label)) {
      return const _ButtonStyle(Color(0xFF6B5CE7), Colors.white, 20);
    }
    if (isFunc) {
      return const _ButtonStyle(Color(0xFF1A2438), Color(0xFFB8C4E0), 13);
    }
    // digits & others
    return const _ButtonStyle(Color(0xFF141E35), Colors.white, 18);
  }
}

class _ButtonStyle {
  final Color bg;
  final Color fg;
  final double fontSize;
  const _ButtonStyle(this.bg, this.fg, this.fontSize);
}

class _CalcLayoutMetrics {
  final bool compact;
  final double expressionMinHeight;
  final double expressionFontSize;
  final double tabFontSize;
  final double rowHorizontalPadding;
  final double rowVerticalPadding;
  final double cellPadding;
  final double buttonHeight;
  final double buttonFontScale;
  final double solveButtonHeight;
  final double solveFontSize;

  const _CalcLayoutMetrics({
    required this.compact,
    required this.expressionMinHeight,
    required this.expressionFontSize,
    required this.tabFontSize,
    required this.rowHorizontalPadding,
    required this.rowVerticalPadding,
    required this.cellPadding,
    required this.buttonHeight,
    required this.buttonFontScale,
    required this.solveButtonHeight,
    required this.solveFontSize,
  });

  factory _CalcLayoutMetrics.fromContext(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final compact = size.height < 760 || size.width < 370;
    return _CalcLayoutMetrics(
      compact: compact,
      expressionMinHeight: compact ? 74 : 90,
      expressionFontSize: compact ? 28 : 32,
      tabFontSize: compact ? 12 : 13,
      rowHorizontalPadding: compact ? 4 : 6,
      rowVerticalPadding: compact ? 1.5 : 2,
      cellPadding: compact ? 1.5 : 2,
      buttonHeight: compact ? 38 : 44,
      buttonFontScale: compact ? 0.9 : 1,
      solveButtonHeight: compact ? 46 : 50,
      solveFontSize: compact ? 16 : 17,
    );
  }
}

class _CalcButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final _ButtonStyle style;
  final double fontScale;
  final double height;

  const _CalcButton({
    required this.label,
    required this.onTap,
    required this.style,
    required this.fontScale,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: style.bg,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          height: height,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: style.fg,
                fontSize: style.fontSize * fontScale,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}
