import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../dtos/quote_dto.dart';
import '../../theme/colors/app_colors.dart';
import '../../theme/gradients/app_gradients.dart';

/// A beautiful neumorphic quote card designed for swipe interactions
class SwipeableQuoteCard extends StatelessWidget {
  final QuoteDto quote;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onShare;
  final VoidCallback? onAuthorTap;

  const SwipeableQuoteCard({
    super.key,
    required this.quote,
    this.isFavorite = false,
    this.onFavoriteToggle,
    this.onShare,
    this.onAuthorTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: AppGradients.cardBackground(context),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colors.shadowDark.withValues(alpha: isDark ? 0.7 : 0.4),
            offset: const Offset(8, 8),
            blurRadius: 20,
          ),
          BoxShadow(
            color: colors.shadowLight.withValues(alpha: isDark ? 0.1 : 0.9),
            offset: const Offset(-8, -8),
            blurRadius: 20,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Decorative top gradient
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 120,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      colors.primary.withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Main content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),

                  // Opening quote mark
                  Icon(
                    Icons.format_quote_rounded,
                    size: 48,
                    color: colors.primary.withValues(alpha: 0.4),
                  ),

                  const SizedBox(height: 16),

                  // Quote text
                  Text(
                    quote.content,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lora(
                      fontSize: 20,
                      fontStyle: FontStyle.italic,
                      height: 1.6,
                      color: colors.onSurface,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Author
                  GestureDetector(
                    onTap: onAuthorTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '— ${quote.author}',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colors.primary,
                        ),
                      ),
                    ),
                  ),

                  // Tags
                  if (quote.tags.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: quote.tags.take(3).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colors.surfaceContainer,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: colors.outline.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  const Spacer(),

                  // Action buttons
                  _ActionButtons(
                    colors: colors,
                    isDark: isDark,
                    isFavorite: isFavorite,
                    onFavoriteToggle: onFavoriteToggle,
                    onShare: onShare,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final AppColorScheme colors;
  final bool isDark;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onShare;

  const _ActionButtons({
    required this.colors,
    required this.isDark,
    required this.isFavorite,
    this.onFavoriteToggle,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Share button
        _NeumorphicActionButton(
          icon: Icons.share_rounded,
          colors: colors,
          isDark: isDark,
          onTap: () {
            HapticFeedback.lightImpact();
            onShare?.call();
          },
        ),

        const SizedBox(width: 24),

        // Favorite button
        _NeumorphicActionButton(
          icon: isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          iconColor: isFavorite ? colors.error : null,
          colors: colors,
          isDark: isDark,
          onTap: () {
            HapticFeedback.lightImpact();
            onFavoriteToggle?.call();
          },
        ),

        const SizedBox(width: 24),

        // Copy button
        _NeumorphicActionButton(
          icon: Icons.copy_rounded,
          colors: colors,
          isDark: isDark,
          onTap: () {
            HapticFeedback.lightImpact();
            final quoteCard = context.findAncestorWidgetOfExactType<SwipeableQuoteCard>();
            if (quoteCard != null) {
              Clipboard.setData(ClipboardData(
                text: '"${quoteCard.quote.content}" — ${quoteCard.quote.author}',
              ));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Quote copied to clipboard'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
        ),
      ],
    );
  }
}

class _NeumorphicActionButton extends StatefulWidget {
  final IconData icon;
  final Color? iconColor;
  final AppColorScheme colors;
  final bool isDark;
  final VoidCallback onTap;

  const _NeumorphicActionButton({
    required this.icon,
    this.iconColor,
    required this.colors,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_NeumorphicActionButton> createState() => _NeumorphicActionButtonState();
}

class _NeumorphicActionButtonState extends State<_NeumorphicActionButton> {
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
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: widget.colors.surface,
          shape: BoxShape.circle,
          boxShadow: _isPressed
              ? [
                  BoxShadow(
                    color: widget.colors.shadowDark
                        .withValues(alpha: widget.isDark ? 0.3 : 0.15),
                    offset: const Offset(2, 2),
                    blurRadius: 4,
                  ),
                ]
              : [
                  BoxShadow(
                    color: widget.colors.shadowDark
                        .withValues(alpha: widget.isDark ? 0.5 : 0.3),
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
          child: Icon(
            widget.icon,
            size: 22,
            color: widget.iconColor ?? widget.colors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
