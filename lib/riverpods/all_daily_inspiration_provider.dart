import 'package:quotely_flutter_app/dtos/daily_inspiration_response_dto.dart';
import 'package:quotely_flutter_app/services/daily_inspiration_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../generated/riverpods/all_daily_inspiration_provider.g.dart';

@Riverpod(keepAlive: true)
Future<DailyInspirationResponseDto> fetchAllDailyInspiration(
  Ref ref,
  int pageNumber,
  int pageSize,
) async {
  return await DailyInspirationService().getAllDailyInspirationFromDatabase(
    pageNumber: pageNumber,
    pageSize: pageSize,
  );
}
