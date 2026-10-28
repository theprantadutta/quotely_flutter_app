import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

import '../components/thread/q_image.dart' show kImageHeaders;
import '../dtos/quote_of_the_day_dto.dart';

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
/// QuoteOfTheDayWidgetProvider.kt and QuotelyWidget.swift.
class QuoteWidgetService {
  QuoteWidgetService._();

  static final instance = QuoteWidgetService._();

  /// Shared with the widget extension on iOS. Must match the App Groups
  /// capability on both the Runner and QuotelyWidget targets.
  static const appGroupId = 'group.com.pranta.quotely';

  /// The WidgetKit `kind` of the iOS widget.
  static const iOSKind = 'QuotelyWidget';

  /// The AppWidgetProvider on Android.
  static const androidProvider =
      'com.pranta.quotely.widget.QuoteOfTheDayWidgetProvider';

  static const kText = 'qotd_text';
  static const kAuthor = 'qotd_author';
  static const kDate = 'qotd_date';

  /// Absolute path of the blurred poster PNG, written by [HomeWidget.saveFile].
  static const kPoster = 'qotd_poster';

  /// The poster URL the saved PNG was made from, so it is only redone when
  /// the day's poster changes.
  static const kPosterUrl = 'qotd_poster_url';

  /// Size of the saved poster. 3:2 sits between the small (square) and
  /// medium (wide) widgets; both crop it to fill. Being a blur, it needs no
  /// more pixels than this.
  static const posterSize = Size(480, 320);

  /// Blur strength at [posterSize], about what `PosterWash` applies on a
  /// phone screen: enough to leave only colour.
  static const posterBlurSigma = 30.0;

  static bool get supported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Future<void>? _ready;
  Future<void> _chain = Future<void>.value();
  String? _lastSignature;

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
    final run = _chain.then((_) => _update(quote, posterUrl, force));
    _chain = run.catchError((Object _) {});
    return run;
  }

  Future<void> _update(
    QuoteOfTheDayDto quote,
    String? posterUrl,
    bool force,
  ) async {
    final date = dateKey(quote.quoteDate);
    final poster = (posterUrl == null || posterUrl.isEmpty) ? null : posterUrl;
    final signature = '$date|${quote.quoteId}|${poster ?? ''}';
    if (!force && signature == _lastSignature) return;
    try {
      await (_ready ??= _init());
      await HomeWidget.saveWidgetData<String>(kText, quote.content.trim());
      await HomeWidget.saveWidgetData<String>(kAuthor, quote.author.trim());
      await HomeWidget.saveWidgetData<String>(kDate, date);
      await _savePoster(poster);
      await HomeWidget.updateWidget(
        qualifiedAndroidName: androidProvider,
        iOSName: iOSKind,
      );
      _lastSignature = signature;
    } catch (e) {
      debugPrint('QuoteWidgetService: update failed: $e');
    }
  }

  Future<void> _init() async {
    if (Platform.isIOS) await HomeWidget.setAppGroupId(appGroupId);
  }

  /// Keeps the saved poster in step with [url]: re-blurs only when the URL
  /// changed or the file went missing, and clears it when there is no poster
  /// (or it can't be fetched) so the widget falls back to the plain page.
  Future<void> _savePoster(String? url) async {
    if (url != null) {
      final savedUrl = await HomeWidget.getWidgetData<String>(kPosterUrl);
      final savedPath = await HomeWidget.getWidgetData<String>(kPoster);
      if (savedUrl == url &&
          savedPath != null &&
          await File(savedPath).exists()) {
        return;
      }
      try {
        final png = await blurredPoster(url);
        await HomeWidget.saveFile(kPoster, png, extension: 'png');
        await HomeWidget.saveWidgetData<String>(kPosterUrl, url);
        return;
      } catch (e) {
        debugPrint('QuoteWidgetService: poster failed: $e');
      }
    }
    // Deletes the file too (saveWidgetData's deleteFile).
    await HomeWidget.saveWidgetData<String>(kPoster, null);
    await HomeWidget.saveWidgetData<String>(kPosterUrl, null);
  }

  /// Downloads [url] and returns it as a [posterSize] PNG, cover-cropped and
  /// blurred to pure colour.
  static Future<Uint8List> blurredPoster(String url) async {
    final response = await Dio().get<List<int>>(
      url,
      options: Options(
        responseType: ResponseType.bytes,
        headers: kImageHeaders,
        receiveTimeout: const Duration(seconds: 20),
      ),
    );
    final data = response.data;
    if (data == null || data.isEmpty) throw StateError('empty poster');

    // Decode small: the blur discards detail anyway.
    final codec = await ui.instantiateImageCodec(
      Uint8List.fromList(data),
      targetWidth: 240,
    );
    final source = (await codec.getNextFrame()).image;
    codec.dispose();

    final out = Offset.zero & posterSize;
    // Draw past the edges so the blur has real pixels to pull in there and
    // the corners don't fade.
    final dest = out.inflate(posterBlurSigma * 2);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..clipRect(out);
    canvas.drawImageRect(
      source,
      coverRect(
        Size(source.width.toDouble(), source.height.toDouble()),
        dest.size,
      ),
      dest,
      Paint()
        ..filterQuality = FilterQuality.medium
        ..imageFilter = ui.ImageFilter.blur(
          sigmaX: posterBlurSigma,
          sigmaY: posterBlurSigma,
          tileMode: TileMode.clamp,
        ),
    );
    final picture = recorder.endRecording();
    final image = await picture.toImage(
      posterSize.width.toInt(),
      posterSize.height.toInt(),
    );
    picture.dispose();
    source.dispose();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (bytes == null) throw StateError('poster encode failed');
    return bytes.buffer.asUint8List();
  }

  /// The centred part of a [source]-sized image with the aspect ratio of
  /// [target], as BoxFit.cover would show it.
  @visibleForTesting
  static Rect coverRect(Size source, Size target) {
    final scale =
        (source.width / target.width) < (source.height / target.height)
        ? source.width / target.width
        : source.height / target.height;
    final w = target.width * scale;
    final h = target.height * scale;
    return Rect.fromLTWH((source.width - w) / 2, (source.height - h) / 2, w, h);
  }
}
