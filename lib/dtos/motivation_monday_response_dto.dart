import 'package:json_annotation/json_annotation.dart';

import 'motivation_monday_dto.dart';
import 'pagination_dto.dart';

part '../generated/dtos/motivation_monday_response_dto.g.dart';

@JsonSerializable()
class MotivationMondayResponseDto {
  final List<MotivationMondayDto> motivationMondayWithQuotes;
  final PaginationDto pagination;

  MotivationMondayResponseDto({
    required this.motivationMondayWithQuotes,
    required this.pagination,
  });

  /// Connect the generated [_$MotivationMondayResponseDtoFromJson] function to the `fromJson`
  /// factory.
  factory MotivationMondayResponseDto.fromJson(Map<String, dynamic> json) =>
      _$MotivationMondayResponseDtoFromJson(json);

  /// Connect the generated [_$MotivationMondayResponseDtoToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$MotivationMondayResponseDtoToJson(this);
}
