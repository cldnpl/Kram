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
                                children: _buildIntroBlocks((_detail!['content_json'] as Map)['intro'] as String? ?? ''),
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

  // Dark purple (same as app gradient) for formula boxes (1st, 3rd, …)
  static const _formulaBoxColor = Color(0xFF6650A4);
  // Light purple for example boxes (2nd, 4th, …)
  static const _exampleBoxColor = Color(0xFF9980F0);

  List<Widget> _buildIntroBlocks(String intro) {
    const boxStart = '[BOX]';
    const boxEnd = '[/BOX]';
    const diagramPrefix = '[DIAGRAM:';
    final blocks = <Widget>[];
    var remaining = intro;
    int boxIndex = 0; // 0-based counter across ALL boxes in this lesson

    while (true) {
      final diagramIdx = remaining.indexOf(diagramPrefix);
      final boxStartIdx = remaining.indexOf(boxStart);

      if (diagramIdx != -1 && (boxStartIdx == -1 || diagramIdx < boxStartIdx)) {
        final textBefore = remaining.substring(0, diagramIdx).trim();
        if (textBefore.isNotEmpty) {
          for (final p in textBefore.split('\n\n')) {
            final t = p.trim();
            if (t.isNotEmpty) {
              blocks.add(Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildTextWithBold(context, t, Theme.of(context).textTheme.bodyLarge!),
              ));
            }
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

      if (boxStartIdx == -1) {
        final text = remaining.trim();
        if (text.isNotEmpty) {
          for (final p in text.split('\n\n')) {
            final t = p.trim();
            if (t.isNotEmpty) {
              blocks.add(Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildTextWithBold(context, t, Theme.of(context).textTheme.bodyLarge!),
              ));
            }
          }
        }
        break;
      }

      final textBefore = remaining.substring(0, boxStartIdx).trim();
      if (textBefore.isNotEmpty) {
        for (final p in textBefore.split('\n\n')) {
          final t = p.trim();
          if (t.isNotEmpty) {
            blocks.add(Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildTextWithBold(context, t, Theme.of(context).textTheme.bodyLarge!),
            ));
          }
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
        // Alternate colors: even index (0,2,4…) → formula (dark purple),
        //                   odd  index (1,3,5…) → example (light purple)
        final isFormulaBox = boxIndex.isEven;
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

  bool _isFormulaLine(String line) {
    final s = line.trim();
    if (s.isEmpty) return false;
    if (s.contains('=')) return true;
    if (s.contains('→') || s.contains('±') || s.contains('√') || s.contains('∫') || s.contains('Δ') || s.contains('^')) return true;
    final lower = s.toLowerCase();
    if (lower.contains('lim') || lower.contains('sin') || lower.contains('cos') || lower.contains('tan') || lower.contains('ln') || lower.contains('log')) return true;
    return false;
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
              ? const Center(child: Text('Diagram not available', style: TextStyle(fontSize: 12, color: Colors.grey)))
              : _controller == null
                  ? const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
                  : WebViewWidget(controller: _controller!),
        ),
      ),
    );
  }
}
