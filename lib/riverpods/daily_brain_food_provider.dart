import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../dtos/daily_brain_food_dto.dart';
import '../services/daily_brain_food_service.dart';

part '../generated/riverpods/daily_brain_food_provider.g.dart';

@Riverpod(keepAlive: true)
Future<DailyBrainFoodDto> fetchTodayDailyBrainFood(Ref ref) async {
  return await DailyBrainFoodService().getTodayDailyBrainFoodFromDatabase();
}
