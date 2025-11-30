import 'dart:convert';

import '../constants/urls.dart';
import '../dtos/daily_inspiration_dto.dart';
import '../dtos/daily_inspiration_response_dto.dart';
import 'http_service.dart';

class DailyInspirationService {
  Future<DailyInspirationResponseDto> getAllDailyInspirationFromDatabase({
    required int pageNumber,
    required int pageSize,
  }) async {
    final response = await HttpService.get(
      '$kApiUrl/$kGetAllDailyInspiration?pageNumber=$pageNumber&pageSize=$pageSize',
    );
    if (response.statusCode == 200) {
      return DailyInspirationResponseDto.fromJson(json.decode(response.data));
    }
    throw Exception('Failed to get daily inspiration list');
  }

  Future<DailyInspirationDto> getTodayDailyInspirationFromDatabase() async {
    final response = await HttpService.get(
      '$kApiUrl/$kGetTodayDailyInspiration',
    );
    if (response.statusCode == 200) {
      return DailyInspirationDto.fromJson(json.decode(response.data));
    }
    throw Exception('Failed to get daily inspiration for today');
  }
}
