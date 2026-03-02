import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoggedIn = false;
  static const _isLoggedInKey = 'is_logged_in';

  @override
  void initState() {
    super.initState();
    _loadLoggedIn();
  }

  Future<void> _loadLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false);
  }

  Future<void> _setLoggedIn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, value);
    setState(() => _isLoggedIn = value);
  }

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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: Icon(_isLoggedIn ? Icons.logout : Icons.login),
            title: Text(_isLoggedIn ? 'Sign Out' : 'Sign In'),
            onTap: () async {
              if (_isLoggedIn) {
                await _setLoggedIn(false);
              } else {
                context.go('/login');
              }
            },
          ),
          const Divider(),
          const CircleAvatar(radius: 40),
          const SizedBox(height: 16),
          Text('User', style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.local_fire_department),
            title: const Text('Streak'),
            trailing: Text('0 days', style: Theme.of(context).textTheme.bodyLarge),
          ),
          ListTile(
            leading: const Icon(Icons.school),
            title: const Text('Lessons completed'),
            trailing: Text('0', style: Theme.of(context).textTheme.bodyLarge),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
