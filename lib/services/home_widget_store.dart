import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

import '../components/thread/q_image.dart' show kImageHeaders;
import '../theme/tokens.dart';

/// Quotely's home-screen widgets. Each one is native (an AppWidgetProvider
/// on Android, a WidgetKit widget in the one QuotelyWidget extension on iOS)
/// and only displays what the app saved for it through home_widget.
///
/// The names here are read on both platforms; keep them in sync with
/// android/app/src/main/kotlin/com/pranta/quotely/widget/ and
/// ios/QuotelyWidget/.
enum QuotelyWidgetKind {
  qotd(
    id: 'qotd',
    label: 'Quote of the Day',
    iOSKind: 'QuotelyWidget',
    androidClass: 'QuoteOfTheDayWidgetProvider',
  ),
  saved(
    id: 'saved',
    label: 'From your saved',
    iOSKind: 'QuotelySavedWidget',
    androidClass: 'SavedQuoteWidgetProvider',
  ),
  scene(
    id: 'scene',
    label: 'Scene of the Day',
    iOSKind: 'QuotelySceneWidget',
    androidClass: 'SceneOfTheDayWidgetProvider',
  );

  const QuotelyWidgetKind({
    required this.id,
    required this.label,
    required this.iOSKind,
    required this.androidClass,
  });

  /// Analytics `widget_kind`, and the `kind` query of the tap URL.
  final String id;

  /// The name people see in the widget gallery.
  final String label;

  /// The WidgetKit `kind`.
  final String iOSKind;

  /// The AppWidgetProvider's simple class name.
  final String androidClass;

  String get androidProvider => 'com.pranta.quotely.widget.$androidClass';

  static QuotelyWidgetKind? fromId(String? id) {
    for (final k in values) {
      if (k.id == id) return k;
    }
    return null;
  }

  /// From home_widget's [HomeWidgetInfo]: the iOS kind, or the Android class
  /// name (short, like `.widget.SavedQuoteWidgetProvider`, or qualified).
  static QuotelyWidgetKind? fromInstalled({
    String? iOSKind,
    String? androidClassName,
  }) {
    for (final k in values) {
      if (iOSKind != null && k.iOSKind == iOSKind) return k;
      if (androidClassName != null &&
          androidClassName.split('.').last == k.androidClass) {
        return k;
      }
    }
    return null;
  }
}

/// The plumbing the widgets share: the App Group, saving values, posters
/// cropped and blurred to colour, the day's glow, and redraws. Nothing here
/// throws to the caller's caller: every public service method catches.
class HomeWidgetStore {
  HomeWidgetStore._();

  /// Shared with the widget extension on iOS. Must match the App Groups
  /// capability on both the Runner and QuotelyWidget targets.
  static const appGroupId = 'group.com.pranta.quotely';

  /// The day's glow for the next [glowHorizon] days, for the widgets that
  /// fall back to (or always use) the page with the glow:
  /// `{"start":"yyyy-MM-dd","light":[argb…],"dark":[argb…]}`. Index i is for
  /// start + i days; past the end the widgets wrap around (the glow repeats
  /// every five days, which [glowHorizon] is a multiple of).
  static const kGlowDays = 'glow_days';
  static const glowHorizon = 30;

  /// Size of a saved poster. 3:2 sits between the small (square) and medium
  /// (wide) widgets; both crop it to fill. Being a blur, it needs no more
  /// pixels than this.
  static const posterSize = Size(480, 320);

  /// Blur strength at [posterSize], about what `PosterWash` applies on a
  /// phone screen: enough to leave only colour.
  static const posterBlurSigma = 30.0;

  /// Tests set this to run the services on the host.
  @visibleForTesting
  static bool? debugSupported;

  static bool get supported =>
      debugSupported ?? (!kIsWeb && (Platform.isAndroid || Platform.isIOS));

  static Future<void>? _ready;

  static Future<void> ready() => _ready ??= _init();

  static Future<void> _init() async {
    if (!kIsWeb && Platform.isIOS) await HomeWidget.setAppGroupId(appGroupId);
  }

  @visibleForTesting
  static void debugReset() {
    _ready = null;
    _remotePoster = null;
  }

  static Future<void> save<T>(String key, T? value) =>
      HomeWidget.saveWidgetData<T>(key, value);

  static Future<T?> read<T>(String key) => HomeWidget.getWidgetData<T>(key);

  /// Asks [kind]'s widgets to redraw from what was saved.
  static Future<void> redraw(QuotelyWidgetKind kind) => HomeWidget.updateWidget(
    qualifiedAndroidName: kind.androidProvider,
    iOSName: kind.iOSKind,
  );

