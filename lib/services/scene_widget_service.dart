import 'dart:async';

import 'package:flutter/foundation.dart';

import '../dtos/scene_quote_dto.dart';
import 'home_widget_store.dart';

/// Feeds the "Scene of the Day" home-screen widget: today's scene line, its
/// character and title, over the title's own poster blurred and washed
/// exactly as the Quote of the Day widget does it.
///
/// Poster order: the scene's own poster, then the app's fallback backdrop
/// poster (the last one shown, else a seed title's), then the plain page
/// with the day's glow. Posters come from the image cache first, so this
/// works offline whenever the app has shown them; and nothing is cleared
/// when there is no scene to save, so the widget keeps the last scene rather
/// than going blank.
///
/// Keep the keys in sync with SceneOfTheDayWidgetProvider.kt and
/// SceneWidget.swift.
class SceneWidgetService {
  SceneWidgetService._();

  static final instance = SceneWidgetService._();

  static const kEyebrow = 'scene_eyebrow';
  static const kText = 'scene_text';
  static const kCharacter = 'scene_character';
  static const kTitle = 'scene_title';
  static const kTitleId = 'scene_title_id';
  static const kDate = 'scene_date';
  static const kPoster = 'scene_poster';
  static const kPosterUrl = 'scene_poster_url';

  final _updates = SerialWidgetUpdates();

  /// The eyebrow both platforms draw: "SCENE · <TITLE>".
  static String eyebrow(String title) {
    final t = title.trim();
    return t.isEmpty ? 'SCENE OF THE DAY' : 'SCENE · ${t.toUpperCase()}';
  }

  /// Saves [scene] for the widget, with the first poster of
  /// [scene's own, fallbackPosterUrl] that can be had, and redraws it.
  /// Never throws.
  Future<void> update({
    required SceneOfTheDayDto scene,
    String? fallbackPosterUrl,
    bool force = false,
    DateTime? now,
  }) {
    if (!HomeWidgetStore.supported) return Future<void>.value();
    final line = scene.sceneQuote;
    final today = now ?? DateTime.now();
    final posters = [line.posterUrl, fallbackPosterUrl];
    return _updates.run(
      [
        HomeWidgetStore.dayKey(today),
        line.id,
        ...posters.map((p) => p ?? ''),
      ].join('|'),
      force,
      label: 'SceneWidgetService',
      () async {
        await HomeWidgetStore.save<String>(kEyebrow, eyebrow(line.titleName));
        await HomeWidgetStore.save<String>(kText, line.content.trim());
        await HomeWidgetStore.save<String>(
          kCharacter,
          line.characterName.trim(),
        );
        await HomeWidgetStore.save<String>(kTitle, line.titleName.trim());
        await HomeWidgetStore.save<String>(kTitleId, line.titleId);
        await HomeWidgetStore.save<String>(
          kDate,
          HomeWidgetStore.dayKey(scene.sceneDate.toUtc()),
        );
        await HomeWidgetStore.keepPoster(
          pathKey: kPoster,
          urlKey: kPosterUrl,
          urls: posters,
        );
        await HomeWidgetStore.saveGlowDays(today);
        await HomeWidgetStore.redraw(QuotelyWidgetKind.scene);
      },
    );
  }

  @visibleForTesting
  void debugReset() => _updates.debugReset();
}
