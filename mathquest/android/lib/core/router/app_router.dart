import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/onboarding/presentation/pages/carousel_onboarding_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/lesson/presentation/pages/lesson_detail_page.dart';
import '../../features/home/presentation/pages/category_subtopics_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/pages/profile_setup_page.dart';
import '../../features/camera/presentation/pages/camera_page.dart';
import '../../features/shop/presentation/pages/shop_page.dart';

const _carouselSeenKey = 'carousel_seen';
const _profileSetupDoneKey = 'profile_setup_done';

final appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenCarousel = prefs.getBool(_carouselSeenKey) ?? false;
    final hasCompletedProfile = prefs.getBool(_profileSetupDoneKey) ?? false;
    final isAuthenticated = FirebaseAuth.instance.currentUser != null;

    final location = state.matchedLocation;
    final isCarouselRoute = location == '/carousel';
    final isLoginRoute = location == '/login';
    final isProfileSetupRoute = location == '/profile-setup';

    if (!hasSeenCarousel) {
      return isCarouselRoute ? null : '/carousel';
    }

    if (!isAuthenticated) {
      return isLoginRoute ? null : '/login';
    }

    if (!hasCompletedProfile) {
      return isProfileSetupRoute ? null : '/profile-setup';
    }

    if (isCarouselRoute || isLoginRoute || isProfileSetupRoute) {
      return '/';
    }

    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
    GoRoute(
      path: '/carousel',
      builder: (_, __) => const CarouselOnboardingPage(),
    ),
    GoRoute(
      path: '/profile-setup',
      builder: (_, __) => const ProfileSetupPage(),
    ),
    GoRoute(path: '/', builder: (_, __) => const HomePage()),
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
    GoRoute(path: '/profile', builder: (_, __) => const ProfilePage()),
  ],
);
