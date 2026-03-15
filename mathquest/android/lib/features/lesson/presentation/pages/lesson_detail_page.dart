import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../core/l10n/app_locale.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/network/dio_client.dart';

class LessonDetailPage extends StatefulWidget {
  const LessonDetailPage({super.key, required this.lessonId});

  final String lessonId;

  @override
  State<LessonDetailPage> createState() => _LessonDetailPageState();
}

class _LessonDetailPageState extends State<LessonDetailPage> {
  static const _lessonAccentColor = Color(0xFF6650A4);
  final DioClient _dio = DioClient();
  Map<String, dynamic>? _detail;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final lang = prefs.getString('settings_language') ?? 'en';
      final res = await _dio.dio.get(
        'lessons/${widget.lessonId}?lang=$lang',
        options: Options(headers: {'Authorization': 'Bearer mock-dev-token'}),
      );
      setState(() {
        _detail = Map<String, dynamic>.from(res.data as Map);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_detail?['title'] ?? AppLocale.tr('lesson')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('${AppLocale.tr('error')}: $_error', textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton(onPressed: _load, child: Text(AppLocale.tr('retry'))),
                    ],
                  ),
                )
              : _detail == null
                  ? Center(child: Text(AppLocale.tr('no_content')))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_detail!['content_json'] != null &&
                              _detail!['content_json'] is Map &&
                              (_detail!['content_json'] as Map).containsKey('intro')) ...[
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: _buildIntroBlocks(
                                  _normalizeLegacyDiagramReplacements(
                                    widget.lessonId,
                                    (_detail!['content_json'] as Map)['intro'] as String? ?? '',
                                  ),
                                ),
                              ),
                            ),
                          ],
                          Padding(
                            padding: const EdgeInsets.only(top: 24),
                            child: SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: () {},
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: Text(AppLocale.tr('practice')),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
  // Dark purple (same as gradient) for formula boxes.
  static const _formulaBoxColor = Color(0xFF6650A4);
  // Light purple for example boxes.
  static const _exampleBoxColor = Color(0xFF9980F0);
  static const Map<String, List<String>> _legacyLessonImages = {
    '1': ['naturalNumbers.png'],
    '1-0': ['naturalNumbers.png'],
    '1-1': ['integersNumbers.png'],
    '1-2': ['rationalNumbers.jpg'],
    '2': ['powerProperties.png'],
    '2-0': ['pedmas.png'],
    '2-1': ['powerProperties.png'],
    '2-2': ['sqrtProperties.png'],
    '3': ['bodmas.jpg'],
    '3-0': ['pedmas.png', 'bodmas.jpg'],
    '4': ['divisors.svg'],
    '4-0': ['multiples.jpg'],
    '4-1': ['divisors.svg'],
    '4-2': ['gcd.png'],
    '4-3': ['multiples.jpg'],
    '5': ['equivalentFractions.png'],
    '5-0': ['equivalentFractions.png'],
    '5-1': ['fractionOperations.jpg'],
    '5-2': ['fractionToPercent.png'],
    '5-3': ['proportions.png'],
    '6': ['operationsPolynomials.png'],
    '6-0': ['operationsPolynomials.png'],
    '6-1': ['degreeOfAPolynomial.jpg'],
    '6-2': ['specialProductsPolynomials.jpg'],
    '7': ['greatestCommonFactoring.jpg'],
    '7-0': ['greatestCommonFactoring.jpg'],
    '7-1': ['ruffiniRule.jpg'],
    '7-2': ['specialProductsPolynomials.jpg'],
    '8': ['firstDegreeEquations.gif'],
    '8-0': ['firstDegreeEquations.gif'],
    '8-1': ['firstDegreeEquations.gif'],
    '9': ['completeAndIncompleteQuadratics.webp'],
    '9-0': ['completeAndIncompleteQuadratics.webp'],
    '9-1': ['discriminant.png'],
    '9-2': ['completeAndIncompleteQuadratics.webp'],
    '10': ['substitutionSystems.jpg'],
    '10-0': ['substitutionSystems.jpg'],
    '10-1': ['comparisonSystems.jpg'],
    '10-2': ['cramerSystems.jpg'],
    '11': ['triangles.png'],
    '11-0': ['segment.png'],
    '11-1': ['angles.png'],
    '11-2': ['triangles.png'],
    '11-3': ['quadrilaters.png'],
    '11-4': ['polygons.png'],
    '12': ['criteriaForTriangles.png'],
    '12-0': ['criteriaForTriangles.png'],
    '12-1': ['pythagoraTheorems.png', 'euclidTheorem.gif'],
    '13': ['circumference.png'],
    '13-0': ['circumference.png'],
    '13-1': ['area.png'],
    '13-2': ['tangents.png'],
    '13-3': ['secants.png'],
    '14': ['prisms.jpg'],
    '14-0': ['prisms.jpg'],
    '14-1': ['pyramids.jpg'],
    '14-2': ['cylinders.png'],
    '14-3': ['cones.png'],
    '14-4': ['spheres.jpg'],
    '15': ['unitCircle.webp'],
    '15-0': ['unitCircle.webp'],
    '15-1': ['sineCosineTangent.avif'],
    '15-2': ['lawOfSinesCosines.jpeg'],
    '16': ['domain.png'],
    '16-0': ['realFunctionsofArEALvARIABLE.gif'],
    '16-2': ['domain.png'],
    '18-0': ['equationsAndInequalitiesvithExandLogx.png'],
    '17-0': ['symmetriesEvenOdd.jpg'],
    '17-1': ['intercepts.jpg'],
    '17-2': ['signStudy.png'],
    '19-0': ['theLine.svg'],
    '19-1': ['theCircle.png'],
    '19-2': ['theParabola.jpg'],
    '19-3': ['theEllipse.png'],
    '19-4': ['theHyperbola.png'],
    '20-0': ['finiteAndInfiniteLimits.png'],
    '20-1': ['indeterminateForms.png'],
    '20-2': ['asymptotes.png'],
    '21-0': ['differenceQuotient.jpg'],
    '21-1': ['geometricMeaning.png'],
    '22-0': ['powerRule.png'],
    '22-1': ['productRule.png'],
    '22-2': ['quotientRule.webp'],
    '22-3': ['chainRule.png'],
    '23-0': ['maximaAndMinima.png'],
    '23-1': ['pointsOfInflections.png'],
    '24-0': ['primitiveFunctions.svg'],
    '24-1': ['integrationRules.png'],
    '25-0': ['integrationSubstitution.jpg'],
    '25-1': ['integrationParts.png'],
    '26-0': ['areaUnderACurve.jpg'],
    '26-1': ['fundamentalTheoremsofCalculus.png'],
    '27-0': ['calculationOfVolumes.jpg'],
    '27-1': ['areasOfPlaneFigures.jpg'],
  };
  static const Set<String> _lessonsWithoutReplacementImages = {
    '16-1', '17', '18', '19', '20', '21', '22', '23', '24', '25', '26', '27',
  };

  List<Widget> _buildIntroBlocks(String intro) {
    const boxStart = '[BOX]';
    const boxEnd = '[/BOX]';
    const diagramPrefix = '[DIAGRAM:';
    const imagePrefix = '[IMAGE:';
    final blocks = <Widget>[];
    var remaining = _normalizeIntroImagePlacement(intro);
    int boxIndex = 0; // 0-based counter across ALL boxes in this lesson

    while (true) {
      final diagramIdx = remaining.indexOf(diagramPrefix);
      final imageIdx = remaining.indexOf(imagePrefix);
      final boxStartIdx = remaining.indexOf(boxStart);
      final markerCandidates = <int>[diagramIdx, imageIdx, boxStartIdx].where((idx) => idx != -1).toList();
      if (markerCandidates.isEmpty) {
        final text = remaining.trim();
        if (text.isNotEmpty) {
          for (final paragraph in _paragraphsFromText(text)) {
            blocks.add(Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _LessonParagraph(text: paragraph),
            ));
          }
        }
        break;
      }

      final nextMarkerIdx = markerCandidates.reduce((a, b) => a < b ? a : b);

      if (diagramIdx != -1 && diagramIdx == nextMarkerIdx) {
        final textBefore = remaining.substring(0, diagramIdx).trim();
        if (textBefore.isNotEmpty) {
          for (final paragraph in _paragraphsFromText(textBefore)) {
            blocks.add(Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _LessonParagraph(text: paragraph),
            ));
          }
        }
        final afterPrefix = remaining.substring(diagramIdx + diagramPrefix.length);
        final bracketIdx = afterPrefix.indexOf(']');
        if (bracketIdx != -1) {
          final diagramId = afterPrefix.substring(0, bracketIdx).trim();
          if (diagramId.isNotEmpty) {
            blocks.add(Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _LessonDiagramWidget(diagramId: diagramId),
            ));
          }
          remaining = afterPrefix.substring(bracketIdx + 1);
          continue;
        }
      }

      if (imageIdx != -1 && imageIdx == nextMarkerIdx) {
        final textBefore = remaining.substring(0, imageIdx).trim();
        if (textBefore.isNotEmpty) {
          for (final paragraph in _paragraphsFromText(textBefore)) {
            blocks.add(Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _LessonParagraph(text: paragraph),
            ));
          }
        }
        final afterPrefix = remaining.substring(imageIdx + imagePrefix.length);
        final bracketIdx = afterPrefix.indexOf(']');
        if (bracketIdx != -1) {
          final imageName = afterPrefix.substring(0, bracketIdx).trim();
          if (imageName.isNotEmpty) {
            blocks.add(Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _LessonImageWidget(imageName: imageName),
            ));
          }
          remaining = afterPrefix.substring(bracketIdx + 1);
          continue;
        }
      }

      final textBefore = remaining.substring(0, boxStartIdx).trim();
      if (textBefore.isNotEmpty) {
        for (final paragraph in _paragraphsFromText(textBefore)) {
          blocks.add(Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _LessonParagraph(text: paragraph),
          ));
        }
      }

      remaining = remaining.substring(boxStartIdx + boxStart.length);
      final boxEndIdx = remaining.indexOf(boxEnd);
      if (boxEndIdx == -1) {
        if (remaining.trim().isNotEmpty) {
          blocks.add(Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _LessonParagraph(text: remaining.trim()),
          ));
        }
        break;
      }

      final boxContent = remaining.substring(0, boxEndIdx).trim();
      if (boxContent.isNotEmpty) {
        final forcedFormulaStyle = _forceFormulaStyleForBox(boxContent);
        final isFormulaBox = forcedFormulaStyle ?? boxIndex.isEven;
        final bgColor = isFormulaBox
            ? _formulaBoxColor.withOpacity(0.15)
            : _exampleBoxColor.withOpacity(0.15);
        final borderColor = isFormulaBox
            ? _formulaBoxColor.withOpacity(0.5)
            : _exampleBoxColor.withOpacity(0.5);
        final textColor = isFormulaBox
            ? _formulaBoxColor
            : _exampleBoxColor;

        blocks.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor, width: 1.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: boxContent
                    .split('\n')
                    .map((line) => line.trim())
                    .where((line) => line.isNotEmpty)
                    .map((line) {
                      final baseStyle = Theme.of(context).textTheme.bodyLarge!.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      );
                      final isFormula = _isFormulaLine(line);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: isFormula
                            ? _LessonFormulaLine(
                                text: line,
                                accentColor: textColor,
                              )
                            : _LessonParagraph(text: line, baseStyle: baseStyle),
                      );
                    })
                    .toList(),
              ),
            ),
          ),
        );
        boxIndex++;
      }

      remaining = remaining.substring(boxEndIdx + boxEnd.length);
    }

    return blocks;
  }

  String _normalizeLegacyDiagramReplacements(String lessonId, String intro) {
    final imageNames = _legacyLessonImages[lessonId];
    final shouldStripOnly = _lessonsWithoutReplacementImages.contains(lessonId);
    if ((imageNames == null || imageNames.isEmpty) && !shouldStripOnly) return intro;

    final stripped = _stripLessonMediaMarkers(intro);
    if (shouldStripOnly) return stripped;

    final replacement = imageNames!.map((name) => '[IMAGE:$name]').join('\n\n');
    final boxIndex = stripped.indexOf('[BOX]');
    if (boxIndex != -1) {
      final before = stripped.substring(0, boxIndex).trimRight();
      final after = stripped.substring(boxIndex);
      if (before.isEmpty) {
        return '$replacement\n\n$after';
      }
      return '$before\n\n$replacement\n\n$after';
    }

    final trimmed = stripped.trim();
    return trimmed.isEmpty ? replacement : '$trimmed\n\n$replacement';
  }

  String _stripLessonMediaMarkers(String intro) {
    final stripped = intro.replaceAll(RegExp(r'\n?\n?\[(?:IMAGE|DIAGRAM):[^\]]+\]'), '');
    return stripped.replaceAll(RegExp(r'\n{3,}'), '\n\n');
  }

  String _normalizeIntroImagePlacement(String intro) {
    final normalized = intro.replaceAll('\r\n', '\n');
    final lines = normalized.split('\n');
    final images = <String>[];
    final remaining = <String>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('[IMAGE:') && trimmed.endsWith(']')) {
        images.add(trimmed);
      } else {
        remaining.add(line);
      }
    }

    if (images.isEmpty) return intro;

    final boxIndex = remaining.indexWhere((line) => line.trim() == '[BOX]');
    if (boxIndex == -1) return intro;

    final before = List<String>.from(remaining.take(boxIndex));
    final after = List<String>.from(remaining.skip(boxIndex));

    while (before.isNotEmpty && before.last.trim().isEmpty) {
      before.removeLast();
    }

    final rebuilt = <String>[
      ...before,
      if (before.isNotEmpty) '',
      for (var i = 0; i < images.length; i++) ...[
        images[i],
        if (i < images.length - 1) '',
      ],
      if (after.isNotEmpty) '',
      ...after,
    ];

    return _collapseBlankLines(rebuilt).trim();
  }

  String _collapseBlankLines(List<String> lines) {
    final result = <String>[];
    var previousWasBlank = false;

    for (final line in lines) {
      final isBlank = line.trim().isEmpty;
      if (isBlank && previousWasBlank) continue;
      result.add(line);
      previousWasBlank = isBlank;
    }

    return result.join('\n');
  }

  bool? _forceFormulaStyleForBox(String boxContent) {
    final lines = boxContent
        .split('\n')
        .map((line) => line.replaceAll('**', '').trim().toLowerCase())
        .where((line) => line.isNotEmpty)
        .toList();
    if (lines.isEmpty) return null;

    const exampleHints = [
      'example', 'examples', 'esempio', 'esempi', 'exemple', 'exemples',
      'ejemplo', 'ejemplos', 'misol', 'misollar'
    ];
    const formulaHints = [
      'formula', 'formulas', 'formule', 'fórmulas', 'formular',
      'equation', 'equazioni', 'équation', 'ecuación', 'tenglama'
    ];

    final header = lines.first;
    if (exampleHints.any(header.contains)) return false;
    if (formulaHints.any(header.contains)) return true;

    final formulaLines = lines.where(_isFormulaLine).length;
    final textLines = lines.length - formulaLines;
    if (formulaLines > textLines) return true;
    if (textLines > formulaLines) return false;
    return null;
  }

  bool _isFormulaLine(String line) {
    final s = line.trim();
    if (s.isEmpty) return false;
    if (s.contains('=')) return true;
    if (s.contains('→') || s.contains('±') || s.contains('√') || s.contains('∫') || s.contains('Δ') || s.contains('^')) return true;
    final lower = s.toLowerCase();
    if (lower.contains('lim') || lower.contains('sin') || lower.contains('cos') || lower.contains('tan') || lower.contains('ln') || lower.contains('log')) return true;
    return false;
  }

  List<String> _paragraphsFromText(String text) {
    final blocks = _normalizeLessonDisplayText(text)
        .split('\n\n')
        .map((block) => block.trim())
        .where((block) => block.isNotEmpty);
    final out = <String>[];

    for (final block in blocks) {
      final lines = block
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();
      if (lines.isEmpty) continue;

      final current = <String>[];
      void flushCurrent() {
        final joined = current.join(' ').trim();
        if (joined.isNotEmpty) {
          out.add(joined);
        }
        current.clear();
      }

      for (final line in lines) {
        if (_isBulletLikeLine(line) || _isStandaloneHeading(line)) {
          flushCurrent();
          out.add(line);
          continue;
        }

        final headingSplit = _splitLeadingBoldHeading(line);
        if (headingSplit != null) {
          flushCurrent();
          out.add(headingSplit[1].isEmpty ? headingSplit[0] : '${headingSplit[0]} ${headingSplit[1]}');
          continue;
        }

        current.add(line);
      }

      flushCurrent();
    }

    return out;
  }

  String _normalizeLessonDisplayText(String text) {
    var normalized = text
        .replaceAll('\r\n', '\n')
        .replaceAll('(BOX)', '')
        .replaceAll('(/BOX)', '');
    normalized = normalized.replaceAllMapped(
      RegExp(r'(^|[ \t])(\\n|/n)(?=[ \t]*$)', multiLine: true),
      (match) => '${match.group(1) ?? ''}\n',
    );
    return normalized.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
  }

  bool _isBulletLikeLine(String line) {
    final s = line.trimLeft();
    return s.startsWith('•') || s.startsWith('- ') || s.startsWith('* ');
  }

  bool _isStandaloneHeading(String line) {
    final s = line.trim();
    return s.startsWith('**') && s.endsWith('**') && s.length > 4;
  }

  List<String>? _splitLeadingBoldHeading(String line) {
    final s = line.trim();
    if (!s.startsWith('**')) return null;
    final end = s.indexOf('**', 2);
    if (end == -1) return null;

    final heading = s.substring(0, end + 2).trim();
    final rest = s.substring(end + 2).trim();
    if (heading.isEmpty) return null;
    return [heading, rest];
  }

  List<String> _splitBySentence(String text) {
    final out = <String>[];
    var buf = StringBuffer();
    var i = 0;

    bool isBreakPunctuation(String ch) => ch == '.' || ch == '?' || ch == '!';
    bool isWhitespace(String ch) => ch.trim().isEmpty;

    while (i < text.length) {
      final ch = text[i];
      buf.write(ch);

      if (isBreakPunctuation(ch)) {
        final atEnd = i + 1 >= text.length;
        final nextIsWhitespace = !atEnd && isWhitespace(text[i + 1]);
        if (atEnd || nextIsWhitespace) {
          final p = buf.toString().trim();
          if (p.isNotEmpty) out.add(p);
          buf = StringBuffer();
          while (i + 1 < text.length && isWhitespace(text[i + 1])) {
            i++;
          }
        }
      }

      i++;
    }

    final tail = buf.toString().trim();
    if (tail.isNotEmpty) out.add(tail);
    return out;
  }

  Widget _buildTextWithBold(BuildContext context, String text, TextStyle baseStyle) {
    final spans = <TextSpan>[];
    final parts = text.split('**');
    for (var i = 0; i < parts.length; i++) {
      if (parts[i].isEmpty) continue;
      spans.add(TextSpan(
        text: parts[i],
        style: i.isOdd ? baseStyle.copyWith(fontWeight: FontWeight.bold) : baseStyle,
      ));
    }
    final color = Theme.of(context).textTheme.bodyLarge?.color ?? Theme.of(context).colorScheme.onSurface;
    return RichText(
      text: TextSpan(style: baseStyle.copyWith(color: color), children: spans),
    );
  }
}

