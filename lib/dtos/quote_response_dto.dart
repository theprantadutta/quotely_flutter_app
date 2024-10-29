import 'package:json_annotation/json_annotation.dart';
import 'package:quotely_flutter_app/dtos/pagination_dto.dart';

import 'quote_dto.dart';

part '../generated/dtos/quote_response_dto.g.dart';

@JsonSerializable()
class QuoteResponseDto {
  final List<QuoteDto> quotes;
  final PaginationDto pagination;

  QuoteResponseDto({
    required this.quotes,
    required this.pagination,
  });

  /// Connect the generated [_$QuoteResponseDtoFromJson] function to the `fromJson`
  /// factory.
  factory QuoteResponseDto.fromJson(Map<String, dynamic> json) =>
      _$QuoteResponseDtoFromJson(json);

  /// Connect the generated [_$QuoteResponseDtoToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$QuoteResponseDtoToJson(this);
}
