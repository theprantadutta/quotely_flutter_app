import 'package:flutter/material.dart';

import 'tokens.dart';

/// Bundled families (see pubspec.yaml). Manrope is the whole UI; the other
/// two only ever render quote and fact text, via [ReadingFont].
const kFontManrope = 'Manrope';
const kFontSerif = 'Newsreader';
const kFontMono = 'FiraCode';

/// Appearance → Reading font. Changes quote/fact bubble text only.
enum ReadingFont { sans, serif, mono }

extension ReadingFontLabel on ReadingFont {
  String get label => switch (this) {
    ReadingFont.sans => 'Sans',
    ReadingFont.serif => 'Serif',
    ReadingFont.mono => 'Mono',
  };

  String get family => switch (this) {
    ReadingFont.sans => kFontManrope,
    ReadingFont.serif => kFontSerif,
    ReadingFont.mono => kFontMono,
  };

  /// Serif and mono are set lighter: 800 Newsreader or Fira Code reads as
  /// shouting, and neither family ships that weight anyway.
  FontWeight weight(FontWeight sansWeight) => switch (this) {
    ReadingFont.sans => sansWeight,
    ReadingFont.serif =>
      sansWeight.value >= 700 ? FontWeight.w600 : FontWeight.w500,
    ReadingFont.mono => FontWeight.w500,
  };
}

/// Flutter letter-spacing is absolute, the design specifies em.
double _em(double size, double em) => size * em;

TextStyle _ui(
  double size,
  FontWeight weight,
  Color color, {
  double em = 0,
  double height = 1.3,
}) => TextStyle(
  fontFamily: kFontManrope,
  fontSize: size,
  fontWeight: weight,
  letterSpacing: _em(size, em),
  height: height,
  color: color,
  leadingDistribution: TextLeadingDistribution.even,
);

/// Every text style in the Thread design, with its default color already
/// applied. Screens `copyWith` only when the design calls for a different
/// color (e.g. `accInk` on an `accSoft` pill).
///
/// The quote styles carry the reading font and the Appearance text-size
/// multiplier, so changing either restyles every bubble live.
@immutable
class QuotelyText extends ThemeExtension<QuotelyText> {
  final ReadingFont readingFont;
  final double quoteScale;

  final TextStyle displayOnboarding;
  final TextStyle titleScreen;
  final TextStyle titlePush;
  final TextStyle titleDetail;
  final TextStyle sectionTitle;
  final TextStyle rowTitle;
  final TextStyle body;
  final TextStyle meta;
  final TextStyle label;
  final TextStyle chip;
  final TextStyle overline;
  final TextStyle caption;
  final TextStyle badge;
  final TextStyle button;
  final TextStyle buttonSecondary;

  final TextStyle quoteHero;
  final TextStyle quoteFeature;
  final TextStyle quoteFact;
  final TextStyle quoteBody;
  final TextStyle quoteCompact;

  const QuotelyText._({
    required this.readingFont,
    required this.quoteScale,
    required this.displayOnboarding,
    required this.titleScreen,
    required this.titlePush,
    required this.titleDetail,
    required this.sectionTitle,
    required this.rowTitle,
    required this.body,
    required this.meta,
    required this.label,
    required this.chip,
    required this.overline,
    required this.caption,
    required this.badge,
    required this.button,
    required this.buttonSecondary,
    required this.quoteHero,
    required this.quoteFeature,
    required this.quoteFact,
    required this.quoteBody,
    required this.quoteCompact,
  });

  factory QuotelyText.build(
    QuotelyTokens t, {
    ReadingFont readingFont = ReadingFont.sans,
    double quoteScale = 1.0,
  }) {
    TextStyle quote(double size, FontWeight weight, double em, double h) =>
        TextStyle(
          fontFamily: readingFont.family,
          fontSize: size * quoteScale,
          fontWeight: readingFont.weight(weight),
          // Negative tracking suits heavy Manrope; the serif and mono faces
          // are drawn with their own spacing and look cramped with it.
          letterSpacing: readingFont == ReadingFont.sans
              ? _em(size * quoteScale, em)
              : 0,
          height: h,
          color: t.ink,
          leadingDistribution: TextLeadingDistribution.even,
        );

    return QuotelyText._(
      readingFont: readingFont,
      quoteScale: quoteScale,
      displayOnboarding: _ui(
        31,
        FontWeight.w800,
        t.ink,
        em: -0.035,
        height: 1.08,
      ),
      titleScreen: _ui(26, FontWeight.w800, t.ink, em: -0.03, height: 1.1),
      titlePush: _ui(24, FontWeight.w800, t.ink, em: -0.03, height: 1.15),
      titleDetail: _ui(26, FontWeight.w800, t.ink, em: -0.03, height: 1.0),
      sectionTitle: _ui(20, FontWeight.w800, t.ink, em: -0.02, height: 1.2),
      rowTitle: _ui(15, FontWeight.w800, t.ink),
      body: _ui(14, FontWeight.w600, t.mute, height: 1.45),
      meta: _ui(13, FontWeight.w600, t.mute, height: 1.35),
      label: _ui(12, FontWeight.w700, t.mute),
      chip: _ui(13, FontWeight.w700, t.ink),
      overline: _ui(12, FontWeight.w800, t.mute, height: 1.2),
      caption: _ui(11, FontWeight.w600, t.mute),
      badge: _ui(9.5, FontWeight.w800, t.accInk, height: 1),
      button: _ui(16, FontWeight.w800, t.onAcc, height: 1),
      buttonSecondary: _ui(15, FontWeight.w800, t.ink, height: 1),
      quoteHero: quote(21.5, FontWeight.w700, -0.02, 1.22),
      quoteFeature: quote(20, FontWeight.w800, -0.02, 1.22),
      quoteFact: quote(25, FontWeight.w800, -0.025, 1.18),
      quoteBody: quote(17, FontWeight.w700, -0.01, 1.30),
      quoteCompact: quote(15.5, FontWeight.w700, -0.01, 1.30),
    );
  }

  @override
  QuotelyText copyWith() => this;

  @override
  QuotelyText lerp(ThemeExtension<QuotelyText>? other, double t) {
    if (other is! QuotelyText) return this;
    TextStyle l(TextStyle a, TextStyle b) => TextStyle.lerp(a, b, t)!;
    return QuotelyText._(
      readingFont: t < 0.5 ? readingFont : other.readingFont,
      quoteScale: t < 0.5 ? quoteScale : other.quoteScale,
      displayOnboarding: l(displayOnboarding, other.displayOnboarding),
      titleScreen: l(titleScreen, other.titleScreen),
      titlePush: l(titlePush, other.titlePush),
      titleDetail: l(titleDetail, other.titleDetail),
      sectionTitle: l(sectionTitle, other.sectionTitle),
      rowTitle: l(rowTitle, other.rowTitle),
      body: l(body, other.body),
      meta: l(meta, other.meta),
      label: l(label, other.label),
      chip: l(chip, other.chip),
      overline: l(overline, other.overline),
      caption: l(caption, other.caption),
      badge: l(badge, other.badge),
      button: l(button, other.button),
      buttonSecondary: l(buttonSecondary, other.buttonSecondary),
      quoteHero: l(quoteHero, other.quoteHero),
      quoteFeature: l(quoteFeature, other.quoteFeature),
      quoteFact: l(quoteFact, other.quoteFact),
      quoteBody: l(quoteBody, other.quoteBody),
      quoteCompact: l(quoteCompact, other.quoteCompact),
    );
  }
}
