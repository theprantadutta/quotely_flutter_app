import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/colors/app_colors.dart';
import '../../theme/gradients/app_gradients.dart';

/// A warm, neumorphic layout for notification screens (Quote of the Day, Fact of the Day, etc.)
class WarmNotificationScreenLayout extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget contentWidget;
  final String allItemsRoute;
  final String seeAllLabel;

  const WarmNotificationScreenLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.contentWidget,
    required this.allItemsRoute,
    required this.seeAllLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppGradients.scaffoldBackground(context),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with back button
              _buildHeader(context, colors, isDark),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      contentWidget,
                      const SizedBox(height: 16),
                      _NeumorphicSeeAllButton(
                        label: seeAllLabel,
                        colors: colors,
                        isDark: isDark,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          context.push(allItemsRoute);
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppColorScheme colors, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 16, 20, 16),
      child: Row(
        children: [
          // Back button
          _NeumorphicBackButton(
            colors: colors,
            isDark: isDark,
            onTap: () {
              HapticFeedback.lightImpact();
              context.pop();
            },
          ),
          const SizedBox(width: 12),
          // Icon
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
                icon,
                color: colors.onPrimary,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.lora(
                    fontSize: 12,
                    color: colors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NeumorphicBackButton extends StatefulWidget {
  final AppColorScheme colors;
  final bool isDark;
  final VoidCallback onTap;

  const _NeumorphicBackButton({
    required this.colors,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_NeumorphicBackButton> createState() => _NeumorphicBackButtonState();
}

class _NeumorphicBackButtonState extends State<_NeumorphicBackButton> {
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
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: widget.colors.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          boxShadow: _isPressed
              ? []
              : [
                  BoxShadow(
                    color: widget.colors.shadowDark
                        .withValues(alpha: widget.isDark ? 0.5 : 0.25),
                    offset: const Offset(3, 3),
                    blurRadius: 6,
                  ),
                  BoxShadow(
                    color: widget.colors.shadowLight
                        .withValues(alpha: widget.isDark ? 0.08 : 0.7),
                    offset: const Offset(-3, -3),
                    blurRadius: 6,
                  ),
                ],
        ),
        child: Center(
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: widget.colors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _NeumorphicSeeAllButton extends StatefulWidget {
  final String label;
  final AppColorScheme colors;
  final bool isDark;
  final VoidCallback onTap;

  const _NeumorphicSeeAllButton({
    required this.label,
    required this.colors,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_NeumorphicSeeAllButton> createState() => _NeumorphicSeeAllButtonState();
}

class _NeumorphicSeeAllButtonState extends State<_NeumorphicSeeAllButton> {
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
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: widget.colors.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _isPressed
              ? []
              : [
                  BoxShadow(
                    color: widget.colors.shadowDark
                        .withValues(alpha: widget.isDark ? 0.5 : 0.25),
                    offset: const Offset(4, 4),
                    blurRadius: 8,
                  ),
                  BoxShadow(
                    color: widget.colors.shadowLight
                        .withValues(alpha: widget.isDark ? 0.08 : 0.7),
                    offset: const Offset(-4, -4),
                    blurRadius: 8,
                  ),
                ],
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.label,
                style: GoogleFonts.lora(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: widget.colors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: widget.colors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A warm, neumorphic layout for notification list screens
class WarmNotificationListLayout extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget listWidget;

  const WarmNotificationListLayout({
    super.key,
    required this.title,
    required this.icon,
    required this.listWidget,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppGradients.scaffoldBackground(context),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with back button
              _buildHeader(context, colors, isDark),

              // List content
              Expanded(
                child: listWidget,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppColorScheme colors, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 16, 20, 16),
      child: Row(
        children: [
          // Back button
          _NeumorphicBackButton(
            colors: colors,
            isDark: isDark,
            onTap: () {
              HapticFeedback.lightImpact();
              context.pop();
            },
          ),
          const SizedBox(width: 12),
          // Icon
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
                icon,
                color: colors.onPrimary,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
