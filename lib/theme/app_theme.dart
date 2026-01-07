import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors/app_colors.dart';
import 'typography/app_typography.dart';

/// Main theme configuration for Quotely
/// Warm & Cozy theme with neumorphic design elements

class AppTheme {
  AppTheme._();

  /// Light theme
  static ThemeData get lightTheme => _buildTheme(Brightness.light);

  /// Dark theme
  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  /// Build theme with custom font family
  static ThemeData lightThemeWithFont(String fontFamily) =>
      _buildTheme(Brightness.light, fontFamily: fontFamily);

  static ThemeData darkThemeWithFont(String fontFamily) =>
      _buildTheme(Brightness.dark, fontFamily: fontFamily);

  static ThemeData _buildTheme(Brightness brightness, {String? fontFamily}) {
    final isDark = brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;

    final textTheme = fontFamily != null
        ? AppTypography.buildCustomFontTextTheme(brightness, fontFamily)
        : AppTypography.buildTextTheme(brightness);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,

      // Color Scheme
      colorScheme: _buildColorScheme(brightness),

      // Scaffold Background
      scaffoldBackgroundColor: colors.scaffoldBackground,

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.lora(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: colors.onSurface,
        ),
        iconTheme: IconThemeData(
          color: colors.onSurface,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: colors.surfaceContainer,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.lora(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.primary,
          side: BorderSide(color: colors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.lora(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.primary,
          textStyle: GoogleFonts.lora(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        elevation: 4,
        shape: const CircleBorder(),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: colors.surfaceContainer,
        labelStyle: GoogleFonts.lora(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: colors.onSurfaceVariant,
        ),
        side: BorderSide(color: colors.outlineVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
        hintStyle: GoogleFonts.lora(
          color: colors.textMuted,
        ),
        labelStyle: GoogleFonts.lora(
          color: colors.onSurfaceVariant,
        ),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.surface,
        selectedItemColor: colors.primary,
        unselectedItemColor: colors.textMuted,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.lora(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: GoogleFonts.lora(
          fontSize: 12,
        ),
      ),

      // Navigation Bar Theme (Material 3)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.surface,
        indicatorColor: colors.primary.withValues(alpha: 0.2),
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.lora(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.primary,
            );
          }
          return GoogleFonts.lora(
            fontSize: 12,
            color: colors.textMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: colors.primary);
          }
          return IconThemeData(color: colors.textMuted);
        }),
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: colors.onSurface,
        ),
        contentTextStyle: GoogleFonts.lora(
          fontSize: 14,
          color: colors.onSurfaceVariant,
        ),
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.onSurface,
        contentTextStyle: GoogleFonts.lora(
          color: colors.surface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: colors.outlineVariant,
        thickness: 1,
      ),

      // Icon Theme
      iconTheme: IconThemeData(
        color: colors.onSurfaceVariant,
        size: 24,
      ),

      // Primary Icon Theme
      primaryIconTheme: IconThemeData(
        color: colors.onPrimary,
        size: 24,
      ),

      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colors.primary;
          }
          return colors.surfaceContainerHigh;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colors.primary.withValues(alpha: 0.3);
          }
          return colors.outline;
        }),
      ),

      // Slider Theme
      sliderTheme: SliderThemeData(
        activeTrackColor: colors.primary,
        inactiveTrackColor: colors.outline,
        thumbColor: colors.primary,
        overlayColor: colors.primary.withValues(alpha: 0.2),
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.primary,
        circularTrackColor: colors.outline,
        linearTrackColor: colors.outline,
      ),

      // Tab Bar Theme
      tabBarTheme: TabBarThemeData(
        labelColor: colors.primary,
        unselectedLabelColor: colors.textMuted,
        indicatorColor: colors.primary,
        labelStyle: GoogleFonts.lora(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.lora(
          fontSize: 14,
        ),
      ),

      // Text Theme
      textTheme: textTheme,
      primaryTextTheme: textTheme,
    );
  }

  static ColorScheme _buildColorScheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;

    return ColorScheme(
      brightness: brightness,
      primary: colors.primary,
      onPrimary: colors.onPrimary,
      primaryContainer: isDark ? const Color(0xFF5C4020) : const Color(0xFFFFE8D4),
      onPrimaryContainer: colors.onSurface,
      secondary: colors.secondary,
      onSecondary: colors.onSecondary,
      secondaryContainer:
          isDark ? const Color(0xFF4D3820) : const Color(0xFFFFE0C8),
      onSecondaryContainer: colors.onSurface,
      tertiary: colors.accent,
      onTertiary: colors.onPrimary,
      tertiaryContainer:
          isDark ? const Color(0xFF5C4420) : const Color(0xFFFFEDD4),
      onTertiaryContainer: colors.onSurface,
      error: colors.error,
      onError: colors.onPrimary,
      errorContainer: isDark ? const Color(0xFF8C1D1D) : const Color(0xFFFFDAD6),
      onErrorContainer: isDark ? const Color(0xFFFFDAD6) : const Color(0xFF410002),
      surface: colors.surface,
      onSurface: colors.onSurface,
      onSurfaceVariant: colors.onSurfaceVariant,
      outline: colors.outline,
      outlineVariant: colors.outlineVariant,
      shadow: isDark ? Colors.black : colors.onSurface,
      scrim: isDark ? Colors.black : colors.onSurface,
      inverseSurface: isDark ? colors.onSurface : colors.surface,
      onInverseSurface: isDark ? colors.surface : colors.onSurface,
      inversePrimary: isDark ? colors.primaryDark : colors.primaryLight,
      surfaceContainerLowest:
          isDark ? const Color(0xFF0F0C0A) : const Color(0xFFFFFFFF),
      surfaceContainerLow: colors.surfaceContainerLow,
      surfaceContainer: colors.surfaceContainer,
      surfaceContainerHigh: colors.surfaceContainerHigh,
      surfaceContainerHighest:
          isDark ? const Color(0xFF40362A) : const Color(0xFFFFE8D8),
    );
  }
}