class _LessonParagraph extends StatelessWidget {
  const _LessonParagraph({required this.text, this.baseStyle});

  final String text;
  final TextStyle? baseStyle;

  @override
  Widget build(BuildContext context) {
    final style = (baseStyle ?? Theme.of(context).textTheme.bodyLarge!).copyWith(height: 1.45);
    return Center(
      child: RichText(
        textAlign: TextAlign.center,
        text: _buildLessonParagraphSpan(
          text,
          style.copyWith(
            color: Theme.of(context).textTheme.bodyLarge?.color ?? Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _LessonFormulaLine extends StatelessWidget {
  const _LessonFormulaLine({required this.text, required this.accentColor});

  final String text;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final split = _splitLessonFormulaLine(text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (split.label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: _BoldText(
              text: split.label!,
              baseStyle: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    color: _LessonDetailPageState._lessonAccentColor,
                  ),
            ),
          ),
        if (split.formula != null)
          _LessonMathBlock(
            latex: _normalizeLessonLatex(split.formula!),
            displayMode: true,
            minHeight: 64,
          ),
        if (split.note != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              split.note!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
            ),
          ),
      ],
    );
  }
}

class _BoldText extends StatelessWidget {
  const _BoldText({required this.text, required this.baseStyle});

  final String text;
  final TextStyle baseStyle;

  @override
  Widget build(BuildContext context) {
    final spans = <TextSpan>[];
    final parts = text.split('**');
    for (var i = 0; i < parts.length; i++) {
      if (parts[i].isEmpty) continue;
      spans.add(TextSpan(
        text: parts[i],
        style: i.isOdd ? baseStyle.copyWith(fontWeight: FontWeight.bold) : baseStyle,
      ));
    }

    return RichText(
      text: TextSpan(
        style: baseStyle.copyWith(
          color: Theme.of(context).textTheme.bodyLarge?.color ?? Theme.of(context).colorScheme.onSurface,
        ),
        children: spans,
      ),
    );
  }
}

class _LessonMathBlock extends StatefulWidget {
  const _LessonMathBlock({
    required this.latex,
    required this.displayMode,
    required this.minHeight,
  });

  final String latex;
  final bool displayMode;
  final double minHeight;

  @override
  State<_LessonMathBlock> createState() => _LessonMathBlockState();
}

class _LessonMathBlockState extends State<_LessonMathBlock> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadHtmlString(_lessonMathHtml(widget.latex, widget.displayMode));
  }

