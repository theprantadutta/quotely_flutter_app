import 'package:json_annotation/json_annotation.dart';

import 'pagination_dto.dart';
import 'quote_of_the_day_dto.dart';

part '../generated/dtos/quote_of_the_day_response_dto.g.dart';

@JsonSerializable()
class QuoteOfTheDayResponseDto {
  final List<QuoteOfTheDayDto> quoteOfTheDayWithQuotes;
  final PaginationDto pagination;

  QuoteOfTheDayResponseDto({
    required this.quoteOfTheDayWithQuotes,
    required this.pagination,
  });

  /// Connect the generated [_$QuoteOfTheDayResponseDtoFromJson] function to the `fromJson`
  /// factory.
  factory QuoteOfTheDayResponseDto.fromJson(Map<String, dynamic> json) =>
      _$QuoteOfTheDayResponseDtoFromJson(json);

  /// Connect the generated [_$QuoteOfTheDayResponseDtoToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$QuoteOfTheDayResponseDtoToJson(this);
}
