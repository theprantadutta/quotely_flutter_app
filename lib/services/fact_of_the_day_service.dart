import 'dart:convert';

import '../constants/urls.dart';
import '../dtos/fact_of_the_day_dto.dart';
import '../dtos/fact_of_the_day_response_dto.dart';
import 'local_first.dart';

class FactOfTheDayService {
  Future<FactOfTheDayResponseDto> getAllFactOfTheDayFromDatabase({
    required int pageNumber,
    required int pageSize,
  }) async {
    final response = await LocalFirst.get(
      '$kApiUrl/$kGetAllFactOfTheDay?pageNumber=$pageNumber&pageSize=$pageSize',
    );
    if (response.statusCode == 200) {
      return FactOfTheDayResponseDto.fromJson(json.decode(response.data));
    }
    throw Exception('Failed to get fact of the day');
  }

  Future<FactOfTheDayDto> getTodayFactOfTheDayFromDatabase() async {
    final response = await LocalFirst.get(
      '$kApiUrl/$kGetTodayFactOfTheDay',
      todayOnly: true,
    );
    if (response.statusCode == 200) {
      return FactOfTheDayDto.fromJson(json.decode(response.data));
    }
    throw Exception('Failed to get fact of the day for today');
  }
}
