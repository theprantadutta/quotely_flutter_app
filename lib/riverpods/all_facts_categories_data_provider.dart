import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quotely_flutter_app/services/fact_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../generated/riverpods/all_facts_categories_data_provider.g.dart';

@Riverpod(keepAlive: true)
Future<List<String>> fetchAllFactsCategories(
  Ref ref,
  int pageNumber,
  int pageSize,
) async {
  return await FactService.getAllFactsCategoriesFromDatabase(
    pageNumber: pageNumber,
    pageSize: pageSize,
  );
}
