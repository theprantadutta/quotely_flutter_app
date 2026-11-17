import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:intl/intl.dart';

import '../dtos/quote_of_the_day_dto.dart';
import 'home_widget_store.dart';

/// Feeds the widgets that show today's quote: Quote of the Day, Minimal
/// quote and the small square (Today, small), on Android
/// (android/app/src/main/kotlin/.../widget) and in the iOS WidgetKit
/// extension (ios/QuotelyWidget). They all read the keys below; see
/// [QuotelyWidgetKind.quoteOfTheDayReaders].
///
/// Both widgets are native and only display what is saved here: the quote,
/// its author, the date, and the day's scene poster as a PNG that is already
/// blurred to pure colour. The blur happens here, in Dart, so neither
/// platform has to do image work in a widget process. The theme-coloured wash
/// on top of the poster is drawn natively, so it follows the system's light
/// or dark mode without another round trip.
///
/// The keys below are read by name on both platforms; keep them in sync with
/// QuoteOfTheDayWidgetProvider.kt, MinimalQuoteWidgetProvider.kt,
/// SquareQuoteWidgetProvider.kt, QuotelyWidget.swift, MinimalQuoteWidget.swift
/// and SquareQuoteWidget.swift. The shared
/// plumbing (App Group, posters, redraws) is in [HomeWidgetStore].
class QuoteWidgetService {
  QuoteWidgetService._();

  static final instance = QuoteWidgetService._();

  static const appGroupId = HomeWidgetStore.appGroupId;

  /// The WidgetKit `kind` of the iOS widget.
  static final iOSKind = QuotelyWidgetKind.qotd.iOSKind;

  /// The AppWidgetProvider on Android.
  static final androidProvider = QuotelyWidgetKind.qotd.androidProvider;

  static const kText = 'qotd_text';
  static const kAuthor = 'qotd_author';
  static const kDate = 'qotd_date';

  /// The small square's line: the quote when it is at most [shortMax]
  /// characters, else empty (the square then shows [kEyebrow] and "Open
  /// today's quote"). Decided here so both platforms agree.
  static const kShort = 'qotd_short';

  /// The small square's eyebrow: the quote's day, like "TUE · NOV 17".
  static const kEyebrow = 'qotd_eyebrow';

  /// The longest quote the small square shows whole.
  static const shortMax = 60;

  /// Absolute path of the blurred poster PNG, written by `HomeWidget.saveFile`.
  static const kPoster = 'qotd_poster';

  /// The poster URL the saved PNG was made from, so it is only redone when
  /// the day's poster changes.
  static const kPosterUrl = 'qotd_poster_url';

  static const posterSize = HomeWidgetStore.posterSize;
  static const posterBlurSigma = HomeWidgetStore.posterBlurSigma;

  static bool get supported => HomeWidgetStore.supported;

  final _updates = SerialWidgetUpdates();

  /// The day the quote is for, as yyyy-MM-dd. The API sends UTC midnight;
  /// formatting the UTC fields keeps that day in every time zone.
  @visibleForTesting
  static String dateKey(DateTime quoteDate) =>
      DateFormat('yyyy-MM-dd').format(quoteDate.toUtc());

  /// [text] for the small square if it is short enough to read whole there,
  /// else null.
  static String? shortLine(String text) {
    final t = text.trim();
    if (t.isEmpty || t.runes.length > shortMax) return null;
    return t;
  }

  /// The small square's eyebrow for the quote's day ("TUE · NOV 17"), from
  /// the UTC fields like [dateKey].
  static String eyebrow(DateTime quoteDate) => DateFormat(
    'EEE · MMM d',
    'en_US',
  ).format(quoteDate.toUtc()).toUpperCase();

  /// Saves [quote] (and a blurred copy of [posterUrl]) for the widget and
  /// asks it to redraw. Calls run one after another; a call that would save
  /// exactly what was saved last does nothing unless [force] is set. Never
  /// throws: the widget is a nicety and must not break the app.
  Future<void> update({
    required QuoteOfTheDayDto quote,
    String? posterUrl,
    bool force = false,
  }) {
    if (!supported) return Future<void>.value();
    final date = dateKey(quote.quoteDate);
    final poster = (posterUrl == null || posterUrl.isEmpty) ? null : posterUrl;
    return _updates.run(
      '$date|${quote.quoteId}|${poster ?? ''}',
      force,
      label: 'QuoteWidgetService',
      () async {
        await HomeWidgetStore.save<String>(kText, quote.content.trim());
        await HomeWidgetStore.save<String>(kAuthor, quote.author.trim());
        await HomeWidgetStore.save<String>(kDate, date);
        await HomeWidgetStore.save<String>(
          kShort,
          shortLine(quote.content) ?? '',
        );
        await HomeWidgetStore.save<String>(kEyebrow, eyebrow(quote.quoteDate));
        await HomeWidgetStore.keepPoster(
          pathKey: kPoster,
          urlKey: kPosterUrl,
          urls: [poster],
        );
        // The small square's background.
        await HomeWidgetStore.saveGlowDays(DateTime.now());
        for (final kind in QuotelyWidgetKind.quoteOfTheDayReaders) {
          await HomeWidgetStore.redraw(kind);
        }
      },
    );
  }

  /// [url] as a [posterSize] PNG, cover-cropped and blurred to pure colour.
  static Future<Uint8List> blurredPoster(String url) =>
      HomeWidgetStore.blurredPoster(url);

  /// The centred part of a [source]-sized image with the aspect ratio of
  /// [target], as BoxFit.cover would show it.
  @visibleForTesting
  static Rect coverRect(Size source, Size target) =>
      HomeWidgetStore.coverRect(source, target);
}
