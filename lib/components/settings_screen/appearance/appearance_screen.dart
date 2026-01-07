import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quotely_flutter_app/main.dart';

import '../../../theme/colors/app_colors.dart';
import '../../../theme/typography/app_typography.dart';
import '../../layouts/main_layout.dart';

class AppearanceScreen extends StatefulWidget {
  static const kRouteName = '/appearance';
  const AppearanceScreen({super.key});

  @override
  State<AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends State<AppearanceScreen> {
  @override
  Widget build(BuildContext context) {
    final quotelyState = QuotelyApp.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;

    return MainLayout(
      title: 'Appearance',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Live Quote Preview ---
            _buildQuotePreview(context, quotelyState.fontFamily),
            const SizedBox(height: 32),

            // --- Section 1: Theme Mode ---
            _buildSectionHeader(context, "Theme Mode"),
            const SizedBox(height: 12),
            _buildThemeModeSelector(context, quotelyState, colors),
            const SizedBox(height: 32),

            // --- Section 2: Typography ---
            _buildSectionHeader(context, "Typography"),
            const SizedBox(height: 12),
            _buildFontSelector(context, quotelyState, colors),
            const SizedBox(height: 32),

            // --- Section 3: Layout Preferences ---
            _buildSectionHeader(context, "Layout"),
            const SizedBox(height: 12),
            _buildLayoutToggle(context, quotelyState, colors),
            const SizedBox(height: 40),

            // --- Reset Button ---
            _buildResetButton(context, quotelyState, colors),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildQuotePreview(BuildContext context, String fontFamily) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.surface,
            colors.surfaceContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.shadowDark.withValues(alpha: isDark ? 0.6 : 0.35),
            offset: const Offset(6, 6),
            blurRadius: 12,
          ),
          BoxShadow(
            color: colors.shadowLight.withValues(alpha: isDark ? 0.1 : 0.8),
            offset: const Offset(-6, -6),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.format_quote_rounded,
            size: 32,
            color: colors.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            '"The only way to do great work is to love what you do."',
            style: GoogleFonts.getFont(
              fontFamily,
              fontSize: 18,
              fontStyle: FontStyle.italic,
              height: 1.6,
              color: colors.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            '— Steve Jobs',
            style: GoogleFonts.playfairDisplay(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeModeSelector(
    BuildContext context,
    dynamic quotelyState,
    AppColorScheme colors,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          child: _ThemeModeCard(
            icon: Icons.light_mode_rounded,
            label: 'Light',
            isSelected: quotelyState.themeMode == ThemeMode.light,
            onTap: () {
              HapticFeedback.lightImpact();
              quotelyState.changeTheme(ThemeMode.light);
            },
            colors: colors,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _ThemeModeCard(
            icon: Icons.dark_mode_rounded,
            label: 'Dark',
            isSelected: quotelyState.themeMode == ThemeMode.dark,
            onTap: () {
              HapticFeedback.lightImpact();
              quotelyState.changeTheme(ThemeMode.dark);
            },
            colors: colors,
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildFontSelector(
    BuildContext context,
    dynamic quotelyState,
    AppColorScheme colors,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
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
            color: colors.shadowLight.withValues(alpha: isDark ? 0.05 : 0.6),
            offset: const Offset(-4, -4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.text_fields_rounded,
                    color: colors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Font Family',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              itemCount: AppTypography.availableFonts.length,
              itemBuilder: (context, index) {
                final fontName = AppTypography.availableFonts[index];
                final isSelected = quotelyState.fontFamily == fontName;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _FontCard(
                    fontName: fontName,
                    isSelected: isSelected,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      quotelyState.changeFontFamily(fontName);
                    },
                    colors: colors,
                    isDark: isDark,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLayoutToggle(
    BuildContext context,
    dynamic quotelyState,
    AppColorScheme colors,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        quotelyState.toggleGridViewEnabled();
        setState(() {});
      },
      child: Container(
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
              color: colors.shadowLight.withValues(alpha: isDark ? 0.05 : 0.6),
              offset: const Offset(-4, -4),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                quotelyState.isGridView
                    ? Icons.grid_view_rounded
                    : Icons.view_list_rounded,
                color: colors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Default to Grid View',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Applies to Home & Favorites screens',
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            _NeumorphicSwitch(
              value: quotelyState.isGridView,
              onChanged: (_) {
                quotelyState.toggleGridViewEnabled();
                setState(() {});
              },
              colors: colors,
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResetButton(
    BuildContext context,
    dynamic quotelyState,
    AppColorScheme colors,
  ) {
    return Center(
      child: OutlinedButton.icon(
        icon: const Icon(Icons.refresh_rounded),
        label: const Text(
          'Reset to Defaults',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.error,
          side: BorderSide(
            color: colors.error.withValues(alpha: 0.5),
          ),
          padding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 20,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () => _showResetDialog(context, quotelyState, colors),
      ),
    );
  }

  Future<void> _showResetDialog(
    BuildContext context,
    dynamic quotelyState,
    AppColorScheme colors,
  ) async {
    final bool? shouldReset = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text(
          'Reset All Settings?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'This will reset your theme, font, and layout preferences to their original defaults.',
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: colors.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Reset',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (shouldReset == true) {
      quotelyState.resetAllSettings();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings have been reset!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;

    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        color: colors.textMuted,
      ),
    );
  }
}

class _ThemeModeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final AppColorScheme colors;
  final bool isDark;

  const _ThemeModeCard({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.colors,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primary.withValues(alpha: 0.15)
              : colors.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: colors.primary, width: 2)
              : null,
          boxShadow: isSelected
              ? []
              : [
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
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? colors.primary : colors.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? colors.primary : colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FontCard extends StatelessWidget {
  final String fontName;
  final bool isSelected;
  final VoidCallback onTap;
  final AppColorScheme colors;
  final bool isDark;

  const _FontCard({
    required this.fontName,
    required this.isSelected,
    required this.onTap,
    required this.colors,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primary.withValues(alpha: 0.15)
              : colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: colors.primary, width: 2)
              : Border.all(color: colors.outline.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Aa',
              style: GoogleFonts.getFont(
                fontName,
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: isSelected ? colors.primary : colors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NeumorphicSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final AppColorScheme colors;
  final bool isDark;

  const _NeumorphicSwitch({
    required this.value,
    required this.onChanged,
    required this.colors,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 52,
        height: 28,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: value ? colors.primary : colors.outline,
          borderRadius: BorderRadius.circular(14),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: colors.surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colors.shadowDark.withValues(alpha: 0.3),
                  offset: const Offset(1, 1),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
