import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quotely_flutter_app/components/author_detail_screen/author_detail_author_bio.dart';
import 'package:quotely_flutter_app/components/author_detail_screen/author_detail_author_quotes.dart';

import '../components/shared/something_went_wrong.dart';
import '../riverpods/get_author_detail_provider.dart';
import '../theme/colors/app_colors.dart';
import '../theme/gradients/app_gradients.dart';

class AuthorDetailScreen extends ConsumerStatefulWidget {
  static const kRouteName = '/author-detail';

  final String authorSlug;

  const AuthorDetailScreen({
    super.key,
    required this.authorSlug,
  });

  @override
  ConsumerState<AuthorDetailScreen> createState() => _AuthorDetailScreenState();
}

class _AuthorDetailScreenState extends ConsumerState<AuthorDetailScreen> {
  bool isAuthorBioSelected = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;

    final authorProvider = ref.watch(
      fetchAuthorDetailProvider(widget.authorSlug),
    );

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppGradients.scaffoldBackground(context),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with back button
              _buildHeader(context, colors),

              // Segmented control
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _NeumorphicSegmentedControl(
                  showBio: isAuthorBioSelected,
                  onToggle: (showBio) {
                    HapticFeedback.lightImpact();
                    setState(() => isAuthorBioSelected = showBio);
                  },
                  colors: colors,
                  isDark: isDark,
                ),
              ),

              const SizedBox(height: 16),

              // Content
              Expanded(
                child: authorProvider.when(
                  data: (author) {
                    if (author == null) return _buildErrorWidget(colors);
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: child,
                        );
                      },
                      child: isAuthorBioSelected
                          ? AuthorDetailAuthorBio(
                              key: const ValueKey('bio'),
                              author: author,
                            )
                          : AuthorDetailAuthorQuotes(
                              key: const ValueKey('quotes'),
                              author: author,
                            ),
                    );
                  },
                  error: (err, stack) => _buildErrorWidget(colors),
                  loading: () => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: AuthorDetailAuthorBioSkeletor(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppColorScheme colors) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 16, 20, 16),
      child: Row(
        children: [
          // Back button
          _NeumorphicBackButton(
            colors: colors,
            isDark: Theme.of(context).brightness == Brightness.dark,
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Author',
                  style: GoogleFonts.lora(
                    fontSize: 12,
                    color: colors.textMuted,
                  ),
                ),
                Text(
                  widget.authorSlug.replaceAll('-', ' ').split(' ').map(
                    (word) => word.isNotEmpty
                        ? '${word[0].toUpperCase()}${word.substring(1)}'
                        : word,
                  ).join(' '),
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(AppColorScheme colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_off_rounded,
            size: 64,
            color: colors.textMuted.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          SomethingWentWrong(
            title: 'Failed to load author',
            onRetryPressed: () {
              ref.invalidate(fetchAuthorDetailProvider(widget.authorSlug));
            },
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

class _NeumorphicSegmentedControl extends StatelessWidget {
  final bool showBio;
  final Function(bool) onToggle;
  final AppColorScheme colors;
  final bool isDark;

  const _NeumorphicSegmentedControl({
    required this.showBio,
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
      child: Stack(
        children: [
          // Animated indicator
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            left: showBio ? 4 : (MediaQuery.of(context).size.width - 32) / 2,
            top: 4,
            bottom: 4,
            width: (MediaQuery.of(context).size.width - 32) / 2 - 4,
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
                  icon: Icons.person_rounded,
                  label: 'Bio',
                  isSelected: showBio,
                  onTap: () => onToggle(true),
                  colors: colors,
                ),
              ),
              Expanded(
                child: _SegmentButton(
                  icon: Icons.format_quote_rounded,
                  label: 'Quotes',
                  isSelected: !showBio,
                  onTap: () => onToggle(false),
                  colors: colors,
                ),
              ),
            ],
          ),
        ],
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
            Icon(
              icon,
              size: 18,
              color: isSelected ? colors.onPrimary : colors.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
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
