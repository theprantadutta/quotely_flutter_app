import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:quotely_flutter_app/dtos/application_info_dto.dart';

import '../constants/urls.dart';
import 'http_service.dart';

class ApplicationService {
  /// Fetches maintenance/version info. Returns null when the backend has no
  /// row yet or the request fails — callers treat null as "nothing to show".
  static Future<ApplicationInfoDto?> getApplicationInfo() async {
    try {
      final url = '$kApiUrl/$kGetApplicationInfo';
      final response = await HttpService.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.data);
        if (data == null) return null;
        return ApplicationInfoDto.fromJson(data);
      }

      throw Exception(
        'Failed to get application info with status code: ${response.statusCode}',
      );
    } catch (e) {
      if (kDebugMode) {
        print('API call for application info failed. Error: $e');
      }
      return null;
    }
  }
}