  /// A local calendar day as yyyy-MM-dd.
  static String dayKey(DateTime day) => DateFormat('yyyy-MM-dd').format(day);

  /// Days from 1 January 2026 to [day]'s calendar date, counted on the
  /// calendar (so a daylight-saving change never skips or repeats a day).
  static int dayNumber(DateTime day) => DateTime.utc(
    day.year,
    day.month,
    day.day,
  ).difference(DateTime.utc(2026)).inDays;

  /// The glow the app paints on each of the next [glowHorizon] days, from
  /// [today]: exactly [QuotelyTokens.glowFor], light and dark.
  @visibleForTesting
  static Map<String, Object> glowDays(DateTime today) {
    final light = QuotelyTokens.of(Brightness.light, QAccent.violet);
    final dark = QuotelyTokens.of(Brightness.dark, QAccent.violet);
    final start = DateTime(today.year, today.month, today.day);
    final days = [
      for (var i = 0; i < glowHorizon; i++)
        DateTime(start.year, start.month, start.day + i),
    ];
    return {
      'start': dayKey(start),
      'light': [for (final d in days) light.glowFor(d).toARGB32()],
      'dark': [for (final d in days) dark.glowFor(d).toARGB32()],
    };
  }

  static Future<void> saveGlowDays(DateTime today) =>
      save<String>(kGlowDays, jsonEncode(glowDays(today)));

  /// Keeps the poster under [pathKey] in step with the first of [urls] that
  /// can be had: an already-saved one is kept as it is, otherwise it is
  /// fetched (from the image cache first, so it works offline when the app
  /// has shown it), cropped and blurred. Clears the poster when none can be
  /// had, so the widget falls back to its page. Returns the URL used.
  static Future<String?> keepPoster({
    required String pathKey,
    required String urlKey,
    required List<String?> urls,
  }) async {
    final candidates = <String>[
      for (final u in urls)
        if (u != null && u.isNotEmpty) u,
    ];
    final savedUrl = await read<String>(urlKey);
    final savedPath = await read<String>(pathKey);
    for (final url in candidates) {
      if (savedUrl == url &&
          savedPath != null &&
          await File(savedPath).exists()) {
        return url;
      }
      try {
        final png = await blurredPoster(url);
        await HomeWidget.saveFile(pathKey, png, extension: 'png');
        await save<String>(urlKey, url);
        return url;
      } catch (e) {
        debugPrint('HomeWidgetStore: poster failed: $e');
      }
    }
    // Deletes the file too (saveWidgetData's deleteFile).
    await save<String>(pathKey, null);
    await save<String>(urlKey, null);
    return null;
  }

  static Future<Uint8List> Function(String url)? _remotePoster;

  /// Tests replace the download.
  @visibleForTesting
  static set debugPosterBytes(Future<Uint8List> Function(String url)? f) =>
      _remotePoster = f;

  /// The poster's bytes: from the app's image cache (what
  /// CachedNetworkImage stored when the app showed it), else downloaded.
  static Future<Uint8List> posterBytes(String url) async {
    final override = _remotePoster;
    if (override != null) return override(url);
    try {
      final cached = await DefaultCacheManager().getFileFromCache(url);
      if (cached != null) return await cached.file.readAsBytes();
    } catch (_) {
      // No cache (or it can't be read): download instead.
    }
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
    return Uint8List.fromList(data);
  }

  /// [url] as a [posterSize] PNG, cover-cropped and blurred to pure colour.
  static Future<Uint8List> blurredPoster(String url) async {
    final data = await posterBytes(url);

    // Decode small: the blur discards detail anyway.
    final codec = await ui.instantiateImageCodec(data, targetWidth: 240);
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

/// Runs one widget's updates one after another, skipping a call that would
/// save exactly what was saved last (unless forced). Never throws.
class SerialWidgetUpdates {
  Future<void> _chain = Future<void>.value();
  String? _lastSignature;

  Future<void> run(
    String signature,
    bool force,
    Future<void> Function() body, {
    required String label,
  }) {
    final run = _chain.then((_) async {
      if (!force && signature == _lastSignature) return;
      try {
        await HomeWidgetStore.ready();
        await body();
        _lastSignature = signature;
      } catch (e) {
        debugPrint('$label: update failed: $e');
      }
    });
    _chain = run.catchError((Object _) {});
    return run;
  }

  /// Forgets the last signature, so the next call saves again.
  void debugReset() => _lastSignature = null;
}
