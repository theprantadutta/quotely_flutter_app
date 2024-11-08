import 'package:flutter/material.dart';
import 'package:quotely_flutter_app/components/authors_screen/author_list.dart';
import 'package:quotely_flutter_app/components/shared/input_form_field.dart';

import '../../components/shared/top_navigation_bar.dart';

class AuthorsScreen extends StatefulWidget {
  static const kRouteName = '/authors';
  const AuthorsScreen({super.key});

  @override
  State<AuthorsScreen> createState() => _AuthorsScreenState();
}

class _AuthorsScreenState extends State<AuthorsScreen> {
  final authorSearchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 8,
          horizontal: 10,
        ),
        child: Column(
          children: [
            const TopNavigationBar(title: 'Authors'),
            InputFormField(
              labelText: 'Enter Author Name',
              controller: authorSearchController,
            ),
            AuthorList(
              authorSearchController: authorSearchController,
            ),
          ],
        ),
      ),
    );
  }
}
