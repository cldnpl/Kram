import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _carouselSeenKey = 'carousel_seen';

class CarouselOnboardingPage extends StatefulWidget {
  const CarouselOnboardingPage({super.key});

  @override
  State<CarouselOnboardingPage> createState() => _CarouselOnboardingPageState();
}

class _CarouselOnboardingPageState extends State<CarouselOnboardingPage> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  static const _slides = [
    _OnboardingSlide(
      title: 'Scan math problems in seconds',
      subtitle:
          'Use the camera to capture equations and get clear step-by-step help.',
      imagePath: 'assets/images/onboarding_1.png',
    ),
    _OnboardingSlide(
      title: 'Learn with structured lessons',
      subtitle:
          'Build skills from basics to advanced topics with a guided path.',
      imagePath: 'assets/images/onboarding_2.png',
    ),
    _OnboardingSlide(
      title: 'Track progress and streaks',
      subtitle: 'Stay consistent and unlock rewards while improving every day.',
      imagePath: 'assets/images/onboarding_3.png',
    ),
  ];

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_carouselSeenKey, true);
    if (!mounted) return;
    context.go('/login');
  }

  void _next() {
    if (_currentIndex == _slides.length - 1) {
      _completeOnboarding();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentIndex == _slides.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _completeOnboarding,
                  child: const Text('Skip'),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (index) =>
                      setState(() => _currentIndex = index),
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return _OnboardingSlideView(slide: slide);
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _slides.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentIndex == index ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentIndex == index
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _next,
                  child: Text(isLast ? 'Continue' : 'Next'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingSlideView extends StatelessWidget {
  const _OnboardingSlideView({required this.slide});

  final _OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: double.infinity,
          height: 240,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset(
            slide.imagePath,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Center(
              child: Icon(
                Icons.image_outlined,
                size: 56,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 30),
        Text(
          slide.title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 12),
        Text(
          slide.subtitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.title,
    required this.subtitle,
    required this.imagePath,
  });

  final String title;
  final String subtitle;
  final String imagePath;
}
