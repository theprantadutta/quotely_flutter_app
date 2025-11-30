import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

class SingleQuoteOfTheComponent extends StatelessWidget {
  final DateTime quoteDate;
  final String author;
  final String content;

  const SingleQuoteOfTheComponent({
    super.key,
    required this.quoteDate,
    required this.author,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final kPrimaryColor = Theme.of(context).primaryColor;
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.79,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: kPrimaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Quote Date: ${DateFormat('dd MMM, yyyy').format(quoteDate)}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                // child: Image.asset(
                //   'assets/quotely_icon.png',
                //   height: MediaQuery.sizeOf(context).height * 0.1,
                //   width: MediaQuery.sizeOf(context).width * 0.2,
                // ),
                child: Icon(
                  FontAwesomeIcons.quoteLeft,
                  size: 20,
                  color: kPrimaryColor,
                ),
              ),
              Text(content, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '- $author',
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
  }
}

class SingleQuoteOfTheComponentSkeletor extends StatelessWidget {
  const SingleQuoteOfTheComponentSkeletor({super.key});

  @override
  Widget build(BuildContext context) {
    final kPrimaryColor = Theme.of(context).primaryColor;
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.8,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: kPrimaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Quote Date: 15 Nov, 2024',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                // child: Image.asset(
                //   'assets/quotely_icon.png',
                //   height: MediaQuery.sizeOf(context).height * 0.1,
                //   width: MediaQuery.sizeOf(context).width * 0.2,
                // ),
                child: Icon(
                  FontAwesomeIcons.quoteLeft,
                  size: 20,
                  color: kPrimaryColor,
                ),
              ),
              const Text(
                'Every time you smile at someone, it is an action of love, a gift to that person, a beautiful thing',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 10),
              const Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '- MOther Teresa',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
