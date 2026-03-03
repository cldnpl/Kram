import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
      final res = await _dio.dio.get(
        'lessons/${widget.lessonId}',
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
        title: Text(_detail?['title'] ?? 'Lesson'),
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
                      Text('Error: $_error', textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                )
              : _detail == null
                  ? const Center(child: Text('No content'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_detail!['content_json'] != null &&
                              _detail!['content_json'] is Map &&
                              (_detail!['content_json'] as Map).containsKey('intro')) ...[
                            Text('Lesson', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
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
                                child: const Text('Practice'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }

  List<Widget> _buildIntroBlocks(String intro) {
    const boxStart = '[BOX]';
    const boxEnd = '[/BOX]';
    final blocks = <Widget>[];
    var remaining = intro;

    while (true) {
      final boxStartIdx = remaining.indexOf(boxStart);
      if (boxStartIdx == -1) {
        final text = remaining.trim();
        if (text.isNotEmpty) {
          for (final p in text.split('\n\n')) {
            final t = p.trim();
            if (t.isNotEmpty) {
              blocks.add(Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(t, style: Theme.of(context).textTheme.bodyLarge),
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
              child: Text(t, style: Theme.of(context).textTheme.bodyLarge),
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
            child: Text(remaining.trim(), style: Theme.of(context).textTheme.bodyLarge),
          ));
        }
        break;
      }

      final boxContent = remaining.substring(0, boxEndIdx).trim();
      if (boxContent.isNotEmpty) {
        blocks.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.5)),
              ),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: boxContent
                      .split('\n')
                      .map((line) => line.trim())
                      .where((line) => line.isNotEmpty)
                      .map((line) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(line, style: Theme.of(context).textTheme.bodyLarge),
                          ))
                      .toList(),
                ),
              ),
            ),
          ),
        );
      }

      remaining = remaining.substring(boxEndIdx + boxEnd.length);
    }

    return blocks;
  }
}
