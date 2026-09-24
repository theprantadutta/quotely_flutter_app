import 'package:flutter/material.dart';

/// The five user-selectable accents. [violet] is the brand default.
enum QAccent { violet, teal, coral, green, rose }

extension QAccentLabel on QAccent {
  String get label => switch (this) {
    QAccent.violet => 'Violet',
    QAccent.teal => 'Teal',
    QAccent.coral => 'Coral',
    QAccent.green => 'Green',
    QAccent.rose => 'Rose',
  };
}

/// The three roles each accent plays in one brightness.
class _AccentRoles {
  final Color acc;
  final Color accSoft;
  final Color accInk;
  const _AccentRoles(this.acc, this.accSoft, this.accInk);
}

// Derived from OKLCH (light acc L0.56 C0.16, soft L0.93 C0.04, ink L0.42 C0.14;
// dark acc L0.74 C0.12, soft L0.30 C0.06, ink L0.88 C0.07).
//
// Teal and Green light `acc` are darkened from #008F91 / #008D3C: white 16px
// bold text measured 3.9:1 and 4.3:1 on those, under the 4.5:1 floor. The
// darker values measure 5.1:1 and 5.6:1. Violet (4.9:1), Coral and Rose pass
// as specified.
const Map<QAccent, _AccentRoles> _light = {
  QAccent.violet: _AccentRoles(
    Color(0xFF6E62CD),
    Color(0xFFE4E5FF),
    Color(0xFF483C95),
  ),
  QAccent.teal: _AccentRoles(
    Color(0xFF007A7C),
    Color(0xFFCAF1F0),
    Color(0xFF006265),
  ),
  QAccent.coral: _AccentRoles(
    Color(0xFFC04637),
    Color(0xFFFFDFD8),
    Color(0xFF892218),
  ),
  QAccent.green: _AccentRoles(
    Color(0xFF007833),
    Color(0xFFD6F0DA),
    Color(0xFF00601C),
  ),
  QAccent.rose: _AccentRoles(
    Color(0xFFB2468A),
    Color(0xFFFDDEEE),
    Color(0xFF7E235E),
  ),
};

const Map<QAccent, _AccentRoles> _dark = {
  QAccent.violet: _AccentRoles(
    Color(0xFFA3A0F3),
    Color(0xFF2B294B),
    Color(0xFFD2D2FF),
  ),
  QAccent.teal: _AccentRoles(
    Color(0xFF25C2C2),
    Color(0xFF003737),
    Color(0xFFA0E7E6),
  ),
  QAccent.coral: _AccentRoles(
    Color(0xFFED8D7D),
    Color(0xFF47211B),
    Color(0xFFFFC7BC),
  ),
  QAccent.green: _AccentRoles(
    Color(0xFF6FC082),
    Color(0xFF14361D),
    Color(0xFFB7E5BF),
  ),
  QAccent.rose: _AccentRoles(
    Color(0xFFE08BBC),
    Color(0xFF432135),
    Color(0xFFFAC6E2),
  ),
};

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
      bg: dark ? const Color(0xFF0F0E14) : const Color(0xFFF4F3F8),
      surf: dark ? const Color(0xFF1C1B24) : const Color(0xFFFFFFFF),
      ink: dark ? const Color(0xFFEEEDF4) : const Color(0xFF16151C),
      mute: dark ? const Color(0xFF9A98A8) : const Color(0xFF67657A),
      line: dark ? const Color(0xFF2A2933) : const Color(0xFFE2E0EA),
      ph: dark ? const Color(0xFF26252F) : const Color(0xFFE8E6F0),
      onAcc: dark ? const Color(0xFF0F0E14) : const Color(0xFFFFFFFF),
      scrim: const Color(0x80080610),
      knob: const Color(0xFFFFFFFF),
      acc: roles.acc,
      accSoft: roles.accSoft,
      accInk: roles.accInk,
    );
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
