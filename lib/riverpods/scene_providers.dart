import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../dtos/character_dto.dart';
import '../dtos/media_title_dto.dart';
import '../dtos/scene_quote_dto.dart';
import '../services/drift_scene_service.dart';
import '../services/scene_repository.dart';
import '../services/scene_service.dart';

part '../generated/riverpods/scene_providers.g.dart';

// Family arguments are strings rather than lists: provider families are keyed
// by ==, and two equal lists are different keys (see the note on
// InterestsScreen._prefetchFirstQuotePage). `typesCsv` is e.g. "movie,anime".

List<MediaType> typesFromCsv(String csv) => [
  for (final name in csv.split(','))
    if (name.isNotEmpty) MediaTypeX.parse(name),
];

String typesToCsv(Iterable<MediaType> types) =>
    (types.map((t) => t.name).toList()..sort()).join(',');

@Riverpod(keepAlive: true)
Future<SceneOfTheDayDto?> sceneOfTheDay(Ref ref) =>
    SceneRepository.instance.sceneOfTheDay();

@Riverpod(keepAlive: true)
Future<List<MediaTitleDto>> trendingTitles(Ref ref, String typesCsv) =>
    SceneRepository.instance.trendingTitles(types: typesFromCsv(typesCsv));

@Riverpod(keepAlive: true)
Future<TitleDetailDto?> titleDetail(Ref ref, String titleIdOrSlug) =>
    SceneRepository.instance.titleDetail(titleIdOrSlug);

/// One page of lines. Screens accumulate pages themselves, the same way Home
/// does with fetchAllQuotes.
@Riverpod(keepAlive: true)
Future<List<SceneQuoteDto>> sceneQuotesPage(
  Ref ref, {
  required int pageNumber,
  required int pageSize,
  String typesCsv = '',
  String? titleId,
  String? characterId,
  String sort = 'random',
}) => SceneRepository.instance.sceneQuotes(
  pageNumber: pageNumber,
  pageSize: pageSize,
  types: typesFromCsv(typesCsv),
  titleId: titleId,
  characterId: characterId,
  sort: SceneSort.values.firstWhere(
    (s) => s.name == sort,
    orElse: () => SceneSort.random,
  ),
);

@Riverpod(keepAlive: true)
Future<List<SceneOfTheDayDto>> fridayNightLinesPage(
  Ref ref,
  int pageNumber,
  int pageSize,
) => SceneRepository.instance.fridayNightLines(
  pageNumber: pageNumber,
  pageSize: pageSize,
);

@Riverpod(keepAlive: true)
Future<List<SceneOfTheDayDto>> sceneOfTheDayArchivePage(
  Ref ref,
  int pageNumber,
  int pageSize,
) => SceneRepository.instance.sceneOfTheDayArchive(
  pageNumber: pageNumber,
  pageSize: pageSize,
);

@Riverpod(keepAlive: true)
Future<List<CharacterDto>> charactersPage(
  Ref ref,
  String search,
  int pageNumber,
) =>
    SceneRepository.instance.characters(search: search, pageNumber: pageNumber);

/// Characters in the local cache, for the People "Characters N" count.
@riverpod
Future<int> localCharacterCount(Ref ref) => DriftSceneService.countCharacters();
