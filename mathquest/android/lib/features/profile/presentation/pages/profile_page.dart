import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.status == AuthStatus.unauthenticated) {
            context.go('/login');
          }
          if (state.status == AuthStatus.failure &&
              state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
          }
        },
        builder: (context, state) {
          final user = state.user;
          final isLoggedIn = state.status == AuthStatus.authenticated;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ListTile(
                leading: Icon(isLoggedIn ? Icons.logout : Icons.login),
                title: Text(isLoggedIn ? 'Sign Out' : 'Sign In'),
                trailing: state.isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
                onTap: state.isLoading
                    ? null
                    : () {
                        if (isLoggedIn) {
                          context
                              .read<AuthBloc>()
                              .add(const AuthSignOutRequested());
                        } else {
                          context.go('/login');
                        }
                      },
              ),
              const Divider(),
              const CircleAvatar(radius: 40),
              const SizedBox(height: 16),
              Text(
                user?.displayName ?? 'User',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              if (user?.email != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    user!.email!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.local_fire_department),
                title: const Text('Streak'),
                trailing: Text(
                  '0 days',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.school),
                title: const Text('Lessons completed'),
                trailing: Text(
                  '0',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Settings'),
                onTap: () {},
              ),
            ],
          );
        },
      ),
    );
  }
}
