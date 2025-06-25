import 'package:json_annotation/json_annotation.dart';

part '../generated/dtos/fact_of_the_day_dto.g.dart';

@JsonSerializable()
class FactOfTheDayDto {
  final int factOfTheDayId;
  @JsonKey(fromJson: _fromJson, toJson: _toJson)
  final DateTime factDate;
  @JsonKey(fromJson: _fromJson, toJson: _toJson)
  final DateTime factOfTheDayDateAdded;
  @JsonKey(fromJson: _fromJson, toJson: _toJson)
  final DateTime factOfTheDayDateModified;
  final int factId;
  final String content;
  final String aiFactCategory;
  final String provider;
  @JsonKey(fromJson: _fromJson, toJson: _toJson)
  final DateTime factDateAdded;
  @JsonKey(fromJson: _fromJson, toJson: _toJson)
  final DateTime factDateModified;

  FactOfTheDayDto({
    required this.factOfTheDayId,
    required this.factDate,
    required this.factOfTheDayDateAdded,
    required this.factOfTheDayDateModified,
    required this.factId,
    required this.content,
    required this.aiFactCategory,
    required this.provider,
    required this.factDateAdded,
    required this.factDateModified,
  });

  static DateTime _fromJson(String date) => DateTime.parse(date).toUtc();
  static String _toJson(DateTime date) => date.toUtc().toIso8601String();

  /// Connect the generated [_$FactOfTheDayDtoFromJson] function to the `fromJson`
  /// factory.
  factory FactOfTheDayDto.fromJson(Map<String, dynamic> json) =>
      _$FactOfTheDayDtoFromJson(json);

  /// Connect the generated [_$FactOfTheDayDtoToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$FactOfTheDayDtoToJson(this);
}
