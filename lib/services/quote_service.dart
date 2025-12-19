import 'dart:convert';

import 'package:quotely_flutter_app/dtos/pagination_dto.dart';
import 'package:quotely_flutter_app/dtos/quote_dto.dart';
import 'package:quotely_flutter_app/services/drift_quote_service.dart';
import 'package:quotely_flutter_app/util/pagination_seed.dart';

import '../../dtos/quote_response_dto.dart';
import '../constants/urls.dart';
import 'http_service.dart';

class QuoteService {
  static Future<QuoteResponseDto> getAllQuotesFromDatabase({
    required int pageNumber,
    required int pageSize,
    required List<String> tags,
    int? seed,
  }) async {
    try {
      // Use provided seed or get the current session seed
      final effectiveSeed = seed ?? PaginationSeed.current;

      // Try to get from API first
      final queryParameters = {
        'pageNumber': pageNumber.toString(),
        'pageSize': pageSize.toString(),
        'seed': effectiveSeed.toString(),
        if (tags.isNotEmpty) 'tags': tags.join(','),
      };

      final uri = Uri.parse(
        '$kApiUrl/$kGetAllQuotes',
      ).replace(queryParameters: queryParameters);

      final response = await HttpService.get(uri.toString());

      if (response.statusCode == 200) {
        final quoteResponseDto = QuoteResponseDto.fromJson(
          json.decode(response.data),
        );
        await DriftQuoteService.saveNewQuotesToDatabase(
          quoteResponseDto.quotes,
        );
        return quoteResponseDto;
      }
      throw Exception('API request failed');
    } catch (e) {
      // Fallback to local database
      final localQuotes = await DriftQuoteService.getLocalQuotesWithPagination(
        pageNumber: pageNumber,
        pageSize: pageSize,
        tags: tags,
      );

      final quoteDtos = QuoteDto.fromQuoteList(localQuotes);
      return QuoteResponseDto(
        quotes: quoteDtos,
        pagination: PaginationDto(
          pageNumber: 0,
          pageSize: 0,
          totalItemCount: 0,
        ),
      );
    }
  }

  Future<QuoteResponseDto> getAllQuotesByAuthorFromDatabase({
    required String authorSlug,
    required int pageNumber,
    required int pageSize,
    int? seed,
  }) async {
    // Use provided seed or get the current session seed
    final effectiveSeed = seed ?? PaginationSeed.current;

    // Initialize query parameters with page number and page size
    final queryParameters = {
      'authorSlug': authorSlug,
      'pageNumber': pageNumber.toString(),
      'pageSize': pageSize.toString(),
      'seed': effectiveSeed.toString(),
    };

    final uri = Uri.parse(
      '$kApiUrl/$kGetAllQuotesByAuthor',
    ).replace(queryParameters: queryParameters);

    final response = await HttpService.get(uri.toString());

    if (response.statusCode == 200) {
      // Deserialize JSON response to QuoteResponseDto
      final quoteResponseDto = QuoteResponseDto.fromJson(
        json.decode(response.data),
      );

      // Iterate through quotes and check if each is a favorite
      for (var quoteDto in quoteResponseDto.quotes) {
        quoteDto.isFavorite = await DriftQuoteService.isFavoriteQuote(
          quoteDto.id,
        );
      }

      return quoteResponseDto;
    }

    throw Exception('Failed to get quotes by id');
  }
}
