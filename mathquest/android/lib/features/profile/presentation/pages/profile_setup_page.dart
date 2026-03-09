import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/router/app_router.dart';

const _profileSetupDoneKey = 'profile_setup_done';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  String _level = 'Beginner';
  bool _saving = false;
  String? _errorMessage;
  bool? _isUsernameAvailable;
  bool _isCheckingUsername = false;
  Timer? _debounceTimer;
  final _dio = Dio(BaseOptions(baseUrl: kApiBaseUrl));

  bool get _canSubmit =>
      _nameController.text.trim().isNotEmpty &&
      _usernameController.text.trim().isNotEmpty &&
      _isUsernameAvailable == true;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  Future<void> _loadExistingData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString('profile_name') ?? '';
    final savedLevel = prefs.getString('profile_level') ?? '';
    final savedUsername = prefs.getString('profile_username') ?? '';

    if (savedName.isNotEmpty) {
      _nameController.text = savedName;
    } else {
      final user = FirebaseAuth.instance.currentUser;
      if (user?.displayName != null && user!.displayName!.isNotEmpty) {
        _nameController.text = user.displayName!;
      }
    }

    if (savedLevel.isNotEmpty) {
      setState(() => _level = savedLevel);
    }

    if (savedUsername.isNotEmpty) {
      _usernameController.text = savedUsername;
    }
  }

  void _onUsernameChanged(String value) {
    final trimmed = value.trim().toLowerCase();
    debugPrint('[ProfileSetup] onUsernameChanged: raw="$value" trimmed="$trimmed"');
    if (trimmed.isEmpty) {
      debugPrint('[ProfileSetup] username empty — resetting state');
      setState(() {
        _isUsernameAvailable = null;
        _isCheckingUsername = false;
      });
      _debounceTimer?.cancel();
      return;
    }

    setState(() {
      _isCheckingUsername = true;
      _isUsernameAvailable = null;
    });

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _checkUsernameAvailability(trimmed);
    });
  }

  Future<void> _checkUsernameAvailability(String username) async {
    debugPrint('[ProfileSetup] checking availability for "$username"');
    try {
      final response = await _dio.get('/auth/check-username', queryParameters: {'username': username});
      debugPrint('[ProfileSetup] response: ${response.statusCode} ${response.data}');
      if (!mounted) return;

      final available = response.data['available'] == true;
      debugPrint('[ProfileSetup] available=$available');
      setState(() {
        _isUsernameAvailable = available;
        _isCheckingUsername = false;
      });
      debugPrint('[ProfileSetup] canSubmit=$_canSubmit name="${_nameController.text}" username="$username" isUsernameAvailable=$_isUsernameAvailable');
    } catch (e) {
      debugPrint('[ProfileSetup] error checking username: $e');
      if (!mounted) return;
      setState(() {
        _isUsernameAvailable = null;
        _isCheckingUsername = false;
      });
    }
  }

  Future<void> _submit() async {
    if (!_canSubmit) {
      setState(() => _errorMessage = 'Please enter your name, username, and select a level.');
      return;
    }

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    final trimmedUsername = _usernameController.text.trim().toLowerCase();

    // Register the username on the server
    try {
      await _dio.post('/auth/register-username', data: {'username': trimmedUsername});
    } on DioException catch (e) {
      if (!mounted) return;
      if (e.response?.statusCode == 409) {
        setState(() {
          _errorMessage = 'Username is already taken. Please choose another.';
          _isUsernameAvailable = false;
          _saving = false;
        });
        return;
      }
      setState(() {
        _errorMessage = 'Failed to register username.';
        _saving = false;
      });
      return;
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Network error: $e';
        _saving = false;
      });
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_name', _nameController.text.trim());
    await prefs.setString('profile_username', trimmedUsername);
    await prefs.setString('profile_level', _level);
    await prefs.setBool(_profileSetupDoneKey, true);

    if (!mounted) return;

    RouterRefreshNotifier.instance.refresh();
    context.go('/');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  String _getLevelDescription(String level) {
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Header
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF6650A4), Color(0xFF9980F0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(
                  Icons.person,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Set up your profile',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tell us a bit about yourself so we can personalize your learning experience',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 32),

              // Name field
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Your Name',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'Enter your name',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 20),

              // Username field
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Username',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _usernameController,
                autocorrect: false,
                enableSuggestions: false,
                textCapitalization: TextCapitalization.none,
                decoration: InputDecoration(
                  hintText: 'Choose a username',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  suffixIcon: _isCheckingUsername
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : _isUsernameAvailable != null
                          ? Icon(
                              _isUsernameAvailable!
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              color: _isUsernameAvailable!
                                  ? Colors.green
                                  : Colors.red,
                            )
                          : null,
                ),
                onChanged: (value) {
                  setState(() {});
                  _onUsernameChanged(value);
                },
              ),
              if (_isUsernameAvailable == false)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Username is already taken',
                      style: TextStyle(fontSize: 13, color: Colors.red.shade600),
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              // Math level
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Math Level',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Level options
              ...['Beginner', 'Intermediate', 'Advanced'].map((level) {
                final isSelected = _level == level;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () => setState(() => _level = level),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF6650A4)
                              : Colors.transparent,
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
                                        Color(0xFF6650A4),
                                        Color(0xFF9980F0)
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              color: isSelected ? null : Colors.grey.shade200,
                            ),
                            child: Icon(
                              _getLevelIcon(level),
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
                                        ? Colors.black87
                                        : Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _getLevelDescription(level),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            isSelected
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            size: 24,
                            color: isSelected
                                ? const Color(0xFF6650A4)
                                : Colors.grey.shade300,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              // Error message
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.red,
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // Continue button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _canSubmit
                        ? const Color(0xFF6650A4)
                        : Colors.grey.shade400,
                    foregroundColor: Colors.white,
                    elevation: _canSubmit ? 4 : 0,
                    shadowColor: const Color(0xFF6650A4).withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
