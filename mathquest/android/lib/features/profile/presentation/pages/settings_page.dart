import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/l10n/app_locale.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _profileName = '';
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _darkMode = false;
  String _difficulty = 'medio';
  String _language = 'en';

  static const _keyNotifications = 'settings_notifications';
  static const _keySound = 'settings_sound';
  static const _keyDarkMode = 'settings_dark_mode';
  static const _keyDifficulty = 'settings_difficulty';
  static const _keyLanguage = 'settings_language';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _profileName = prefs.getString('profile_name') ?? '';
      _notificationsEnabled = prefs.getBool(_keyNotifications) ?? true;
      _soundEnabled = prefs.getBool(_keySound) ?? true;
      _darkMode = prefs.getBool(_keyDarkMode) ?? false;
      _difficulty = prefs.getString(_keyDifficulty) ?? 'medio';
      _language = prefs.getString(_keyLanguage) ?? 'en';
    });
  }

  Future<void> _setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF2C2C2E) : Colors.white;
    final borderColor = isDark ? Colors.white12 : Colors.black12;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: ValueListenableBuilder<String>(
          valueListenable: AppLocale.localeNotifier,
          builder: (_, __, ___) => Text(AppLocale.tr('settings_title')),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          _sectionTitle(AppLocale.tr('profile')),
          const SizedBox(height: 8),
          _card(
            context,
            backgroundColor: cardBg,
            borderColor: borderColor,
            child: ListTile(
              leading: Icon(Icons.person, color: AppColors.appPurple, size: 22),
              title: Text(AppLocale.tr('name'), style: const TextStyle(fontWeight: FontWeight.w500)),
              trailing: Text(
                _profileName.isEmpty ? '—' : _profileName,
                style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6)),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _sectionTitle(AppLocale.tr('study_preferences')),
          const SizedBox(height: 8),
          _card(
            context,
            backgroundColor: cardBg,
            borderColor: borderColor,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.bar_chart, color: AppColors.appPurple, size: 22),
                      const SizedBox(width: 12),
                      Text(AppLocale.tr('difficulty'), style: const TextStyle(fontWeight: FontWeight.w500)),
                      const Spacer(),
                      DropdownButton<String>(
                        value: _difficulty,
                        underline: const SizedBox(),
                        icon: Icon(Icons.arrow_drop_down, color: AppColors.appPurple),
                        items: [
                          DropdownMenuItem(value: 'facile', child: Text(AppLocale.tr('difficulty_easy'))),
                          DropdownMenuItem(value: 'medio', child: Text(AppLocale.tr('difficulty_medium'))),
                          DropdownMenuItem(value: 'difficile', child: Text(AppLocale.tr('difficulty_hard'))),
                        ],
                        onChanged: (v) {
                          if (v != null) {
                            setState(() => _difficulty = v);
                            _setString(_keyDifficulty, v);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: borderColor),
                SwitchListTile(
                  secondary: Icon(Icons.notifications, color: AppColors.appPurple, size: 22),
                  title: Text(AppLocale.tr('study_reminder'), style: const TextStyle(fontWeight: FontWeight.w500)),
                  value: _notificationsEnabled,
                  activeColor: AppColors.appPurple,
                  onChanged: (v) {
                    setState(() => _notificationsEnabled = v);
                    _setBool(_keyNotifications, v);
                  },
                ),
                Divider(height: 1, color: borderColor),
                SwitchListTile(
                  secondary: Icon(Icons.volume_up, color: AppColors.appPurple, size: 22),
                  title: Text(AppLocale.tr('sounds'), style: const TextStyle(fontWeight: FontWeight.w500)),
                  value: _soundEnabled,
                  activeColor: AppColors.appPurple,
                  onChanged: (v) {
                    setState(() => _soundEnabled = v);
                    _setBool(_keySound, v);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _sectionTitle(AppLocale.tr('interface')),
          const SizedBox(height: 8),
          _card(
            context,
            backgroundColor: cardBg,
            borderColor: borderColor,
            child: SwitchListTile(
              secondary: Icon(Icons.dark_mode, color: AppColors.appPurple, size: 22),
              title: Text(AppLocale.tr('dark_theme'), style: const TextStyle(fontWeight: FontWeight.w500)),
              value: _darkMode,
              activeColor: AppColors.appPurple,
              onChanged: (v) {
                setState(() => _darkMode = v);
                _setBool(_keyDarkMode, v);
              },
            ),
          ),
          const SizedBox(height: 24),
          _sectionTitle(AppLocale.tr('account_language')),
          const SizedBox(height: 8),
          _card(
            context,
            backgroundColor: cardBg,
            borderColor: borderColor,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.language, color: AppColors.appPurple, size: 22),
                  const SizedBox(width: 12),
                  Text(AppLocale.tr('language'), style: const TextStyle(fontWeight: FontWeight.w500)),
                  const Spacer(),
                  DropdownButton<String>(
                    value: _language,
                    underline: const SizedBox(),
                    icon: Icon(Icons.arrow_drop_down, color: AppColors.appPurple),
                    items: [
                      DropdownMenuItem(value: 'it', child: Text(AppLocale.tr('language_italian'))),
                      DropdownMenuItem(value: 'en', child: Text(AppLocale.tr('language_english'))),
                      DropdownMenuItem(value: 'fr', child: Text(AppLocale.tr('language_french'))),
                      DropdownMenuItem(value: 'es', child: Text(AppLocale.tr('language_spanish'))),
                      DropdownMenuItem(value: 'uz', child: Text(AppLocale.tr('language_uzbek'))),
                    ],
                    onChanged: (v) async {
                      if (v != null) {
                        setState(() => _language = v);
                        await _setString(_keyLanguage, v);
                        await AppLocale.setLocale(v);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _card(
    BuildContext context, {
    required Color backgroundColor,
    required Color borderColor,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: child,
    );
  }
}
