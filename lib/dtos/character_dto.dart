import 'package:json_annotation/json_annotation.dart';

import '../database/database.dart';
import 'pagination_dto.dart';

part '../generated/dtos/character_dto.g.dart';

@JsonSerializable()
class CharacterDto {
  final String id;
  final String titleId;
  @JsonKey(defaultValue: '')
  final String titleName;
  final String name;
  final String? avatarUrl;
  @JsonKey(defaultValue: 0)
  final int quoteCount;

  CharacterDto({
    required this.id,
    required this.titleId,
    this.titleName = '',
    required this.name,
    this.avatarUrl,
    this.quoteCount = 0,
  });

  /// "Luffy" from "Monkey D. Luffy": the story rows and character pickers
  /// show one word. Keeps well-known single names ("Dory") untouched.
  String get shortName {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.length <= 1 ? name : parts.last;
  }

  factory CharacterDto.fromDrift(MediaCharacter row, {String titleName = ''}) =>
      CharacterDto(
        id: row.id,
        titleId: row.titleId,
        titleName: titleName,
        name: row.name,
        avatarUrl: row.avatarUrl,
        quoteCount: row.quoteCount,
      );

  factory CharacterDto.fromJson(Map<String, dynamic> json) =>
      _$CharacterDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CharacterDtoToJson(this);
}

@JsonSerializable()
class CharacterResponseDto {
  final List<CharacterDto> characters;
  final PaginationDto pagination;

  CharacterResponseDto({required this.characters, required this.pagination});

  factory CharacterResponseDto.fromJson(Map<String, dynamic> json) =>
      _$CharacterResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CharacterResponseDtoToJson(this);
}
