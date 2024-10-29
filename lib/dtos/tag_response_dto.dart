import 'package:json_annotation/json_annotation.dart';
import 'package:quotely_flutter_app/dtos/pagination_dto.dart';
import 'package:quotely_flutter_app/dtos/tag_dto.dart';

part '../generated/dtos/tag_response_dto.g.dart';

@JsonSerializable()
class TagResponseDto {
  final List<TagDto> tags;
  final PaginationDto pagination;

  TagResponseDto({
    required this.tags,
    required this.pagination,
  });

  /// Connect the generated [_$TagResponseDtoFromJson] function to the `fromJson`
  /// factory.
  factory TagResponseDto.fromJson(Map<String, dynamic> json) =>
      _$TagResponseDtoFromJson(json);

  /// Connect the generated [_$TagResponseDtoToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$TagResponseDtoToJson(this);
}