  @override
  void didUpdateWidget(covariant _LessonMathBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.latex != widget.latex || oldWidget.displayMode != widget.displayMode) {
      _controller.loadHtmlString(_lessonMathHtml(widget.latex, widget.displayMode));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: widget.minHeight, maxHeight: widget.displayMode ? 132 : 56),
      child: WebViewWidget(controller: _controller),
    );
  }
}

class _LessonFormulaSplit {
  const _LessonFormulaSplit({this.label, required this.formula, this.note});

  final String? label;
  final String? formula;
  final String? note;
}

bool _looksLikeInlineMath(String text) {
  final candidate = text.trim();
  if (candidate.isEmpty) return false;
  if (RegExp(r'[=+\-*/^(){}\[\]≤≥≠±√∫π∞]').hasMatch(candidate)) {
    return true;
  }
  final lower = candidate.toLowerCase();
  return lower.contains('lim') ||
      lower.contains('sin') ||
      lower.contains('cos') ||
      lower.contains('tan') ||
      lower.contains('ln') ||
      lower.contains('log');
}

_LessonFormulaSplit _splitLessonFormulaLine(String text) {
  final trimmed = text.trim();
  final sanitized = _sanitizeLessonFormulaContent(trimmed);
  final formulaSource = sanitized.formula ?? trimmed;
  final index = formulaSource.indexOf(':');
  if (index == -1) {
    if (_containsProseWords(formulaSource)) {
      return _LessonFormulaSplit(
        formula: null,
        note: sanitized.note == null ? formulaSource : '$formulaSource ${sanitized.note!}',
      );
    }
    return _LessonFormulaSplit(formula: formulaSource, note: sanitized.note);
  }

  final left = formulaSource.substring(0, index).trim();
  final right = formulaSource.substring(index + 1).trim();
  if (left.isEmpty || right.isEmpty || !_looksLikeInlineMath(right)) {
    if (_containsProseWords(formulaSource)) {
      return _LessonFormulaSplit(
        formula: null,
        note: sanitized.note == null ? formulaSource : '$formulaSource ${sanitized.note!}',
      );
    }
    return _LessonFormulaSplit(formula: formulaSource, note: sanitized.note);
  }

  if (_containsProseWords(right)) {
    return _LessonFormulaSplit(
      label: '$left:',
      formula: null,
      note: sanitized.note == null ? right : '$right ${sanitized.note!}',
    );
  }

  return _LessonFormulaSplit(label: '$left:', formula: right, note: sanitized.note);
}

