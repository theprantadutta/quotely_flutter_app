import 'package:flutter/material.dart';

class HomeScreenQuoteListView extends StatelessWidget {
  const HomeScreenQuoteListView({super.key});

  @override
  Widget build(BuildContext context) {
    final kPrimaryColor = Theme.of(context).primaryColor;
    return Expanded(
      child: ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 5),
            height: MediaQuery.sizeOf(context).height * 0.2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  kPrimaryColor.withOpacity(0.3),
                  kPrimaryColor.withOpacity(0.2),
                  kPrimaryColor.withOpacity(0.1),
                  kPrimaryColor.withOpacity(0.4),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: const [0.1, 0.4, 0.9, 1.0],
              ),
              border: Border.all(
                color: kPrimaryColor.withOpacity(0.1),
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Center(
              child: Text('Index $index'),
            ),
          );
        },
      ),
    );
  }
}
