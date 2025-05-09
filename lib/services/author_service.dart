import 'dart:convert';

import '../constants/urls.dart';
import '../dtos/author_dto.dart';
import '../dtos/author_response_dto.dart';
import 'http_service.dart';

class AuthorService {
  Future<AuthorResponseDto> getAllAuthorsFromDatabase({
    required String search,
    required int pageNumber,
    required int pageSize,
  }) async {
    final response = await HttpService.get(
        '$kApiUrl/$kGetAllAuthors?search=$search&pageNumber=$pageNumber&pageSize=$pageSize');
    if (response.statusCode == 200) {
      return AuthorResponseDto.fromJson(json.decode(response.data));
    }
    throw Exception('Failed to get authors');
  }

  Future<AuthorDto?> getAuthorDetails({
    required String authorSlug,
  }) async {
    final response = await HttpService.get(
        '$kApiUrl/$kGetAuthorDetails?authorSlug=$authorSlug');
    if (response.statusCode == 200) {
      final data = json.decode(response.data);
      return data != null ? AuthorDto.fromJson(data) : null;
    }
    throw Exception('Failed to get authors');
  }
}
