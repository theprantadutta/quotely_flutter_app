import 'package:json_annotation/json_annotation.dart';

import '../database/database.dart';

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

  /// --- ADD THIS FACTORY CONSTRUCTOR ---
  /// Creates a TagDto from a Drift 'Tag' entity.
  factory TagDto.fromDrift(Tag tag) {
    return TagDto(
      id: tag.id,
      name: tag.name,
      slug: tag.slug,
      quoteCount: tag.quoteCount,
      dateAdded: tag.dateAdded,
      dateModified: tag.dateModified,
    );
  }

  /// --- ADD THIS STATIC METHOD ---
  /// Converts a list of Drift 'Tag' entities to a list of 'TagDto's.
  static List<TagDto> fromTagList(List<Tag> tags) {
    return tags.map((tag) => TagDto.fromDrift(tag)).toList();
  }

  /// Connect the generated [_$TagDtoFromJson] function to the `fromJson`
  /// factory.
  factory TagDto.fromJson(Map<String, dynamic> json) => _$TagDtoFromJson(json);

  /// Connect the generated [_$TagDtoToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$TagDtoToJson(this);
}
