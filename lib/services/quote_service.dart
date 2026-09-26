import 'dart:convert';

import 'package:quotely_flutter_app/dtos/pagination_dto.dart';
import 'package:quotely_flutter_app/dtos/quote_dto.dart';
import 'package:quotely_flutter_app/services/drift_quote_service.dart';
import 'package:quotely_flutter_app/util/pagination_seed.dart';

import '../../dtos/quote_response_dto.dart';
import '../constants/urls.dart';
import '../database/database.dart';
import 'http_service.dart';
import 'local_first.dart';

/// Quotes, local first (see [LocalFirst]): a page comes from the local
/// database when it has one, and the backend refreshes it in the background.
class QuoteService {
  static Future<QuoteResponseDto> getAllQuotesFromDatabase({
    required int pageNumber,
    required int pageSize,
    required List<String> tags,
    int? seed,
  }) {
    final effectiveSeed = seed ?? PaginationSeed.current;
    return LocalFirst.load<QuoteResponseDto>(
      key: 'quotes:${tags.join(',')}:$pageNumber:$pageSize',
      local: () async => _local(
        await DriftQuoteService.getLocalQuotesWithPagination(
          pageNumber: pageNumber,
          pageSize: pageSize,
          tags: tags,
          seed: effectiveSeed,
        ),
      ),
      remote: () async {
        final uri = Uri.parse('$kApiUrl/$kGetAllQuotes').replace(
          queryParameters: {
            'pageNumber': pageNumber.toString(),
            'pageSize': pageSize.toString(),
            'seed': effectiveSeed.toString(),
            if (tags.isNotEmpty) 'tags': tags.join(','),
          },
        );
        final response = await HttpService.get(uri.toString());
        if (response.statusCode != 200) {
          throw Exception('Quotes request failed: ${response.statusCode}');
        }
        final dto = QuoteResponseDto.fromJson(json.decode(response.data));
        await DriftQuoteService.saveNewQuotesToDatabase(dto.quotes);
        return dto;
      },
      isEmpty: (r) => r.quotes.isEmpty,
    );
  }

  Future<QuoteResponseDto> getAllQuotesByAuthorFromDatabase({
    required String authorSlug,
    required int pageNumber,
    required int pageSize,
    int? seed,
  }) {
    final effectiveSeed = seed ?? PaginationSeed.current;
    return LocalFirst.load<QuoteResponseDto>(
      key: 'quotes-by:$authorSlug:$pageNumber:$pageSize',
      local: () async => _local(
        await DriftQuoteService.getLocalQuotesByAuthor(
          authorSlug: authorSlug,
          pageNumber: pageNumber,
          pageSize: pageSize,
          seed: effectiveSeed,
        ),
      ),
      remote: () async {
        final uri = Uri.parse('$kApiUrl/$kGetAllQuotesByAuthor').replace(
          queryParameters: {
            'authorSlug': authorSlug,
            'pageNumber': pageNumber.toString(),
            'pageSize': pageSize.toString(),
            'seed': effectiveSeed.toString(),
          },
        );
        final response = await HttpService.get(uri.toString());
        if (response.statusCode != 200) {
          throw Exception('Failed to get quotes by author');
        }
        final dto = QuoteResponseDto.fromJson(json.decode(response.data));
        await DriftQuoteService.saveNewQuotesToDatabase(dto.quotes);
        final favorites = await DriftQuoteService.getAllFavoriteQuoteIds();
        for (final q in dto.quotes) {
          q.isFavorite = favorites.contains(q.id);
        }
        return dto;
      },
      isEmpty: (r) => r.quotes.isEmpty,
    );
  }

  static QuoteResponseDto _local(List<Quote> rows) => QuoteResponseDto(
    quotes: QuoteDto.fromQuoteList(rows),
    pagination: PaginationDto(pageNumber: 0, pageSize: 0, totalItemCount: 0),
  );
}
