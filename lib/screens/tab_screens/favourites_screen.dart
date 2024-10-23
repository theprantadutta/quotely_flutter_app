import 'package:flutter/material.dart';

class FavouritesScreen extends StatelessWidget {
  static const kRouteName = '/favourites';
  const FavouritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: const Center(
        child: Text('Favourites Screen'),
      ),
    );
  }
}
