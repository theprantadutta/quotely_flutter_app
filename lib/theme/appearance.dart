import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/shared_preference_keys.dart';
import '../service_locator/init_service_locators.dart';
import 'tokens.dart';
import 'typography.dart';

part '../generated/theme/appearance.g.dart';

/// Appearance → Default layout. Thread is the chat-style list; Cards is one
/// full-width card per item (the old carousel, restyled).
enum ThreadLayout { thread, cards }

@immutable
class AppearanceSettings {
  static const double minQuoteScale = 0.85;
  static const double maxQuoteScale = 1.30;

  final ThemeMode themeMode;
  final QAccent accent;
  final double quoteScale;
  final ReadingFont readingFont;
  final ThreadLayout layout;

  /// Soft glows of the day's colour behind every screen. On by default.
  final bool backgroundGlow;

  const AppearanceSettings({
    this.themeMode = ThemeMode.system,
    this.accent = QAccent.violet,
    this.quoteScale = 1.0,
    this.readingFont = ReadingFont.serif,
    this.layout = ThreadLayout.thread,
    this.backgroundGlow = true,
  });

  AppearanceSettings copyWith({
    ThemeMode? themeMode,
    QAccent? accent,
    double? quoteScale,
    ReadingFont? readingFont,
    ThreadLayout? layout,
    bool? backgroundGlow,
  }) => AppearanceSettings(
    themeMode: themeMode ?? this.themeMode,
    accent: accent ?? this.accent,
    quoteScale: quoteScale ?? this.quoteScale,
    readingFont: readingFont ?? this.readingFont,
    layout: layout ?? this.layout,
    backgroundGlow: backgroundGlow ?? this.backgroundGlow,
  );

  /// Reads the saved settings. Runs the legacy-pref migration first so an
  /// updating user keeps their dark mode (and, where it maps, their color).
  static Future<AppearanceSettings> load(SharedPreferences prefs) async {
    await _migrateLegacy(prefs);
    await _migrateSpotlightFont(prefs);
    T pick<T extends Enum>(List<T> values, String key, T fallback) {
      final name = prefs.getString(key);
      return values.firstWhere((v) => v.name == name, orElse: () => fallback);
    }

    return AppearanceSettings(
      themeMode: pick(ThemeMode.values, kAppearanceThemeKey, ThemeMode.system),
      accent: pick(QAccent.values, kAppearanceAccentKey, QAccent.violet),
      quoteScale: (prefs.getDouble(kAppearanceQuoteScaleKey) ?? 1.0).clamp(
        minQuoteScale,
        maxQuoteScale,
      ),
      readingFont: pick(
        ReadingFont.values,
        kAppearanceReadingFontKey,
        ReadingFont.serif,
      ),
      layout: pick(
        ThreadLayout.values,
        kAppearanceLayoutKey,
        ThreadLayout.thread,
      ),
      backgroundGlow: prefs.getBool(kAppearanceGlowKey) ?? true,
    );
  }

  /// One-time mapping from the pre-Thread prefs (flex scheme, Google font,
  /// grid toggle, theme mode) to the new keys. The old keys are then removed.
  ///
  /// Only values the user actually saved exist: the old app wrote each key on
  /// change, so an untouched install has none of them and gets the defaults.
  static Future<void> _migrateLegacy(SharedPreferences prefs) async {
    if (prefs.getBool(kAppearanceMigratedKey) ?? false) return;

    final oldTheme = prefs.getString(kThemeModeKey);
    if (oldTheme != null && prefs.getString(kAppearanceThemeKey) == null) {
      await prefs.setString(kAppearanceThemeKey, oldTheme);
    }

    final oldScheme = prefs.getString(kFlexSchemeKey);
    if (oldScheme != null && prefs.getString(kAppearanceAccentKey) == null) {
      await prefs.setString(
        kAppearanceAccentKey,
        accentForLegacyScheme(oldScheme).name,
      );
    }

    // Fira Code was the old default monospace look; everything else was a
    // sans or slab that Manrope now covers.
    final oldFont = prefs.getString(kFontFamilyKey);
    if (oldFont != null && prefs.getString(kAppearanceReadingFontKey) == null) {
      await prefs.setString(
        kAppearanceReadingFontKey,
        (oldFont == 'Fira Code' ? ReadingFont.mono : ReadingFont.sans).name,
      );
    }

    final oldGrid = prefs.getBool(kIsGridViewKey);
    if (oldGrid == true && prefs.getString(kAppearanceLayoutKey) == null) {
      await prefs.setString(kAppearanceLayoutKey, ThreadLayout.cards.name);
    }

    for (final key in [
      kThemeModeKey,
      kFlexSchemeKey,
      kFontFamilyKey,
      kIsGridViewKey,
      kIsDarkModeKey,
      kBiometricKey,
      kLegacyContentViewModeKey,
    ]) {
      await prefs.remove(key);
    }
    await prefs.setBool(kAppearanceMigratedKey, true);
  }

