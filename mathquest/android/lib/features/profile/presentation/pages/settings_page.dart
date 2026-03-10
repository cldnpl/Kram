import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/api_config.dart';
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
  String _profileLevel = 'Beginner';
  String _profileUsername = '';
  bool? _isUsernameAvailable;
  bool _isCheckingUsername = false;
  Timer? _usernameDebounce;
  Timer? _profileSyncDebounce;
  final _nameEditController = TextEditingController();
  final _usernameEditController = TextEditingController();
  final _dio = Dio(BaseOptions(baseUrl: kApiBaseUrl));

  static const _keyProfileUsername = 'profile_username';
  static const _keyNotifications = 'settings_notifications';
  static const _keySound = 'settings_sound';
  static const _keyDarkMode = 'settings_dark_mode';
  static const _keyDifficulty = 'settings_difficulty';
  static const _keyLanguage = 'settings_language';
  static const _keyProfileLevel = 'profile_level';
  static const _keyProfileName = 'profile_name';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameEditController.dispose();
    _usernameEditController.dispose();
    _usernameDebounce?.cancel();
    _profileSyncDebounce?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _profileName = prefs.getString(_keyProfileName) ?? '';
      _nameEditController.text = _profileName;
      _profileUsername = prefs.getString(_keyProfileUsername) ?? '';
      _usernameEditController.text = _profileUsername;
      _notificationsEnabled = prefs.getBool(_keyNotifications) ?? true;
      _soundEnabled = prefs.getBool(_keySound) ?? true;
      _darkMode = prefs.getBool(_keyDarkMode) ?? false;
      _difficulty = prefs.getString(_keyDifficulty) ?? 'medio';
      _language = prefs.getString(_keyLanguage) ?? 'en';
      _profileLevel = prefs.getString(_keyProfileLevel) ?? 'Beginner';
    });
    await _syncRemoteProfile();
  }

  String _mathLevelDescription(String level) {
    switch (level) {
      case 'Beginner':
        return 'Basic arithmetic, fractions, decimals';
      case 'Intermediate':
        return 'Algebra, geometry, basic equations';
      case 'Advanced':
        return 'Calculus, trigonometry, advanced algebra';
      default:
        return '';
    }
  }

  IconData _mathLevelIcon(String level) {
    switch (level) {
      case 'Beginner':
        return Icons.eco;
      case 'Intermediate':
        return Icons.local_fire_department;
      case 'Advanced':
        return Icons.bolt;
      default:
        return Icons.star;
    }
  }

  void _onUsernameChanged(String value) {
    final trimmed = value.trim().toLowerCase();

    // Same as saved — no check needed
    if (trimmed == _profileUsername.toLowerCase()) {
      setState(() {
        _isUsernameAvailable = null;
        _isCheckingUsername = false;
      });
      _usernameDebounce?.cancel();
      return;
    }

    if (trimmed.isEmpty) {
      setState(() {
        _isUsernameAvailable = null;
        _isCheckingUsername = false;
      });
      _usernameDebounce?.cancel();
      return;
    }

    setState(() {
      _isCheckingUsername = true;
      _isUsernameAvailable = null;
    });

    _usernameDebounce?.cancel();
    _usernameDebounce = Timer(const Duration(milliseconds: 500), () {
      _checkAndSaveUsername(trimmed);
    });
  }

  Future<void> _checkAndSaveUsername(String username) async {
    try {
      final response = await _dio.get('/auth/check-username', queryParameters: {'username': username});
      if (!mounted) return;

      final available = response.data['available'] == true;
      setState(() {
        _isUsernameAvailable = available;
        _isCheckingUsername = false;
      });

      if (available) {
        _profileUsername = username;
        await _setString(_keyProfileUsername, username);
        _scheduleProfileSync();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isUsernameAvailable = null;
        _isCheckingUsername = false;
      });
    }
  }

  Future<void> _setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  String? _resolveAuthToken() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isNotEmpty) return uid;
    final username = _profileUsername.trim().toLowerCase();
    if (username.isNotEmpty) return 'username:$username';
    return null;
  }

  void _scheduleProfileSync() {
    _profileSyncDebounce?.cancel();
    _profileSyncDebounce = Timer(const Duration(milliseconds: 500), () {
      _syncProfileToBackend();
    });
  }

  Future<void> _syncProfileToBackend() async {
    final token = _resolveAuthToken();
    if (token == null) return;
    try {
      await _dio.put(
        '/profile',
        data: {
          'name': _profileName.trim(),
          'username': _profileUsername.trim().toLowerCase(),
          'math_level': _profileLevel.trim(),
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } catch (_) {}
  }

  Future<void> _syncRemoteProfile() async {
    final token = _resolveAuthToken();
    if (token == null) return;
    try {
      final res = await _dio.get(
        '/profile',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final data = Map<String, dynamic>.from(res.data as Map);
      final remoteName = (data['name'] as String?)?.trim() ?? '';
      final remoteUsername = (data['username'] as String?)?.trim() ?? '';
      final remoteLevel = (data['math_level'] as String?)?.trim() ?? '';
      final isPlaceholder = remoteName.toLowerCase() == 'mock user' ||
          remoteName.toLowerCase() == 'mathquest user';

      final prefs = await SharedPreferences.getInstance();
      if (remoteName.isNotEmpty && !isPlaceholder) {
        await prefs.setString(_keyProfileName, remoteName);
      }
      if (remoteUsername.isNotEmpty) {
        await prefs.setString(_keyProfileUsername, remoteUsername);
      }
      if (remoteLevel.isNotEmpty) {
        await prefs.setString(_keyProfileLevel, remoteLevel);
      }

      if (!mounted) return;
      setState(() {
        if (remoteName.isNotEmpty && !isPlaceholder) {
          _profileName = remoteName;
          _nameEditController.text = remoteName;
        }
        if (remoteUsername.isNotEmpty) {
          _profileUsername = remoteUsername;
          _usernameEditController.text = remoteUsername;
        }
        if (remoteLevel.isNotEmpty) {
          _profileLevel = remoteLevel;
        }
      });
    } catch (_) {}
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
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Icon(Icons.person, color: AppColors.appPurple, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _nameEditController,
                          decoration: InputDecoration(
                            hintText: AppLocale.tr('name'),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                          onChanged: (v) async {
                            _profileName = v;
                            await _setString(_keyProfileName, v);
                            _scheduleProfileSync();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: borderColor),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Icon(Icons.alternate_email, color: AppColors.appPurple, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _usernameEditController,
                          autocorrect: false,
                          enableSuggestions: false,
                          textCapitalization: TextCapitalization.none,
                          decoration: const InputDecoration(
                            hintText: 'Username',
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                          onChanged: _onUsernameChanged,
                        ),
                      ),
                      if (_isCheckingUsername)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else if (_isUsernameAvailable != null)
                        Icon(
                          _isUsernameAvailable! ? Icons.check_circle : Icons.cancel,
                          color: _isUsernameAvailable! ? Colors.green : Colors.red,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _sectionTitle('Math Level'),
          const SizedBox(height: 8),
          ...['Beginner', 'Intermediate', 'Advanced'].map((level) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _mathLevelCard(context, level, isDark),
          )),
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: child,
    );
  }

  Widget _mathLevelCard(BuildContext context, String level, bool isDark) {
    final isSelected = _profileLevel == level;
    final cardBg = isDark ? const Color(0xFF2C2C2E) : Colors.white;
    return GestureDetector(
      onTap: () async {
        setState(() => _profileLevel = level);
        await _setString(_keyProfileLevel, level);
        _scheduleProfileSync();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.appPurple : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [
                          Color(0xFF664DE6),
                          Color(0xFF9980F0),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSelected ? null : Colors.grey.shade200,
              ),
              child: Icon(
                _mathLevelIcon(level),
                size: 20,
                color: isSelected ? Colors.white : Colors.grey,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    level,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? (isDark ? Colors.white : Colors.black87)
                          : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _mathLevelDescription(level),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              size: 24,
              color: isSelected ? AppColors.appPurple : Colors.grey.shade300,
            ),
          ],
        ),
      ),
    );
  }
}
