import 'dart:convert';

import 'package:quotely_flutter_app/dtos/quote_response_dto.dart';

import '../constants/urls.dart';
import 'http_service.dart';

class QuoteService {
  Future<QuoteResponseDto> getAllQuotesFromDatabase({
    required int pageNumber,
    required int pageSize,
  }) async {
    final response = await HttpService.get('$kApiUrl/$kGetAllQuotes');
    // await Future.delayed(const Duration(seconds: 5));
    if (response.statusCode == 200) {
      return QuoteResponseDto.fromJson(json.decode(response.data));
    }
    throw Exception('Failed to get quotes');
  }
}
