import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../dtos/fact_of_the_day_dto.dart';
import '../services/fact_of_the_day_service.dart';

part '../generated/riverpods/today_fact_of_the_day_provider.g.dart';

@Riverpod(keepAlive: true)
Future<FactOfTheDayDto> fetchTodayFactOfTheDay(
  Ref ref,
) async {
  return await FactOfTheDayService().getTodayFactOfTheDayFromDatabase();
}
