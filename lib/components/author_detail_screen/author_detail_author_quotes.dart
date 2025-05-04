import 'package:flutter/material.dart';
import 'package:quotely_flutter_app/components/author_detail_screen/author_detail_author_quote_list.dart';
import 'package:quotely_flutter_app/dtos/author_dto.dart';

class AuthorDetailAuthorQuotes extends StatelessWidget {
  final AuthorDto author;

  const AuthorDetailAuthorQuotes({
    super.key,
    required this.author,
  });

  @override
  Widget build(BuildContext context) {
    final kPrimaryColor = Theme.of(context).primaryColor;
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            vertical: 10,
            horizontal: 15,
          ),
          decoration: BoxDecoration(
            border: Border.all(
              color: kPrimaryColor.withValues(alpha: 0.4),
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            children: [
              Text(
                'Quotes from "${author.name}"',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                author.description,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        AuthorDetailAuthorQuoteList(
          author: author,
        ),
      ],
    );
  }
}
