import 'dart:convert';

import '../constants/urls.dart';
import '../dtos/daily_brain_food_dto.dart';
import '../dtos/daily_brain_food_response_dto.dart';
import 'http_service.dart';

class DailyBrainFoodService {
  Future<DailyBrainFoodResponseDto> getAllDailyBrainFoodFromDatabase({
    required int pageNumber,
    required int pageSize,
  }) async {
    final response = await HttpService.get(
        '$kApiUrl/$kGetAllDailyBrainFood?pageNumber=$pageNumber&pageSize=$pageSize');
    if (response.statusCode == 200) {
      return DailyBrainFoodResponseDto.fromJson(json.decode(response.data));
    }
    throw Exception('Failed to get daily inspiration list');
  }

  Future<DailyBrainFoodDto> getTodayDailyBrainFoodFromDatabase() async {
    final response = await HttpService.get('$kApiUrl/$kGetTodayDailyBrainFood');
    if (response.statusCode == 200) {
      return DailyBrainFoodDto.fromJson(json.decode(response.data));
    }
    throw Exception('Failed to get daily inspiration for today');
  }
}
