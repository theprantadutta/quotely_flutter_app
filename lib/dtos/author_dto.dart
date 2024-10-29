import 'package:json_annotation/json_annotation.dart';

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
  });

  static DateTime _fromJson(String date) => DateTime.parse(date).toUtc();
  static String _toJson(DateTime date) => date.toUtc().toIso8601String();

  /// Connect the generated [_$AuthorDtoFromJson] function to the `fromJson`
  /// factory.
  factory AuthorDto.fromJson(Map<String, dynamic> json) =>
      _$AuthorDtoFromJson(json);

  /// Connect the generated [_$AuthorDtoToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$AuthorDtoToJson(this);
}
