import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_bloc/theme_bloc.dart';
import 'core/theme/theme_bloc/theme_event.dart';
import 'core/theme/theme_bloc/theme_state.dart';
import 'core/router/app_router.dart';
import 'core/l10n/app_locale.dart';
import 'injection.dart';

class MathQuestApp extends StatelessWidget {
  const MathQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => ThemeBloc()..add(const ThemeLoadRequested()),
        ),
        BlocProvider(
          create: (_) => AuthBloc(getIt()),
        ),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, state) {
          return ValueListenableBuilder<String>(
            valueListenable: AppLocale.localeNotifier,
            builder: (_, localeCode, __) {
              return MaterialApp.router(
                title: 'Kram',
                debugShowCheckedModeBanner: false,
                locale: Locale(localeCode),
                theme: AppTheme.light,
                darkTheme: AppTheme.dark,
                themeMode: state.mode,
                routerConfig: appRouter,
              );
            },
          );
        },
      ),
    );
  }
}
