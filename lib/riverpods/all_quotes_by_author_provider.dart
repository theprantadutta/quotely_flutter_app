import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quotely_flutter_app/dtos/quote_response_dto.dart';
import 'package:quotely_flutter_app/services/quote_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../generated/riverpods/all_quotes_by_author_provider.g.dart';

@Riverpod(keepAlive: true)
Future<QuoteResponseDto> fetchAllQuotesByAuthor(
  Ref ref,
  String authorSlug,
  int pageNumber,
  int pageSize,
) async {
  return await QuoteService().getAllQuotesByAuthorFromDatabase(
    authorSlug: authorSlug,
    pageNumber: pageNumber,
    pageSize: pageSize,
  );
}
