import 'package:quotely_flutter_app/dtos/quote_of_the_day_response_dto.dart';
import 'package:quotely_flutter_app/services/quote_of_the_day_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../generated/riverpods/all_quote_of_the_day_provider.g.dart';

@Riverpod(keepAlive: true)
Future<QuoteOfTheDayResponseDto> fetchAllQuoteOfTheDay(
  Ref ref,
  int pageNumber,
  int pageSize,
) async {
  return await QuoteOfTheDayService().getAllQuoteOfTheDayFromDatabase(
    pageNumber: pageNumber,
    pageSize: pageSize,
  );
}