_LessonFormulaSplit _sanitizeLessonFormulaContent(String text) {
  var formula = text.trim();
  final notes = <String>[];

  final arrowMatch = RegExp(r'\s*(?:→|⇒|->)\s*([A-Za-z][A-Za-z \-]+\.?)$').firstMatch(formula);
  if (arrowMatch != null) {
    notes.add(formula.substring(arrowMatch.start).trim());
    formula = formula.substring(0, arrowMatch.start).trim();
  }

  final parenMatch = RegExp(r'\(([A-Za-z][A-Za-z \-]+)\)\s*$').firstMatch(formula);
  if (parenMatch != null) {
    notes.add(formula.substring(parenMatch.start).trim());
    formula = formula.substring(0, parenMatch.start).trim();
  }

  return _LessonFormulaSplit(
    formula: formula.isEmpty ? text.trim() : formula,
    note: notes.isEmpty ? null : notes.join(' '),
  );
}

bool _containsProseWords(String text) {
  final matches = RegExp(r'\b[a-z]{3,}\b', caseSensitive: false)
      .allMatches(text)
      .map((match) => match.group(0)!.toLowerCase());
  const allowed = {'sin', 'cos', 'tan', 'log', 'lim', 'mod', 'gcd', 'lcm'};
  return matches.any((word) => !allowed.contains(word));
}

