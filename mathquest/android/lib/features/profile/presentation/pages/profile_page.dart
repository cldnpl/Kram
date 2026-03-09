import 'dart:io';

import 'package:dio/dio.dart';
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
  String _userName = '';
  String _profileUsername = '';
  String _mathLevel = 'Beginner';
  int _streakDays = 0;
  int _lessonsCompleted = 0;
  String _profilePhotoPath = '';

  static const _keyProfilePhoto = 'profile_photo_path';
  static const _profilePhotoFilename = 'profile_photo.jpg';

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    _fetchStreak();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('profile_name') ?? '';
      _profileUsername = prefs.getString('profile_username') ?? '';
      _mathLevel = prefs.getString('profile_level') ?? 'Beginner';
      _profilePhotoPath = prefs.getString(_keyProfilePhoto) ?? '';
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
    if (!mounted) return;
    setState(() => _profilePhotoPath = destFile.path);
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
          if (state.status == AuthStatus.failure &&
              state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
          }
        },
        builder: (context, state) {
          final user = state.user;
          final isLoggedIn = state.status == AuthStatus.authenticated ||
              _profileUsername.isNotEmpty;
          final displayName =
              _userName.isNotEmpty ? _userName : (user?.displayName ?? 'User');
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
                        _mathLevel,
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
                          label: 'Day Streak',
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
                  title: 'Help & Support',
                  onTap: () {},
                ),
                const SizedBox(height: 12),
                _MenuRow(
                  icon: Icons.star,
                  iconColor: Colors.amber,
                  title: 'Rate the App',
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
                              final prefs =
                                  await SharedPreferences.getInstance();
                              final photoPath = prefs.getString(_keyProfilePhoto);
                              if (photoPath != null) {
                                try {
                                  final f = File(photoPath);
                                  if (f.existsSync()) f.deleteSync();
                                } catch (_) {}
                              }
                              await prefs.remove('profile_name');
                              await prefs.remove('profile_username');
                              await prefs.remove('profile_level');
                              await prefs.remove(_keyProfilePhoto);
                              if (!context.mounted) return;
                              context
                                  .read<AuthBloc>()
                                  .add(const AuthSignOutRequested());
                              await _loadProfileData();
                              if (!context.mounted) return;
                              setState(() {});
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
