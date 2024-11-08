import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:quotely_flutter_app/riverpods/today_quote_of_the_day_provider.dart';

class QuoteOfTheDayComponent extends ConsumerWidget {
  const QuoteOfTheDayComponent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quoteOfTheDayProvider = ref.watch(fetchTodayQuoteOfTheDayProvider);
    final kPrimaryColor = Theme.of(context).primaryColor;
    return quoteOfTheDayProvider.when(
      data: (data) {
        return Container(
          // height: MediaQuery.sizeOf(context).height * 0.7,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: kPrimaryColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Quote Date: ${DateFormat('dd MMM, yyyy').format(data.quoteDate)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Image.asset(
                      'assets/quotely_icon.png',
                      height: MediaQuery.sizeOf(context).height * 0.1,
                      width: MediaQuery.sizeOf(context).width * 0.2,
                    ),
                  ),
                  Text(
                    data.content,
                    style: const TextStyle(
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '- ${data.author}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
      error: (err, stack) => const Center(
        child: Text('Something Went Wrong'),
      ),
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
