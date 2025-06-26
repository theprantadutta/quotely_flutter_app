import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:quotely_flutter_app/dtos/quote_dto.dart';

class HomeScreenListContent extends StatelessWidget {
  final QuoteDto quote;
  const HomeScreenListContent({super.key, required this.quote});

  @override
  Widget build(BuildContext context) {
    // final imageHeight = MediaQuery.sizeOf(context).height * 0.02;
    // final imageWidth = MediaQuery.sizeOf(context).width * 0.05;
    final kPrimaryColor = Theme.of(context).primaryColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 5),
          // child: Image.asset(
          //   'assets/quotely_icon.png',
          //   height: imageHeight,
          //   width: imageWidth,
          // ),
          child: Icon(
            FontAwesomeIcons.quoteLeft,
            size: 20,
            color: kPrimaryColor,
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
            // child: Image.asset(
            //   'assets/quotely_icon.png',
            //   height: imageHeight,
            //   width: imageWidth,
            // ),
            child: Icon(
              FontAwesomeIcons.quoteLeft,
              size: 20,
              color: kPrimaryColor,
            ),
          ),
        ),
        const SizedBox(height: 5),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              '- ${quote.author}',
              style: TextStyle(
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ),
      ],
    );
  }
}

class HomeScreenListContentSkeletor extends StatelessWidget {
  const HomeScreenListContentSkeletor({super.key});

  @override
  Widget build(BuildContext context) {
    // final imageHeight = MediaQuery.sizeOf(context).height * 0.02;
    // final imageWidth = MediaQuery.sizeOf(context).width * 0.05;
    final kPrimaryColor = Theme.of(context).primaryColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 5),
          // child: Image.asset(
          //   'assets/quotely_icon.png',
          //   height: imageHeight,
          //   width: imageWidth,
          // ),
          child: Icon(
            FontAwesomeIcons.quoteLeft,
            size: 20,
            color: kPrimaryColor,
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
            // child: Image.asset(
            //   'assets/quotely_icon.png',
            //   height: imageHeight,
            //   width: imageWidth,
            // ),
            child: Icon(
              FontAwesomeIcons.quoteLeft,
              size: 20,
              color: kPrimaryColor,
            ),
          ),
        ),
        const SizedBox(height: 5),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              '- Rumy',
              style: TextStyle(
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ),
      ],
    );
  }
}
