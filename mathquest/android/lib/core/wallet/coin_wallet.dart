import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CoinWallet {
  static const _localBonusKey = 'local_bonus_coins';
  static const _rewardedLessonsKey = 'rewarded_lesson_ids';
  static final ValueNotifier<int> localBonusNotifier = ValueNotifier<int>(0);
  static bool _loaded = false;

  static Future<void> ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    localBonusNotifier.value = prefs.getInt(_localBonusKey) ?? 0;
    _loaded = true;
  }

  static int localBonus() => localBonusNotifier.value;

  static Future<void> addLocalBonus(int coins) async {
    if (coins <= 0) return;
    await ensureLoaded();
    final prefs = await SharedPreferences.getInstance();
    final updated = localBonus() + coins;
    await prefs.setInt(_localBonusKey, updated);
    localBonusNotifier.value = updated;
  }

  static Future<void> resetLocalBonus() async {
    await ensureLoaded();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_localBonusKey);
    localBonusNotifier.value = 0;
  }

  static Future<bool> hasRewardedLesson(String lessonId) async {
    await ensureLoaded();
    final prefs = await SharedPreferences.getInstance();
    final rewarded = prefs.getStringList(_rewardedLessonsKey) ?? const [];
    return rewarded.contains(lessonId.trim());
  }

  static Future<void> markLessonRewarded(String lessonId) async {
    final trimmed = lessonId.trim();
    if (trimmed.isEmpty) return;
    await ensureLoaded();
    final prefs = await SharedPreferences.getInstance();
    final rewarded = {
      ...(prefs.getStringList(_rewardedLessonsKey) ?? const [])
    };
    rewarded.add(trimmed);
    await prefs.setStringList(_rewardedLessonsKey, rewarded.toList()..sort());
  }

  static Future<void> resetRewardedLessons() async {
    await ensureLoaded();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_rewardedLessonsKey);
  }
}
