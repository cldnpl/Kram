import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/l10n/app_locale.dart';

/// Register page: stesso layout del Login (sfondo bianco, viola dell'app, card bianca) con titolo "Register".
class UsernamePasswordRegisterPage extends StatefulWidget {
  const UsernamePasswordRegisterPage({super.key});

  @override
  State<UsernamePasswordRegisterPage> createState() =>
      _UsernamePasswordRegisterPageState();
}

class _UsernamePasswordRegisterPageState
    extends State<UsernamePasswordRegisterPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _loading = false;
  String? _errorMessage;

  static const _appPurple = Color(0xFF6650A4);

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submitRegister() {
    setState(() => _errorMessage = null);
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }
    setState(() => _loading = true);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage =
            'Registration not yet connected. Use Google or Apple for now.';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      body: Stack(
        children: [
          Positioned(
            top: -40,
            left: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _appPurple.withOpacity(0.18),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.sizeOf(context).height * 0.35,
            right: -80,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _appPurple.withOpacity(0.12),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: MediaQuery.sizeOf(context).width * 0.05,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _appPurple.withOpacity(0.1),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.chevron_left),
                    style: IconButton.styleFrom(
                      foregroundColor: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          AppLocale.tr('register'),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildFieldSection(
                                theme,
                                label: 'Username',
                                controller: _usernameController,
                                obscureText: false,
                              ),
                              Divider(height: 1, color: theme.dividerColor),
                              _buildFieldSection(
                                theme,
                                label: 'Password',
                                controller: _passwordController,
                                obscureText: true,
                              ),
                              Divider(height: 1, color: theme.dividerColor),
                              _buildFieldSection(
                                theme,
                                label: 'Confirm password',
                                controller: _confirmPasswordController,
                                obscureText: true,
                              ),
                              Divider(height: 1, color: theme.dividerColor),
                              InkWell(
                                onTap: () => context.pop(),
                                borderRadius: const BorderRadius.vertical(
                                  bottom: Radius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 20,
                                    horizontal: 20,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        AppLocale.tr('already_have_account'),
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        AppLocale.tr('sign_in'),
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: _appPurple,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _errorMessage!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 56,
                          child: FilledButton(
                            onPressed: _loading
                                ? null
                                : _submitRegister,
                            style: FilledButton.styleFrom(
                              backgroundColor: _appPurple,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _loading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(AppLocale.tr('register')),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldSection(
    ThemeData theme, {
    required String label,
    required TextEditingController controller,
    required bool obscureText,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            obscureText: obscureText,
            decoration: const InputDecoration(
              hintText: 'Value',
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            style: theme.textTheme.bodyLarge,
            textInputAction: TextInputAction.next,
          ),
        ],
      ),
    );
  }
}
