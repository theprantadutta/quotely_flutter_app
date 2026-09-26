import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'appearance.dart';
import 'tokens.dart';
import 'typography.dart';

export 'appearance.dart';
export 'tokens.dart';
export 'typography.dart';

extension QuotelyThemeContext on BuildContext {
  /// Color tokens for the current theme.
  QuotelyTokens get q => Theme.of(this).extension<QuotelyTokens>()!;

  /// Text styles for the current theme.
  QuotelyText get qt => Theme.of(this).extension<QuotelyText>()!;

  /// Honors the OS "reduce motion" setting.
  bool get reduceMotion => MediaQuery.disableAnimationsOf(this);
}

/// Builds the Material theme from the Thread tokens so stock widgets
/// (dialogs, text fields, sliders, snackbars) match without per-widget styling.
ThemeData buildQuotelyTheme(Brightness brightness, AppearanceSettings s) {
  final t = QuotelyTokens.of(brightness, s.accent);
  final text = QuotelyText.build(
    t,
    readingFont: s.readingFont,
    quoteScale: s.quoteScale,
  );
  final light = brightness == Brightness.light;
  final isIOS = defaultTargetPlatform == TargetPlatform.iOS;

  final scheme = ColorScheme(
    brightness: brightness,
    primary: t.acc,
    onPrimary: t.onAcc,
    primaryContainer: t.accSoft,
    onPrimaryContainer: t.accInk,
    secondary: t.accInk,
    onSecondary: t.onAcc,
    secondaryContainer: t.accSoft,
    onSecondaryContainer: t.accInk,
    tertiary: t.accInk,
    onTertiary: t.onAcc,
    surface: t.surf,
    onSurface: t.ink,
    surfaceContainerLowest: t.bg,
    surfaceContainerLow: t.bg,
    surfaceContainer: t.surf,
    surfaceContainerHigh: t.surf,
    surfaceContainerHighest: t.ph,
    onSurfaceVariant: t.mute,
    outline: t.line,
    outlineVariant: t.line,
    error: light ? const Color(0xFFB3261E) : const Color(0xFFF2B8B5),
    onError: light ? Colors.white : const Color(0xFF601410),
    inverseSurface: t.ink,
    onInverseSurface: t.bg,
    inversePrimary: t.accSoft,
    scrim: t.scrim,
    shadow: Colors.black,
  );

  final baseText = ThemeData(brightness: brightness).textTheme.apply(
    fontFamily: kFontUi,
    bodyColor: t.ink,
    displayColor: t.ink,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    fontFamily: kFontUi,
    textTheme: baseText,
    scaffoldBackgroundColor: t.bg,
    canvasColor: t.bg,
    dividerColor: t.line,
    primaryColor: t.acc,
    highlightColor: Colors.transparent,
    splashColor: t.accSoft.withValues(alpha: 0.4),
    splashFactory: isIOS ? NoSplash.splashFactory : InkSparkle.splashFactory,
    extensions: [t, text],
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      },
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: t.bg,
      foregroundColor: t.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: quotelyOverlayStyle(t),
      titleTextStyle: text.sectionTitle,
    ),
    dividerTheme: DividerThemeData(color: t.line, thickness: 1, space: 1),
    dialogTheme: DialogThemeData(
      backgroundColor: t.surf,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      titleTextStyle: text.sectionTitle,
      contentTextStyle: text.body,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: t.surf,
      surfaceTintColor: Colors.transparent,
      modalBarrierColor: t.scrim,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: t.ink,
      contentTextStyle: text.chip.copyWith(color: t.bg, fontSize: 14),
      actionTextColor: t.accSoft,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: t.bg,
      hintStyle: text.body.copyWith(color: t.mute),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: t.acc, width: 1.5),
      ),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: t.acc,
      selectionColor: t.accSoft,
      selectionHandleColor: t.acc,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: t.acc,
      linearTrackColor: t.line,
      circularTrackColor: t.line,
    ),
    sliderTheme: SliderThemeData(
      trackHeight: 6,
      activeTrackColor: t.acc,
      inactiveTrackColor: t.line,
      thumbColor: t.knob,
      overlayColor: t.accSoft.withValues(alpha: 0.4),
      thumbShape: const RoundSliderThumbShape(
        enabledThumbRadius: 11,
        elevation: 2,
      ),
      trackShape: const RoundedRectSliderTrackShape(),
      tickMarkShape: SliderTickMarkShape.noTickMark,
    ),
    timePickerTheme: TimePickerThemeData(
      backgroundColor: t.surf,
      dialBackgroundColor: t.bg,
      hourMinuteColor: t.bg,
      dayPeriodColor: t.accSoft,
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: t.accInk,
        textStyle: text.chip.copyWith(fontSize: 14),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: t.acc,
        foregroundColor: t.onAcc,
        textStyle: text.button,
        shape: const StadiumBorder(),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: t.ink,
        borderRadius: BorderRadius.circular(10),
      ),
      textStyle: text.label.copyWith(color: t.bg),
    ),
  );
}

/// Status and navigation bar icons that read on the current background.
SystemUiOverlayStyle quotelyOverlayStyle(QuotelyTokens t) =>
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: t.isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: t.isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: t.bg,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: t.isDark
          ? Brightness.light
          : Brightness.dark,
    );
