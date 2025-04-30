import 'dart:convert';

import 'package:quotely_flutter_app/services/drift_service.dart';

import '../../dtos/quote_response_dto.dart';
import '../constants/urls.dart';
import 'http_service.dart';

class QuoteService {
  Future<QuoteResponseDto> getAllQuotesFromDatabase({
    required int pageNumber,
    required int pageSize,
    required List<String> tags,
  }) async {
    // Initialize query parameters with page number and page size
    final queryParameters = {
      'pageNumber': pageNumber.toString(),
      'pageSize': pageSize.toString(),
    };

    // Only add the tags parameter if tags list is not empty
    if (tags.isNotEmpty) {
      queryParameters['tags'] = tags.join(',');
    }

    final uri = Uri.parse('$kApiUrl/$kGetAllQuotes').replace(
      queryParameters: queryParameters,
    );

    final response = await HttpService.get(uri.toString());

    if (response.statusCode == 200) {
      // Deserialize JSON response to QuoteResponseDto
      final quoteResponseDto =
          QuoteResponseDto.fromJson(json.decode(response.data));

      // Iterate through quotes and check if each is a favorite
      for (var quoteDto in quoteResponseDto.quotes) {
        quoteDto.isFavorite = await DriftService.isFavorite(quoteDto.id);
      }

      return quoteResponseDto;
    }

    throw Exception('Failed to get quotes');
  }

  Future<QuoteResponseDto> getAllQuotesByAuthorFromDatabase({
    required String authorSlug,
    required int pageNumber,
    required int pageSize,
  }) async {
    // Initialize query parameters with page number and page size
    final queryParameters = {
      'authorSlug': authorSlug,
      'pageNumber': pageNumber.toString(),
      'pageSize': pageSize.toString(),
    };

    final uri = Uri.parse('$kApiUrl/$kGetAllQuotesByAuthor').replace(
      queryParameters: queryParameters,
    );

    final response = await HttpService.get(uri.toString());

    if (response.statusCode == 200) {
      // Deserialize JSON response to QuoteResponseDto
      final quoteResponseDto =
          QuoteResponseDto.fromJson(json.decode(response.data));

      // Iterate through quotes and check if each is a favorite
      for (var quoteDto in quoteResponseDto.quotes) {
        quoteDto.isFavorite = await DriftService.isFavorite(quoteDto.id);
      }

      return quoteResponseDto;
    }

    throw Exception('Failed to get quotes by id');
  }
}