TextSpan _buildLessonParagraphSpan(String text, TextStyle baseStyle) {
  final parts = text.split('**');
  final children = <InlineSpan>[];

  for (var i = 0; i < parts.length; i++) {
    final trimmed = parts[i].trim();
    if (parts[i].isEmpty) continue;
    final rendered = trimmed.isNotEmpty && _looksLikeInlineMath(trimmed)
        ? parts[i].replaceFirst(trimmed, _prettifyLessonInlineMath(trimmed))
        : _prettifyLessonTextContent(parts[i]);
    children.add(
      TextSpan(
        text: rendered,
        style: i.isOdd
            ? baseStyle.copyWith(
                fontWeight: FontWeight.bold,
                color: _LessonDetailPageState._lessonAccentColor,
              )
            : baseStyle,
      ),
    );
  }

  if (children.isEmpty) {
    return TextSpan(text: text, style: baseStyle);
  }

  return TextSpan(style: baseStyle, children: children);
}

String _prettifyLessonInlineMath(String text) {
  return _prettifyLessonTextContent(text).replaceAll('*', '×');
}

String _prettifyLessonTextContent(String text) {
  var value = text
      .replaceAll(r'\pi', 'π')
      .replaceAll('pi', 'π')
      .replaceAll('∫_', '∫');

  value = value.replaceAllMapped(
    RegExp(r'∫([A-Za-z0-9+\-]+)\^([A-Za-z0-9+\-]+)'),
    (match) => '∫${_lessonSubscript(match.group(1)!)}${_lessonSuperscript(match.group(2)!)}',
  );
  value = value.replaceAllMapped(
    RegExp(r'\]_([A-Za-z0-9+\-]+)\^([A-Za-z0-9+\-]+)'),
    (match) => ']${_lessonSubscript(match.group(1)!)}${_lessonSuperscript(match.group(2)!)}',
  );
  value = value.replaceAll(' e^x', ' eˣ');
  return value;
}

