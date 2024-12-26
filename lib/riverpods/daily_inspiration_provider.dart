import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quotely_flutter_app/dtos/daily_inspiration_dto.dart';
import 'package:quotely_flutter_app/services/daily_inspiration_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../generated/riverpods/daily_inspiration_provider.g.dart';

@Riverpod(keepAlive: true)
Future<DailyInspirationDto> fetchTodayDailyInspiration(
  Ref ref,
) async {
  return await DailyInspirationService().getTodayDailyInspirationFromDatabase();
}
