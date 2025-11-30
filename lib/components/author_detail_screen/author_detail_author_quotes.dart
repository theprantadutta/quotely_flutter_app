import 'package:flutter/material.dart';
import 'package:quotely_flutter_app/components/author_detail_screen/author_detail_author_quote_list.dart';
import 'package:quotely_flutter_app/dtos/author_dto.dart';

// class AuthorDetailAuthorQuotes extends StatelessWidget {
//   final AuthorDto author;

//   const AuthorDetailAuthorQuotes({
//     super.key,
//     required this.author,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final kPrimaryColor = Theme.of(context).primaryColor;
//     return Column(
//       children: [
//         Container(
//           width: double.infinity,
//           padding: const EdgeInsets.symmetric(
//             vertical: 10,
//             horizontal: 15,
//           ),
//           decoration: BoxDecoration(
//             border: Border.all(
//               color: kPrimaryColor.withValues(alpha: 0.4),
//             ),
//             borderRadius: BorderRadius.circular(15),
//           ),
//           child: Column(
//             children: [
//               Text(
//                 'Quotes from "${author.name}"',
//                 textAlign: TextAlign.center,
//                 style: const TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.w700,
//                 ),
//               ),
//               const SizedBox(height: 3),
//               Text(
//                 author.description,
//                 textAlign: TextAlign.center,
//               ),
//             ],
//           ),
//         ),
//         const SizedBox(height: 10),
//         AuthorDetailAuthorQuoteList(
//           author: author,
//         ),
//       ],
//     );
//   }
// }

class AuthorDetailAuthorQuotes extends StatelessWidget {
  final AuthorDto author;

  const AuthorDetailAuthorQuotes({super.key, required this.author});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // Enhanced header section
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.primaryColor.withValues(alpha: 0.08),
                theme.primaryColor.withValues(alpha: 0.02),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.primaryColor.withValues(alpha: 0.15),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              // Title with decorative icon
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.format_quote_rounded,
                    color: theme.primaryColor.withValues(alpha: 0.7),
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  // Flexible text container
                  Flexible(
                    child: Text(
                      'Quotes by ${author.name}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    Icons.format_quote_rounded,
                    color: theme.primaryColor.withValues(alpha: 0.7),
                    size: 24,
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Description with subtle divider
              if (author.description.isNotEmpty) ...[
                Divider(
                  color: theme.primaryColor.withValues(alpha: 0.1),
                  thickness: 1,
                  indent: 40,
                  endIndent: 40,
                ),
                const SizedBox(height: 8),
                Text(
                  author.description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Keep the original quote list component exactly as is
        AuthorDetailAuthorQuoteList(author: author),
      ],
    );
  }
}
