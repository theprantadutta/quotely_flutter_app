import 'package:json_annotation/json_annotation.dart';

import 'fact_of_the_day_dto.dart';
import 'pagination_dto.dart';

part '../generated/dtos/fact_of_the_day_response_dto.g.dart';

@JsonSerializable()
class FactOfTheDayResponseDto {
  final List<FactOfTheDayDto> factOfTheDayWithFacts;
  final PaginationDto pagination;

  FactOfTheDayResponseDto({
    required this.factOfTheDayWithFacts,
    required this.pagination,
  });

  /// Connect the generated [_$FactOfTheDayResponseDtoFromJson] function to the `fromJson`
  /// factory.
  factory FactOfTheDayResponseDto.fromJson(Map<String, dynamic> json) =>
      _$FactOfTheDayResponseDtoFromJson(json);

  /// Connect the generated [_$FactOfTheDayResponseDtoToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$FactOfTheDayResponseDtoToJson(this);
}