String _lessonSubscript(String text) {
  const map = {
    '0': '₀', '1': '₁', '2': '₂', '3': '₃', '4': '₄', '5': '₅', '6': '₆', '7': '₇', '8': '₈', '9': '₉',
    'a': 'ₐ', 'e': 'ₑ', 'h': 'ₕ', 'i': 'ᵢ', 'j': 'ⱼ', 'k': 'ₖ', 'l': 'ₗ', 'm': 'ₘ', 'n': 'ₙ',
    'o': 'ₒ', 'p': 'ₚ', 'r': 'ᵣ', 's': 'ₛ', 't': 'ₜ', 'u': 'ᵤ', 'v': 'ᵥ', 'x': 'ₓ', '+': '₊', '-': '₋', '=': '₌',
  };
  return text.split('').map((char) => map[char] ?? char).join();
}

String _lessonSuperscript(String text) {
  const map = {
    '0': '⁰', '1': '¹', '2': '²', '3': '³', '4': '⁴', '5': '⁵', '6': '⁶', '7': '⁷', '8': '⁸', '9': '⁹',
    'a': 'ᵃ', 'b': 'ᵇ', 'c': 'ᶜ', 'd': 'ᵈ', 'e': 'ᵉ', 'f': 'ᶠ', 'g': 'ᵍ', 'h': 'ʰ', 'i': 'ⁱ', 'j': 'ʲ',
    'k': 'ᵏ', 'l': 'ˡ', 'm': 'ᵐ', 'n': 'ⁿ', 'o': 'ᵒ', 'p': 'ᵖ', 'r': 'ʳ', 's': 'ˢ', 't': 'ᵗ',
    'u': 'ᵘ', 'v': 'ᵛ', 'w': 'ʷ', 'x': 'ˣ', '+': '⁺', '-': '⁻', '=': '⁼', '(': '⁽', ')': '⁾',
  };
  return text.split('').map((char) => map[char] ?? char).join();
}

