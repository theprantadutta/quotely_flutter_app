import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show DateUtils;

import '../dtos/character_dto.dart';
import '../dtos/media_title_dto.dart';
import '../dtos/scene_quote_dto.dart';
import '../util/pagination_seed.dart';
import '../util/profanity.dart';
import 'drift_scene_service.dart';
import 'local_first.dart';
import 'scene_service.dart';

/// Flip to false to run Scenes entirely from the bundled seed + local cache
/// (e.g. against an API build that predates the Scenes endpoints).
const bool kScenesApiEnabled = true;

/// Everything the app needs from Scenes. Two implementations: the API one
/// (local first, refreshed from the backend, see [LocalFirst]) and a
/// local-only one.
abstract class SceneRepository {
  static final SceneRepository instance = kScenesApiEnabled
      ? ApiSceneRepository()
      : LocalSceneRepository();

  Future<List<SceneQuoteDto>> sceneQuotes({
    required int pageNumber,
    required int pageSize,
    List<MediaType> types = const [],
    String? titleId,
    String? characterId,
    SceneSort sort = SceneSort.random,
  });

  Future<List<MediaTitleDto>> trendingTitles({
    List<MediaType> types = const [],
    int pageNumber = 1,
    int pageSize = 12,
  });

  Future<List<MediaTitleDto>> searchTitles(String search);

  Future<TitleDetailDto?> titleDetail(String idOrSlug);

  Future<List<CharacterDto>> characters({
    String? search,
    int pageNumber = 1,
    int pageSize = 20,
  });

  Future<SceneOfTheDayDto?> sceneOfTheDay();

  Future<List<SceneOfTheDayDto>> sceneOfTheDayArchive({
    required int pageNumber,
    required int pageSize,
  });

  Future<List<SceneOfTheDayDto>> fridayNightLines({
    required int pageNumber,
    required int pageSize,
  });

  /// Downloads every title, character and line into Drift for the offline
  /// "Scenes" pack. Returns the number of lines saved.
  Future<int> downloadAll();
}

/// Local-only: Drift cache, which always contains the bundled seed.
class LocalSceneRepository implements SceneRepository {
  @override
  Future<List<SceneQuoteDto>> sceneQuotes({
    required int pageNumber,
    required int pageSize,
    List<MediaType> types = const [],
    String? titleId,
    String? characterId,
    SceneSort sort = SceneSort.random,
  }) => DriftSceneService.getSceneQuotes(
    pageNumber: pageNumber,
    pageSize: pageSize,
    types: types,
    titleId: titleId,
    characterId: characterId,
    sort: sort,
    seed: PaginationSeed.current,
  );

  @override
  Future<List<MediaTitleDto>> trendingTitles({
    List<MediaType> types = const [],
    int pageNumber = 1,
    int pageSize = 12,
  }) => DriftSceneService.getTitles(
    types: types,
    pageNumber: pageNumber,
    pageSize: pageSize,
  );

  @override
  Future<List<MediaTitleDto>> searchTitles(String search) =>
      DriftSceneService.getTitles(search: search, pageSize: 20);

  @override
  Future<TitleDetailDto?> titleDetail(String idOrSlug) =>
      DriftSceneService.getTitleDetail(idOrSlug);

  @override
  Future<List<CharacterDto>> characters({
    String? search,
    int pageNumber = 1,
    int pageSize = 20,
  }) => DriftSceneService.getCharacters(
    search: search,
    pageNumber: pageNumber,
    pageSize: pageSize,
  );

  /// Deterministic per calendar day, so every screen agrees on today's pick.
  @override
  Future<SceneOfTheDayDto?> sceneOfTheDay() async {
    final today = DateUtils.dateOnly(DateTime.now());
    return _pickFor(today, salt: 17, spoilerFree: true);
  }

  /// Archives are history: only the server knows what was actually sent,
  /// so there is nothing to invent locally.
  @override
  Future<List<SceneOfTheDayDto>> sceneOfTheDayArchive({
    required int pageNumber,
    required int pageSize,
  }) async => const [];

  @override
  Future<List<SceneOfTheDayDto>> fridayNightLines({
    required int pageNumber,
    required int pageSize,
  }) async => const [];

