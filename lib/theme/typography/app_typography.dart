import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../colors/app_colors.dart';

/// Typography system for Quotely
/// Headers: Playfair Display (elegant serif)
/// Body: Lora (readable serif)

class AppTypography {
  AppTypography._();

  /// Font family names
  static const String headerFontFamily = 'Playfair Display';
  static const String bodyFontFamily = 'Lora';

  /// Available fonts for user selection in appearance settings
  static const List<String> availableFonts = [
    'Playfair Display',
    'Lora',
    'Merriweather',
    'Libre Baskerville',
    'Crimson Text',
    'Source Serif 4',
    'Poppins',
    'Nunito',
    'Inter',
    'Roboto',
  ];

  /// Build the complete text theme for light/dark mode
  static TextTheme buildTextTheme(Brightness brightness) {
    final textColor = brightness == Brightness.light
        ? AppColors.light.onSurface
        : AppColors.dark.onSurface;
    final textColorVariant = brightness == Brightness.light
        ? AppColors.light.onSurfaceVariant
        : AppColors.dark.onSurfaceVariant;

    return TextTheme(
      // Display styles - Playfair Display for hero sections
      displayLarge: GoogleFonts.playfairDisplay(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
        height: 1.12,
        color: textColor,
      ),
      displayMedium: GoogleFonts.playfairDisplay(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.16,
        color: textColor,
      ),
      displaySmall: GoogleFonts.playfairDisplay(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.22,
        color: textColor,
      ),

      // Headline styles - Playfair Display for section headers
      headlineLarge: GoogleFonts.playfairDisplay(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.25,
        color: textColor,
      ),
      headlineMedium: GoogleFonts.playfairDisplay(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.29,
        color: textColor,
      ),
      headlineSmall: GoogleFonts.playfairDisplay(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.33,
        color: textColor,
      ),

      // Title styles - Lora for UI titles
      titleLarge: GoogleFonts.lora(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        height: 1.27,
        color: textColor,
      ),
      titleMedium: GoogleFonts.lora(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        height: 1.5,
        color: textColor,
      ),
      titleSmall: GoogleFonts.lora(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.43,
        color: textColor,
      ),

      // Label styles - Lora for buttons and labels
      labelLarge: GoogleFonts.lora(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.43,
        color: textColor,
      ),
      labelMedium: GoogleFonts.lora(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.33,
        color: textColorVariant,
      ),
      labelSmall: GoogleFonts.lora(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.45,
        color: textColorVariant,
      ),

      // Body styles - Lora for readable content
      bodyLarge: GoogleFonts.lora(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        height: 1.5,
        color: textColor,
      ),
      bodyMedium: GoogleFonts.lora(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        height: 1.43,
        color: textColor,
      ),
      bodySmall: GoogleFonts.lora(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        height: 1.33,
        color: textColorVariant,
      ),
    );
  }

  /// Get a TextTheme with a custom font family (for user-selected fonts)
  static TextTheme buildCustomFontTextTheme(
    Brightness brightness,
    String fontFamily,
  ) {
    final textColor = brightness == Brightness.light
        ? AppColors.light.onSurface
        : AppColors.dark.onSurface;
    final textColorVariant = brightness == Brightness.light
        ? AppColors.light.onSurfaceVariant
        : AppColors.dark.onSurfaceVariant;

    TextStyle getFont(double size, FontWeight weight, {FontStyle? style}) {
      return GoogleFonts.getFont(
        fontFamily,
        fontSize: size,
        fontWeight: weight,
        fontStyle: style,
        color: textColor,
      );
    }

    return TextTheme(
      displayLarge: getFont(57, FontWeight.w400),
      displayMedium: getFont(45, FontWeight.w400),
      displaySmall: getFont(36, FontWeight.w400),
      headlineLarge: getFont(32, FontWeight.w600),
      headlineMedium: getFont(28, FontWeight.w600),
      headlineSmall: getFont(24, FontWeight.w600),
      titleLarge: getFont(22, FontWeight.w500),
      titleMedium: getFont(16, FontWeight.w500),
      titleSmall: getFont(14, FontWeight.w500),
      labelLarge: getFont(14, FontWeight.w500),
      labelMedium: getFont(12, FontWeight.w500).copyWith(color: textColorVariant),
      labelSmall: getFont(11, FontWeight.w500).copyWith(color: textColorVariant),
      bodyLarge: getFont(16, FontWeight.w400),
      bodyMedium: getFont(14, FontWeight.w400),
      bodySmall: getFont(12, FontWeight.w400).copyWith(color: textColorVariant),
    );
  }
}

/// Custom text styles for quotes and special elements
class QuoteTextStyles {
  QuoteTextStyles._();

  /// Quote content text - italic and elegant
  static TextStyle quoteText(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GoogleFonts.lora(
      fontSize: 20,
      fontWeight: FontWeight.w400,
      fontStyle: FontStyle.italic,
      height: 1.7,
      color: isDark ? AppColors.dark.onSurface : AppColors.light.onSurface,
    );
  }

  /// Large quote text for featured quotes
  static TextStyle quoteTextLarge(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GoogleFonts.lora(
      fontSize: 24,
      fontWeight: FontWeight.w400,
      fontStyle: FontStyle.italic,
      height: 1.6,
      color: isDark ? AppColors.dark.onSurface : AppColors.light.onSurface,
    );
  }

  /// Author name attribution
  static TextStyle quoteAuthor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GoogleFonts.playfairDisplay(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: isDark ? AppColors.dark.primary : AppColors.light.primary,
    );
  }

  /// Large author name for featured sections
  static TextStyle quoteAuthorLarge(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GoogleFonts.playfairDisplay(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: isDark ? AppColors.dark.primary : AppColors.light.primary,
    );
  }

  /// Tag/chip text
  static TextStyle tagText(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GoogleFonts.lora(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: isDark ? AppColors.dark.onSurfaceVariant : AppColors.light.onSurfaceVariant,
    );
  }

  /// Section header text
  static TextStyle sectionHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GoogleFonts.lora(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.5,
      color: isDark
          ? AppColors.dark.textMuted
          : AppColors.light.textMuted,
    );
  }
}
