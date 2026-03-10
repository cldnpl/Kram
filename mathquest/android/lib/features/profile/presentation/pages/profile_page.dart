import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/l10n/app_locale.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final DioClient _dio = DioClient();
  User? _authUser;
  String _userName = '';
  String _profileUsername = '';
  String _mathLevel = 'Beginner';
  int _streakDays = 0;
  int _lessonsCompleted = 0;
  String _profilePhotoPath = '';
  bool _sessionLoggedIn = false;

  static const _keyProfilePhoto = 'profile_photo_path';
  static const _profilePhotoFilename = 'profile_photo.jpg';
  static const _keySessionLoggedIn = 'session_logged_in';

  @override
  void initState() {
    super.initState();
    _loadProfileData().then((_) => _syncRemoteProfile());
    _fetchStreak();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('profile_name') ?? '';
      _profileUsername = prefs.getString('profile_username') ?? '';
      _mathLevel = prefs.getString('profile_level') ?? 'Beginner';
      _profilePhotoPath = prefs.getString(_keyProfilePhoto) ?? '';
      _sessionLoggedIn = prefs.getBool(_keySessionLoggedIn) ?? false;
    });
  }

  Future<void> _fetchStreak() async {
    try {
      final res = await _dio.dio.get(
        'streak',
        options: Options(headers: {'Authorization': 'Bearer mock-dev-token'}),
      );
      final data = res.data as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _streakDays = (data['streak_days'] as num?)?.toInt() ?? 0;
        });
      }
    } catch (e) {
      debugPrint('[Profile] streak fetch error: $e');
    }
  }

  Future<void> _pickProfilePhoto() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: ImageSource.gallery);
    if (xFile == null || !mounted) return;
    final dir = await getApplicationDocumentsDirectory();
    final destFile = File('${dir.path}/$_profilePhotoFilename');
    await File(xFile.path).copy(destFile.path);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyProfilePhoto, destFile.path);
    try {
      final bytes = await destFile.readAsBytes();
      final avatarDataUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      await _syncRemoteProfilePhoto(avatarDataUrl);
    } catch (_) {}
    if (!mounted) return;
    setState(() => _profilePhotoPath = destFile.path);
  }

  String? _resolveAuthToken({User? user}) {
    final effectiveUser = user ?? _authUser;
    final uid = effectiveUser?.uid ?? '';
    if (uid.isNotEmpty) return uid;
    final username = _profileUsername.trim().toLowerCase();
    if (username.isNotEmpty) return 'username:$username';
    return null;
  }

  Future<void> _syncRemoteProfile({User? user}) async {
    final token = _resolveAuthToken(user: user);
    if (token == null) return;
    try {
      final res = await _dio.dio.get(
        'profile',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final data = Map<String, dynamic>.from(res.data as Map);
      final remoteName = (data['name'] as String?)?.trim() ?? '';
      final remoteUsername = (data['username'] as String?)?.trim() ?? '';
      final remoteLevel = (data['math_level'] as String?)?.trim() ?? '';
      final remoteAvatar = (data['avatar_url'] as String?)?.trim() ?? '';
      final isPlaceholderName = remoteName.toLowerCase() == 'mock user' ||
          remoteName.toLowerCase() == 'mathquest user';

      final prefs = await SharedPreferences.getInstance();
      if (remoteName.isNotEmpty && !isPlaceholderName) {
        await prefs.setString('profile_name', remoteName);
      }
      if (remoteUsername.isNotEmpty) await prefs.setString('profile_username', remoteUsername);
      if (remoteLevel.isNotEmpty) await prefs.setString('profile_level', remoteLevel);

      String nextPhotoPath = _profilePhotoPath;
      if (remoteAvatar.isNotEmpty) {
        final bytes = _avatarBytesFromString(remoteAvatar);
        if (bytes != null) {
          final dir = await getApplicationDocumentsDirectory();
          final destFile = File('${dir.path}/$_profilePhotoFilename');
          await destFile.writeAsBytes(bytes, flush: true);
          await prefs.setString(_keyProfilePhoto, destFile.path);
          nextPhotoPath = destFile.path;
        }
      }

      if (!mounted) return;
      setState(() {
        if (remoteName.isNotEmpty && !isPlaceholderName) _userName = remoteName;
        if (remoteUsername.isNotEmpty) _profileUsername = remoteUsername;
        if (remoteLevel.isNotEmpty) _mathLevel = remoteLevel;
        _profilePhotoPath = nextPhotoPath;
      });
    } catch (e) {
      debugPrint('[Profile] remote profile sync error: $e');
    }
  }

  Future<void> _syncRemoteProfilePhoto(String avatarDataUrl) async {
    final token = _resolveAuthToken();
    if (token == null) return;
    try {
      await _dio.dio.put(
        'profile',
        data: {
          'name': _userName.trim(),
          'username': _profileUsername.trim().toLowerCase(),
          'math_level': _mathLevel.trim(),
          'avatar_url': avatarDataUrl,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } catch (e) {
      debugPrint('[Profile] avatar upload sync error: $e');
    }
  }

  List<int>? _avatarBytesFromString(String raw) {
    try {
      if (raw.startsWith('data:image') && raw.contains(',')) {
        final comma = raw.indexOf(',');
        final b64 = raw.substring(comma + 1);
        return base64Decode(b64);
      }
      return base64Decode(raw);
    } catch (_) {
      return null;
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  IconData _getLevelIcon(String level) {
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

  String _localizedLevelName(String level) {
    switch (level) {
      case 'Beginner':
        return AppLocale.tr('level_beginner');
      case 'Intermediate':
        return AppLocale.tr('level_intermediate');
      case 'Advanced':
        return AppLocale.tr('level_advanced');
      default:
        return level;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: ValueListenableBuilder<String>(
          valueListenable: AppLocale.localeNotifier,
          builder: (_, __, ___) => Text(AppLocale.tr('profile_tab')),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          _authUser = state.user;
          if (state.status == AuthStatus.failure &&
              state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
          }
          if (state.status == AuthStatus.authenticated) {
            _syncRemoteProfile(user: state.user);
            SharedPreferences.getInstance().then((prefs) {
              prefs.setBool(_keySessionLoggedIn, true);
            });
          }
        },
        builder: (context, state) {
          final user = state.user;
          final isLoggedIn = state.status == AuthStatus.authenticated || _sessionLoggedIn;
          final displayName =
              _userName.isNotEmpty ? _userName : (user?.displayName ?? AppLocale.tr('user_fallback'));
          final email = user?.email ?? '';
          final photoUrl = user?.photoURL;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Profile header
                const SizedBox(height: 10),
                // Avatar (tap per cambiare foto)
                GestureDetector(
                  onTap: _pickProfilePhoto,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: _profilePhotoPath.isNotEmpty &&
                                File(_profilePhotoPath).existsSync()
                            ? ClipOval(
                                child: Image.file(
                                  File(_profilePhotoPath),
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : photoUrl != null
                                ? CircleAvatar(
                                    radius: 50,
                                    backgroundImage: NetworkImage(photoUrl),
                                    onBackgroundImageError: (_, __) {},
                                    child: null,
                                  )
                                : Container(
                                    width: 100,
                                    height: 100,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFF6650A4),
                                          Color(0xFF9980F0),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        _getInitials(displayName),
                                        style: const TextStyle(
                                          fontSize: 36,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFF6650A4),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Name
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isLoggedIn && _profileUsername.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '@$_profileUsername',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],

                // Email
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // Math level badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6650A4), Color(0xFF9980F0)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getLevelIcon(_mathLevel),
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _localizedLevelName(_mathLevel),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Stats cards
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => context.push('/streak'),
                        child: _StatCard(
                          icon: Icons.local_fire_department,
                          iconColor: Colors.orange,
                          value: '$_streakDays',
                          label: AppLocale.tr('day_streak'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.book,
                        iconColor: const Color(0xFF6650A4),
                        value: '$_lessonsCompleted',
                        label: AppLocale.tr('lessons'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Menu items
                _MenuRow(
                  icon: Icons.settings,
                  iconColor: Colors.grey,
                  title: AppLocale.tr('settings_title'),
                  onTap: () => context.push('/settings'),
                ),
                const SizedBox(height: 12),
                _MenuRow(
                  icon: Icons.help_outline,
                  iconColor: Colors.blue,
                  title: AppLocale.tr('help_support'),
                  onTap: () {},
                ),
                const SizedBox(height: 12),
                _MenuRow(
                  icon: Icons.star,
                  iconColor: Colors.amber,
                  title: AppLocale.tr('rate_app'),
                  onTap: () {},
                ),

                const SizedBox(height: 24),

                // Sign out button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: state.isLoading
                        ? null
                        : () async {
                            if (isLoggedIn) {
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.setBool(_keySessionLoggedIn, false);
                              if (mounted) {
                                setState(() => _sessionLoggedIn = false);
                              }
                              if (!context.mounted) return;
                              context
                                  .read<AuthBloc>()
                                  .add(const AuthSignOutRequested());
                              // Keep cached profile data/photo across logout-login.
                              // When user logs in again, backend profile sync refreshes values.
                              await _loadProfileData();
                            } else {
                              context.go('/login');
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: state.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.red,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.logout, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                isLoggedIn ? AppLocale.tr('sign_out') : AppLocale.tr('sign_in'),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 6),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback onTap;

  const _MenuRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
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
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 14),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}
