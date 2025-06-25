import 'package:json_annotation/json_annotation.dart';

part '../generated/dtos/weird_fact_wednesday_dto.g.dart';

@JsonSerializable()
class WeirdFactWednesdayDto {
  final int weirdFactWednesdayId;
  @JsonKey(fromJson: _fromJson, toJson: _toJson)
  final DateTime factDate;
  @JsonKey(fromJson: _fromJson, toJson: _toJson)
  final DateTime weirdFactWednesdayDateAdded;
  @JsonKey(fromJson: _fromJson, toJson: _toJson)
  final DateTime weirdFactWednesdayDateModified;

  final int factId;
  final String content;
  final String aiFactCategory;
  final String provider;
  @JsonKey(fromJson: _fromJson, toJson: _toJson)
  final DateTime factDateAdded;
  @JsonKey(fromJson: _fromJson, toJson: _toJson)
  final DateTime factDateModified;

  static DateTime _fromJson(String date) => DateTime.parse(date).toUtc();
  static String _toJson(DateTime date) => date.toUtc().toIso8601String();

  WeirdFactWednesdayDto({
    required this.weirdFactWednesdayId,
    required this.factDate,
    required this.weirdFactWednesdayDateAdded,
    required this.weirdFactWednesdayDateModified,
    required this.factId,
    required this.content,
    required this.aiFactCategory,
    required this.provider,
    required this.factDateAdded,
    required this.factDateModified,
  });

  /// Connect the generated [_$WeirdFactWednesdayDtoFromJson] function to the `fromJson`
  /// factory.
  factory WeirdFactWednesdayDto.fromJson(Map<String, dynamic> json) =>
      _$WeirdFactWednesdayDtoFromJson(json);

  /// Connect the generated [_$WeirdFactWednesdayDtoToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$WeirdFactWednesdayDtoToJson(this);
}
