import 'package:flutter/material.dart';

import 'tokens.dart';

/// Bundled families (see pubspec.yaml). Spotlight/Folio: a grotesk for the
/// interface, a display serif for the words people read, and a mono for
/// small uppercase labels.
const kFontUi = 'SchibstedGrotesk';
const kFontSerif = 'InstrumentSerif';
const kFontMono = 'IBMPlexMono';

/// Appearance → Reading font. Changes quote/fact text only. Serif is the
/// default in this design.
enum ReadingFont { sans, serif, mono }

extension ReadingFontLabel on ReadingFont {
  String get label => switch (this) {
    ReadingFont.sans => 'Sans',
    ReadingFont.serif => 'Serif',
    ReadingFont.mono => 'Mono',
  };

  String get family => switch (this) {
    ReadingFont.sans => kFontUi,
    ReadingFont.serif => kFontSerif,
    ReadingFont.mono => kFontMono,
  };

  /// Instrument Serif ships a single weight; the others read best at 500.
  FontWeight get weight => switch (this) {
    ReadingFont.serif => FontWeight.w400,
    _ => FontWeight.w500,
  };

  /// A display serif needs more size than a grotesk to read the same.
  double get sizeFactor => switch (this) {
    ReadingFont.serif => 1.0,
    ReadingFont.sans => 0.82,
    ReadingFont.mono => 0.74,
  };
}

/// Flutter letter-spacing is absolute, the design specifies em.
double _em(double size, double em) => size * em;

TextStyle _ui(
  double size,
  FontWeight weight,
  Color color, {
  double em = 0,
  double height = 1.35,
  String family = kFontUi,
}) => TextStyle(
  fontFamily: family,
  fontSize: size,
  fontWeight: weight,
  letterSpacing: _em(size, em),
  height: height,
  color: color,
  leadingDistribution: TextLeadingDistribution.even,
);

/// Every text style in the design, with its default color applied. Screens
/// `copyWith` only when a different color is called for.
///
/// Headings are the display serif at a single weight: hierarchy comes from
/// size and space, not boldness. The quote styles carry the reading font and
/// the Appearance text-size multiplier, so changing either restyles live.
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

  /// Full-screen feed: the one line on screen.
  final TextStyle quoteSpotlight;
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
    required this.quoteSpotlight,
    required this.quoteHero,
    required this.quoteFeature,
    required this.quoteFact,
    required this.quoteBody,
    required this.quoteCompact,
  });

  factory QuotelyText.build(
    QuotelyTokens t, {
    ReadingFont readingFont = ReadingFont.serif,
    double quoteScale = 1.0,
  }) {
    TextStyle quote(double size, double h, {double em = -0.01}) {
      final s = size * quoteScale * readingFont.sizeFactor;
      return TextStyle(
        fontFamily: readingFont.family,
        fontSize: s,
        fontWeight: readingFont.weight,
        letterSpacing: readingFont == ReadingFont.mono ? 0 : _em(s, em),
        height: h,
        color: t.ink,
        leadingDistribution: TextLeadingDistribution.even,
      );
    }

    TextStyle display(double size, {double h = 1.05, double em = -0.01}) =>
        _ui(size, FontWeight.w400, t.ink,
            em: em, height: h, family: kFontSerif);

    return QuotelyText._(
      readingFont: readingFont,
      quoteScale: quoteScale,
      displayOnboarding: display(40, h: 1.02, em: -0.015),
      titleScreen: display(38),
      titlePush: display(32),
      titleDetail: display(34, h: 1.0),
      sectionTitle: display(24, h: 1.15),
      rowTitle: _ui(15, FontWeight.w600, t.ink),
      body: _ui(14, FontWeight.w400, t.mute, height: 1.5),
      meta: _ui(13, FontWeight.w400, t.mute),
      label: _ui(12.5, FontWeight.w500, t.mute),
      chip: _ui(13.5, FontWeight.w500, t.ink),
      overline: _ui(10.5, FontWeight.w500, t.mute,
          em: 0.14, height: 1.2, family: kFontMono),
      caption: _ui(11.5, FontWeight.w400, t.mute),
      badge: _ui(9.5, FontWeight.w600, t.accInk,
          em: 0.08, height: 1, family: kFontMono),
      button: _ui(15, FontWeight.w600, t.onAcc, height: 1),
      buttonSecondary: _ui(15, FontWeight.w600, t.ink, height: 1),
      quoteSpotlight: quote(44, 1.02, em: -0.015),
      quoteHero: quote(32, 1.08),
      quoteFeature: quote(28, 1.1),
      quoteFact: quote(32, 1.08),
      quoteBody: quote(24, 1.15),
      quoteCompact: quote(21, 1.2),
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
      quoteSpotlight: l(quoteSpotlight, other.quoteSpotlight),
      quoteHero: l(quoteHero, other.quoteHero),
      quoteFeature: l(quoteFeature, other.quoteFeature),
      quoteFact: l(quoteFact, other.quoteFact),
      quoteBody: l(quoteBody, other.quoteBody),
      quoteCompact: l(quoteCompact, other.quoteCompact),
    );
  }
}
