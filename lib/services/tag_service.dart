import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:quotely_flutter_app/dtos/tag_dto.dart';
import 'package:quotely_flutter_app/services/drift_tag_service.dart';
import 'package:quotely_flutter_app/services/http_service.dart';
import 'package:quotely_flutter_app/util/pagination_seed.dart';

import '../constants/urls.dart';
import '../dtos/pagination_dto.dart';
import '../dtos/tag_response_dto.dart';

class TagService {
  /// Fetches a paginated list of all tags.
  /// Tries the API first, falls back to the local database if the API fails.
  static Future<TagResponseDto> getAllTags({
    required int pageNumber,
    required int pageSize,
    int? seed,
  }) async {
    try {
      // Use provided seed or get the current session seed
      final effectiveSeed = seed ?? PaginationSeed.current;

      // --- ONLINE PATH ---
      final queryParameters = {
        'pageNumber': pageNumber.toString(),
        'pageSize': pageSize.toString(),
        'seed': effectiveSeed.toString(),
      };

      final uri = Uri.parse(
        '$kApiUrl/$kGetAllTags',
      ).replace(queryParameters: queryParameters);

      final response = await HttpService.get(uri.toString());

      if (response.statusCode == 200) {
        final tagResponseDto = TagResponseDto.fromJson(
          json.decode(response.data),
        );

        // Save the fresh tags to the local database for offline use
        if (tagResponseDto.tags.isNotEmpty) {
          await DriftTagService.saveTagsToDatabase(tagResponseDto.tags);
        }

        return tagResponseDto;
      }
      throw Exception(
        'API request for tags failed with status code: ${response.statusCode}',
      );
    } catch (e) {
      if (kDebugMode) {
        print(
          'API call failed, falling back to local database for tags. Error: $e',
        );
      }

      // --- OFFLINE FALLBACK ---
      final localTags = await DriftTagService.getLocalTagsWithPagination(
        pageNumber: pageNumber,
        pageSize: pageSize,
      );

      // Convert the list of Drift entities to a list of DTOs
      final tagDtos = TagDto.fromTagList(localTags);

      // Return the local data wrapped in a response object
      return TagResponseDto(
        tags: tagDtos,
        // Provide empty pagination data for the offline fallback
        pagination: PaginationDto(
          pageNumber: 0,
          pageSize: 0,
          totalItemCount: 0,
        ),
      );
    }
  }
}
