import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quotely_flutter_app/dtos/ai_fact_response_dto.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/fact_service.dart';

part '../generated/riverpods/all_facts_data_provider.g.dart';

@Riverpod(keepAlive: true)
Future<AiFactResponseDto> fetchAllFacts(
  Ref ref,
  int pageNumber,
  int pageSize,
  List<String> categories,
  List<String> providers,
) async {
  return await FactService.getAllAiFactsFromDatabase(
    pageNumber: pageNumber,
    pageSize: pageSize,
    aiProviders: providers,
    factCategories: categories,
  );
}
