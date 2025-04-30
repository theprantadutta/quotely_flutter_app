import 'dart:convert';

import 'package:quotely_flutter_app/constants/urls.dart';

import '../dtos/ai_fact_response_dto.dart';
import 'http_service.dart';

class QuoteService {
  Future<AiFactResponseDto> getAllAiFactsFromDatabase({
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

    final response = await HttpService.get(uri.toString());

    if (response.statusCode == 200) {
      // Deserialize JSON response to AiFactResponseDto
      final aiFactResponseDto =
          AiFactResponseDto.fromJson(json.decode(response.data));

      // Iterate through quotes and check if each is a favorite
      // for (var quoteDto in aiFactResponseDto.aiFacts) {
      //   quoteDto.isFavorite = await IsarService().isFavorite(quoteDto.id);
      // }

      return aiFactResponseDto;
    }

    throw Exception('Failed to get facts');
  }
}
