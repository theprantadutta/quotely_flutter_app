import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:go_router/go_router.dart';
import 'package:quotely_flutter_app/screens/tab_screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnboardingScreen extends StatefulWidget {
  static const kRouteName = '/onboarding';
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  bool _isLastPage = false;

  @override
  void initState() {
    super.initState();
    FlutterNativeSplash.remove();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // This function sets the flag and navigates to the HomeScreen
  void _finishOnboarding() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('hasSeenOnboarding', true);

    if (mounted) {
      // Use pushReplacementNamed to prevent the user from going back to the onboarding
      context.pushReplacement(HomeScreen.kRouteName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // The PageView that contains the onboarding slides
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                // The last page has index 2 (0, 1, 2)
                _isLastPage = (index == 2);
              });
            },
            children: [
              _buildOnboardingPage(
                theme: theme,
                imagePath: 'assets/onboarding/onboarding_1.png',
                title: 'Welcome to Quotely!',
                subtitle: 'Your daily dose of inspiration and wisdom awaits.',
              ),
              _buildOnboardingPage(
                theme: theme,
                imagePath: 'assets/onboarding/onboarding_2.png',
                title: 'Discover Endless Inspiration',
                subtitle:
                    'Explore thousands of timeless quotes and fascinating AI facts.',
              ),
              _buildOnboardingPage(
                theme: theme,
                imagePath: 'assets/onboarding/onboarding_3.png',
                title: 'Get Inspired Daily',
                subtitle:
                    'Receive custom notifications and save your favorite moments.',
              ),
            ],
          ),

          // The bottom navigation controls (dots and buttons)
          Positioned(
            bottom: 30.0,
            left: 20.0,
            right: 20.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // The "SKIP" button
                TextButton(
                  onPressed: _finishOnboarding,
                  child: const Text(
                    'SKIP',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),

                // The animated dot indicator
                SmoothPageIndicator(
                  controller: _pageController,
                  count: 3,
                  effect: WormEffect(
                    spacing: 16,
                    dotColor: Colors.black26,
                    activeDotColor: theme.colorScheme.primary,
                  ),
                  onDotClicked: (index) => _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeIn,
                  ),
                ),

                // The "NEXT" or "GET STARTED" button
                TextButton(
                  onPressed: _isLastPage
                      ? _finishOnboarding
                      : () => _pageController.nextPage(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeIn,
                          ),
                  child: Text(
                    _isLastPage ? 'DONE' : 'NEXT',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
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

  // A reusable helper widget for building each page to keep the code clean
  Widget _buildOnboardingPage({
    required ThemeData theme,
    required String imagePath,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(imagePath, height: 300),
          const SizedBox(height: 40),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}
