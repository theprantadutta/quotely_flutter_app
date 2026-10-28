import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quotely_flutter_app/constants/shared_preference_keys.dart';
import 'package:quotely_flutter_app/riverpods/backdrop_poster_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('every seed title has a poster', () {
    final data =
        json.decode(File('assets/data/scenes_seed.json').readAsStringSync())
            as Map<String, dynamic>;
    for (final t in data['titles'] as List) {
      expect(
        (t as Map<String, dynamic>)['posterUrl'],
        startsWith('https://'),
        reason: t['name'] as String,
      );
    }
  });

  test('seed pick is stable within a day and turns over daily', () {
    const posters = ['a', 'b', 'c'];
    final morning = DateTime(2026, 3, 4, 7);
    final night = DateTime(2026, 3, 4, 23);
    expect(seedPosterFor(morning, posters), seedPosterFor(night, posters));
    expect(
      seedPosterFor(morning, posters),
      isNot(seedPosterFor(DateTime(2026, 3, 5), posters)),
    );
    expect(seedPosterFor(morning, const []), isNull);
  });

  test('a fresh install falls back to a seed poster', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final url = await container.read(fallbackPosterProvider.future);
    expect(url, startsWith('https://'));
  });

  test('the last poster shown wins over the seed', () async {
    SharedPreferences.setMockInitialValues({
      kLastBackdropPosterKey: 'https://example.com/last.jpg',
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(
      await container.read(fallbackPosterProvider.future),
      'https://example.com/last.jpg',
    );
  });

  test('remembering a poster persists it', () async {
    rememberBackdropPoster('https://example.com/today.jpg');
    await Future<void>.delayed(Duration.zero);
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString(kLastBackdropPosterKey),
      'https://example.com/today.jpg',
    );
  });
}
