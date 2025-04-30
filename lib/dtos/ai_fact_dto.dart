import 'package:json_annotation/json_annotation.dart';

part '../generated/dtos/ai_fact_dto.g.dart';

@JsonSerializable()
class AiFactDto {
  final int id;
  final String content;
  final String aiFactCategory;
  final String provider;
  bool isFavorite;
  @JsonKey(fromJson: _fromJson, toJson: _toJson)
  final DateTime dateAdded;
  @JsonKey(fromJson: _fromJson, toJson: _toJson)
  final DateTime dateModified;

  AiFactDto({
    required this.id,
    required this.content,
    required this.aiFactCategory,
    required this.provider,
    this.isFavorite = false,
    required this.dateAdded,
    required this.dateModified,
  });

  static DateTime _fromJson(String date) => DateTime.parse(date).toUtc();
  static String _toJson(DateTime date) => date.toUtc().toIso8601String();

  /// Connect the generated [_$AiFactDtoFromJson] function to the `fromJson`
  /// factory.
  factory AiFactDto.fromJson(Map<String, dynamic> json) =>
      _$AiFactDtoFromJson(json);

  /// Connect the generated [_$AiFactDtoToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$AiFactDtoToJson(this);
}
