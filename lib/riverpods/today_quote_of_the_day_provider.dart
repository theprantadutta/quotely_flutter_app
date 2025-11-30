import 'package:quotely_flutter_app/dtos/quote_of_the_day_dto.dart';
import 'package:quotely_flutter_app/services/quote_of_the_day_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../generated/riverpods/today_quote_of_the_day_provider.g.dart';

@Riverpod(keepAlive: true)
Future<QuoteOfTheDayDto> fetchTodayQuoteOfTheDay(Ref ref) async {
  return await QuoteOfTheDayService().getTodayQuoteOfTheDayFromDatabase();
}
