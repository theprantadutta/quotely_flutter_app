import 'package:json_annotation/json_annotation.dart';

part '../generated/dtos/daily_brain_food_dto.g.dart';

@JsonSerializable()
class DailyBrainFoodDto {
  final int dailyBrainFoodId;
  @JsonKey(fromJson: _fromJson, toJson: _toJson)
  final DateTime factDate;
  @JsonKey(fromJson: _fromJson, toJson: _toJson)
  final DateTime dailyBrainFoodDateAdded;
  @JsonKey(fromJson: _fromJson, toJson: _toJson)
  final DateTime dailyBrainFoodDateModified;

  final int factId;
  final String content;
  final String aiFactCategory;
  final String provider;

  /// AI-written false version for the True-or-false game; may be null.
  final String? falseVariant;
  @JsonKey(fromJson: _fromJson, toJson: _toJson)
  final DateTime factDateAdded;
  @JsonKey(fromJson: _fromJson, toJson: _toJson)
  final DateTime factDateModified;

  static DateTime _fromJson(String date) => DateTime.parse(date).toUtc();
  static String _toJson(DateTime date) => date.toUtc().toIso8601String();

  DailyBrainFoodDto({
    required this.dailyBrainFoodId,
    required this.factDate,
    required this.dailyBrainFoodDateAdded,
    required this.dailyBrainFoodDateModified,
    required this.factId,
    required this.content,
    required this.aiFactCategory,
    required this.provider,
    this.falseVariant,
    required this.factDateAdded,
    required this.factDateModified,
  });

  /// Connect the generated [_$DailyBrainFoodDtoFromJson] function to the `fromJson`
  /// factory.
  factory DailyBrainFoodDto.fromJson(Map<String, dynamic> json) =>
      _$DailyBrainFoodDtoFromJson(json);

  /// Connect the generated [_$DailyBrainFoodDtoToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$DailyBrainFoodDtoToJson(this);
}
