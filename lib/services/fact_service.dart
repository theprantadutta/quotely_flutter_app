import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:quotely_flutter_app/dtos/pagination_dto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/urls.dart';
import '../dtos/ai_fact_dto.dart';
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

  // static Future<AiFactResponseDto> getAllAiFactsFromDatabase({
  //   required int pageNumber,
  //   required int pageSize,
  //   required List<String> factCategories,
  //   required List<String> aiProviders,
  // }) async {
  //   try {
  //     // Try to get from API first
  //     final queryParameters = {
  //       'pageNumber': pageNumber.toString(),
  //       'pageSize': pageSize.toString(),
  //       if (factCategories.isNotEmpty)
  //         'factCategories': factCategories.join(','),
  //       if (aiProviders.isNotEmpty) 'aiProviders': aiProviders.join(','),
  //     };

  //     final uri = Uri.parse('$kApiUrl/$kGetAllAiFacts').replace(
  //       queryParameters: queryParameters,
  //     );

  //     final response = await HttpService.get(uri.toString());

  //     if (response.statusCode == 200) {
  //       final aiFactResponseDto =
  //           AiFactResponseDto.fromJson(json.decode(response.data));

  //       // Save new facts to local database
  //       await DriftFactService.saveNewFactsToDatabase(
  //           aiFactResponseDto.aiFacts);

  //       // Update favorite status
  //       // for (final fact in aiFactResponseDto.aiFacts) {
  //       //   fact.isFavorite = await DriftFactService.isFavoriteFact(fact.id);
  //       // }

  //       return aiFactResponseDto;
  //     }
  //     throw Exception('API request failed');
  //   } catch (e) {
  //     // Fallback to local database
  //     final localFacts = await DriftFactService.getLocalFactsWithPagination(
  //       pageNumber: pageNumber,
  //       pageSize: pageSize,
  //       factCategories: factCategories,
  //       aiProviders: aiProviders,
  //     );

  //     // Set favorite status for local facts
  //     for (final fact in localFacts) {
  //       fact.isFavorite = await DriftFactService.isFavoriteFact(fact.id);
  //     }

  //     return AiFactResponseDto(
  //       aiFacts: localFacts,
  //       // totalCount: await DriftFactService.getTotalFactCount(
  //       //   factCategories: factCategories,
  //       //   aiProviders: aiProviders,
  //       // ),
  //       // currentPage: pageNumber,
  //       // totalPages: await DriftFactService.getTotalFactPages(
  //       //   pageSize: pageSize,
  //       //   factCategories: factCategories,
  //       //   aiProviders: aiProviders,
  //       // ),
  //       pagination:
  //           PaginationDto(pageNumber: 0, pageSize: 0, totalItemCount: 0),
  //     );
  //   }
  // }

  static Future<AiFactResponseDto> getAllAiFactsFromDatabase({
    required int pageNumber,
    required int pageSize,
    required List<String> factCategories,
    required List<String> aiProviders,
  }) async {
    try {
      // Try to get from the API first
      final queryParameters = {
        'pageNumber': pageNumber.toString(),
        'pageSize': pageSize.toString(),
        if (factCategories.isNotEmpty)
          'factCategories': factCategories.join(','),
        if (aiProviders.isNotEmpty) 'aiProviders': aiProviders.join(','),
      };

      final uri = Uri.parse(
        '$kApiUrl/$kGetAllAiFacts',
      ).replace(queryParameters: queryParameters);

      final response = await HttpService.get(uri.toString());

      if (response.statusCode == 200) {
        final aiFactResponseDto = AiFactResponseDto.fromJson(
          json.decode(response.data),
        );

        // Save new facts to the local database before returning
        if (aiFactResponseDto.aiFacts.isNotEmpty) {
          await DriftFactService.saveNewFactsToDatabase(
            aiFactResponseDto.aiFacts,
          );
        }

        // --- EFFICIENT FAVORITE CHECK (for Online Data) ---
        // Get all favorite IDs in one go for efficiency.
        final favoriteIds = await DriftFactService.getAllFavoriteFactIds();
        // Set the favorite status for each fact from the API response in memory.
        for (final fact in aiFactResponseDto.aiFacts) {
          fact.isFavorite = favoriteIds.contains(fact.id);
        }

        return aiFactResponseDto;
      }
      throw Exception(
        'API request failed with status code: ${response.statusCode}',
      );
    } catch (e) {
      // Fallback to local database if the API call fails
      final localFacts = await DriftFactService.getLocalFactsWithPagination(
        pageNumber: pageNumber,
        pageSize: pageSize,
        // Pass the categories to the local query
        categories: factCategories,
      );

      // --- EFFICIENT FAVORITE CHECK (for Offline Data) ---
      final favoriteIds = await DriftFactService.getAllFavoriteFactIds();

      // --- Convert Drift entities to DTOs and set favorite status ---
      final factDtos = localFacts.map((fact) {
        final isFavorite = favoriteIds.contains(fact.id);
        // Create DTO from Drift model
        final dto = AiFactDto.fromDrift(fact);
        // Update its favorite status
        dto.isFavorite = isFavorite;
        return dto;
      }).toList();

      // Return the locally fetched data wrapped in the response DTO
      return AiFactResponseDto(
        aiFacts: factDtos,
        pagination: PaginationDto(
          pageNumber: 0,
          pageSize: 0,
          totalItemCount: 0,
        ),
      );
    }
  }

  // static Future<List<String>> getAllFactsCategoriesFromDatabase({
  //   required int pageNumber,
  //   required int pageSize,
  // }) async {
  //   final url =
  //       '$kApiUrl/$kGetAllAiFactCategories?pageNumber=$pageNumber&pageSize=$pageSize';

  //   try {
  //     final response = await HttpService.get(url);

  //     if (response.statusCode == 200) {
  //       // First decode the JSON string if needed
  //       final dynamic data =
  //           response.data is String ? jsonDecode(response.data) : response.data;

  //       // Ensure we have a List and convert items to String
  //       if (data is List) {
  //         return data.map((item) => item.toString()).toList();
  //       }
  //       throw FormatException('Expected List but got ${data.runtimeType}');
  //     }
  //     throw Exception('Failed with status ${response.statusCode}');
  //   } catch (e) {
  //     if (kDebugMode) print(e);
  //     throw Exception('Failed to fetch categories: $e');
  //   }
  // }

  // Renamed for clarity, as it no longer exclusively uses the database
  static Future<List<String>> getAllFactsCategories() async {
    // Define a key for storing the categories in SharedPreferences
    const String kCategoriesCacheKey = 'fact_categories_cache';

    try {
      // --- ONLINE PATH: Try to get fresh data from the API first ---

      // We fetch all categories at once, so pagination is removed.
      final url = '$kApiUrl/$kGetAllAiFactCategories';
      final response = await HttpService.get(url);

      if (response.statusCode == 200) {
        final dynamic data = response.data is String
            ? jsonDecode(response.data)
            : response.data;

        if (data is List) {
          final categories = data.map((item) => item.toString()).toList();

          // --- CACHING: Save the fresh list to SharedPreferences ---
          final prefs = await SharedPreferences.getInstance();
          await prefs.setStringList(kCategoriesCacheKey, categories);

          debugPrint(
            "Successfully fetched and cached ${categories.length} fact categories.",
          );
          return categories;
        }
        // If the data is not a list, it's an unexpected format.
        throw const FormatException(
          'API response for categories was not a list.',
        );
      }
      // If the status code is not 200, throw to trigger the catch block.
      throw Exception('API request failed with status ${response.statusCode}');
    } catch (e) {
      if (kDebugMode) {
        print(
          'API call for categories failed, falling back to SharedPreferences. Error: $e',
        );
      }

      // --- OFFLINE FALLBACK ---

      // --- RETRIEVAL: Load the cached list from SharedPreferences ---
      final prefs = await SharedPreferences.getInstance();
      final cachedCategories = prefs.getStringList(kCategoriesCacheKey);

      if (cachedCategories != null) {
        debugPrint("Loaded ${cachedCategories.length} categories from cache.");
        return cachedCategories;
      } else {
        // If there's no cache and the API failed, return an empty list.
        debugPrint("No categories in cache, returning empty list.");
        return [];
      }
    }
  }
}
