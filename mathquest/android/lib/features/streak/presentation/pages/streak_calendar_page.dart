import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/dio_client.dart';

class StreakCalendarPage extends StatefulWidget {
  const StreakCalendarPage({super.key});

  @override
  State<StreakCalendarPage> createState() => _StreakCalendarPageState();
}

class _StreakCalendarPageState extends State<StreakCalendarPage> {
  final DioClient _dio = DioClient();
  int _streakDays = 0;
  bool _activeToday = false;
  Set<String> _activeDates = {};
  late int _displayYear;
  late int _displayMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayYear = now.year;
    _displayMonth = now.month;
    _load();
  }

  Options _authOptions() =>
      Options(headers: {'Authorization': 'Bearer mock-dev-token'});

  Future<void> _load() async {
    await Future.wait([_fetchStreak(), _fetchCalendar()]);
  }

  Future<void> _fetchStreak() async {
    try {
      final res = await _dio.dio.get('streak', options: _authOptions());
      final data = res.data as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _streakDays = (data['streak_days'] as num?)?.toInt() ?? 0;
          _activeToday = data['active_today'] as bool? ?? false;
        });
      }
    } catch (e) {
      debugPrint('[StreakCalendar] streak error: $e');
    }
  }

  Future<void> _fetchCalendar() async {
    try {
      final res = await _dio.dio.get(
        'streak/calendar?year=$_displayYear&month=$_displayMonth',
        options: _authOptions(),
      );
      final data = res.data as Map<String, dynamic>;
      final dates = (data['active_dates'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toSet() ??
          {};
      if (mounted) {
        setState(() => _activeDates = dates);
      }
    } catch (e) {
      debugPrint('[StreakCalendar] calendar error: $e');
    }
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _displayYear == now.year && _displayMonth == now.month;
  }

  String get _monthYearString {
    final date = DateTime(_displayYear, _displayMonth);
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  void _previousMonth() {
    setState(() {
      if (_displayMonth == 1) {
        _displayMonth = 12;
        _displayYear -= 1;
      } else {
        _displayMonth -= 1;
      }
    });
    _fetchCalendar();
  }

  void _nextMonth() {
    if (_isCurrentMonth) return;
    setState(() {
      if (_displayMonth == 12) {
        _displayMonth = 1;
        _displayYear += 1;
      } else {
        _displayMonth += 1;
      }
    });
    _fetchCalendar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Streak'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Streak hero
            _buildStreakHero(),
            const SizedBox(height: 24),
            // Calendar
            _buildCalendar(),
            const SizedBox(height: 20),
            // Stats
            _buildStats(),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakHero() {
    return Column(
      children: [
        Icon(
          Icons.local_fire_department,
          size: 56,
          color: _streakDays > 0 ? Colors.orange : Colors.grey,
        ),
        const SizedBox(height: 8),
        Text(
          '$_streakDays',
          style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
        ),
        const Text(
          'Day Streak',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _activeToday ? Icons.check_circle : Icons.error_outline,
              size: 16,
              color: _activeToday ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 4),
            Text(
              _activeToday ? 'Active today' : 'Not active yet today',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _activeToday ? Colors.green : Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCalendar() {
    final firstOfMonth = DateTime(_displayYear, _displayMonth, 1);
    // Monday = 1, Sunday = 7
    int weekday = firstOfMonth.weekday;
    final daysInMonth = DateTime(_displayYear, _displayMonth + 1, 0).day;
    final today = DateTime.now();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Month nav
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _previousMonth,
              ),
              Text(
                _monthYearString,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _isCurrentMonth ? null : _nextMonth,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Weekday headers
          Row(
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                .map((d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          // Days grid
          ...List.generate(6, (weekIndex) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: List.generate(7, (dayIndex) {
                  final cellIndex = weekIndex * 7 + dayIndex;
                  final dayNum = cellIndex - (weekday - 1) + 1;

                  if (dayNum < 1 || dayNum > daysInMonth) {
                    return const Expanded(child: SizedBox(height: 40));
                  }

                  final dateStr = '${_displayYear.toString().padLeft(4, '0')}-${_displayMonth.toString().padLeft(2, '0')}-${dayNum.toString().padLeft(2, '0')}';
                  final isActive = _activeDates.contains(dateStr);
                  final isToday = dayNum == today.day &&
                      _displayMonth == today.month &&
                      _displayYear == today.year;
                  final isFuture = DateTime(_displayYear, _displayMonth, dayNum)
                      .isAfter(today);

                  return Expanded(
                    child: SizedBox(
                      height: 40,
                      child: Center(
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isActive ? Colors.orange : null,
                            border: isToday && !isActive
                                ? Border.all(color: Colors.orange, width: 2)
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              '$dayNum',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                color: isActive
                                    ? Colors.white
                                    : isFuture
                                        ? Colors.grey.shade300
                                        : Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        Expanded(
          child: _StatBox(title: 'This Month', value: '${_activeDates.length}', subtitle: 'active days'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatBox(title: 'Best Streak', value: '$_streakDays', subtitle: 'days'),
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;

  const _StatBox({required this.title, required this.value, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
