import 'package:json_annotation/json_annotation.dart';

part '../generated/dtos/daily_inspiration_dto.g.dart';

@JsonSerializable()
class DailyInspirationDto {
  final int dailyInspirationId;
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

  DailyInspirationDto({
    required this.dailyInspirationId,
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

  /// Connect the generated [_$DailyInspirationDtoFromJson] function to the `fromJson`
  /// factory.
  factory DailyInspirationDto.fromJson(Map<String, dynamic> json) =>
      _$DailyInspirationDtoFromJson(json);

  /// Connect the generated [_$DailyInspirationDtoToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$DailyInspirationDtoToJson(this);
}