  /// Sans was the default before this design, so a saved "sans" is almost
  /// always that old default rather than a choice. Move it to the serif
  /// once; anything picked after this sticks.
  static Future<void> _migrateSpotlightFont(SharedPreferences prefs) async {
    if (prefs.getBool(kSpotlightFontMigratedKey) ?? false) return;
    if (prefs.getString(kAppearanceReadingFontKey) == ReadingFont.sans.name) {
      await prefs.remove(kAppearanceReadingFontKey);
    }
    await prefs.setBool(kSpotlightFontMigratedKey, true);
  }

  /// Maps a FlexScheme name onto the closest of the five hues. Anything
  /// ambiguous (blues, greys, the old bahamaBlue default) lands on Violet.
  @visibleForTesting
  static QAccent accentForLegacyScheme(String scheme) {
    final s = scheme.toLowerCase();
    bool any(List<String> words) => words.any(s.contains);
    if (any(['teal', 'aqua', 'cyan', 'outerspace'])) return QAccent.teal;
    if (any(['green', 'jungle', 'money', 'verdun', 'genoa', 'lime'])) {
      return QAccent.green;
    }
    if (any(['sakura', 'pink', 'rose', 'mandy', 'blumine'])) {
      return QAccent.rose;
    }
    if (any(['red', 'coral', 'mango', 'amber', 'orange', 'gold', 'espresso'])) {
      return QAccent.coral;
    }
    return QAccent.violet;
  }
}

/// Live appearance settings. [AppearanceSettings.load] runs in main() before
/// the first frame and seeds [bootstrap], so the app never paints a frame in
/// the wrong theme.
@Riverpod(keepAlive: true)
class Appearance extends _$Appearance {
  static AppearanceSettings bootstrap = const AppearanceSettings();

  @override
  AppearanceSettings build() => bootstrap;

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  void _log(String name, Map<String, Object> params) {
    // Analytics isn't registered in widget tests; never let it throw here.
    if (!getIt.isRegistered<FirebaseAnalytics>()) return;
    getIt.get<FirebaseAnalytics>().logEvent(name: name, parameters: params);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await (await _prefs).setString(kAppearanceThemeKey, mode.name);
    _log('theme_changed', {'theme_mode': mode.name});
  }

  Future<void> setAccent(QAccent accent) async {
    state = state.copyWith(accent: accent);
    await (await _prefs).setString(kAppearanceAccentKey, accent.name);
    _log('accent_changed', {'accent': accent.name});
  }

  /// Called continuously while the slider drags; persisted on release via
  /// [commitQuoteScale].
  void previewQuoteScale(double scale) {
    state = state.copyWith(
      quoteScale: scale.clamp(
        AppearanceSettings.minQuoteScale,
        AppearanceSettings.maxQuoteScale,
      ),
    );
  }

  Future<void> commitQuoteScale() async {
    await (await _prefs).setDouble(kAppearanceQuoteScaleKey, state.quoteScale);
    _log('text_size_changed', {'scale': state.quoteScale});
  }

  Future<void> setReadingFont(ReadingFont font) async {
    state = state.copyWith(readingFont: font);
    await (await _prefs).setString(kAppearanceReadingFontKey, font.name);
    _log('font_family_changed', {'font_family': font.name});
  }

  Future<void> setLayout(ThreadLayout layout) async {
    state = state.copyWith(layout: layout);
    await (await _prefs).setString(kAppearanceLayoutKey, layout.name);
    _log('view_mode_toggled', {'layout': layout.name});
  }

  Future<void> setBackgroundGlow(bool on) async {
    state = state.copyWith(backgroundGlow: on);
    await (await _prefs).setBool(kAppearanceGlowKey, on);
    _log('background_glow_toggled', {'on': on.toString()});
  }

  Future<void> reset() async {
    state = const AppearanceSettings();
    final prefs = await _prefs;
    for (final key in [
      kAppearanceThemeKey,
      kAppearanceAccentKey,
      kAppearanceQuoteScaleKey,
      kAppearanceReadingFontKey,
      kAppearanceLayoutKey,
      kAppearanceGlowKey,
    ]) {
      await prefs.remove(key);
    }
    _log('settings_reset_to_default', {'source': 'appearance'});
  }
}
