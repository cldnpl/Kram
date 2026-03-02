import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/widgets/coin_badge.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DioClient _dio = DioClient();
  List<Map<String, dynamic>> _categories = [];
  int _coinBalance = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    debugPrint('[Home] initState - loading data');
    _load();
  }

  Future<void> _load() async {
    debugPrint('[Home] load() called');
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      debugPrint('[Home] fetching lessons...');
      final res = await _dio.dio.get('lessons', options: _authOptions());
      final data = res.data as Map<String, dynamic>;
      final list = data['categories'] as List<dynamic>? ?? [];
      _categories = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      debugPrint('[Home] got ${_categories.length} categories');

      debugPrint('[Home] fetching balance...');
      final balanceRes = await _dio.dio.get('coins/balance', options: _authOptions());
      final balanceData = balanceRes.data as Map<String, dynamic>;
      _coinBalance = (balanceData['balance'] as num?)?.toInt() ?? 0;
      debugPrint('[Home] balance = $_coinBalance');

      setState(() {
        _loading = false;
      });
    } catch (e, st) {
      debugPrint('[Home] ERROR: $e');
      debugPrint('[Home] stack: $st');
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  dynamic _authOptions() {
    return Options(headers: {'Authorization': 'Bearer mock-dev-token'});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lessons'),
        actions: [CoinBadge(coins: _coinBalance)],
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
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: _categories.length,
                  itemBuilder: (context, i) {
                    final cat = _categories[i];
                    final id = cat['id'] as String? ?? '';
                    final title = cat['title'] as String? ?? '';
                    return Card(
                      child: InkWell(
                        onTap: () => context.go('/category/$id'),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Center(
                            child: Text(
                              title,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: [
          const NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(
            icon: const Icon(Icons.camera_alt),
            label: 'Camera',
            onTap: () => context.go('/camera'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.person),
            label: 'Profile',
            onTap: () => context.go('/profile'),
          ),
        ],
      ),
    );
  }
}

