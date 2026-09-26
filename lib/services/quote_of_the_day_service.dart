import 'dart:convert';

import '../constants/urls.dart';
import '../dtos/quote_of_the_day_dto.dart';
import '../dtos/quote_of_the_day_response_dto.dart';
import 'local_first.dart';

class QuoteOfTheDayService {
  Future<QuoteOfTheDayResponseDto> getAllQuoteOfTheDayFromDatabase({
    required int pageNumber,
    required int pageSize,
  }) async {
    final response = await LocalFirst.get(
      '$kApiUrl/$kGetAllQuoteOfTheDay?pageNumber=$pageNumber&pageSize=$pageSize',
    );
    if (response.statusCode == 200) {
      return QuoteOfTheDayResponseDto.fromJson(json.decode(response.data));
    }
    throw Exception('Failed to get quote of the day');
  }

  Future<QuoteOfTheDayDto> getTodayQuoteOfTheDayFromDatabase() async {
    final response = await LocalFirst.get(
      '$kApiUrl/$kGetTodayQuoteOfTheDay',
      todayOnly: true,
    );
    if (response.statusCode == 200) {
      return QuoteOfTheDayDto.fromJson(json.decode(response.data));
    }
    throw Exception('Failed to get quote of the day for today');
  }
}
