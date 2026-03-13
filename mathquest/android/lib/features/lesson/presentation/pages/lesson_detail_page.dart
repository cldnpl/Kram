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
                            Text(AppLocale.tr('lesson'), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
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
              child: _buildTextWithBold(context, paragraph, Theme.of(context).textTheme.bodyLarge!),
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
              child: _buildTextWithBold(context, paragraph, Theme.of(context).textTheme.bodyLarge!),
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
              child: _buildTextWithBold(context, paragraph, Theme.of(context).textTheme.bodyLarge!),
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
            child: _buildTextWithBold(context, paragraph, Theme.of(context).textTheme.bodyLarge!),
          ));
        }
      }

      remaining = remaining.substring(boxStartIdx + boxStart.length);
      final boxEndIdx = remaining.indexOf(boxEnd);
      if (boxEndIdx == -1) {
        if (remaining.trim().isNotEmpty) {
          blocks.add(Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildTextWithBold(context, remaining.trim(), Theme.of(context).textTheme.bodyLarge!),
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
                            ? Text(
                                line,
                                style: baseStyle.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'monospace',
                                  color: textColor,
                                ),
                              )
                            : _buildTextWithBold(context, line, baseStyle),
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
    if (!intro.contains('[DIAGRAM:')) return intro;
    final imageNames = _legacyLessonImages[lessonId];
    if (imageNames == null || imageNames.isEmpty) return intro;

    final replacement = imageNames.map((name) => '[IMAGE:$name]').join('\n\n');
    return intro.replaceAll(RegExp(r'\[DIAGRAM:[^\]]+\]'), replacement);
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
    final normalized = text.replaceAll('\r\n', '\n');
    final out = <String>[];

    for (final rawLine in normalized.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      if (_isBulletLikeLine(line) || _isStandaloneHeading(line)) {
        out.add(line);
        continue;
      }

      final headingSplit = _splitLeadingBoldHeading(line);
      if (headingSplit != null) {
        out.add(headingSplit[0]);
        if (headingSplit[1].isNotEmpty) {
          out.addAll(_splitBySentence(headingSplit[1]));
        }
        continue;
      }

      out.addAll(_splitBySentence(line));
    }

    return out;
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
