import 'package:json_annotation/json_annotation.dart';

import 'daily_brain_food_dto.dart';
import 'pagination_dto.dart';

part '../generated/dtos/daily_brain_food_response_dto.g.dart';

@JsonSerializable()
class DailyBrainFoodResponseDto {
  final List<DailyBrainFoodDto> dailyBrainFoodWithFacts;
  final PaginationDto pagination;

  DailyBrainFoodResponseDto({
    required this.dailyBrainFoodWithFacts,
    required this.pagination,
  });

  /// Connect the generated [_$DailyBrainFoodResponseDtoFromJson] function to the `fromJson`
  /// factory.
  factory DailyBrainFoodResponseDto.fromJson(Map<String, dynamic> json) =>
      _$DailyBrainFoodResponseDtoFromJson(json);

  /// Connect the generated [_$DailyBrainFoodResponseDtoToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$DailyBrainFoodResponseDtoToJson(this);
}