String _normalizeLessonLatex(String raw) {
  var value = raw.trim();
  if (value.isEmpty) return '';

  value = value
      .replaceAll('−', '-')
      .replaceAll('×', r' \times ')
      .replaceAll('÷', r' \div ')
      .replaceAll('π', r'\pi')
      .replaceAll('²', '^2')
      .replaceAll('³', '^3')
      .replaceAll('≤', r'\le')
      .replaceAll('≥', r'\ge')
      .replaceAll('≠', r'\ne')
      .replaceAll('±', r'\pm')
      .replaceAll('∞', r'\infty')
      .replaceAll('ℝ', r'\mathbb{R}')
      .replaceAll('ℤ', r'\mathbb{Z}')
      .replaceAll('ℚ', r'\mathbb{Q}')
      .replaceAll('ℕ', r'\mathbb{N}')
      .replaceAll('⇔', r'\Leftrightarrow')
      .replaceAll('⇒', r'\Rightarrow')
      .replaceAll('→', r'\to')
      .replaceAll('∈', r'\in')
      .replaceAll('∉', r'\notin');

  value = value.replaceAllMapped(RegExp(r'\bpi\b'), (_) => r'\pi');
  value = value.replaceAllMapped(RegExp(r'√\s*([A-Za-z0-9\(\)\+\-]+)'), (match) => r'\sqrt{${match.group(1)!}}');
  value = value.replaceAllMapped(
    RegExp(r'(?<!\\)\b([A-Za-z0-9]+)\s*/\s*([A-Za-z0-9]+)\b'),
    (match) => r'\frac{${match.group(1)!}}{${match.group(2)!}}',
  );
  value = value.replaceAllMapped(
    RegExp(r'(?<!\\)\b([A-Za-z])\s*\^\s*([0-9A-Za-z\+\-]+)\b'),
    (match) => '${match.group(1)!}^{${match.group(2)!}}',
  );
  value = value.replaceAll(RegExp(r'\s{2,}'), ' ').trim();

  if (!value.contains(r'\displaystyle')) {
    value = r'\displaystyle \large ' + value;
  }

  return value;
}

String _lessonMathHtml(String latex, bool displayMode) {
  final escaped = const HtmlEscape(HtmlEscapeMode.element).convert(latex);
  final math = displayMode ? r'\[' + escaped + r'\]' : r'\(' + escaped + r'\)';
  final fontSize = displayMode ? '1.12rem' : '1.00rem';
  final maxHeight = displayMode ? '132px' : '56px';

  return '''
<!DOCTYPE html>
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
        background: transparent;
        overflow: hidden;
      }
      body {
        display: flex;
        align-items: center;
        justify-content: center;
      }
      .math-wrap {
        width: 100%;
        text-align: center;
        font-size: $fontSize;
        line-height: 1.35;
        overflow-x: ${displayMode ? 'auto' : 'hidden'};
        overflow-y: hidden;
        max-height: $maxHeight;
      }
      mjx-container {
        margin: 0 !important;
      }
      svg {
        max-width: none !important;
        height: auto !important;
      }
    </style>
  </head>
  <body>
    <div class="math-wrap">$math</div>
  </body>
</html>
''';
}

