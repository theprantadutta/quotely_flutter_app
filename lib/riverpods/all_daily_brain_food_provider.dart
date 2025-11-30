import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../dtos/daily_brain_food_response_dto.dart';
import '../services/daily_brain_food_service.dart';

part '../generated/riverpods/all_daily_brain_food_provider.g.dart';

@Riverpod(keepAlive: true)
Future<DailyBrainFoodResponseDto> fetchAllDailyBrainFood(
  Ref ref,
  int pageNumber,
  int pageSize,
) async {
  return await DailyBrainFoodService().getAllDailyBrainFoodFromDatabase(
    pageNumber: pageNumber,
    pageSize: pageSize,
  );
}
