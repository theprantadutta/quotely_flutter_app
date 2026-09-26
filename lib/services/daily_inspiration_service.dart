import 'dart:convert';

import '../constants/urls.dart';
import '../dtos/daily_inspiration_dto.dart';
import '../dtos/daily_inspiration_response_dto.dart';
import 'local_first.dart';

class DailyInspirationService {
  Future<DailyInspirationResponseDto> getAllDailyInspirationFromDatabase({
    required int pageNumber,
    required int pageSize,
  }) async {
    final response = await LocalFirst.get(
      '$kApiUrl/$kGetAllDailyInspiration?pageNumber=$pageNumber&pageSize=$pageSize',
    );
    if (response.statusCode == 200) {
      return DailyInspirationResponseDto.fromJson(json.decode(response.data));
    }
    throw Exception('Failed to get daily inspiration list');
  }

  Future<DailyInspirationDto> getTodayDailyInspirationFromDatabase() async {
    final response = await LocalFirst.get(
      '$kApiUrl/$kGetTodayDailyInspiration',
      todayOnly: true,
    );
    if (response.statusCode == 200) {
      return DailyInspirationDto.fromJson(json.decode(response.data));
    }
    throw Exception('Failed to get daily inspiration for today');
  }
}
