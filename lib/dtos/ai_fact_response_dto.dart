import 'package:json_annotation/json_annotation.dart';

import 'ai_fact_dto.dart';
import 'pagination_dto.dart';

part '../generated/dtos/ai_fact_response_dto.g.dart';

@JsonSerializable()
class AiFactResponseDto {
  final List<AiFactDto> aiFacts;
  final PaginationDto pagination;

  AiFactResponseDto({required this.aiFacts, required this.pagination});

  /// Connect the generated [_$AiFactResponseDtoFromJson] function to the `fromJson`
  /// factory.
  factory AiFactResponseDto.fromJson(Map<String, dynamic> json) =>
      _$AiFactResponseDtoFromJson(json);

  /// Connect the generated [_$AiFactResponseDtoToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$AiFactResponseDtoToJson(this);
}
