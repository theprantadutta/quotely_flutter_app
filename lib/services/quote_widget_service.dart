import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:intl/intl.dart';

import '../dtos/quote_of_the_day_dto.dart';
import 'home_widget_store.dart';

/// Feeds the Quote of the Day home-screen widget: the Android AppWidget
/// (android/app/src/main/kotlin/.../widget) and the iOS WidgetKit extension
/// (ios/QuotelyWidget).
///
/// Both widgets are native and only display what is saved here: the quote,
/// its author, the date, and the day's scene poster as a PNG that is already
/// blurred to pure colour. The blur happens here, in Dart, so neither
/// platform has to do image work in a widget process. The theme-coloured wash
/// on top of the poster is drawn natively, so it follows the system's light
/// or dark mode without another round trip.
///
/// The keys below are read by name on both platforms; keep them in sync with
/// QuoteOfTheDayWidgetProvider.kt and QuotelyWidget.swift. The shared
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
        await HomeWidgetStore.keepPoster(
          pathKey: kPoster,
          urlKey: kPosterUrl,
          urls: [poster],
        );
        await HomeWidgetStore.redraw(QuotelyWidgetKind.qotd);
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
