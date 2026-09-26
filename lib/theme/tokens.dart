import 'package:flutter/material.dart';

/// The five user-selectable accents. The enum names are what's persisted,
/// so they stay stable; the Spotlight palette gives them new colours
/// ([QAccentLabel.label]). [violet] (Terracotta here) is the default.
enum QAccent { violet, teal, coral, green, rose }

extension QAccentLabel on QAccent {
  String get label => switch (this) {
    QAccent.violet => 'Terracotta',
    QAccent.teal => 'Teal',
    QAccent.coral => 'Ink blue',
    QAccent.green => 'Olive',
    QAccent.rose => 'Plum',
  };
}

/// The three roles each accent plays in one brightness.
class _AccentRoles {
  final Color acc;
  final Color accSoft;
  final Color accInk;
  const _AccentRoles(this.acc, this.accSoft, this.accInk);
}

// OKLCH: light acc L0.52 C0.13, soft L0.90 C0.035, ink L0.40 C0.11;
// dark acc L0.74 C0.12, soft L0.30 C0.05, ink L0.86 C0.07.
// Hues: terracotta 38 (dark 50), teal 195, ink blue 255, olive 125, plum 330.
const Map<QAccent, _AccentRoles> _light = {
  QAccent.violet: _AccentRoles(
    Color(0xFFA5492B),
    Color(0xFFF4D7CE),
    Color(0xFF772D15),
  ),
  QAccent.teal: _AccentRoles(
    Color(0xFF007A7C),
    Color(0xFFC4E6E5),
    Color(0xFF00585A),
  ),
  QAccent.coral: _AccentRoles(
    Color(0xFF2E69B2),
    Color(0xFFCFE0F6),
    Color(0xFF164781),
  ),
  QAccent.green: _AccentRoles(
    Color(0xFF587502),
    Color(0xFFD8E3CA),
    Color(0xFF3A5100),
  ),
  QAccent.rose: _AccentRoles(
    Color(0xFF914A8C),
    Color(0xFFECD6E9),
    Color(0xFF672E63),
  ),
};

const Map<QAccent, _AccentRoles> _dark = {
  QAccent.violet: _AccentRoles(
    Color(0xFFE79363),
    Color(0xFF43241B),
    Color(0xFFFBC2B0),
  ),
  QAccent.teal: _AccentRoles(
    Color(0xFF25C2C2),
    Color(0xFF023536),
    Color(0xFF9AE0DF),
  ),
  QAccent.coral: _AccentRoles(
    Color(0xFF75AEF5),
    Color(0xFF1C2F46),
    Color(0xFFB3D4FF),
  ),
  QAccent.green: _AccentRoles(
    Color(0xFF99B860),
    Color(0xFF283215),
    Color(0xFFC6DAA8),
  ),
  QAccent.rose: _AccentRoles(
    Color(0xFFD58ECF),
    Color(0xFF3C243A),
    Color(0xFFECC1E7),
  ),
};

/// "Tinted background of the day" for the full-screen feed: the hue turns
/// over each day. Light L0.92 C0.045, dark L0.26 C0.05 (visible against the dark page).
const List<(Color, Color)> _dayTints = [
  (Color(0xFFFFDCCC), Color(0xFF3A1D12)), // clay
  (Color(0xFFC3EEF0), Color(0xFF0B2B2D)), // sea
  (Color(0xFFE6E8C6), Color(0xFF28290E)), // moss
  (Color(0xFFE9DEFF), Color(0xFF2A1F3F)), // lilac
  (Color(0xFFCFE8FF), Color(0xFF10263C)), // sky
];

/// The same five hues, saturated enough to read as light when laid over the
/// page at low opacity ([QuotelyTokens.glowFor]). The flat tints above are
/// too close to the dark page to show through a gradient.
const List<(Color, Color)> _dayGlows = [
  (Color(0xFFF2A07E), Color(0xFFC0643F)), // clay
  (Color(0xFF7FD3D6), Color(0xFF2E9A9C)), // sea
  (Color(0xFFC9CF7A), Color(0xFF8E9A38)), // moss
  (Color(0xFFC6B0FF), Color(0xFF8465D6)), // lilac
  (Color(0xFF9CCBFF), Color(0xFF3F7EC4)), // sky
];