/// Fetches SVG from public URL then displays it in WebView as data to avoid encoding/load errors (red box).
class _LessonDiagramWidget extends StatefulWidget {
  const _LessonDiagramWidget({required this.diagramId});

  final String diagramId;

  @override
  State<_LessonDiagramWidget> createState() => _LessonDiagramWidgetState();
}

class _LessonDiagramWidgetState extends State<_LessonDiagramWidget> {
  WebViewController? _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _fetchAndLoad();
  }

  Future<void> _fetchAndLoad() async {
    final base = kServerBaseUrl.endsWith('/') ? kServerBaseUrl.substring(0, kServerBaseUrl.length - 1) : kServerBaseUrl;
    try {
      final dio = Dio(BaseOptions(baseUrl: base, connectTimeout: const Duration(seconds: 10)));
      final res = await dio.get<List<int>>(
        'diagrams/${widget.diagramId}',
        options: Options(responseType: ResponseType.bytes),
      );
      if (res.statusCode == 200 && res.data != null) {
        final bytes = res.data!;
        final base64 = base64Encode(bytes);
        final dataUrl = 'data:image/svg+xml;charset=utf-8;base64,$base64';
        if (!mounted) return;
        setState(() {
          _controller = WebViewController()
            ..setJavaScriptMode(JavaScriptMode.disabled)
            ..loadRequest(Uri.parse(dataUrl));
          _failed = false;
        });
      } else {
        if (mounted) setState(() => _failed = true);
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 120, maxHeight: 280),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.5)),
          ),
          child: _failed
              ? Center(child: Text(AppLocale.tr('diagram_not_available'), style: const TextStyle(fontSize: 12, color: Colors.grey)))
              : _controller == null
                  ? const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
                  : WebViewWidget(controller: _controller!),
        ),
      ),
    );
  }
}

class _LessonImageWidget extends StatefulWidget {
  const _LessonImageWidget({required this.imageName});

  final String imageName;

  @override
  State<_LessonImageWidget> createState() => _LessonImageWidgetState();
}

class _LessonImageWidgetState extends State<_LessonImageWidget> {
  WebViewController? _controller;
  bool _failed = false;

  bool get _isSvg => widget.imageName.toLowerCase().endsWith('.svg');
  bool get _usesWebView {
    final lower = widget.imageName.toLowerCase();
    return lower.endsWith('.svg') || lower.endsWith('.gif') || lower.endsWith('.webp') || lower.endsWith('.avif');
  }

  String get _base =>
      kServerBaseUrl.endsWith('/') ? kServerBaseUrl.substring(0, kServerBaseUrl.length - 1) : kServerBaseUrl;

  String get _imageUrl => '$_base/lesson-images/${Uri.encodeComponent(widget.imageName)}';

  @override
  void initState() {
    super.initState();
    if (_isSvg) {
      _fetchAndLoadSvg();
    } else if (_usesWebView) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.disabled)
        ..loadRequest(Uri.parse(_imageUrl));
    }
  }

  Future<void> _fetchAndLoadSvg() async {
    try {
      final dio = Dio(BaseOptions(baseUrl: _base, connectTimeout: const Duration(seconds: 10)));
      final res = await dio.get<List<int>>(
        'lesson-images/${Uri.encodeComponent(widget.imageName)}',
        options: Options(responseType: ResponseType.bytes),
      );
      if (res.statusCode == 200 && res.data != null) {
        final bytes = res.data!;
        final base64 = base64Encode(bytes);
        final dataUrl = 'data:image/svg+xml;charset=utf-8;base64,$base64';
        if (!mounted) return;
        setState(() {
          _controller = WebViewController()
            ..setJavaScriptMode(JavaScriptMode.disabled)
            ..loadRequest(Uri.parse(dataUrl));
          _failed = false;
        });
      } else {
        if (mounted) setState(() => _failed = true);
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 120, maxHeight: 280),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.5)),
          ),
          child: _usesWebView
              ? _failed
                  ? Center(child: Text(AppLocale.tr('diagram_not_available'), style: const TextStyle(fontSize: 12, color: Colors.grey)))
                  : _controller == null
                      ? const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
                      : WebViewWidget(controller: _controller!)
              : Image.network(
                  _imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Center(child: Text(AppLocale.tr('diagram_not_available'), style: const TextStyle(fontSize: 12, color: Colors.grey)));
                  },
                ),
        ),
      ),
    );
  }
}
