import 'package:json_annotation/json_annotation.dart';
import 'package:quotely_flutter_app/dtos/pagination_dto.dart';

import 'author_dto.dart';

part '../generated/dtos/author_response_dto.g.dart';

@JsonSerializable()
class AuthorResponseDto {
  final List<AuthorDto> authors;
  final PaginationDto pagination;

  AuthorResponseDto({required this.authors, required this.pagination});

  /// Connect the generated [_$AuthorResponseDtoFromJson] function to the `fromJson`
  /// factory.
  factory AuthorResponseDto.fromJson(Map<String, dynamic> json) =>
      _$AuthorResponseDtoFromJson(json);

  /// Connect the generated [_$AuthorResponseDtoToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$AuthorResponseDtoToJson(this);
}
