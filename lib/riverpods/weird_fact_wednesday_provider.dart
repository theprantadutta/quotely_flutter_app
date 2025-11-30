import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../dtos/weird_fact_wednesday_dto.dart';
import '../services/weird_fact_wednesday_service.dart';

part '../generated/riverpods/weird_fact_wednesday_provider.g.dart';

@Riverpod(keepAlive: true)
Future<WeirdFactWednesdayDto> fetchWeirdFactWednesday(Ref ref) async {
  return await WeirdFactWednesdayService()
      .getTodayWeirdFactWednesdayFromDatabase();
}
