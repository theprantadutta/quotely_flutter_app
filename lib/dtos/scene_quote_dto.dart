import 'package:json_annotation/json_annotation.dart';

import '../database/database.dart';
import 'media_title_dto.dart';
import 'pagination_dto.dart';

part '../generated/dtos/scene_quote_dto.g.dart';

DateTime _date(String? value) =>
    value == null ? DateTime.utc(2026) : DateTime.parse(value).toUtc();
String _dateOut(DateTime date) => date.toUtc().toIso8601String();

/// One line from a title, spoken by a character. Title and character fields
/// are denormalized (see docs/scenes_api.md) so a bubble renders from this
/// object alone.
@JsonSerializable()
class SceneQuoteDto {
  final String id;
  final String content;
  final String titleId;
  @JsonKey(defaultValue: '')
  final String titleSlug;
  final String titleName;
  @JsonKey(fromJson: MediaTypeX.parse, toJson: _typeOut)
  final MediaType titleType;
  final int? titleYear;
  final String? posterUrl;
  final String characterId;
  final String characterName;
  final String? characterAvatarUrl;
  final String? episodeLabel;
  final int? season;
  final int? episode;
  @JsonKey(defaultValue: false)
  final bool isSpoiler;
  final int? spoilerAfterEpisode;
  @JsonKey(defaultValue: <String>[])
  final List<String> tags;
  @JsonKey(defaultValue: 0)
  final int likes;
  @JsonKey(fromJson: _date, toJson: _dateOut)
  final DateTime dateAdded;
  @JsonKey(fromJson: _date, toJson: _dateOut)
  final DateTime dateModified;

  SceneQuoteDto({
    required this.id,
    required this.content,
    required this.titleId,
    this.titleSlug = '',
    required this.titleName,
    required this.titleType,
    this.titleYear,
    this.posterUrl,
    required this.characterId,
    required this.characterName,
    this.characterAvatarUrl,
    this.episodeLabel,
    this.season,
    this.episode,
    this.isSpoiler = false,
    this.spoilerAfterEpisode,
    required this.tags,
    this.likes = 0,
    required this.dateAdded,
    required this.dateModified,
  });

  static String _typeOut(MediaType type) => type.name;

  /// "Movie · 1994" for the title chip.
  String get chipMeta =>
      [titleType.label, if (titleYear != null) '$titleYear'].join(' · ');

  /// Share text, per the brief: `"Line" — Character, Title (Year) · via Quotely`.
  String get shareText {
    final year = titleYear == null ? '' : ' ($titleYear)';
    return '"$content" — $characterName, $titleName$year · via Quotely';
  }

  factory SceneQuoteDto.fromDrift(SceneQuote row) => SceneQuoteDto(
    id: row.id,
    content: row.content,
    titleId: row.titleId,
    titleSlug: row.titleSlug,
    titleName: row.titleName,
    titleType: MediaTypeX.parse(row.titleType),
    titleYear: row.titleYear,
    posterUrl: row.posterUrl,
    characterId: row.characterId,
    characterName: row.characterName,
    characterAvatarUrl: row.characterAvatarUrl,
    episodeLabel: row.episodeLabel,
    season: row.season,
    episode: row.episode,
    isSpoiler: row.isSpoiler,
    spoilerAfterEpisode: row.spoilerAfterEpisode,
    tags: row.tags.isEmpty ? const [] : row.tags.split(','),
    likes: row.likes,
    dateAdded: row.dateAdded,
    dateModified: row.dateModified,
  );

  factory SceneQuoteDto.fromJson(Map<String, dynamic> json) =>
      _$SceneQuoteDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SceneQuoteDtoToJson(this);
}

@JsonSerializable()
class SceneQuoteResponseDto {
  final List<SceneQuoteDto> sceneQuotes;
  final PaginationDto pagination;

  SceneQuoteResponseDto({required this.sceneQuotes, required this.pagination});

  factory SceneQuoteResponseDto.fromJson(Map<String, dynamic> json) =>
      _$SceneQuoteResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SceneQuoteResponseDtoToJson(this);
}

/// Scene of the day and Friday night lines share this shape.
@JsonSerializable()
class SceneOfTheDayDto {
  final int id;
  @JsonKey(fromJson: _date, toJson: _dateOut)
  final DateTime sceneDate;
  final SceneQuoteDto sceneQuote;

  SceneOfTheDayDto({
    required this.id,
    required this.sceneDate,
    required this.sceneQuote,
  });

  factory SceneOfTheDayDto.fromJson(Map<String, dynamic> json) =>
      _$SceneOfTheDayDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SceneOfTheDayDtoToJson(this);
}

@JsonSerializable()
class SceneOfTheDayResponseDto {
  @JsonKey(defaultValue: <SceneOfTheDayDto>[])
  final List<SceneOfTheDayDto> sceneOfTheDayWithScenes;
  final PaginationDto pagination;

  SceneOfTheDayResponseDto({
    required this.sceneOfTheDayWithScenes,
    required this.pagination,
  });

  factory SceneOfTheDayResponseDto.fromJson(Map<String, dynamic> json) =>
      _$SceneOfTheDayResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SceneOfTheDayResponseDtoToJson(this);
}

@JsonSerializable()
class FridayNightLinesResponseDto {
  @JsonKey(defaultValue: <SceneOfTheDayDto>[])
  final List<SceneOfTheDayDto> fridayNightLinesWithScenes;
  final PaginationDto pagination;

  FridayNightLinesResponseDto({
    required this.fridayNightLinesWithScenes,
    required this.pagination,
  });

  factory FridayNightLinesResponseDto.fromJson(Map<String, dynamic> json) =>
      _$FridayNightLinesResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$FridayNightLinesResponseDtoToJson(this);
}
