import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/dio_client.dart';
class CategorySubtopicsPage extends StatefulWidget {
  const CategorySubtopicsPage({super.key, required this.categoryId});

  final String categoryId;

  @override
  State<CategorySubtopicsPage> createState() => _CategorySubtopicsPageState();
}

class _CategorySubtopicsPageState extends State<CategorySubtopicsPage> {
  final DioClient _dio = DioClient();
  String? _categoryTitle;
  List<Map<String, dynamic>> _subtopics = [];
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
      final categories = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
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
      final subtopics = cat['subtopics'] as List<dynamic>? ?? [];
      setState(() {
        _categoryTitle = cat['title'] as String? ?? widget.categoryId;
        _subtopics = subtopics.map((e) => Map<String, dynamic>.from(e as Map)).toList();
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
                      Text('Error: $_error', textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _subtopics.length,
                  itemBuilder: (context, i) {
                    final sub = _subtopics[i];
                    final id = sub['id'] as String? ?? '';
                    final title = sub['title'] as String? ?? '';
                    final desc = sub['description'] as String? ?? '';
                    final coinCost = (sub['coin_cost'] as num?)?.toInt() ?? 10;
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: ListTile(
                        title: Text(title),
                        subtitle: desc.isEmpty ? null : Text(desc, maxLines: 2, overflow: TextOverflow.ellipsis),
                        trailing: Text('$coinCost coins', style: Theme.of(context).textTheme.bodySmall),
                        onTap: () => context.push('/lesson/$id'),
                      ),
                    );
                  },
                ),
    );
  }
}
