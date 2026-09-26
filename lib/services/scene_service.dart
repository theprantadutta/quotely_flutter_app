import 'dart:convert';

import '../constants/urls.dart';
import '../dtos/character_dto.dart';
import '../dtos/media_title_dto.dart';
import '../dtos/scene_quote_dto.dart';
import 'http_service.dart';
import 'local_first.dart';

/// Sort orders accepted by `Scene/GetAllSceneQuotes`.
enum SceneSort { random, popular, episode, newest }

/// Raw HTTP calls for the Scenes API (docs/scenes_api.md). Endpoints with a
/// Drift table are cached by [SceneRepository]; the daily picks and their
/// archives, which have none, use [LocalFirst.get]'s saved responses here.
class SceneService {
  SceneService._();

  static Future<Map<String, dynamic>?> _get(
    String action,
    Map<String, String?> query, {
    bool cached = false,
    bool todayOnly = false,
  }) async {
    final params = {
      for (final e in query.entries)
        if (e.value != null && e.value!.isNotEmpty) e.key: e.value!,
    };
    final uri = Uri.parse(
      '$kApiUrl/$action',
    ).replace(queryParameters: params.isEmpty ? null : params);
    final response = cached
        ? await LocalFirst.get(uri.toString(), todayOnly: todayOnly)
        : await HttpService.get(uri.toString());
    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw Exception('$action failed with ${response.statusCode}');
    }
    final data = response.data is String
        ? json.decode(response.data as String)
        : response.data;
    return data as Map<String, dynamic>?;
  }

  static Future<SceneQuoteResponseDto> getSceneQuotes({
    required int pageNumber,
    required int pageSize,
    List<MediaType> types = const [],
    String? titleId,
    String? characterId,
    SceneSort sort = SceneSort.random,
    int? seed,
    bool getAllRows = false,
  }) async {
    final json = await _get(kGetAllSceneQuotes, {
      'pageNumber': '$pageNumber',
      'pageSize': '$pageSize',
      'types': types.map((t) => t.name).join(','),
      'titleId': titleId,
      'characterId': characterId,
      'sort': sort.name,
      'seed': seed?.toString(),
      if (getAllRows) 'getAllRows': 'true',
    });
    return SceneQuoteResponseDto.fromJson(json!);
  }

  static Future<MediaTitleResponseDto> getTitles({
    required int pageNumber,
    required int pageSize,
    List<MediaType> types = const [],
    String? search,
    bool trending = false,
    bool getAllRows = false,
  }) async {
    final json = await _get(trending ? kGetTrendingTitles : kGetAllTitles, {
      'pageNumber': '$pageNumber',
      'pageSize': '$pageSize',
      'types': types.map((t) => t.name).join(','),
      'search': search,
      if (getAllRows) 'getAllRows': 'true',
    });
    return MediaTitleResponseDto.fromJson(json!);
  }

  static Future<TitleDetailDto?> getTitleDetail(String titleIdOrSlug) async {
    final json = await _get(kGetTitleDetail, {'titleId': titleIdOrSlug});
    return json == null ? null : TitleDetailDto.fromJson(json);
  }

  static Future<CharacterResponseDto> getCharacters({
    required int pageNumber,
    required int pageSize,
    String? search,
    String? titleId,
    bool getAllRows = false,
  }) async {
    final json = await _get(kGetAllCharacters, {
      'pageNumber': '$pageNumber',
      'pageSize': '$pageSize',
      'search': search,
      'titleId': titleId,
      if (getAllRows) 'getAllRows': 'true',
    });
    return CharacterResponseDto.fromJson(json!);
  }

  static Future<SceneOfTheDayDto?> getTodaySceneOfTheDay() async {
    final json = await _get(
      kGetTodaySceneOfTheDay,
      const {},
      cached: true,
      todayOnly: true,
    );
    return json == null ? null : SceneOfTheDayDto.fromJson(json);
  }

  static Future<SceneOfTheDayResponseDto> getAllSceneOfTheDay({
    required int pageNumber,
    required int pageSize,
  }) async {
    final json = await _get(kGetAllSceneOfTheDay, {
      'pageNumber': '$pageNumber',
      'pageSize': '$pageSize',
    }, cached: true);
    return SceneOfTheDayResponseDto.fromJson(json!);
  }

  static Future<SceneOfTheDayDto?> getTodayFridayNightLines() async {
    final json = await _get(
      kGetTodayFridayNightLines,
      const {},
      cached: true,
      todayOnly: true,
    );
    return json == null ? null : SceneOfTheDayDto.fromJson(json);
  }

  static Future<FridayNightLinesResponseDto> getAllFridayNightLines({
    required int pageNumber,
    required int pageSize,
  }) async {
    final json = await _get(kGetAllFridayNightLines, {
      'pageNumber': '$pageNumber',
      'pageSize': '$pageSize',
    }, cached: true);
    return FridayNightLinesResponseDto.fromJson(json!);
  }
}
