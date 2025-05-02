import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:quotely_flutter_app/dtos/pagination_dto.dart';

import '../constants/urls.dart';

import '../dtos/ai_fact_response_dto.dart';
import 'drift_fact_service.dart';
import 'http_service.dart';

class FactService {
  FactService._();

  // static Future<AiFactResponseDto> getAllAiFactsFromDatabase({
  //   required int pageNumber,
  //   required int pageSize,
  //   required List<String> factCategories,
  //   required List<String> aiProviders,
  // }) async {
  //   // Initialize query parameters with page number and page size
  //   final queryParameters = {
  //     'pageNumber': pageNumber.toString(),
  //     'pageSize': pageSize.toString(),
  //   };

  //   // Only add the tags parameter if list is not empty
  //   if (factCategories.isNotEmpty) {
  //     queryParameters['factCategories'] = factCategories.join(',');
  //   }

  //   if (aiProviders.isNotEmpty) {
  //     queryParameters['aiProviders'] = aiProviders.join(',');
  //   }

  //   final uri = Uri.parse('$kApiUrl/$kGetAllAiFacts').replace(
  //     queryParameters: queryParameters,
  //   );

  //   final response = await HttpService.get(uri.toString());

  //   if (response.statusCode == 200) {
  //     final aiFactResponseDto =
  //         AiFactResponseDto.fromJson(json.decode(response.data));

  //     // Iterate through quotes and check if each is a favorite
  //     for (var factDto in aiFactResponseDto.aiFacts) {
  //       factDto.isFavorite = await DriftFactService.isFavoriteFact(factDto.id);
  //     }

  //     // Deserialize JSON response to AiFactResponseDto
  //     return aiFactResponseDto;
  //   }

  //   throw Exception('Failed to get facts');
  // }

  static Future<AiFactResponseDto> getAllAiFactsFromDatabase({
    required int pageNumber,
    required int pageSize,
    required List<String> factCategories,
    required List<String> aiProviders,
  }) async {
    try {
      // Try to get from API first
      final queryParameters = {
        'pageNumber': pageNumber.toString(),
        'pageSize': pageSize.toString(),
        if (factCategories.isNotEmpty)
          'factCategories': factCategories.join(','),
        if (aiProviders.isNotEmpty) 'aiProviders': aiProviders.join(','),
      };

      final uri = Uri.parse('$kApiUrl/$kGetAllAiFacts').replace(
        queryParameters: queryParameters,
      );

      final response = await HttpService.get(uri.toString());

      if (response.statusCode == 200) {
        final aiFactResponseDto =
            AiFactResponseDto.fromJson(json.decode(response.data));

        // Save new facts to local database
        await DriftFactService.saveNewFactsToDatabase(
            aiFactResponseDto.aiFacts);

        // Update favorite status
        for (final fact in aiFactResponseDto.aiFacts) {
          fact.isFavorite = await DriftFactService.isFavoriteFact(fact.id);
        }

        return aiFactResponseDto;
      }
      throw Exception('API request failed');
    } catch (e) {
      // Fallback to local database
      final localFacts = await DriftFactService.getLocalFactsWithPagination(
        pageNumber: pageNumber,
        pageSize: pageSize,
        factCategories: factCategories,
        aiProviders: aiProviders,
      );

      // Set favorite status for local facts
      for (final fact in localFacts) {
        fact.isFavorite = await DriftFactService.isFavoriteFact(fact.id);
      }

      return AiFactResponseDto(
        aiFacts: localFacts,
        // totalCount: await DriftFactService.getTotalFactCount(
        //   factCategories: factCategories,
        //   aiProviders: aiProviders,
        // ),
        // currentPage: pageNumber,
        // totalPages: await DriftFactService.getTotalFactPages(
        //   pageSize: pageSize,
        //   factCategories: factCategories,
        //   aiProviders: aiProviders,
        // ),
        pagination:
            PaginationDto(pageNumber: 0, pageSize: 0, totalItemCount: 0),
      );
    }
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
