import 'package:json_annotation/json_annotation.dart';

part '../generated/dtos/motivation_monday_dto.g.dart';

@JsonSerializable()
class MotivationMondayDto {
  final int motivationMondayId;
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

  MotivationMondayDto({
    required this.motivationMondayId,
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

  /// Connect the generated [_$MotivationMondayDtoFromJson] function to the `fromJson`
  /// factory.
  factory MotivationMondayDto.fromJson(Map<String, dynamic> json) =>
      _$MotivationMondayDtoFromJson(json);

  /// Connect the generated [_$MotivationMondayDtoToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$MotivationMondayDtoToJson(this);
}
