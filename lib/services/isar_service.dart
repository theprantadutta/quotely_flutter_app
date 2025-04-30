import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../../dtos/quote_dto.dart';

class IsarService {
  late Future<Isar> db;

  /// Gets Called when we initiate a new Isar Instance
  IsarService() {
    db = openDB();
  }

  /// This functions opens up the database for CRUD operations
  Future<Isar> openDB() async {
    final dir = await getApplicationDocumentsDirectory();
    return Isar.open(
      schemas: [QuoteDtoSchema],
      directory: dir.path,
      inspector: true,
    );
  }

  Future<bool> isFavorite(String quoteId) async {
    final isar = await openDB();
    final existingQuote =
        await isar.quoteDtos.where().idEqualTo(quoteId).findFirstAsync();
    return existingQuote == null ? false : existingQuote.isFavorite;
  }

  Future<bool> changeQuoteUpdateStatus(
      QuoteDto quoteDto, bool isFavorite) async {
    try {
      final isar = await openDB();

      isar.write((isarDb) {
        final newQuote = QuoteDto(
          id: quoteDto.id,
          author: quoteDto.author,
          content: quoteDto.content,
          tags: quoteDto.tags,
          authorSlug: quoteDto.authorSlug,
          length: quoteDto.length,
          isFavorite: isFavorite,
          dateAdded: quoteDto.dateAdded,
          dateModified: quoteDto.dateModified,
        );
        isarDb.quoteDtos.put(newQuote);
      });

      return true;
    } catch (e) {
      if (kDebugMode) print(e);
      return false;
    }
  }

  Future<List<QuoteDto>> getAllFavouriteQuotes(List<String> tags) async {
    final isar = await openDB();
    return await isar.quoteDtos
        .where()
        .isFavoriteEqualTo(true)
        .anyOf(
          tags,
          (q, element) => q.tagsElementEqualTo(element),
        )
        .findAllAsync();
  }

  Stream<List<QuoteDto>> watchAllFavouriteQuotes(List<String> tags) async* {
    final isar = await openDB();
    yield* isar.quoteDtos
        .where()
        .isFavoriteEqualTo(true)
        .anyOf(
          tags,
          (q, element) => q.tagsElementEqualTo(element),
        )
        .watch(fireImmediately: true);
  }
}
