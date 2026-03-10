import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/l10n/app_locale.dart';

const _onboardingDoneKey = 'onboarding_done';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocale.tr('setup'))),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(decoration: InputDecoration(labelText: AppLocale.tr('name'))),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(labelText: AppLocale.tr('age')),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: AppLocale.tr('math_level')),
              items: [
                AppLocale.tr('level_beginner'),
                AppLocale.tr('level_intermediate'),
                AppLocale.tr('level_advanced')
              ]
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (_) {},
            ),
            const Spacer(),
            FilledButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool(_onboardingDoneKey, true);
                if (context.mounted) context.go('/');
              },
              child: Text(AppLocale.tr('continue')),
            ),
          ],
        ),
      ),
    );
  }
}
