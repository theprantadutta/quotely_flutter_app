import 'dart:convert';

import 'package:quotely_flutter_app/dtos/author_response_dto.dart';

import '../constants/urls.dart';
import 'http_service.dart';

class AuthorService {
  Future<AuthorResponseDto> getAllAuthorsFromDatabase({
    required int pageNumber,
    required int pageSize,
  }) async {
    final response = await HttpService.get('$kApiUrl/$kGetAllAuthors');
    if (response.statusCode == 200) {
      return AuthorResponseDto.fromJson(json.decode(response.data));
    }
    throw Exception('Failed to get authors');
  }
}
