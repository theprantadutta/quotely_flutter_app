import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quotely_flutter_app/dtos/quote_response_dto.dart';
import 'package:quotely_flutter_app/services/quote_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../generated/riverpods/all_quote_data_provider.g.dart';

@Riverpod(keepAlive: true)
Future<QuoteResponseDto> fetchAllQuotes(
  Ref ref,
  int pageNumber,
  int pageSize,
  List<String> tags,
) async {
  return await QuoteService().getAllQuotesFromDatabase(
    ref: ref,
    pageNumber: pageNumber,
    pageSize: pageSize,
    tags: tags,
  );
}
