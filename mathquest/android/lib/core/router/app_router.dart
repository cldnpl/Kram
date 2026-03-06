import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/pages/login_page.dart';
<<<<<<< HEAD
import '../../features/auth/presentation/pages/username_login_page.dart';
=======
import '../../features/auth/presentation/pages/username_password_auth_page.dart';
import '../../features/auth/presentation/pages/username_password_register_page.dart';
>>>>>>> 5c98b591af9cb2ac601d5e8e91219daddfd31737
import '../../features/onboarding/presentation/pages/carousel_onboarding_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/lesson/presentation/pages/lesson_detail_page.dart';
import '../../features/home/presentation/pages/category_subtopics_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/pages/profile_setup_page.dart';
import '../../features/camera/presentation/pages/camera_page.dart';
import '../../features/shop/presentation/pages/shop_page.dart';
import 'main_shell_scaffold.dart';

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
<<<<<<< HEAD
    final prefs = await SharedPreferences.getInstance();
    final hasSeenCarousel = prefs.getBool(_carouselSeenKey) ?? false;
    final hasCompletedProfile = prefs.getBool(_profileSetupDoneKey) ?? false;
    final profileName = prefs.getString('profile_name') ?? '';
    final profileLevel = prefs.getString('profile_level') ?? '';
    final isProfileComplete = hasCompletedProfile &&
        profileName.isNotEmpty &&
        profileLevel.isNotEmpty;
    final isFirebaseAuth = FirebaseAuth.instance.currentUser != null;
    final hasUsername = (prefs.getString('profile_username') ?? '').isNotEmpty;
    final isLoggedIn = isFirebaseAuth || hasUsername;
=======
    final isAuthenticated = FirebaseAuth.instance.currentUser != null;
>>>>>>> fc0d863da90dc4edd125a225f5211d800566e104

    final location = state.matchedLocation;
    final isLoginRoute = location == '/login';
    final isCameraRoute = location == '/camera';

<<<<<<< HEAD
    if (!hasSeenCarousel) {
      return isCarouselRoute ? null : '/carousel';
    }

    if (!isProfileComplete) {
      return isProfileSetupRoute ? null : '/profile-setup';
    }

    if (!isLoggedIn && isCameraRoute) {
      return '/login?reason=camera';
    }

    if (isCarouselRoute || isProfileSetupRoute) {
      return '/';
    }

    if (isLoggedIn && isLoginRoute) {
=======
    if (!isAuthenticated && isCameraRoute) {
      return '/login?reason=camera';
    }

    if (isAuthenticated && isLoginRoute) {
>>>>>>> fc0d863da90dc4edd125a225f5211d800566e104
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
    GoRoute(path: '/camera', builder: (_, __) => const CameraPage()),
  ],
);
