import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show DateUtils;

import '../dtos/character_dto.dart';
import '../dtos/media_title_dto.dart';
import '../dtos/scene_quote_dto.dart';
import '../util/pagination_seed.dart';
import 'drift_scene_service.dart';
import 'scene_service.dart';

/// Flip to false to run Scenes entirely from the bundled seed + local cache
/// (e.g. against an API build that predates the Scenes endpoints).
const bool kScenesApiEnabled = true;

/// Everything the app needs from Scenes. Two implementations: the API one
/// (network first, cached to Drift, local fallback) and a local-only one.
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
    return _pickFor(today, salt: 17);
  }

  @override
  Future<List<SceneOfTheDayDto>> sceneOfTheDayArchive({
    required int pageNumber,
    required int pageSize,
  }) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final start = (pageNumber - 1) * pageSize;
    final picks = <SceneOfTheDayDto>[];
    for (var i = start; i < start + pageSize && i < 60; i++) {
      final pick = await _pickFor(today.subtract(Duration(days: i)), salt: 17);
      if (pick != null) picks.add(pick);
    }
    return picks;
  }

  /// The last N Fridays (today counts when it is Friday).
  @override
  Future<List<SceneOfTheDayDto>> fridayNightLines({
    required int pageNumber,
    required int pageSize,
  }) async {
    var friday = DateUtils.dateOnly(DateTime.now());
    while (friday.weekday != DateTime.friday) {
      friday = friday.subtract(const Duration(days: 1));
    }
    final start = (pageNumber - 1) * pageSize;
    final picks = <SceneOfTheDayDto>[];
    for (var i = start; i < start + pageSize && i < 26; i++) {
      final pick = await _pickFor(
        friday.subtract(Duration(days: 7 * i)),
        salt: 53,
        spoilerFree: true,
      );
      if (pick != null) picks.add(pick);
    }
    return picks;
  }

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

/// Network first; every response is cached to Drift so the same screens work
/// offline. Any failure falls through to [LocalSceneRepository].
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
  }) => _try(
    () async {
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
      return res.sceneQuotes;
    },
    () => _local.sceneQuotes(
      pageNumber: pageNumber,
      pageSize: pageSize,
      types: types,
      titleId: titleId,
      characterId: characterId,
      sort: sort,
    ),
    isEmpty: (v) => v.isEmpty && pageNumber == 1,
  );

  @override
  Future<List<MediaTitleDto>> trendingTitles({
    List<MediaType> types = const [],
    int pageNumber = 1,
    int pageSize = 12,
  }) => _try(
    () async {
      final res = await SceneService.getTitles(
        pageNumber: pageNumber,
        pageSize: pageSize,
        types: types,
        trending: true,
      );
      await DriftSceneService.saveTitles(res.titles);
      return res.titles;
    },
    () => _local.trendingTitles(
      types: types,
      pageNumber: pageNumber,
      pageSize: pageSize,
    ),
    isEmpty: (v) => v.isEmpty && pageNumber == 1,
  );

  @override
  Future<List<MediaTitleDto>> searchTitles(String search) => _try(() async {
    final res = await SceneService.getTitles(
      pageNumber: 1,
      pageSize: 20,
      search: search,
    );
    await DriftSceneService.saveTitles(res.titles);
    return res.titles;
  }, () => _local.searchTitles(search));

  @override
  Future<TitleDetailDto?> titleDetail(String idOrSlug) => _try(() async {
    final detail = await SceneService.getTitleDetail(idOrSlug);
    if (detail == null) return _local.titleDetail(idOrSlug);
    await DriftSceneService.saveTitles([detail.title]);
    await DriftSceneService.saveCharacters(detail.characters);
    return detail;
  }, () => _local.titleDetail(idOrSlug));

  @override
  Future<List<CharacterDto>> characters({
    String? search,
    int pageNumber = 1,
    int pageSize = 20,
  }) => _try(
    () async {
      final res = await SceneService.getCharacters(
        pageNumber: pageNumber,
        pageSize: pageSize,
        search: search,
      );
      await DriftSceneService.saveCharacters(res.characters);
      return res.characters;
    },
    () => _local.characters(
      search: search,
      pageNumber: pageNumber,
      pageSize: pageSize,
    ),
    isEmpty: (v) => v.isEmpty && pageNumber == 1 && (search ?? '').isEmpty,
  );

  @override
  Future<SceneOfTheDayDto?> sceneOfTheDay() => _try(() async {
    final dto = await SceneService.getTodaySceneOfTheDay();
    if (dto == null) return _local.sceneOfTheDay();
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
      return res.sceneOfTheDayWithScenes;
    },
    () =>
        _local.sceneOfTheDayArchive(pageNumber: pageNumber, pageSize: pageSize),
    isEmpty: (v) => v.isEmpty && pageNumber == 1,
  );

  @override
  Future<List<SceneOfTheDayDto>> fridayNightLines({
    required int pageNumber,
    required int pageSize,
  }) => _try(
    () async {
      final res = await SceneService.getAllFridayNightLines(
        pageNumber: pageNumber,
        pageSize: pageSize,
      );
      await DriftSceneService.saveSceneQuotes([
        for (final d in res.fridayNightLinesWithScenes) d.sceneQuote,
      ]);
      return res.fridayNightLinesWithScenes;
    },
    () => _local.fridayNightLines(pageNumber: pageNumber, pageSize: pageSize),
    isEmpty: (v) => v.isEmpty && pageNumber == 1,
  );

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
