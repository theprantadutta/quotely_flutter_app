import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../dtos/weird_fact_wednesday_response_dto.dart';
import '../services/weird_fact_wednesday_service.dart';

part '../generated/riverpods/all_weird_fact_wednesday_provider.g.dart';

@Riverpod(keepAlive: true)
Future<WeirdFactWednesdayResponseDto> fetchAllWeirdFactWednesday(
  Ref ref,
  int pageNumber,
  int pageSize,
) async {
  return await WeirdFactWednesdayService().getAllWeirdFactWednesdayFromDatabase(
    pageNumber: pageNumber,
    pageSize: pageSize,
  );
}
