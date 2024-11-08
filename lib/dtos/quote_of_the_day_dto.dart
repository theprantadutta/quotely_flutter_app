import 'package:json_annotation/json_annotation.dart';

part '../generated/dtos/quote_of_the_day_dto.g.dart';

@JsonSerializable()
class QuoteOfTheDayDto {
  final int quoteOfTheDayId;
  @JsonKey(fromJson: _fromJson, toJson: _toJson)
  final DateTime quoteDate;
  final String quoteId;
  final String author;
  final String content;
  final List<String> tags;
  final String authorSlug;
  final int length;
  @JsonKey(fromJson: _fromJson, toJson: _toJson)
  final DateTime quoteDateAdded;
  @JsonKey(fromJson: _fromJson, toJson: _toJson)
  final DateTime quoteDateModified;

  static DateTime _fromJson(String date) => DateTime.parse(date).toUtc();
  static String _toJson(DateTime date) => date.toUtc().toIso8601String();

  QuoteOfTheDayDto({
    required this.quoteOfTheDayId,
    required this.quoteDate,
    required this.quoteId,
    required this.author,
    required this.content,
    required this.tags,
    required this.authorSlug,
    required this.length,
    required this.quoteDateAdded,
    required this.quoteDateModified,
  });

  /// Connect the generated [_$QuoteOfTheDayDtoFromJson] function to the `fromJson`
  /// factory.
  factory QuoteOfTheDayDto.fromJson(Map<String, dynamic> json) =>
      _$QuoteOfTheDayDtoFromJson(json);

  /// Connect the generated [_$QuoteOfTheDayDtoToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$QuoteOfTheDayDtoToJson(this);
}