  Future<SceneOfTheDayDto?> _pickFor(
    DateTime day, {
    required int salt,
    bool spoilerFree = false,
  }) async {
    final all = await DriftSceneService.getSceneQuotes(
      pageNumber: 1,
      pageSize: 100000,
      sort: SceneSort.random,
      seed: 7,
    );
    final pool = spoilerFree ? all.where((q) => !q.isSpoiler).toList() : all;
    if (pool.isEmpty) return null;
    final index =
        (day.year * 372 + day.month * 31 + day.day + salt) % pool.length;
    return SceneOfTheDayDto(
      id: -(day.millisecondsSinceEpoch ~/ 86400000),
      sceneDate: day,
      sceneQuote: pool[index],
    );
  }

  @override
  Future<int> downloadAll() => DriftSceneService.countSceneQuotes();
}

/// Local first: lists come from Drift (which always holds the bundled seed)
/// and the backend refreshes them in the background. The daily picks and
/// archives have no table; [SceneService] serves their saved responses.
/// Any backend failure falls through to [LocalSceneRepository].
class ApiSceneRepository implements SceneRepository {
  final LocalSceneRepository _local = LocalSceneRepository();

  Future<T> _try<T>(
    Future<T> Function() network,
    Future<T> Function() local, {
    bool Function(T value)? isEmpty,
  }) async {
    try {
      final value = await network();
      // An empty first page from a fresh backend should not hide the seed.
      if (isEmpty != null && isEmpty(value)) return await local();
      return value;
    } catch (e) {
      debugPrint('Scenes API unavailable, using local data: $e');
      return local();
    }
  }

  @override
  Future<List<SceneQuoteDto>> sceneQuotes({
    required int pageNumber,
    required int pageSize,
    List<MediaType> types = const [],
    String? titleId,
    String? characterId,
    SceneSort sort = SceneSort.random,
  }) => LocalFirst.load(
    key:
        'scenes:${types.map((t) => t.name).join(',')}:$titleId:$characterId:'
        '${sort.name}:$pageNumber:$pageSize',
    local: () async => [
      for (final q in await _local.sceneQuotes(
        pageNumber: pageNumber,
        pageSize: pageSize,
        types: types,
        titleId: titleId,
        characterId: characterId,
        sort: sort,
      ))
        if (isClean(q.content)) q,
    ],
    remote: () async {
      final res = await SceneService.getSceneQuotes(
        pageNumber: pageNumber,
        pageSize: pageSize,
        types: types,
        titleId: titleId,
        characterId: characterId,
        sort: sort,
        seed: PaginationSeed.current,
      );
      await DriftSceneService.saveSceneQuotes(res.sceneQuotes);
      return [
        for (final q in res.sceneQuotes)
          if (isClean(q.content)) q,
      ];
    },
    isEmpty: (v) => v.isEmpty,
  );

  @override
  Future<List<MediaTitleDto>> trendingTitles({
    List<MediaType> types = const [],
    int pageNumber = 1,
    int pageSize = 12,
  }) => LocalFirst.load(
    key: 'titles:${types.map((t) => t.name).join(',')}:$pageNumber:$pageSize',
    local: () => _local.trendingTitles(
      types: types,
      pageNumber: pageNumber,
      pageSize: pageSize,
    ),
    remote: () async {
      // The backend refreshes the cache and the list is read from it, so
      // API titles and the bundled seed show together (seed rows for the
      // same slug are dropped on save).
      final res = await SceneService.getTitles(
        pageNumber: pageNumber,
        pageSize: pageSize,
        types: types,
        trending: true,
      );
      await DriftSceneService.saveTitles(res.titles);
      return _local.trendingTitles(
        types: types,
        pageNumber: pageNumber,
        pageSize: pageSize,
      );
    },
    isEmpty: (v) => v.isEmpty,
  );

