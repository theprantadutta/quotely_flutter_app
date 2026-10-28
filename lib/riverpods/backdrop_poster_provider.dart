import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/shared_preference_keys.dart';

part '../generated/riverpods/backdrop_poster_provider.g.dart';

const _seedAsset = 'assets/data/scenes_seed.json';

/// The poster for the Poster background when today has no scene of the day:
/// the last scene poster shown (see [rememberBackdropPoster]), else a seed
/// title's poster picked by date, so a fresh install has one before
/// anything loads. Null only if the seed can't be read.
@Riverpod(keepAlive: true)
Future<String?> fallbackPoster(Ref ref) async {
  final prefs = await SharedPreferences.getInstance();
  final last = prefs.getString(kLastBackdropPosterKey);
  if (last != null && last.isNotEmpty) return last;
  return seedPosterFor(DateTime.now(), await _seedPosters());
}

/// Picks one of [posters] for [day], turning over daily like the glow hue.
@visibleForTesting
String? seedPosterFor(DateTime day, List<String> posters) {
  if (posters.isEmpty) return null;
  final i = DateTime(
    day.year,
    day.month,
    day.day,
  ).difference(DateTime(2026)).inDays.abs();
  return posters[i % posters.length];
}

Future<List<String>> _seedPosters() async {
  try {
    final data =
        json.decode(await rootBundle.loadString(_seedAsset))
            as Map<String, dynamic>;
    return [
      for (final t in data['titles'] as List)
        if ((t as Map<String, dynamic>)['posterUrl'] case final String url
            when url.isNotEmpty)
          url,
    ];
  } catch (e) {
    debugPrint('Seed posters failed to load: $e');
    return const [];
  }
}

String? _remembered;

/// Saves [url] as the last poster shown. Cheap to call on every build: it
/// only writes when the poster changes.
void rememberBackdropPoster(String url) {
  if (url == _remembered) return;
  _remembered = url;
  SharedPreferences.getInstance().then(
    (prefs) => prefs.setString(kLastBackdropPosterKey, url),
  );
}
