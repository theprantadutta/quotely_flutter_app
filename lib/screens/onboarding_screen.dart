import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quotely_flutter_app/screens/tab_screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/colors/app_colors.dart';
import '../theme/gradients/app_gradients.dart';

class OnboardingScreen extends StatefulWidget {
  static const kRouteName = '/onboarding';
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<OnboardingPageData> _pages = [
    OnboardingPageData(
      imagePath: 'assets/onboarding/onboarding_1.png',
      title: 'Welcome to Quotely!',
      subtitle: 'Your daily dose of inspiration and wisdom awaits.',
      gradientIndex: 0,
    ),
    OnboardingPageData(
      imagePath: 'assets/onboarding/onboarding_2.png',
      title: 'Discover Endless Inspiration',
      subtitle: 'Explore thousands of timeless quotes and fascinating AI facts.',
      gradientIndex: 1,
    ),
    OnboardingPageData(
      imagePath: 'assets/onboarding/onboarding_3.png',
      title: 'Get Inspired Daily',
      subtitle: 'Receive custom notifications and save your favorite moments.',
      gradientIndex: 2,
    ),
  ];

  @override
  void initState() {
    super.initState();
    FlutterNativeSplash.remove();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _finishOnboarding() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('hasSeenOnboarding', true);

    if (mounted) {
      context.pushReplacement(HomeScreen.kRouteName);
    }
  }

  void _nextPage() {
    HapticFeedback.lightImpact();
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _skipOnboarding() {
    HapticFeedback.lightImpact();
    _finishOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            // Animated background gradient
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              decoration: BoxDecoration(
                gradient: _getPageGradient(context, _currentPage),
              ),
            ),

            // Page content
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
              itemCount: _pages.length,
              itemBuilder: (context, index) {
                return _OnboardingPage(
                  data: _pages[index],
                  colors: colors,
                  isDark: isDark,
                );
              },
            ),

            // Bottom controls
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Custom neumorphic page indicator
                      _NeumorphicPageIndicator(
                        pageCount: _pages.length,
                        currentPage: _currentPage,
                        colors: colors,
                        isDark: isDark,
                        onDotTap: (index) {
                          HapticFeedback.lightImpact();
                          _pageController.animateToPage(
                            index,
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOutCubic,
                          );
                        },
                      ),
                      const SizedBox(height: 32),

