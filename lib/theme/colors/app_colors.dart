import 'package:flutter/material.dart';

/// Warm & Cozy color palette for Quotely
/// Theme: Reading by firelight - amber, cream, warm browns

class AppColors {
  AppColors._();

  static const LightColors light = LightColors();
  static const DarkColors dark = DarkColors();

  /// Get colors based on brightness
  static AppColorScheme of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? dark
        : light;
  }
}

/// Base class for color schemes
abstract class AppColorScheme {
  // Primary Colors
  Color get primary;
  Color get primaryLight;
  Color get primaryDark;
  Color get onPrimary;

  // Secondary Colors
  Color get secondary;
  Color get secondaryLight;
  Color get secondaryDark;
  Color get onSecondary;

  // Surface Colors
  Color get surface;
  Color get surfaceContainer;
  Color get surfaceContainerHigh;
  Color get surfaceContainerLow;

  // Background Colors
  Color get background;
  Color get scaffoldBackground;

  // Text Colors
  Color get onSurface;
  Color get onSurfaceVariant;
  Color get textMuted;

  // Accent Colors
  Color get accent;
  Color get accentSecondary;
  Color get success;
  Color get error;
  Color get warning;

  // Neumorphic Shadow Colors
  Color get shadowLight;
  Color get shadowDark;

  // Outline Colors
  Color get outline;
  Color get outlineVariant;
}

/// Light mode colors - Warm cream and amber tones
class LightColors implements AppColorScheme {
  const LightColors();

  // Primary Colors - Amber/Caramel
  @override
  Color get primary => const Color(0xFFC17D3D);
  @override
  Color get primaryLight => const Color(0xFFD9A566);
  @override
  Color get primaryDark => const Color(0xFF9A6230);
  @override
  Color get onPrimary => const Color(0xFFFFFBF5);

  // Secondary Colors - Warm Brown
  @override
  Color get secondary => const Color(0xFF8B5E34);
  @override
  Color get secondaryLight => const Color(0xFFA67B52);
  @override
  Color get secondaryDark => const Color(0xFF6B4426);
  @override
  Color get onSecondary => const Color(0xFFFFFBF5);

  // Surface Colors - Warm Cream
  @override
  Color get surface => const Color(0xFFFFF8F0);
  @override
  Color get surfaceContainer => const Color(0xFFFFF3E8);
  @override
  Color get surfaceContainerHigh => const Color(0xFFFFEDE0);
  @override
  Color get surfaceContainerLow => const Color(0xFFFFFCF8);

  // Background Colors
  @override
  Color get background => const Color(0xFFFFFBF5);
  @override
  Color get scaffoldBackground => const Color(0xFFFFF8F0);

  // Text Colors - Dark Warm Brown
  @override
  Color get onSurface => const Color(0xFF3D2914);
  @override
  Color get onSurfaceVariant => const Color(0xFF6B5240);
  @override
  Color get textMuted => const Color(0xFF9A8575);

  // Accent Colors
  @override
  Color get accent => const Color(0xFFE8A84C);
  @override
  Color get accentSecondary => const Color(0xFFD4763A);
  @override
  Color get success => const Color(0xFF7A9E6D);
  @override
  Color get error => const Color(0xFFC75050);
  @override
  Color get warning => const Color(0xFFD4963A);

  // Neumorphic Shadow Colors
  @override
  Color get shadowLight => const Color(0xFFFFFFFF);
  @override
  Color get shadowDark => const Color(0xFFD9C9B5);

  // Outline Colors
  @override
  Color get outline => const Color(0xFFD9C9B5);
  @override
  Color get outlineVariant => const Color(0xFFE8DDD0);
}

/// Dark mode colors - Deep ember tones
class DarkColors implements AppColorScheme {
  const DarkColors();

  // Primary Colors - Lighter Amber for dark mode
  @override
  Color get primary => const Color(0xFFD9A566);
  @override
  Color get primaryLight => const Color(0xFFE8C08A);
  @override
  Color get primaryDark => const Color(0xFFC17D3D);
  @override
  Color get onPrimary => const Color(0xFF1F1408);

  // Secondary Colors - Lighter Warm Brown
  @override
  Color get secondary => const Color(0xFFA67B52);
  @override
  Color get secondaryLight => const Color(0xFFC29872);
  @override
  Color get secondaryDark => const Color(0xFF8B5E34);
  @override
  Color get onSecondary => const Color(0xFF1F1408);

  // Surface Colors - Dark Warm
  @override
  Color get surface => const Color(0xFF1F1A14);
  @override
  Color get surfaceContainer => const Color(0xFF2A231A);
  @override
  Color get surfaceContainerHigh => const Color(0xFF352C21);
  @override
  Color get surfaceContainerLow => const Color(0xFF171310);

  // Background Colors - Like embers
  @override
  Color get background => const Color(0xFF141110);
  @override
  Color get scaffoldBackground => const Color(0xFF1A1512);

  // Text Colors - Warm White
  @override
  Color get onSurface => const Color(0xFFF5EDE5);
  @override
  Color get onSurfaceVariant => const Color(0xFFC9BAA8);
  @override
  Color get textMuted => const Color(0xFF8A7B6B);

  // Accent Colors
  @override
  Color get accent => const Color(0xFFE8A84C);
  @override
  Color get accentSecondary => const Color(0xFFE89654);
  @override
  Color get success => const Color(0xFF8FB280);
  @override
  Color get error => const Color(0xFFE07070);
  @override
  Color get warning => const Color(0xFFE8B060);

  // Neumorphic Shadow Colors
  @override
  Color get shadowLight => const Color(0xFF2A231A);
  @override
  Color get shadowDark => const Color(0xFF0A0806);

  // Outline Colors
  @override
  Color get outline => const Color(0xFF6B5A48);
  @override
  Color get outlineVariant => const Color(0xFF4D4030);
}

/// Extension for easy alpha modifications
extension ColorAlpha on Color {
  Color get withAlpha10 => withValues(alpha: 0.1);
  Color get withAlpha20 => withValues(alpha: 0.2);
  Color get withAlpha30 => withValues(alpha: 0.3);
  Color get withAlpha50 => withValues(alpha: 0.5);
  Color get withAlpha70 => withValues(alpha: 0.7);
  Color get withAlpha80 => withValues(alpha: 0.8);
  Color get withAlpha90 => withValues(alpha: 0.9);
}
