import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/colors/app_colors.dart';
import '../theme/gradients/app_gradients.dart';

/// Default gradient for backgrounds and cards
/// Uses warm amber to warm brown gradient
LinearGradient kGetDefaultGradient(BuildContext context) {
  return AppGradients.warmPrimary(context);
}

/// Card background gradient
LinearGradient kGetCardGradient(BuildContext context) {
  return AppGradients.cardBackground(context);
}

/// Firelight glow gradient for special sections
LinearGradient kGetFirelightGradient(BuildContext context) {
  return AppGradients.firelight(context);
}

/// Sunset warmth gradient for hero sections
LinearGradient kGetSunsetGradient(BuildContext context) {
  return AppGradients.sunsetWarmth(context);
}

/// System UI overlay style based on theme
SystemUiOverlayStyle getDefaultSystemUiStyle(bool isDarkTheme) {
  return SystemUiOverlayStyle(
    // Status bar color
    statusBarColor: Colors.transparent,
    // Status bar brightness
    statusBarIconBrightness: isDarkTheme
        ? Brightness.light
        : Brightness.dark,
    statusBarBrightness: isDarkTheme
        ? Brightness.dark
        : Brightness.light,
    // Navigation bar color - use theme surface
    systemNavigationBarColor: isDarkTheme
        ? AppColors.dark.surface
        : AppColors.light.surface,
    systemNavigationBarIconBrightness: isDarkTheme
        ? Brightness.light
        : Brightness.dark,
  );
}
