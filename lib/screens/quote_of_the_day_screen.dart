import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quotely_flutter_app/components/layouts/main_layout.dart';
import 'package:quotely_flutter_app/components/quote_of_the_day_screen/quote_of_the_day_component.dart';
import 'package:quotely_flutter_app/screens/quote_of_the_day_list_screen.dart';

class QuoteOfTheDayScreen extends StatelessWidget {
  static const kRouteName = '/quote-of-the-day';
  const QuoteOfTheDayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final kPrimaryColor = Theme.of(context).primaryColor;
    return MainLayout(
      title: 'Quote of the Day',
      body: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 8,
          horizontal: 10,
        ),
        child: Column(
          // mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const QuoteOfTheDayComponent(),
            GestureDetector(
              onTap: () => context.push(QuoteOfTheDayListScreen.kRouteName),
              child: Container(
                height: MediaQuery.sizeOf(context).height * 0.05,
                margin: const EdgeInsets.only(top: 8, bottom: 5),
                width: double.infinity,
                decoration: BoxDecoration(
                  // color: kPrimaryColor.withOpacity(0.7),
                  border: Border.all(
                    color: kPrimaryColor.withOpacity(0.5),
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Center(
                  child: Text(
                    'See All Quote of the Day',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: kPrimaryColor,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
