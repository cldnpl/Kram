import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionAccess {
  SubscriptionAccess._();

  static const _keyTier = 'subscription_tier';
  static const _keySessionLoggedIn = 'session_logged_in';
  static const _developerAppleEmail = 'napolitano.claudia@icloud.com';

  static Future<bool> isDeveloperOverrideActive() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool(_keySessionLoggedIn) ?? false;
    final user = FirebaseAuth.instance.currentUser;
    if (!loggedIn || user == null) return false;

    final hasAppleProvider = user.providerData
        .map((provider) => provider.providerId.toLowerCase())
        .contains('apple.com');
    if (!hasAppleProvider) return false;

    final email = (user.email ?? '').trim().toLowerCase();
    return email == _developerAppleEmail;
  }

  static Future<String> currentTierRaw() async {
    if (await isDeveloperOverrideActive()) {
      return 'premium';
    }

    final prefs = await SharedPreferences.getInstance();
    final raw = (prefs.getString(_keyTier) ?? '').trim().toLowerCase();
    if (raw == 'premium' || raw == 'pro' || raw == 'max') return 'premium';
    return 'free';
  }
}
