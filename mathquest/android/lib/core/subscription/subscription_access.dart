import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionAccess {
  SubscriptionAccess._();

  static const _keyTier = 'subscription_tier';
  static const _keySessionLoggedIn = 'session_logged_in';
  static const _keyProfileUsername = 'profile_username';
  static const Set<String> _developerUsernames = {
    'cldnpl',
    'claudianapolitano',
  };

  static Future<bool> isDeveloperOverrideActive() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool(_keySessionLoggedIn) ?? false;
    if (!loggedIn) return false;

    final username = (prefs.getString(_keyProfileUsername) ?? '').trim().toLowerCase();
    return _developerUsernames.contains(username);
  }

  static Future<String> currentTierRaw() async {
    if (await isDeveloperOverrideActive()) {
      return 'max';
    }

    final prefs = await SharedPreferences.getInstance();
    final raw = (prefs.getString(_keyTier) ?? '').trim().toLowerCase();
    if (raw == 'pro' || raw == 'max') return raw;
    return 'free';
  }
}
