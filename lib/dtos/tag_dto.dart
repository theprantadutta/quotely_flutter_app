import 'package:json_annotation/json_annotation.dart';

part '../generated/dtos/tag_dto.g.dart';

@JsonSerializable()
class TagDto {
  final String id;
  final String name;
  final String slug;
  final int quoteCount;
  final DateTime dateAdded;
  final DateTime dateModified;

  TagDto({
    required this.id,
    required this.name,
    required this.slug,
    required this.quoteCount,
    required this.dateAdded,
    required this.dateModified,
  });

  /// Connect the generated [_$TagDtoFromJson] function to the `fromJson`
  /// factory.
  factory TagDto.fromJson(Map<String, dynamic> json) => _$TagDtoFromJson(json);

  /// Connect the generated [_$TagDtoToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$TagDtoToJson(this);
}
