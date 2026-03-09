import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/l10n/app_locale.dart';
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
  int _streakDays = 0;
  bool _activeToday = false;
  bool _loading = true;
  String? _error;
  String _profileName = '';

  @override
  void initState() {
    super.initState();
    debugPrint('[Home] initState - loading data');
    _load();
    _loadProfileName();
  }

  Future<void> _loadProfileName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _profileName = prefs.getString('profile_name') ?? '');
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
      _categories =
          list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      debugPrint('[Home] got ${_categories.length} categories');

      debugPrint('[Home] fetching balance...');
      final balanceRes =
          await _dio.dio.get('coins/balance', options: _authOptions());
      final balanceData = balanceRes.data as Map<String, dynamic>;
      _coinBalance = (balanceData['balance'] as num?)?.toInt() ?? 0;
      debugPrint('[Home] balance = $_coinBalance');

      debugPrint('[Home] fetching streak...');
      final streakRes =
          await _dio.dio.get('streak', options: _authOptions());
      final streakData = streakRes.data as Map<String, dynamic>;
      _streakDays = (streakData['streak_days'] as num?)?.toInt() ?? 0;
      _activeToday = streakData['active_today'] as bool? ?? false;
      debugPrint('[Home] streak = $_streakDays, activeToday = $_activeToday');

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
    final progressRemaining = isDark ? Colors.black54 : Colors.black26;

    return Scaffold(
      body: Stack(
        children: [
          // Gradiente su tutto lo sfondo (come iOS)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.appPurple,
                    Color(0xFFD9D6F5),
                    Color(0xFFEDEAFB),
                    Color(0xFFF7F6FF),
                    Colors.white,
                  ],
                  stops: [0.0, 0.25, 0.3, 0.4, 0.55],
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Header (height 120 come iOS)
                SizedBox(
                  height: 120,
                  child: Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 20, top: 56),
                          child: Text(
                            'Hi, ${_profileName.isEmpty ? AppLocale.tr('hi_there') : _profileName}!',
                            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 52, right: 16),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Streak badge (tap to open calendar)
                            GestureDetector(
                              onTap: () => context.push('/streak'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.local_fire_department,
                                      size: 18,
                                      color: _streakDays > 0 ? Colors.orange : Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$_streakDays',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            CoinBadge(
                              coins: _coinBalance,
                              onTap: () => context.push('/shop'),
                              pillStyle: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _loading
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
                          : GridView.builder(
                              padding: const EdgeInsets.fromLTRB(25, 20, 25, 24),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 0.85,
                              ),
                              itemCount: _categories.length,
                              itemBuilder: (context, i) {
                                final cat = _categories[i];
                                final id = cat['id'] as String? ?? '';
                                final title = cat['title'] as String? ?? '';
                                final sections =
                                    cat['sections'] as List<dynamic>? ?? [];
                                int total = 0;
                                for (final s in sections) {
                                  final items =
                                      (s as Map)['items'] as List<dynamic>? ?? [];
                                  total += items.length;
                                }
                                final completed = _completedCount(cat);

                                return Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => context.go('/category/$id'),
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      constraints: const BoxConstraints(minHeight: 120),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: AppColors.appPurple,
                                          width: 1,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            title,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.black,
                                                ),
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '$completed/$total',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.black,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(2),
                                            child: LinearProgressIndicator(
                                              value: total > 0
                                                  ? completed / total
                                                  : 0,
                                              backgroundColor: progressRemaining,
                                              valueColor: const AlwaysStoppedAnimation<Color>(
                                                  AppColors.successLight),
                                              minHeight: 6,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/');
              break;
            case 1:
              context.go('/camera');
              break;
            case 2:
              context.go('/profile');
              break;
          }
        },
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home), label: AppLocale.tr('lessons')),
          NavigationDestination(
            icon: const Icon(Icons.camera_alt),
            label: AppLocale.tr('camera'),
          ),
          NavigationDestination(
              icon: const Icon(Icons.person), label: AppLocale.tr('profile_tab')),
        ],
      ),
    );
  }
}
