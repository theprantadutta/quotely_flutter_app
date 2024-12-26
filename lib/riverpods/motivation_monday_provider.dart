import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quotely_flutter_app/dtos/motivation_monday_dto.dart';
import 'package:quotely_flutter_app/services/motivation_monday_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../generated/riverpods/motivation_monday_provider.g.dart';

@Riverpod(keepAlive: true)
Future<MotivationMondayDto> fetchMotivationMonday(
  Ref ref,
) async {
  return await MotivationMondayService().getTodayMotivationMondayFromDatabase();
}
