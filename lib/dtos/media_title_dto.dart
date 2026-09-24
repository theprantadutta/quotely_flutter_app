import 'package:json_annotation/json_annotation.dart';

import '../database/database.dart';
import 'character_dto.dart';
import 'pagination_dto.dart';

part '../generated/dtos/media_title_dto.g.dart';

/// The five kinds of title a scene can come from. Serialized lowercase to
/// match the API (`movie`, `tv`, `anime`, `game`, `cartoon`).
enum MediaType { movie, tv, anime, game, cartoon }

extension MediaTypeX on MediaType {
  /// "Movie", "TV", "Anime"… as shown in title chips and type pills.
  String get label => switch (this) {
    MediaType.movie => 'Movie',
    MediaType.tv => 'TV',
    MediaType.anime => 'Anime',
    MediaType.game => 'Game',
    MediaType.cartoon => 'Cartoon',
  };

  /// Filter-chip label: "Movies", "TV", "Anime", "Games", "Cartoons".
  String get plural => switch (this) {
    MediaType.movie => 'Movies',
    MediaType.tv => 'TV',
    MediaType.anime => 'Anime',
    MediaType.game => 'Games',
    MediaType.cartoon => 'Cartoons',
  };

  /// Interests picker label.
  String get interestLabel => switch (this) {
    MediaType.tv => 'TV shows',
    _ => plural,
  };

  static MediaType parse(String? value) => MediaType.values.firstWhere(
    (t) => t.name == value?.toLowerCase(),
    orElse: () => MediaType.movie,
  );
}

DateTime _date(String? value) =>
    value == null ? DateTime.utc(2026) : DateTime.parse(value).toUtc();
String _dateOut(DateTime date) => date.toUtc().toIso8601String();

@JsonSerializable()
class MediaTitleDto {
  final String id;
  final String slug;
  final String name;
  @JsonKey(fromJson: MediaTypeX.parse, toJson: _typeOut)
  final MediaType type;
  final int? yearStart;
  final int? yearEnd;
  @JsonKey(defaultValue: <String>[])
  final List<String> genres;
  @JsonKey(defaultValue: '')
  final String description;
  final String? posterUrl;
  @JsonKey(defaultValue: 0)
  final int quoteCount;
  @JsonKey(defaultValue: 0)
  final int popularity;
  @JsonKey(fromJson: _date, toJson: _dateOut)
  final DateTime dateAdded;
  @JsonKey(fromJson: _date, toJson: _dateOut)
  final DateTime dateModified;

  MediaTitleDto({
    required this.id,
    required this.slug,
    required this.name,
    required this.type,
    this.yearStart,
    this.yearEnd,
    required this.genres,
    this.description = '',
    this.posterUrl,
    this.quoteCount = 0,
    this.popularity = 0,
    required this.dateAdded,
    required this.dateModified,
  });

  static String _typeOut(MediaType type) => type.name;

  /// First genre, capitalised ("science fiction" arrives lowercase).
  String? get primaryGenre {
    if (genres.isEmpty || genres.first.trim().isEmpty) return null;
    final g = genres.first.trim();
    return g[0].toUpperCase() + g.substring(1);
  }

  /// "1999 – present", "2008 – 2013" or "1994". Only series run on.
  String get yearsLabel {
    if (yearStart == null) return '';
    final series = type == MediaType.tv || type == MediaType.anime;
    if (!series) return '$yearStart';
    if (yearEnd == null) return '$yearStart – present';
    if (yearEnd == yearStart) return '$yearStart';
    return '$yearStart – $yearEnd';
  }

  /// "Movie · 1994" for title chips.
  String get chipMeta =>
      [type.label, if (yearStart != null) '$yearStart'].join(' · ');

  factory MediaTitleDto.fromDrift(MediaTitle row) => MediaTitleDto(
    id: row.id,
    slug: row.slug,
    name: row.name,
    type: MediaTypeX.parse(row.type),
    yearStart: row.yearStart,
    yearEnd: row.yearEnd,
    genres: row.genres.isEmpty ? const [] : row.genres.split(','),
    description: row.description,
    posterUrl: row.posterUrl,
    quoteCount: row.quoteCount,
    popularity: row.popularity,
    dateAdded: row.dateAdded,
    dateModified: row.dateModified,
  );

  factory MediaTitleDto.fromJson(Map<String, dynamic> json) =>
      _$MediaTitleDtoFromJson(json);

  Map<String, dynamic> toJson() => _$MediaTitleDtoToJson(this);
}

@JsonSerializable()
class MediaTitleResponseDto {
  final List<MediaTitleDto> titles;
  final PaginationDto pagination;

  MediaTitleResponseDto({required this.titles, required this.pagination});

  factory MediaTitleResponseDto.fromJson(Map<String, dynamic> json) =>
      _$MediaTitleResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$MediaTitleResponseDtoToJson(this);
}

/// `Scene/GetTitleDetail`: the title plus its main characters.
@JsonSerializable()
class TitleDetailDto {
  final MediaTitleDto title;
  @JsonKey(defaultValue: <CharacterDto>[])
  final List<CharacterDto> characters;

  TitleDetailDto({required this.title, required this.characters});

  factory TitleDetailDto.fromJson(Map<String, dynamic> json) =>
      _$TitleDetailDtoFromJson(json);

  Map<String, dynamic> toJson() => _$TitleDetailDtoToJson(this);
}