  @override
  Future<List<MediaTitleDto>> searchTitles(String search) => LocalFirst.load(
    key: 'title-search:${search.toLowerCase()}',
    local: () => _local.searchTitles(search),
    remote: () async {
      final res = await SceneService.getTitles(
        pageNumber: 1,
        pageSize: 20,
        search: search,
      );
      await DriftSceneService.saveTitles(res.titles);
      // Read back from the cache so seed titles match too.
      return _local.searchTitles(search);
    },
    isEmpty: (v) => v.isEmpty,
  );

  @override
  Future<TitleDetailDto?> titleDetail(String idOrSlug) => LocalFirst.load(
    key: 'title:$idOrSlug',
    local: () => _local.titleDetail(idOrSlug),
    remote: () async {
      final detail = await SceneService.getTitleDetail(idOrSlug);
      if (detail == null) return _local.titleDetail(idOrSlug);
      await DriftSceneService.saveTitles([detail.title]);
      await DriftSceneService.saveCharacters(detail.characters);
      return detail;
    },
    isEmpty: (v) => v == null,
  );

  @override
  Future<List<CharacterDto>> characters({
    String? search,
    int pageNumber = 1,
    int pageSize = 20,
  }) => LocalFirst.load(
    key: 'characters:${search ?? ''}:$pageNumber:$pageSize',
    local: () => _local.characters(
      search: search,
      pageNumber: pageNumber,
      pageSize: pageSize,
    ),
    remote: () async {
      final res = await SceneService.getCharacters(
        pageNumber: pageNumber,
        pageSize: pageSize,
        search: search,
      );
      await DriftSceneService.saveCharacters(res.characters);
      // Cache-backed, like titles: API and seed characters list together.
      return _local.characters(
        search: search,
        pageNumber: pageNumber,
        pageSize: pageSize,
      );
    },
    isEmpty: (v) => v.isEmpty,
  );

  @override
  Future<SceneOfTheDayDto?> sceneOfTheDay() => _try(() async {
    final dto = await SceneService.getTodaySceneOfTheDay();
    if (dto == null || isProfane(dto.sceneQuote.content)) {
      return _local.sceneOfTheDay();
    }
    await DriftSceneService.saveSceneQuotes([dto.sceneQuote]);
    return dto;
  }, _local.sceneOfTheDay);

  @override
  Future<List<SceneOfTheDayDto>> sceneOfTheDayArchive({
    required int pageNumber,
    required int pageSize,
  }) => _try(
    () async {
      final res = await SceneService.getAllSceneOfTheDay(
        pageNumber: pageNumber,
        pageSize: pageSize,
      );
      await DriftSceneService.saveSceneQuotes([
        for (final d in res.sceneOfTheDayWithScenes) d.sceneQuote,
      ]);
      return [
        for (final d in res.sceneOfTheDayWithScenes)
          if (isClean(d.sceneQuote.content)) d,
      ];
    },
    () =>
        _local.sceneOfTheDayArchive(pageNumber: pageNumber, pageSize: pageSize),
  );

  @override
  Future<List<SceneOfTheDayDto>> fridayNightLines({
    required int pageNumber,
    required int pageSize,
  }) => _try(() async {
    final res = await SceneService.getAllFridayNightLines(
      pageNumber: pageNumber,
      pageSize: pageSize,
    );
    await DriftSceneService.saveSceneQuotes([
      for (final d in res.fridayNightLinesWithScenes) d.sceneQuote,
    ]);
    return [
      for (final d in res.fridayNightLinesWithScenes)
        if (isClean(d.sceneQuote.content)) d,
    ];
  }, () => _local.fridayNightLines(pageNumber: pageNumber, pageSize: pageSize));

  @override
  Future<int> downloadAll() async {
    final titles = await SceneService.getTitles(
      pageNumber: 1,
      pageSize: 1000,
      getAllRows: true,
    );
    await DriftSceneService.saveTitles(titles.titles);
    final characters = await SceneService.getCharacters(
      pageNumber: 1,
      pageSize: 1000,
      getAllRows: true,
    );
    await DriftSceneService.saveCharacters(characters.characters);
    final quotes = await SceneService.getSceneQuotes(
      pageNumber: 1,
      pageSize: 1000,
      getAllRows: true,
    );
    await DriftSceneService.saveSceneQuotes(quotes.sceneQuotes);
    return quotes.sceneQuotes.length;
  }
}
