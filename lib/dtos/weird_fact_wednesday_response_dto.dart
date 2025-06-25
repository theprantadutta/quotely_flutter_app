import 'package:json_annotation/json_annotation.dart';

import 'pagination_dto.dart';
import 'weird_fact_wednesday_dto.dart';

part '../generated/dtos/weird_fact_wednesday_response_dto.g.dart';

@JsonSerializable()
class WeirdFactWednesdayResponseDto {
  final List<WeirdFactWednesdayDto> weirdFactWednesdayWithFacts;
  final PaginationDto pagination;

  WeirdFactWednesdayResponseDto({
    required this.weirdFactWednesdayWithFacts,
    required this.pagination,
  });

  /// Connect the generated [_$WeirdFactWednesdayResponseDtoFromJson] function to the `fromJson`
  /// factory.
  factory WeirdFactWednesdayResponseDto.fromJson(Map<String, dynamic> json) =>
      _$WeirdFactWednesdayResponseDtoFromJson(json);

  /// Connect the generated [_$WeirdFactWednesdayResponseDtoToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$WeirdFactWednesdayResponseDtoToJson(this);
}
