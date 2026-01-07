import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quotely_flutter_app/service_locator/init_service_locators.dart';

import '../../components/favorites_screen/facts_list.dart';
import '../../components/favorites_screen/quote_list.dart';
import '../../theme/colors/app_colors.dart';
import '../../theme/gradients/app_gradients.dart';

class FavoritesScreen extends StatefulWidget {
  static const kRouteName = '/favorites';
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _analytics = getIt.get<FirebaseAnalytics>();
  bool showQuotes = true;

  void _toggleView(bool displayQuotes) {
    if (showQuotes == displayQuotes) return;

    HapticFeedback.lightImpact();
    setState(() => showQuotes = displayQuotes);

    _analytics.logEvent(
      name: 'favorites_view_changed',
      parameters: {'view_name': displayQuotes ? 'quotes' : 'facts'},
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;

    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.scaffoldBackground(context),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(colors),

            // Segmented control
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _NeumorphicSegmentedControl(
                showQuotes: showQuotes,
                onToggle: _toggleView,
                colors: colors,
                isDark: isDark,
              ),
            ),

            const SizedBox(height: 16),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.05, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: showQuotes
                      ? const QuoteList(key: ValueKey('QuoteList'))
                      : const FactsList(key: ValueKey('FactsList')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppColorScheme colors) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppGradients.warmPrimary(context),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.3),
                  offset: const Offset(0, 4),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.favorite_rounded,
                color: colors.onPrimary,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Favorites',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
              Text(
                'Your saved treasures',
                style: GoogleFonts.lora(
                  fontSize: 12,
                  color: colors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NeumorphicSegmentedControl extends StatelessWidget {
  final bool showQuotes;
  final Function(bool) onToggle;
  final AppColorScheme colors;
  final bool isDark;

  const _NeumorphicSegmentedControl({
    required this.showQuotes,
    required this.onToggle,
    required this.colors,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.shadowDark.withValues(alpha: isDark ? 0.5 : 0.25),
            offset: const Offset(4, 4),
            blurRadius: 8,
          ),
          BoxShadow(
            color: colors.shadowLight.withValues(alpha: isDark ? 0.08 : 0.7),
            offset: const Offset(-4, -4),
            blurRadius: 8,
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final containerWidth = constraints.maxWidth;
          final indicatorWidth = (containerWidth - 8) / 2; // 4px padding on each side

          return Stack(
            children: [
              // Animated indicator
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                left: showQuotes ? 4 : containerWidth / 2,
                top: 4,
                bottom: 4,
                width: indicatorWidth,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [colors.primary, colors.primaryDark],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: colors.primary.withValues(alpha: 0.4),
                        offset: const Offset(0, 2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: _SegmentButton(
                      icon: Icons.format_quote_rounded,
                      label: 'Quotes',
                      isSelected: showQuotes,
                      onTap: () => onToggle(true),
                      colors: colors,
                    ),
                  ),
                  Expanded(
                    child: _SegmentButton(
                      icon: Icons.lightbulb_outline_rounded,
                      label: 'Facts',
                      isSelected: !showQuotes,
                      onTap: () => onToggle(false),
                      colors: colors,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final AppColorScheme colors;

  const _SegmentButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: GoogleFonts.lora(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? colors.onPrimary : colors.onSurfaceVariant,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

class FavoritesScreenSkeletor extends StatelessWidget {
  final Widget widget;

  const FavoritesScreenSkeletor({super.key, required this.widget});

  @override
  Widget build(BuildContext context) {
    return Column(children: [Expanded(child: widget)]);
  }
}
