import 'dart:convert';

import '../constants/urls.dart';
import '../dtos/tag_response_dto.dart';
import 'http_service.dart';

class TagService {
  Future<TagResponseDto> getAllTagsFromDatabase({
    required int pageNumber,
    required int pageSize,
  }) async {
    final response = await HttpService.get('$kApiUrl/$kGetAllTags');
    if (response.statusCode == 200) {
      return TagResponseDto.fromJson(json.decode(response.data));
    }
    throw Exception('Failed to get tags home screen data');
  }
}
