import 'package:flutter/material.dart';

import '../../../dtos/quote_dto.dart';

class HomeScreenGridContent extends StatelessWidget {
  final QuoteDto quote;

  const HomeScreenGridContent({super.key, required this.quote});

  double calculateDynamicFontSize(BuildContext context, int quoteLength) {
    // Screen width for responsive adjustment
    double screenWidth = MediaQuery.of(context).size.width;

    // Large base size, decrease proportionally with quote length
    double baseFontSize = screenWidth * 0.08; // 8% of screen width as a base
    double adjustedFontSize = baseFontSize - (quoteLength * 0.2);

    // Ensure font size remains within readable bounds
    return adjustedFontSize.clamp(
        16.0, baseFontSize); // Minimum 16, max at base size
  }

  @override
  Widget build(BuildContext context) {
    final imageHeight = MediaQuery.sizeOf(context).height * 0.06;
    final imageWidth = MediaQuery.sizeOf(context).width * 0.2;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/quotely_icon.png',
            height: imageHeight,
            width: imageWidth,
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              quote.content,
              style: TextStyle(
                fontSize: calculateDynamicFontSize(context, quote.length),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              '- ${quote.author}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HomeScreenGridContentSkeletor extends StatelessWidget {
  const HomeScreenGridContentSkeletor({super.key});

  @override
  Widget build(BuildContext context) {
    final imageHeight = MediaQuery.sizeOf(context).height * 0.06;
    final imageWidth = MediaQuery.sizeOf(context).width * 0.2;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/quotely_icon.png',
            height: imageHeight,
            width: imageWidth,
          ),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              'You will never find the same person twice, not even in the same person',
              style: TextStyle(
                fontSize: (28 / 224) * 200,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              '- Rumy',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
