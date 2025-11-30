import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../generated/riverpods/quote_view.g.dart';

enum QuoteView { grid, tile }

@Riverpod(keepAlive: true)
QuoteView quoteView(Ref ref) {
  return QuoteView.grid;
}
