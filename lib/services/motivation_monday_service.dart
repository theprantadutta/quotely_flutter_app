import 'dart:convert';

import '../constants/urls.dart';
import '../dtos/motivation_monday_dto.dart';
import '../dtos/motivation_monday_response_dto.dart';
import 'local_first.dart';

class MotivationMondayService {
  Future<MotivationMondayResponseDto> getAllMotivationMondayFromDatabase({
    required int pageNumber,
    required int pageSize,
  }) async {
    final response = await LocalFirst.get(
      '$kApiUrl/$kGetAllMotivationMonday?pageNumber=$pageNumber&pageSize=$pageSize',
    );
    if (response.statusCode == 200) {
      return MotivationMondayResponseDto.fromJson(json.decode(response.data));
    }
    throw Exception('Failed to get motivation monday list');
  }

  Future<MotivationMondayDto> getTodayMotivationMondayFromDatabase() async {
    final response = await LocalFirst.get(
      '$kApiUrl/$kGetTodayMotivationMonday',
      todayOnly: true,
    );
    if (response.statusCode == 200) {
      return MotivationMondayDto.fromJson(json.decode(response.data));
    }
    throw Exception('Failed to get motivation monday for today');
  }
}
