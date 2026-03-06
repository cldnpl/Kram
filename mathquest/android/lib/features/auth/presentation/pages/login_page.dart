import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final reason = GoRouterState.of(context).uri.queryParameters['reason'];
    final reasonMessage = switch (reason) {
      'camera' => 'Sign in to use camera solving.',
      'lesson-limit' => 'Guests can open one lesson. Sign in to continue.',
      _ => null,
    };

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF6650A4),
              Color(0xFF9980F0),
              Color(0xFF8B6FC0),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              top: -50,
              left: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            Positioned(
              bottom: 150,
              right: -80,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
            Positioned(
              top: 100,
              right: -60,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            // Main content
            SafeArea(
              child: BlocConsumer<AuthBloc, AuthState>(
                listener: (context, state) {
                  if (state.status == AuthStatus.authenticated) {
                    context.go('/');
                  }

                  if (state.status == AuthStatus.failure &&
                      state.errorMessage != null) {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(
                          content: Text(state.errorMessage!),
                          backgroundColor: Colors.red.shade400,
                        ),
                      );
                  }
                },
                builder: (context, state) {
                  final loading = state.isLoading;
                  return Column(
                    children: [
                      if (reasonMessage != null)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            reasonMessage,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      const Spacer(),
                      // Logo and title
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.functions,
                          size: 48,
                          color: Color(0xFF6650A4),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Kram',
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Master math, one step at a time',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),
                      const Spacer(),
                      // Sign in buttons
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            // Google Sign-In Button
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: loading
                                    ? null
                                    : () {
                                        context.read<AuthBloc>().add(
                                              const AuthGoogleSignInRequested(),
                                            );
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black87,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.network(
                                      'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                                      width: 22,
                                      height: 22,
                                      errorBuilder: (_, __, ___) => const Icon(
                                        Icons.g_mobiledata,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Continue with Google',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: OutlinedButton(
                                onPressed: loading
                                    ? null
                                    : () => context.go('/username-login'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white70, width: 2),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text(
                                  'Continue with username',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            if (loading)
                              const Padding(
                                padding: EdgeInsets.only(top: 20),
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: loading ? null : () => context.go('/'),
                        child: Text(
                          'Continue as guest',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Footer
                      TextButton(
                        onPressed: loading
                            ? null
                            : () async {
                                final prefs =
                                    await SharedPreferences.getInstance();
                                await prefs.setBool('carousel_seen', false);
                                if (context.mounted) context.go('/carousel');
                              },
                        child: Text(
                          'View onboarding again',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
