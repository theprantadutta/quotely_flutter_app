import 'dart:convert';

import '../../dtos/quote_response_dto.dart';
import '../constants/urls.dart';
import 'http_service.dart';
import 'isar_service.dart';

// class QuoteService {
//   Future<QuoteResponseDto> getAllQuotesFromDatabase({
//     required int pageNumber,
//     required int pageSize,
//     required List<String> tags,
//   }) async {
//     // Initialize query parameters with page number and page size
//     final queryParameters = {
//       'pageNumber': pageNumber.toString(),
//       'pageSize': pageSize.toString(),
//     };

//     // Only add the tags parameter if tags list is not empty
//     if (tags.isNotEmpty) {
//       queryParameters['tags'] = tags.join(',');
//     }

//     final uri = Uri.parse('$kApiUrl/$kGetAllQuotes').replace(
//       queryParameters: queryParameters,
//     );

//     final response = await HttpService.get(uri.toString());

//     if (response.statusCode == 200) {
//       return QuoteResponseDto.fromJson(json.decode(response.data));
//     }
//     throw Exception('Failed to get quotes');
//   }
// }

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
        quoteDto.isFavourite = await IsarService().isFavourite(quoteDto.id);
      }

      return quoteResponseDto;
    }

    throw Exception('Failed to get quotes');
  }
}
