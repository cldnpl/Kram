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
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
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
                    SnackBar(content: Text(state.errorMessage!)),
                  );
              }
            },
            builder: (context, state) {
              final loading = state.isLoading;
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Kram',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Sign in to continue',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 48),
                  FilledButton.icon(
                    onPressed: loading
                        ? null
                        : () {
                            context.read<AuthBloc>().add(
                                  const AuthGoogleSignInRequested(),
                                );
                          },
                    icon: const Icon(Icons.login),
                    label: const Text('Google Sign-In'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: loading
                        ? null
                        : () {
                            context.read<AuthBloc>().add(
                                  const AuthAppleSignInRequested(),
                                );
                          },
                    icon: const Icon(Icons.apple),
                    label: const Text('Apple Sign-In'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: loading
                        ? null
                        : () async {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setBool('carousel_seen', false);
                            if (context.mounted) context.go('/carousel');
                          },
                    child: const Text('View onboarding'),
                  ),
                  if (loading) const CircularProgressIndicator(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
