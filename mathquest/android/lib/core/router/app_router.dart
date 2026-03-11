import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/username_login_page.dart';
import '../../features/auth/presentation/pages/username_password_auth_page.dart';
import '../../features/auth/presentation/pages/username_password_register_page.dart';
import '../../features/onboarding/presentation/pages/carousel_onboarding_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/lesson/presentation/pages/lesson_detail_page.dart';
import '../../features/home/presentation/pages/category_subtopics_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/pages/profile_setup_page.dart';
import '../../features/camera/presentation/pages/camera_page.dart';
import '../../features/shop/presentation/pages/shop_page.dart';
import '../../features/streak/presentation/pages/streak_calendar_page.dart';
import 'main_shell_scaffold.dart';

const _carouselSeenKey = 'carousel_seen';
const _sessionLoggedInKey = 'session_logged_in';

// Notifier to trigger router refresh
class RouterRefreshNotifier extends ChangeNotifier {
  static final RouterRefreshNotifier instance = RouterRefreshNotifier._();
  RouterRefreshNotifier._();

  void refresh() {
    notifyListeners();
  }
}

final appRouter = GoRouter(
  initialLocation: '/',
  refreshListenable: RouterRefreshNotifier.instance,
  redirect: (context, state) async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenCarousel = prefs.getBool(_carouselSeenKey) ?? false;
    final isFirebaseAuth = FirebaseAuth.instance.currentUser != null;
    final hasSession = prefs.getBool(_sessionLoggedInKey) ?? false;
    final isLoggedIn = isFirebaseAuth || hasSession;

    final location = state.matchedLocation;
    final isLoginRoute = location == '/login';
    final isCameraRoute = location == '/camera';
    final isCarouselRoute = location == '/carousel';
    final isProfileSetupRoute = location == '/profile-setup';

    if (!hasSeenCarousel) {
      return isCarouselRoute ? null : '/carousel';
    }

    if (!isLoggedIn && isCameraRoute) {
      return '/login?reason=camera';
    }

    if (isCarouselRoute || isProfileSetupRoute) {
      return '/';
    }

    if (isLoggedIn && isLoginRoute) {
      return '/';
    }

    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
    GoRoute(path: '/username-login', builder: (_, __) => const UsernameLoginPage()),
    GoRoute(
      path: '/login/username-password',
      builder: (_, __) => const UsernamePasswordAuthPage(),
    ),
    GoRoute(
      path: '/login/username-password/register',
      builder: (_, __) => const UsernamePasswordRegisterPage(),
    ),
    GoRoute(
      path: '/carousel',
      builder: (_, __) => const CarouselOnboardingPage(),
    ),
    GoRoute(
      path: '/profile-setup',
      builder: (_, __) => const ProfileSetupPage(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          MainShellScaffold(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [GoRoute(path: '/', builder: (_, __) => const HomePage())],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/profile', builder: (_, __) => const ProfilePage()),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/category/:categoryId',
      builder: (context, state) {
        final categoryId = state.pathParameters['categoryId'] ?? '';
        return CategorySubtopicsPage(categoryId: categoryId);
      },
    ),
    GoRoute(
      path: '/lesson/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return LessonDetailPage(lessonId: id);
      },
    ),
    GoRoute(path: '/shop', builder: (_, __) => const ShopPage()),
    GoRoute(path: '/streak', builder: (_, __) => const StreakCalendarPage()),
    GoRoute(path: '/camera', builder: (_, __) => const CameraPage()),
  ],
);
