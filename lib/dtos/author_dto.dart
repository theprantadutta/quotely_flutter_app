import 'package:json_annotation/json_annotation.dart';

import '../database/database.dart';

part '../generated/dtos/author_dto.g.dart';

@JsonSerializable()
class AuthorDto {
  final String id;
  final String name;
  final String bio;
  final String description;
  final String link;
  final int quoteCount;
  final String slug;
  final String? imageUrl;
  @JsonKey(fromJson: _fromJson, toJson: _toJson)
  final DateTime dateAdded;
  @JsonKey(fromJson: _fromJson, toJson: _toJson)
  final DateTime dateModified;

  AuthorDto({
    required this.id,
    required this.name,
    required this.bio,
    required this.description,
    required this.link,
    required this.quoteCount,
    required this.slug,
    required this.dateAdded,
    required this.dateModified,
    required this.imageUrl,
  });

  static DateTime _fromJson(String date) => DateTime.parse(date).toUtc();
  static String _toJson(DateTime date) => date.toUtc().toIso8601String();

  /// Creates an AuthorDto from a Drift 'Author' entity.
  factory AuthorDto.fromDrift(Author author) {
    return AuthorDto(
      id: author.id,
      name: author.name,
      bio: author.bio,
      description: author.description,
      link: author.link,
      quoteCount: author.quoteCount,
      slug: author.slug,
      imageUrl: author.imageUrl,
      dateAdded: author.dateAdded,
      dateModified: author.dateModified,
    );
  }

  /// --- ADD THIS STATIC METHOD ---
  /// Converts a list of Drift 'Author' entities to a list of 'AuthorDto's.
  static List<AuthorDto> fromAuthorList(List<Author> authors) {
    return authors.map((author) => AuthorDto.fromDrift(author)).toList();
  }

  /// Connect the generated [_$AuthorDtoFromJson] function to the `fromJson`
  /// factory.
  factory AuthorDto.fromJson(Map<String, dynamic> json) =>
      _$AuthorDtoFromJson(json);

  /// Connect the generated [_$AuthorDtoToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$AuthorDtoToJson(this);
}
