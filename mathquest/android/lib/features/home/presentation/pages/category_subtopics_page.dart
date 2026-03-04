import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/l10n/app_locale.dart';
import '../../../../core/network/dio_client.dart';

const _guestLessonsOpenedCountKey = 'guest_lessons_opened_count';

class CategorySubtopicsPage extends StatefulWidget {
  const CategorySubtopicsPage({super.key, required this.categoryId});

  final String categoryId;

  @override
  State<CategorySubtopicsPage> createState() => _CategorySubtopicsPageState();
}

class _CategorySubtopicsPageState extends State<CategorySubtopicsPage> {
  final DioClient _dio = DioClient();
  String? _categoryTitle;
  List<Map<String, dynamic>> _sections = [];
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
        'lessons',
        options: Options(headers: {'Authorization': 'Bearer mock-dev-token'}),
      );
      final data = res.data as Map<String, dynamic>;
      final list = data['categories'] as List<dynamic>? ?? [];
      final categories =
          list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      Map<String, dynamic>? cat;
      for (final c in categories) {
        if ((c['id'] as String?) == widget.categoryId) {
          cat = c;
          break;
        }
      }
      if (cat == null) {
        setState(() {
          _loading = false;
          _error = 'Category not found';
        });
        return;
      }
      final category = cat;
      final sections = category['sections'] as List<dynamic>? ?? [];
      setState(() {
        _categoryTitle = category['title'] as String? ?? widget.categoryId;
        _sections =
            sections.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _handleLessonTap(String lessonId) async {
    final isAuthenticated = FirebaseAuth.instance.currentUser != null;
    if (isAuthenticated) {
      if (!mounted) return;
      context.push('/lesson/$lessonId');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final openedCount = prefs.getInt(_guestLessonsOpenedCountKey) ?? 0;

    if (openedCount >= 1) {
      if (!mounted) return;
      _showLoginRequiredDialog();
      return;
    }

    await prefs.setInt(_guestLessonsOpenedCountKey, openedCount + 1);
    if (!mounted) return;
    context.push('/lesson/$lessonId');
  }

  void _showLoginRequiredDialog() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocale.tr('sign_in_required')),
          content: Text(AppLocale.tr('guest_lesson_message')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocale.tr('not_now')),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                this.context.go('/login?reason=lesson-limit');
              },
              child: Text(AppLocale.tr('sign_in')),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sectionHeaderColor =
        isDark ? Colors.grey.shade600 : Colors.grey.shade700;
    final buttonBg = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA);

    return Scaffold(
      appBar: AppBar(
        title: Text(_categoryTitle ?? widget.categoryId),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
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
                      FilledButton(
                          onPressed: _load, child: Text(AppLocale.tr('retry'))),
                    ],
                  ),
                )
              : ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: _sections.length,
                  itemBuilder: (context, sectionIndex) {
                    final section = _sections[sectionIndex];
                    final sectionTitle = section['title'] as String? ?? '';
                    final lessonId = section['lesson_id'] as String? ?? '';
                    final items = section['items'] as List<dynamic>? ?? [];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 8),
                            child: Text(
                              sectionTitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    color: sectionHeaderColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                          ...items.asMap().entries.map((entry) {
                            final itemIndex = entry.key;
                            final it = entry.value;
                            final itemMap =
                                Map<String, dynamic>.from(it as Map);
                            final itemTitle = itemMap['title'] as String? ?? '';
                            final itemLessonId = '$lessonId-$itemIndex';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _handleLessonTap(itemLessonId),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: buttonBg,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      itemTitle,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
