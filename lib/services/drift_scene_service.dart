import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import '../database/database.dart';
import '../dtos/character_dto.dart';
import '../dtos/media_title_dto.dart';
import '../dtos/scene_quote_dto.dart';
import '../service_locator/init_service_locators.dart';
import 'scene_service.dart';

/// Offline cache for Scenes, plus the bundled seed that makes the feature
/// work on a first launch with no network (or before the backend has
/// generated anything).
class DriftSceneService {
  DriftSceneService._();

  static const _seedAsset = 'assets/data/scenes_seed.json';
  static const _seededKey = 'scenes-seed-loaded-v1';
  static const _seedIdPrefix = 'seed-';

  static AppDatabase get _db => getIt.get<AppDatabase>();

  static Future<void>? _seeding;

  /// Loads the bundled seed into Drift once per install. Safe to call from
  /// anywhere; concurrent callers share one load.
  static Future<void> ensureSeeded() => _seeding ??= _loadSeed();

  static Future<void> _loadSeed() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_seededKey) ?? false) return;
    try {
      final raw = await rootBundle.loadString(_seedAsset);
      final data = json.decode(raw) as Map<String, dynamic>;
      final titles = [
        for (final t in data['titles'] as List)
          MediaTitleDto.fromJson(t as Map<String, dynamic>),
      ];
      final characters = [
        for (final c in data['characters'] as List)
          CharacterDto.fromJson(c as Map<String, dynamic>),
      ];
      final quotes = [
        for (final q in data['sceneQuotes'] as List)
          SceneQuoteDto.fromJson(q as Map<String, dynamic>),
      ];
      await saveTitles(titles, replaceSeedDuplicates: false);
      await saveCharacters(characters);
      await saveSceneQuotes(quotes);
      await prefs.setBool(_seededKey, true);
    } catch (e) {
      debugPrint('Scenes seed failed to load: $e');
      _seeding = null;
    }
  }

  // --- Writes ---------------------------------------------------------------

  static MediaTitlesCompanion _titleCompanion(MediaTitleDto t) =>
      MediaTitlesCompanion(
        id: Value(t.id),
        slug: Value(t.slug),
        name: Value(t.name),
        type: Value(t.type.name),
        yearStart: Value(t.yearStart),
        yearEnd: Value(t.yearEnd),
        genres: Value(t.genres.join(',')),
        description: Value(t.description),
        posterUrl: Value(t.posterUrl),
        quoteCount: Value(t.quoteCount),
        popularity: Value(t.popularity),
        dateAdded: Value(t.dateAdded),
        dateModified: Value(t.dateModified),
      );

  /// Upserts titles. When real (API) titles arrive, seed rows for the same
  /// slug are dropped so offline lists don't show the title twice. Seed
  /// lines the user saved are kept.
  static Future<void> saveTitles(
    List<MediaTitleDto> titles, {
    bool replaceSeedDuplicates = true,
  }) async {
    if (titles.isEmpty) return;
    await _db.batch((b) {
      for (final t in titles) {
        b.insert(
          _db.mediaTitles,
          _titleCompanion(t),
          onConflict: DoUpdate((_) => _titleCompanion(t)),
        );
      }
    });
    if (!replaceSeedDuplicates) return;
    final realSlugs = [
      for (final t in titles)
        if (!t.id.startsWith(_seedIdPrefix)) t.slug,
    ];
    if (realSlugs.isEmpty) return;
    final seedIds =
        await (_db.selectOnly(_db.mediaTitles)
              ..addColumns([_db.mediaTitles.id])
              ..where(
                _db.mediaTitles.slug.isIn(realSlugs) &
                    _db.mediaTitles.id.like('$_seedIdPrefix%'),
              ))
            .map((r) => r.read(_db.mediaTitles.id)!)
            .get();
    if (seedIds.isEmpty) return;
    await (_db.delete(_db.mediaTitles)..where((t) => t.id.isIn(seedIds))).go();
    await (_db.delete(
      _db.mediaCharacters,
    )..where((c) => c.titleId.isIn(seedIds))).go();
    await (_db.delete(
      _db.sceneQuotes,
    )..where((q) => q.titleId.isIn(seedIds) & q.isFavorite.equals(false))).go();
  }

  static Future<void> saveCharacters(List<CharacterDto> characters) async {
    if (characters.isEmpty) return;
    await _db.batch((b) {
      for (final c in characters) {
        final row = MediaCharactersCompanion(
          id: Value(c.id),
          titleId: Value(c.titleId),
          name: Value(c.name),
          avatarUrl: Value(c.avatarUrl),
          quoteCount: Value(c.quoteCount),
        );
        b.insert(_db.mediaCharacters, row, onConflict: DoUpdate((_) => row));
      }
    });
  }

  static SceneQuotesCompanion _quoteCompanion(SceneQuoteDto q) =>
      SceneQuotesCompanion(
        id: Value(q.id),
        content: Value(q.content),
        titleId: Value(q.titleId),
        titleSlug: Value(q.titleSlug),
        titleName: Value(q.titleName),
        titleType: Value(q.titleType.name),
        titleYear: Value(q.titleYear),
        posterUrl: Value(q.posterUrl),
        characterId: Value(q.characterId),
        characterName: Value(q.characterName),
        characterAvatarUrl: Value(q.characterAvatarUrl),
        episodeLabel: Value(q.episodeLabel),
        season: Value(q.season),
        episode: Value(q.episode),
        isSpoiler: Value(q.isSpoiler),
        spoilerAfterEpisode: Value(q.spoilerAfterEpisode),
        tags: Value(q.tags.join(',')),
        likes: Value(q.likes),
        dateAdded: Value(q.dateAdded),
        dateModified: Value(q.dateModified),
      );

  /// Upserts lines without touching `isFavorite` (absent from the update).
  static Future<void> saveSceneQuotes(List<SceneQuoteDto> quotes) async {
    if (quotes.isEmpty) return;
    await _db.batch((b) {
      for (final q in quotes) {
        final row = _quoteCompanion(q);
        b.insert(_db.sceneQuotes, row, onConflict: DoUpdate((_) => row));
      }
    });
  }

  static Future<void> setFavorite(SceneQuoteDto quote, bool isFavorite) async {
    await saveSceneQuotes([quote]);
    await (_db.update(_db.sceneQuotes)..where((q) => q.id.equals(quote.id)))
        .write(SceneQuotesCompanion(isFavorite: Value(isFavorite)));
  }

  // --- Reads ----------------------------------------------------------------

  static Future<List<String>> getFavoriteIds() async {
    final rows =
        await (_db.selectOnly(_db.sceneQuotes)
              ..addColumns([_db.sceneQuotes.id])
              ..where(_db.sceneQuotes.isFavorite.equals(true)))
            .get();
    return rows.map((r) => r.read(_db.sceneQuotes.id)!).toList();
  }

  static Stream<List<SceneQuoteDto>> watchFavorites() {
    final query = _db.select(_db.sceneQuotes)
      ..where((q) => q.isFavorite.equals(true))
      ..orderBy([(q) => OrderingTerm.desc(q.dateModified)]);
    return query.watch().map(
      (rows) => rows.map(SceneQuoteDto.fromDrift).toList(),
    );
  }

  static Future<SceneQuoteDto?> getById(String id) async {
    final row = await (_db.select(
      _db.sceneQuotes,
    )..where((q) => q.id.equals(id))).getSingleOrNull();
    return row == null ? null : SceneQuoteDto.fromDrift(row);
  }

  static Future<List<SceneQuoteDto>> getByIds(List<String> ids) async {
    if (ids.isEmpty) return const [];
    final rows = await (_db.select(
      _db.sceneQuotes,
    )..where((q) => q.id.isIn(ids))).get();
    return rows.map(SceneQuoteDto.fromDrift).toList();
  }

  /// Paged local lines with the same filters as the API. Random order is
  /// shuffled in Dart with [seed] so paging stays stable, like the server.
  static Future<List<SceneQuoteDto>> getSceneQuotes({
    required int pageNumber,
    required int pageSize,
    List<MediaType> types = const [],
    String? titleId,
    String? characterId,
    SceneSort sort = SceneSort.random,
    int? seed,
  }) async {
    await ensureSeeded();
    final query = _db.select(_db.sceneQuotes);
    if (types.isNotEmpty) {
      query.where((q) => q.titleType.isIn(types.map((t) => t.name)));
    }
    if (titleId != null) {
      query.where(
        (q) => q.titleId.equals(titleId) | q.titleSlug.equals(titleId),
      );
    }
    if (characterId != null) {
      query.where((q) => q.characterId.equals(characterId));
    }
    switch (sort) {
      case SceneSort.popular:
        query.orderBy([
          (q) => OrderingTerm.desc(q.likes),
          (q) => OrderingTerm.asc(q.id),
        ]);
      case SceneSort.episode:
        query.orderBy([
          (q) => OrderingTerm.asc(q.season, nulls: NullsOrder.first),
          (q) => OrderingTerm.asc(q.episode),
          (q) => OrderingTerm.asc(q.episodeLabel),
        ]);
      case SceneSort.newest:
        query.orderBy([(q) => OrderingTerm.desc(q.dateAdded)]);
      case SceneSort.random:
        query.orderBy([(q) => OrderingTerm.asc(q.id)]);
    }
    var rows = await query.get();
    if (sort == SceneSort.random) {
      rows = List.of(rows)..shuffle(Random(seed ?? 1));
    }
    final start = (pageNumber - 1) * pageSize;
    if (start >= rows.length) return const [];
    return rows
        .sublist(start, min(start + pageSize, rows.length))
        .map(SceneQuoteDto.fromDrift)
        .toList();
  }

  static Future<List<MediaTitleDto>> getTitles({
    List<MediaType> types = const [],
    String? search,
    int pageNumber = 1,
    int pageSize = 20,
  }) async {
    await ensureSeeded();
    final query = _db.select(_db.mediaTitles)
      ..orderBy([
        (t) => OrderingTerm.desc(t.popularity),
        (t) => OrderingTerm.desc(t.quoteCount),
      ])
      ..limit(pageSize, offset: (pageNumber - 1) * pageSize);
    if (types.isNotEmpty) {
      query.where((t) => t.type.isIn(types.map((e) => e.name)));
    }
    if (search != null && search.trim().isNotEmpty) {
      query.where((t) => t.name.like('%${search.trim()}%'));
    }
    return (await query.get()).map(MediaTitleDto.fromDrift).toList();
  }

  static Future<TitleDetailDto?> getTitleDetail(String idOrSlug) async {
    await ensureSeeded();
    final title =
        await (_db.select(_db.mediaTitles)
              ..where((t) => t.id.equals(idOrSlug) | t.slug.equals(idOrSlug)))
            .getSingleOrNull();
    if (title == null) return null;
    final characters =
        await (_db.select(_db.mediaCharacters)
              ..where((c) => c.titleId.equals(title.id))
              ..orderBy([(c) => OrderingTerm.desc(c.quoteCount)]))
            .get();
    return TitleDetailDto(
      title: MediaTitleDto.fromDrift(title),
      characters: [
        for (final c in characters)
          CharacterDto.fromDrift(c, titleName: title.name),
      ],
    );
  }

  static Future<List<CharacterDto>> getCharacters({
    String? search,
    int pageNumber = 1,
    int pageSize = 20,
  }) async {
    await ensureSeeded();
    final c = _db.mediaCharacters;
    final t = _db.mediaTitles;
    final query = _db.select(c).join([innerJoin(t, t.id.equalsExp(c.titleId))])
      ..orderBy([OrderingTerm.desc(c.quoteCount), OrderingTerm.asc(c.name)])
      ..limit(pageSize, offset: (pageNumber - 1) * pageSize);
    if (search != null && search.trim().isNotEmpty) {
      query.where(c.name.like('%${search.trim()}%'));
    }
    final rows = await query.get();
    return [
      for (final r in rows)
        CharacterDto.fromDrift(r.readTable(c), titleName: r.readTable(t).name),
    ];
  }

  static Future<int> countCharacters() async {
    await ensureSeeded();
    final count = _db.mediaCharacters.id.count();
    final row = await (_db.selectOnly(
      _db.mediaCharacters,
    )..addColumns([count])).getSingle();
    return row.read(count) ?? 0;
  }

  static Future<int> countSceneQuotes() async {
    final count = _db.sceneQuotes.id.count();
    final row = await (_db.selectOnly(
      _db.sceneQuotes,
    )..addColumns([count])).getSingle();
    return row.read(count) ?? 0;
  }

  /// All local lines (the composer's local search runs over these).
  static Future<List<SceneQuoteDto>> getAll() async {
    await ensureSeeded();
    return (await _db.select(_db.sceneQuotes).get())
        .map(SceneQuoteDto.fromDrift)
        .toList();
  }
}
