import 'package:flutter/material.dart';
import 'package:quotely_flutter_app/components/author_detail_screen/author_detail_author_quote_list.dart';
import 'package:quotely_flutter_app/dtos/author_dto.dart';

/// The "Quotes by …" section: a clean heading + the swipeable quote carousel.
class AuthorDetailAuthorQuotes extends StatelessWidget {
  final AuthorDto author;

  const AuthorDetailAuthorQuotes({super.key, required this.author});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.brightness == Brightness.dark
        ? theme.colorScheme.secondary
        : theme.primaryColor.withValues(alpha: 0.85);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Row(
            children: [
              Icon(Icons.format_quote_rounded, size: 20, color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Quotes by ${author.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${author.quoteCount}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
            ],
          ),
        ),
        AuthorDetailAuthorQuoteList(author: author),
      ],
    );
  }
}
