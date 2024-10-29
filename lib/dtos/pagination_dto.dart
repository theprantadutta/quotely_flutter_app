import 'package:json_annotation/json_annotation.dart';

part '../generated/dtos/pagination_dto.g.dart';

@JsonSerializable()
class PaginationDto {
  final int pageNumber;
  final int pageSize;
  final int totalItemCount;

  PaginationDto({
    required this.pageNumber,
    required this.pageSize,
    required this.totalItemCount,
  });

  /// Connect the generated [_$PaginationDtoFromJson] function to the `fromJson`
  /// factory.
  factory PaginationDto.fromJson(Map<String, dynamic> json) =>
      _$PaginationDtoFromJson(json);

  /// Connect the generated [_$PaginationDtoToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$PaginationDtoToJson(this);
}
