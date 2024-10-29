import 'package:flutter/material.dart';

import '../../../dtos/quote_dto.dart';

class HomeScreenListContent extends StatelessWidget {
  final QuoteDto quote;
  const HomeScreenListContent({super.key, required this.quote});

  @override
  Widget build(BuildContext context) {
    final imageHeight = MediaQuery.sizeOf(context).height * 0.02;
    final imageWidth = MediaQuery.sizeOf(context).width * 0.05;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 5),
          child: Image.asset(
            'assets/quotely_icon.png',
            height: imageHeight,
            width: imageWidth,
          ),
        ),
        Container(
          width: MediaQuery.sizeOf(context).width * 0.9,
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            quote.content,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 8, top: 5),
          child: Transform.rotate(
            angle: 180 * (3.14159265359 / 180), // Convert 90 degrees to radians
            child: Image.asset(
              'assets/quotely_icon.png',
              height: imageHeight,
              width: imageWidth,
            ),
          ),
        ),
        const SizedBox(height: 5),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            '- ${quote.author}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class HomeScrenListContentSkeletor extends StatelessWidget {
  const HomeScrenListContentSkeletor({super.key});

  @override
  Widget build(BuildContext context) {
    final imageHeight = MediaQuery.sizeOf(context).height * 0.02;
    final imageWidth = MediaQuery.sizeOf(context).width * 0.05;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 5),
          child: Image.asset(
            'assets/quotely_icon.png',
            height: imageHeight,
            width: imageWidth,
          ),
        ),
        Container(
          width: MediaQuery.sizeOf(context).width * 0.9,
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: const Text(
            'You will never find the same person twice, not even in the same person',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 8, top: 5),
          child: Transform.rotate(
            angle: 180 * (3.14159265359 / 180), // Convert 90 degrees to radians
            child: Image.asset(
              'assets/quotely_icon.png',
              height: imageHeight,
              width: imageWidth,
            ),
          ),
        ),
        const SizedBox(height: 5),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            '- Rumy',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