                      // Action buttons
                      Row(
                        children: [
                          // Skip button
                          if (!isLastPage)
                            Expanded(
                              child: _NeumorphicOutlineButton(
                                label: 'Skip',
                                onTap: _skipOnboarding,
                                colors: colors,
                                isDark: isDark,
                              ),
                            )
                          else
                            const Spacer(),

                          const SizedBox(width: 16),

                          // Next / Get Started button
                          Expanded(
                            flex: isLastPage ? 2 : 1,
                            child: _NeumorphicPrimaryButton(
                              label: isLastPage ? 'Get Started' : 'Next',
                              onTap: _nextPage,
                              colors: colors,
                              isDark: isDark,
                              showArrow: !isLastPage,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  LinearGradient _getPageGradient(BuildContext context, int pageIndex) {
    switch (pageIndex) {
      case 0:
        return AppGradients.onboardingPage(context, 0);
      case 1:
        return AppGradients.onboardingPage(context, 1);
      case 2:
        return AppGradients.onboardingPage(context, 2);
      default:
        return AppGradients.scaffoldBackground(context);
    }
  }
}

class OnboardingPageData {
  final String imagePath;
  final String title;
  final String subtitle;
  final int gradientIndex;

  const OnboardingPageData({
    required this.imagePath,
    required this.title,
    required this.subtitle,
    required this.gradientIndex,
  });
}

class _OnboardingPage extends StatelessWidget {
  final OnboardingPageData data;
  final AppColorScheme colors;
  final bool isDark;

  const _OnboardingPage({
    required this.data,
    required this.colors,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          children: [
            const Spacer(flex: 1),

            // Neumorphic image frame
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: colors.shadowDark.withValues(alpha: isDark ? 0.6 : 0.35),
                    offset: const Offset(8, 8),
                    blurRadius: 16,
                  ),
                  BoxShadow(
                    color: colors.shadowLight.withValues(alpha: isDark ? 0.1 : 0.8),
                    offset: const Offset(-8, -8),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: Image.asset(
                data.imagePath,
                height: 220,
                fit: BoxFit.contain,
              ),
            ),

            const Spacer(flex: 1),

            // Title
            Text(
              data.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
                height: 1.2,
              ),
            ),

            const SizedBox(height: 16),

            // Subtitle
            Text(
              data.subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.lora(
                fontSize: 16,
                color: colors.onSurfaceVariant,
                height: 1.5,
              ),
            ),

            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}

class _NeumorphicPageIndicator extends StatelessWidget {
  final int pageCount;
  final int currentPage;
  final AppColorScheme colors;
  final bool isDark;
  final Function(int) onDotTap;

  const _NeumorphicPageIndicator({
    required this.pageCount,
    required this.currentPage,
    required this.colors,
    required this.isDark,
    required this.onDotTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colors.shadowDark.withValues(alpha: isDark ? 0.4 : 0.2),
            offset: const Offset(4, 4),
            blurRadius: 8,
          ),
          BoxShadow(
            color: colors.shadowLight.withValues(alpha: isDark ? 0.05 : 0.6),
            offset: const Offset(-4, -4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(pageCount, (index) {
          final isActive = index == currentPage;
          return GestureDetector(
            onTap: () => onDotTap(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: EdgeInsets.only(right: index < pageCount - 1 ? 12 : 0),
              width: isActive ? 28 : 10,
              height: 10,
              decoration: BoxDecoration(
                color: isActive ? colors.primary : colors.outline,
                borderRadius: BorderRadius.circular(5),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: colors.primary.withValues(alpha: 0.4),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _NeumorphicPrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final AppColorScheme colors;
  final bool isDark;
  final bool showArrow;

  const _NeumorphicPrimaryButton({
    required this.label,
    required this.onTap,
    required this.colors,
    required this.isDark,
    this.showArrow = false,
  });

  @override
  State<_NeumorphicPrimaryButton> createState() => _NeumorphicPrimaryButtonState();
}

class _NeumorphicPrimaryButtonState extends State<_NeumorphicPrimaryButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              widget.colors.primary,
              widget.colors.primaryDark,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: _isPressed
              ? []
              : [
                  BoxShadow(
                    color: widget.colors.primary.withValues(alpha: 0.4),
                    offset: const Offset(0, 4),
                    blurRadius: 12,
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.label,
              style: GoogleFonts.lora(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: widget.colors.onPrimary,
              ),
            ),
            if (widget.showArrow) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_rounded,
                size: 20,
                color: widget.colors.onPrimary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NeumorphicOutlineButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final AppColorScheme colors;
  final bool isDark;

  const _NeumorphicOutlineButton({
    required this.label,
    required this.onTap,
    required this.colors,
    required this.isDark,
  });

  @override
  State<_NeumorphicOutlineButton> createState() => _NeumorphicOutlineButtonState();
}

class _NeumorphicOutlineButtonState extends State<_NeumorphicOutlineButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          color: _isPressed
              ? widget.colors.surfaceContainer
              : widget.colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.colors.outline,
            width: 1.5,
          ),
          boxShadow: _isPressed
              ? []
              : [
                  BoxShadow(
                    color: widget.colors.shadowDark
                        .withValues(alpha: widget.isDark ? 0.4 : 0.2),
                    offset: const Offset(3, 3),
                    blurRadius: 6,
                  ),
                  BoxShadow(
                    color: widget.colors.shadowLight
                        .withValues(alpha: widget.isDark ? 0.05 : 0.6),
                    offset: const Offset(-3, -3),
                    blurRadius: 6,
                  ),
                ],
        ),
        child: Center(
          child: Text(
            widget.label,
            style: GoogleFonts.lora(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: widget.colors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
