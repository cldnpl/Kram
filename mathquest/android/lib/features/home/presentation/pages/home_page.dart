import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
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

  int _completedCount(Map<String, dynamic> category) {
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA);
    final progressDone = AppColors.errorLight;
    final progressRemaining = isDark ? Colors.black54 : Colors.black26;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('HOME', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        centerTitle: true,
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
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.88,
                  ),
                  itemCount: _categories.length,
                  itemBuilder: (context, i) {
                    final cat = _categories[i];
                    final id = cat['id'] as String? ?? '';
                    final title = cat['title'] as String? ?? '';
                    final sections = cat['sections'] as List<dynamic>? ?? [];
                    int total = 0;
                    for (final s in sections) {
                      final items = (s as Map)['items'] as List<dynamic>? ?? [];
                      total += items.length;
                    }
                    final completed = _completedCount(cat);

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => context.go('/category/$id'),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                title,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      height: 1.25,
                                      fontSize: 17,
                                    ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                '$completed/$total',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: LinearProgressIndicator(
                                  value: total > 0 ? completed / total : 0,
                                  backgroundColor: progressRemaining,
                                  valueColor: const AlwaysStoppedAnimation<Color>(progressDone),
                                  minHeight: 8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: [
          const NavigationDestination(icon: Icon(Icons.home), label: 'Lessons'),
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
