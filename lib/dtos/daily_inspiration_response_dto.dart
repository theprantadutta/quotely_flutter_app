import 'package:json_annotation/json_annotation.dart';

import 'daily_inspiration_dto.dart';
import 'pagination_dto.dart';

part '../generated/dtos/daily_inspiration_response_dto.g.dart';

@JsonSerializable()
class DailyInspirationResponseDto {
  final List<DailyInspirationDto> quoteOfTheDayWithQuotes;
  final PaginationDto pagination;

  DailyInspirationResponseDto({
    required this.quoteOfTheDayWithQuotes,
    required this.pagination,
  });

  /// Connect the generated [_$DailyInspirationResponseDtoFromJson] function to the `fromJson`
  /// factory.
  factory DailyInspirationResponseDto.fromJson(Map<String, dynamic> json) =>
      _$DailyInspirationResponseDtoFromJson(json);

  /// Connect the generated [_$DailyInspirationResponseDtoToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$DailyInspirationResponseDtoToJson(this);
}
