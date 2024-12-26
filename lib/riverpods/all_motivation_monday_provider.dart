import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quotely_flutter_app/dtos/motivation_monday_response_dto.dart';
import 'package:quotely_flutter_app/services/motivation_monday_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../generated/riverpods/all_motivation_monday_provider.g.dart';

@Riverpod(keepAlive: true)
Future<MotivationMondayResponseDto> fetchAllMotivationMonday(
  Ref ref,
  int pageNumber,
  int pageSize,
) async {
  return await MotivationMondayService().getAllMotivationMondayFromDatabase(
    pageNumber: pageNumber,
    pageSize: pageSize,
  );
}
