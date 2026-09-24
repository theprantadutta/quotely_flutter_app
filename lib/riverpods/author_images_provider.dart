import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/urls.dart';
import '../database/database.dart';
import '../dtos/author_response_dto.dart';
import '../service_locator/init_service_locators.dart';
import '../services/drift_author_service.dart';
import '../services/http_service.dart';

part '../generated/riverpods/author_images_provider.g.dart';

const _kAuthorsSyncedAtKey = 'author-images-synced-at';
const _kResyncAfter = Duration(days: 3);

/// Author slug → portrait URL, for every quote bubble in the app.
///
/// Quotes only carry the author's slug, so bubbles would otherwise show
/// initials everywhere except Author detail. The whole author list is one
/// request (a few hundred rows), cached in Drift and refreshed every few
/// days; offline, the cached photos keep working.
@Riverpod(keepAlive: true)
Future<Map<String, String>> authorImages(Ref ref) async {
  final prefs = await SharedPreferences.getInstance();
  final syncedAt = DateTime.tryParse(
    prefs.getString(_kAuthorsSyncedAtKey) ?? '',
  );
  var images = await _fromDrift();

  final stale =
      syncedAt == null || DateTime.now().difference(syncedAt) > _kResyncAfter;
  if (images.isEmpty || stale) {
    try {
      final response = await HttpService.get(
        '$kApiUrl/$kGetAllAuthors?getAllRows=true',
      );
      if (response.statusCode == 200) {
        final authors = AuthorResponseDto.fromJson(
          json.decode(response.data),
        ).authors;
        await DriftAuthorService.saveAuthorsToDatabase(authors);
        await prefs.setString(
          _kAuthorsSyncedAtKey,
          DateTime.now().toIso8601String(),
        );
        images = await _fromDrift();
      }
    } catch (_) {
      // Offline: whatever is cached still applies.
    }
  }
  return images;
}

Future<Map<String, String>> _fromDrift() async {
  final db = getIt.get<AppDatabase>();
  final rows = await (db.select(
    db.authors,
  )..where((a) => a.imageUrl.isNotNull())).get();
  return {
    for (final a in rows)
      if ((a.imageUrl ?? '').isNotEmpty) a.slug: a.imageUrl!,
  };
}
