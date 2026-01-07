import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../theme/colors/app_colors.dart';

/// A neumorphic card for displaying a fact in notification screens
class NeumorphicNotificationFactCard extends StatelessWidget {
  final DateTime factDate;
  final String content;
  final String? category;

  const NeumorphicNotificationFactCard({
    super.key,
    required this.factDate,
    required this.content,
    this.category,
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
          // Date and category badges
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
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
                      DateFormat('MMMM dd, yyyy').format(factDate),
                      style: GoogleFonts.lora(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              if (category != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.category_rounded,
                        size: 14,
                        color: colors.accent,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        category!,
                        style: GoogleFonts.lora(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.accent,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 24),

          // Lightbulb icon
          Icon(
            Icons.lightbulb_rounded,
            size: 32,
            color: colors.accent.withValues(alpha: 0.4),
          ),

          const SizedBox(height: 12),

          // Fact content
          Text(
            content,
            style: GoogleFonts.lora(
              fontSize: 17,
              height: 1.6,
              color: colors.onSurface,
            ),
          ),

          const SizedBox(height: 16),

          // "Did you know?" label
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(
                  color: colors.textMuted.withValues(alpha: 0.3),
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Did you know?',
                style: GoogleFonts.lora(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: colors.textMuted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NeumorphicNotificationFactCardSkeleton extends StatelessWidget {
  const NeumorphicNotificationFactCardSkeleton({super.key});

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
            Icon(
              Icons.lightbulb_rounded,
              size: 32,
              color: colors.accent.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              'Honey never spoils. Archaeologists have found 3,000-year-old honey in Egyptian tombs that was still edible.',
              style: GoogleFonts.lora(
                fontSize: 17,
                height: 1.6,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Did you know?',
                style: GoogleFonts.lora(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: colors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A neumorphic card for displaying a fact item in a list
class NeumorphicFactListItem extends StatelessWidget {
  final int index;
  final DateTime factDate;
  final String content;
  final String? category;

  const NeumorphicFactListItem({
    super.key,
    required this.index,
    required this.factDate,
    required this.content,
    this.category,
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
          // Date and category badges
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  DateFormat('MMM dd, yyyy').format(factDate),
                  style: GoogleFonts.lora(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colors.primary,
                  ),
                ),
              ),
              if (category != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    category!,
                    style: GoogleFonts.lora(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colors.accent,
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 12),

          // Fact content
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
        ],
      ),
    );
  }
}

class NeumorphicFactListItemSkeleton extends StatelessWidget {
  const NeumorphicFactListItemSkeleton({super.key});

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
              'Honey never spoils. Archaeologists have found 3,000-year-old honey.',
              style: GoogleFonts.lora(
                fontSize: 15,
                height: 1.5,
                color: colors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
