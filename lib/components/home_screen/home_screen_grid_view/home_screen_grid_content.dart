import 'package:flutter/material.dart';

class HomeScreenGridContent extends StatelessWidget {
  const HomeScreenGridContent({super.key});

  @override
  Widget build(BuildContext context) {
    final imageHeight = MediaQuery.sizeOf(context).height * 0.06;
    final imageWidth = MediaQuery.sizeOf(context).width * 0.2;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                fontSize: (32 / 224) * 200,
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
