import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../dtos/fact_of_the_day_response_dto.dart';
import '../services/fact_of_the_day_service.dart';

part '../generated/riverpods/all_fact_of_the_day_provider.g.dart';

@Riverpod(keepAlive: true)
Future<FactOfTheDayResponseDto> fetchAllFactOfTheDay(
  Ref ref,
  int pageNumber,
  int pageSize,
) async {
  return await FactOfTheDayService().getAllFactOfTheDayFromDatabase(
    pageNumber: pageNumber,
    pageSize: pageSize,
  );
}
