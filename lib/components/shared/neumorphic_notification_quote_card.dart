import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../theme/colors/app_colors.dart';

/// A neumorphic card for displaying a quote in notification screens
class NeumorphicNotificationQuoteCard extends StatelessWidget {
  final DateTime quoteDate;
  final String author;
  final String content;

  const NeumorphicNotificationQuoteCard({
    super.key,
    required this.quoteDate,
    required this.author,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.shadowDark.withValues(alpha: isDark ? 0.5 : 0.25),
            offset: const Offset(6, 6),
            blurRadius: 12,
          ),
          BoxShadow(
            color: colors.shadowLight.withValues(alpha: isDark ? 0.08 : 0.7),
            offset: const Offset(-6, -6),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colors.primary.withValues(alpha: 0.15),
                  colors.primaryDark.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 14,
                  color: colors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  DateFormat('MMMM dd, yyyy').format(quoteDate),
                  style: GoogleFonts.lora(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.primary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Quote icon
          Icon(
            Icons.format_quote_rounded,
            size: 32,
            color: colors.primary.withValues(alpha: 0.3),
          ),

          const SizedBox(height: 12),

          // Quote content
          Text(
            content,
            style: GoogleFonts.lora(
              fontSize: 18,
              height: 1.6,
              fontStyle: FontStyle.italic,
              color: colors.onSurface,
            ),
          ),

          const SizedBox(height: 20),

          // Author
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 24,
                  height: 2,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  author,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
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

class NeumorphicNotificationQuoteCardSkeleton extends StatelessWidget {
  const NeumorphicNotificationQuoteCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;

    return Skeletonizer(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colors.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: colors.shadowDark.withValues(alpha: isDark ? 0.5 : 0.25),
              offset: const Offset(6, 6),
              blurRadius: 12,
            ),
            BoxShadow(
              color: colors.shadowLight.withValues(alpha: isDark ? 0.08 : 0.7),
              offset: const Offset(-6, -6),
              blurRadius: 12,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'December 15, 2024',
                style: GoogleFonts.lora(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.primary,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Quote icon
            Icon(
              Icons.format_quote_rounded,
              size: 32,
              color: colors.primary.withValues(alpha: 0.3),
            ),

            const SizedBox(height: 12),

            // Quote content
            Text(
              'The only way to do great work is to love what you do. If you haven\'t found it yet, keep looking.',
              style: GoogleFonts.lora(
                fontSize: 18,
                height: 1.6,
                fontStyle: FontStyle.italic,
                color: colors.onSurface,
              ),
            ),

            const SizedBox(height: 20),

            // Author
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '— Steve Jobs',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A neumorphic card for displaying a quote item in a list
class NeumorphicQuoteListItem extends StatelessWidget {
  final int index;
  final DateTime quoteDate;
  final String author;
  final String content;

  const NeumorphicQuoteListItem({
    super.key,
    required this.index,
    required this.quoteDate,
    required this.author,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.shadowDark.withValues(alpha: isDark ? 0.4 : 0.2),
            offset: const Offset(4, 4),
            blurRadius: 8,
          ),
          BoxShadow(
            color: colors.shadowLight.withValues(alpha: isDark ? 0.06 : 0.6),
            offset: const Offset(-4, -4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              DateFormat('MMM dd, yyyy').format(quoteDate),
              style: GoogleFonts.lora(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colors.primary,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Quote content
          Text(
            content,
            style: GoogleFonts.lora(
              fontSize: 15,
              height: 1.5,
              color: colors.onSurface,
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 12),

          // Author
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 16,
                  height: 1.5,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  author,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurfaceVariant,
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

class NeumorphicQuoteListItemSkeleton extends StatelessWidget {
  const NeumorphicQuoteListItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;

    return Skeletonizer(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colors.shadowDark.withValues(alpha: isDark ? 0.4 : 0.2),
              offset: const Offset(4, 4),
              blurRadius: 8,
            ),
            BoxShadow(
              color: colors.shadowLight.withValues(alpha: isDark ? 0.06 : 0.6),
              offset: const Offset(-4, -4),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Dec 15, 2024',
                style: GoogleFonts.lora(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colors.primary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'The only way to do great work is to love what you do.',
              style: GoogleFonts.lora(
                fontSize: 15,
                height: 1.5,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '— Steve Jobs',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
