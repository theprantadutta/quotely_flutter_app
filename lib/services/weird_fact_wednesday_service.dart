import 'dart:convert';

import '../constants/urls.dart';
import '../dtos/weird_fact_wednesday_dto.dart';
import '../dtos/weird_fact_wednesday_response_dto.dart';
import 'local_first.dart';

class WeirdFactWednesdayService {
  Future<WeirdFactWednesdayResponseDto> getAllWeirdFactWednesdayFromDatabase({
    required int pageNumber,
    required int pageSize,
  }) async {
    final response = await LocalFirst.get(
      '$kApiUrl/$kGetAllWeirdFactWednesday?pageNumber=$pageNumber&pageSize=$pageSize',
    );
    if (response.statusCode == 200) {
      return WeirdFactWednesdayResponseDto.fromJson(json.decode(response.data));
    }
    throw Exception('Failed to get motivation monday list');
  }

  Future<WeirdFactWednesdayDto> getTodayWeirdFactWednesdayFromDatabase() async {
    final response = await LocalFirst.get(
      '$kApiUrl/$kGetTodayWeirdFactWednesday',
      todayOnly: true,
    );
    if (response.statusCode == 200) {
      return WeirdFactWednesdayDto.fromJson(json.decode(response.data));
    }
    throw Exception('Failed to get motivation monday for today');
  }
}
