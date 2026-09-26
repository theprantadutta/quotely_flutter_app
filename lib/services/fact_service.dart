import 'dart:convert';

import 'package:quotely_flutter_app/dtos/pagination_dto.dart';
import 'package:quotely_flutter_app/util/pagination_seed.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/urls.dart';
import '../dtos/ai_fact_dto.dart';
import '../dtos/ai_fact_response_dto.dart';
import 'drift_fact_service.dart';
import 'http_service.dart';
import 'local_first.dart';

/// Facts, local first (see [LocalFirst]).
class FactService {
  FactService._();

  static Future<AiFactResponseDto> getAllAiFactsFromDatabase({
    required int pageNumber,
    required int pageSize,
    required List<String> factCategories,
    required List<String> aiProviders,
    int? seed,

    /// Only facts with a false twin, for "True or false?".
    bool playable = false,
  }) {
    final effectiveSeed = seed ?? PaginationSeed.current;
    return LocalFirst.load<AiFactResponseDto>(
      key:
          'facts:${factCategories.join(',')}:${aiProviders.join(',')}:'
          '$playable:$pageNumber:$pageSize',
      local: () async {
        // Providers aren't stored locally; a provider-filtered page is
        // backend only.
        if (aiProviders.isNotEmpty) return _empty();
        final rows = await DriftFactService.getLocalFactsWithPagination(
          pageNumber: pageNumber,
          pageSize: pageSize,
          categories: factCategories,
          seed: effectiveSeed,
          playable: playable,
        );
        final favorites = await DriftFactService.getAllFavoriteFactIds();
        return AiFactResponseDto(
          aiFacts: [
            for (final row in rows)
              AiFactDto.fromDrift(row)..isFavorite = favorites.contains(row.id),
          ],
          pagination: PaginationDto(
            pageNumber: 0,
            pageSize: 0,
            totalItemCount: 0,
          ),
        );
      },
      remote: () async {
        final uri = Uri.parse('$kApiUrl/$kGetAllAiFacts').replace(
          queryParameters: {
            'pageNumber': pageNumber.toString(),
            'pageSize': pageSize.toString(),
            'seed': effectiveSeed.toString(),
            if (factCategories.isNotEmpty)
              'factCategories': factCategories.join(','),
            if (aiProviders.isNotEmpty) 'aiProviders': aiProviders.join(','),
            if (playable) 'playable': 'true',
          },
        );
        final response = await HttpService.get(uri.toString());
        if (response.statusCode != 200) {
          throw Exception('Facts request failed: ${response.statusCode}');
        }
        final dto = AiFactResponseDto.fromJson(json.decode(response.data));
        if (dto.aiFacts.isNotEmpty) {
          await DriftFactService.saveNewFactsToDatabase(dto.aiFacts);
        }
        final favorites = await DriftFactService.getAllFavoriteFactIds();
        for (final fact in dto.aiFacts) {
          fact.isFavorite = favorites.contains(fact.id);
        }
        return dto;
      },
      isEmpty: (r) => r.aiFacts.isEmpty,
    );
  }

  static const _kCategoriesCacheKey = 'fact_categories_cache';

  /// Fact categories, most used first. Local first from the saved list.
  static Future<List<String>> getAllFactsCategories() {
    return LocalFirst.load<List<String>>(
      key: 'fact-categories',
      local: () async {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getStringList(_kCategoriesCacheKey) ?? const [];
      },
      remote: () async {
        final response = await HttpService.get(
          '$kApiUrl/$kGetAllAiFactCategories',
        );
        if (response.statusCode != 200) {
          throw Exception('Categories request failed: ${response.statusCode}');
        }
        final data = response.data is String
            ? jsonDecode(response.data)
            : response.data;
        if (data is! List) {
          throw const FormatException('Categories response was not a list.');
        }
        final categories = [for (final item in data) item.toString()];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(_kCategoriesCacheKey, categories);
        return categories;
      },
      isEmpty: (c) => c.isEmpty,
    );
  }

  static AiFactResponseDto _empty() => AiFactResponseDto(
    aiFacts: const [],
    pagination: PaginationDto(pageNumber: 0, pageSize: 0, totalItemCount: 0),
  );
}