/// Brand constants for icons, splash and the Android notification accent.
class QBrand {
  QBrand._();
  static const violet = Color(0xFF6E62CD);
  static const violetLight = Color(0xFFA3A0F3);
  static const paper = Color(0xFFF4F3F8);
  static const night = Color(0xFF0F0E14);
}

/// Every color the Thread design uses. Widgets read these through
/// `context.q` and never hard-code a color.
@immutable
class QuotelyTokens extends ThemeExtension<QuotelyTokens> {
  final Brightness brightness;
  final QAccent accent;

  /// Page background; also the title-chip fill inside a bubble.
  final Color bg;

  /// Bubbles, cards, grouped lists, unselected chips, sheets, inputs.
  final Color surf;
  final Color ink;
  final Color mute;
  final Color line;

  /// Image placeholder / skeleton fill.
  final Color ph;
  final Color onAcc;
  final Color scrim;
  final Color knob;
  final Color acc;
  final Color accSoft;
  final Color accInk;

  const QuotelyTokens({
    required this.brightness,
    required this.accent,
    required this.bg,
    required this.surf,
    required this.ink,
    required this.mute,
    required this.line,
    required this.ph,
    required this.onAcc,
    required this.scrim,
    required this.knob,
    required this.acc,
    required this.accSoft,
    required this.accInk,
  });

  bool get isDark => brightness == Brightness.dark;

  factory QuotelyTokens.of(Brightness brightness, QAccent accent) {
    final dark = brightness == Brightness.dark;
    final roles = (dark ? _dark : _light)[accent]!;
    return QuotelyTokens(
      brightness: brightness,
      accent: accent,
      bg: dark ? const Color(0xFF15120F) : const Color(0xFFF3EEE5),
      surf: dark ? const Color(0xFF221E19) : const Color(0xFFFBF7F0),
      ink: dark ? const Color(0xFFEEE7DB) : const Color(0xFF1D1915),
      mute: dark ? const Color(0xFF9B9184) : const Color(0xFF6F665B),
      line: dark ? const Color(0xFF2F2A23) : const Color(0xFFDCD3C4),
      ph: dark ? const Color(0xFF2A241D) : const Color(0xFFE4DCCD),
      onAcc: dark ? const Color(0xFF15120F) : const Color(0xFFFFFFFF),
      scrim: const Color(0x8015120F),
      knob: const Color(0xFFFFFFFF),
      acc: roles.acc,
      accSoft: roles.accSoft,
      accInk: roles.accInk,
    );
  }

  /// Background tint for the full-screen feed on [day].
  Color tintFor(DateTime day) {
    final i = DateTime(day.year, day.month, day.day)
        .difference(DateTime(2026))
        .inDays
        .abs();
    final (light, dark) = _dayTints[i % _dayTints.length];
    return isDark ? dark : light;
  }

  /// Glow colour for the page backdrop on [day]; same hue as [tintFor].
  Color glowFor(DateTime day) {
    final i = DateTime(day.year, day.month, day.day)
        .difference(DateTime(2026))
        .inDays
        .abs();
    final (light, dark) = _dayGlows[i % _dayGlows.length];
    return isDark ? dark : light;
  }

  /// The `acc` swatch for [accent] in [brightness], for the Appearance picker.
  static Color swatch(QAccent accent, Brightness brightness) =>
      (brightness == Brightness.dark ? _dark : _light)[accent]!.acc;

  @override
  QuotelyTokens copyWith({QAccent? accent}) =>
      QuotelyTokens.of(brightness, accent ?? this.accent);

  @override
  QuotelyTokens lerp(ThemeExtension<QuotelyTokens>? other, double t) {
    if (other is! QuotelyTokens) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return QuotelyTokens(
      brightness: t < 0.5 ? brightness : other.brightness,
      accent: t < 0.5 ? accent : other.accent,
      bg: l(bg, other.bg),
      surf: l(surf, other.surf),
      ink: l(ink, other.ink),
      mute: l(mute, other.mute),
      line: l(line, other.line),
      ph: l(ph, other.ph),
      onAcc: l(onAcc, other.onAcc),
      scrim: l(scrim, other.scrim),
      knob: l(knob, other.knob),
      acc: l(acc, other.acc),
      accSoft: l(accSoft, other.accSoft),
      accInk: l(accInk, other.accInk),
    );
  }
}
