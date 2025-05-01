import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../constants/urls.dart';

import '../dtos/ai_fact_response_dto.dart';
import 'http_service.dart';

class FactService {
  FactService._();

  static Future<AiFactResponseDto> getAllAiFactsFromDatabase({
    required int pageNumber,
    required int pageSize,
    required List<String> factCategories,
    required List<String> aiProviders,
  }) async {
    // Initialize query parameters with page number and page size
    final queryParameters = {
      'pageNumber': pageNumber.toString(),
      'pageSize': pageSize.toString(),
    };

    // Only add the tags parameter if list is not empty
    if (factCategories.isNotEmpty) {
      queryParameters['factCategories'] = factCategories.join(',');
    }

    if (aiProviders.isNotEmpty) {
      queryParameters['aiProviders'] = aiProviders.join(',');
    }

    final uri = Uri.parse('$kApiUrl/$kGetAllAiFacts').replace(
      queryParameters: queryParameters,
    );

    print('URI: ${uri.toString()}');
    final response = await HttpService.get(uri.toString());

    if (response.statusCode == 200) {
      // Deserialize JSON response to AiFactResponseDto
      return AiFactResponseDto.fromJson(json.decode(response.data));
    }

    throw Exception('Failed to get facts');
  }

  static Future<List<String>> getAllFactsCategoriesFromDatabase({
    required int pageNumber,
    required int pageSize,
  }) async {
    final url =
        '$kApiUrl/$kGetAllAiFactCategories?pageNumber=$pageNumber&pageSize=$pageSize';

    try {
      final response = await HttpService.get(url);

      if (response.statusCode == 200) {
        // First decode the JSON string if needed
        final dynamic data =
            response.data is String ? jsonDecode(response.data) : response.data;

        // Ensure we have a List and convert items to String
        if (data is List) {
          return data.map((item) => item.toString()).toList();
        }
        throw FormatException('Expected List but got ${data.runtimeType}');
      }
      throw Exception('Failed with status ${response.statusCode}');
    } catch (e) {
      if (kDebugMode) print(e);
      throw Exception('Failed to fetch categories: $e');
    }
  }
}
