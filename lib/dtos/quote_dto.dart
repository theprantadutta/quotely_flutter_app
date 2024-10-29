import 'package:json_annotation/json_annotation.dart';

part '../generated/dtos/quote_dto.g.dart';

@JsonSerializable()
class QuoteDto {
  final String id;
  final String author;
  final String content;
  final List<String> tags;
  final String authorSlug;
  final int length;
  @JsonKey(fromJson: _fromJson, toJson: _toJson)
  final DateTime dateAdded;
  @JsonKey(fromJson: _fromJson, toJson: _toJson)
  final DateTime dateModified;

  QuoteDto({
    required this.id,
    required this.author,
    required this.content,
    required this.tags,
    required this.authorSlug,
    required this.length,
    required this.dateAdded,
    required this.dateModified,
  });

  static DateTime _fromJson(String date) => DateTime.parse(date).toUtc();
  static String _toJson(DateTime date) => date.toUtc().toIso8601String();

  /// Connect the generated [_$QuoteDtoFromJson] function to the `fromJson`
  /// factory.
  factory QuoteDto.fromJson(Map<String, dynamic> json) =>
      _$QuoteDtoFromJson(json);

  /// Connect the generated [_$QuoteDtoToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$QuoteDtoToJson(this);
}
