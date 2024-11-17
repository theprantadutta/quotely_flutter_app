import 'package:flutter/material.dart';
import 'package:quotely_flutter_app/components/author_detail_screen/author_detail_author_bio.dart';
import 'package:quotely_flutter_app/components/author_detail_screen/author_detail_author_quotes.dart';
import 'package:quotely_flutter_app/screen_arguments/author_detail_screen_arguments.dart';

import '../components/layouts/main_layout.dart';

class AuthorDetailScreen extends StatefulWidget {
  static const kRouteName = '/author-detail';

  final AuthorDetailScreenArguments authorDetailScreenArguments;

  const AuthorDetailScreen({
    super.key,
    required this.authorDetailScreenArguments,
  });

  @override
  State<AuthorDetailScreen> createState() => _AuthorDetailScreenState();
}

class _AuthorDetailScreenState extends State<AuthorDetailScreen> {
  bool isAuthorBioSelected = true;

  @override
  Widget build(BuildContext context) {
    final author = widget.authorDetailScreenArguments.author;
    return MainLayout(
      title: 'Author Detail',
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 8,
            horizontal: 10,
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  SingleAuthorDetailButton(
                    title: 'Author Bio',
                    isSelected: isAuthorBioSelected,
                    onTap: () => setState(() => isAuthorBioSelected = true),
                  ),
                  SingleAuthorDetailButton(
                    title: 'Author Quotes',
                    isSelected: !isAuthorBioSelected,
                    onTap: () => setState(() => isAuthorBioSelected = false),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              isAuthorBioSelected
                  ? AuthorDetailAuthorBio(
                      author: author,
                    )
                  : AuthorDetailAuthorQuotes(
                      author: author,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class SingleAuthorDetailButton extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const SingleAuthorDetailButton({
    super.key,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final kPrimaryColor = Theme.of(context).primaryColor;
    return Flexible(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? kPrimaryColor.withOpacity(0.8)
                : kPrimaryColor.withOpacity(0.2),
            border: Border.all(
              color: kPrimaryColor.withOpacity(0.2),
            ),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : kPrimaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
