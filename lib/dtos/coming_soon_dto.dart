import 'media_title_dto.dart';

/// Why an item is in Coming soon: a dated release ahead, or simply trending.
enum ComingSoonReason { upcoming, trending }

/// A title with lines to catch up on before a [ComingSoonDto] comes out.
class ComingSoonTitleDto {
  final String id;
  final String slug;
  final String name;
  final MediaType type;
  final String? posterUrl;
  final int? yearStart;
  final int lineCount;

  const ComingSoonTitleDto({
    required this.id,
    required this.slug,
    required this.name,
    required this.type,
    this.posterUrl,
    this.yearStart,
    this.lineCount = 0,
  });

  /// The title screen accepts either; the id is preferred.
  String get route => id.isNotEmpty ? id : slug;

  /// "Movie · 2019 · 9 lines".
  String get meta => [
    type.label,
    if (yearStart != null) '$yearStart',
    if (lineCount > 0) '$lineCount ${lineCount == 1 ? 'line' : 'lines'}',
  ].join(' · ');

  factory ComingSoonTitleDto.fromJson(Map<String, dynamic> json) =>
      ComingSoonTitleDto(
        id: json['id'] as String? ?? '',
        slug: json['slug'] as String? ?? '',
        name: json['name'] as String? ?? '',
        type: MediaTypeX.parse(json['type'] as String?),
        posterUrl: json['posterUrl'] as String?,
        yearStart: (json['yearStart'] as num?)?.toInt(),
        lineCount: (json['lineCount'] as num?)?.toInt() ?? 0,
      );
}

/// One item of `Spotlight/GetComingSoon`: an upcoming (or trending) release
/// and the titles with lines that lead into it.
class ComingSoonDto {
  final String id;
  final String name;
  final MediaType type;

  /// The release day as a plain local date, or null.
  final DateTime? releaseDate;

  /// As the backend counted when it answered. Labels recompute from
  /// [releaseDate] instead, since a saved copy goes stale.
  final int? daysUntil;
  final ComingSoonReason reason;
  final String? posterUrl;
  final String overview;
  final List<ComingSoonTitleDto> titles;

  const ComingSoonDto({
    required this.id,
    required this.name,
    required this.type,
    this.releaseDate,
    this.daysUntil,
    this.reason = ComingSoonReason.upcoming,
    this.posterUrl,
    this.overview = '',
    this.titles = const [],
  });

  /// "2026-12-16" (or a full timestamp) as a date with no time or zone.
  static DateTime? _date(Object? value) {
    if (value is! String || value.isEmpty) return null;
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  factory ComingSoonDto.fromJson(Map<String, dynamic> json) => ComingSoonDto(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    type: MediaTypeX.parse(json['type'] as String?),
    releaseDate: _date(json['releaseDate']),
    daysUntil: (json['daysUntil'] as num?)?.toInt(),
    reason: json['reason'] == 'trending'
        ? ComingSoonReason.trending
        : ComingSoonReason.upcoming,
    posterUrl: json['posterUrl'] as String?,
    overview: json['overview'] as String? ?? '',
    titles: [
      for (final t in json['titles'] as List? ?? const [])
        if (t is Map<String, dynamic>) ComingSoonTitleDto.fromJson(t),
    ],
  );

  /// A response body; anything that isn't a list reads as empty.
  static List<ComingSoonDto> listFromJson(Object? json) => [
    if (json is List)
      for (final item in json)
        if (item is Map<String, dynamic>) ComingSoonDto.fromJson(item),
  ];
}
