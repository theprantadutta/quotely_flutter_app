import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quotely_flutter_app/components/shared/circle_avatar_with_fallback.dart';
import 'package:quotely_flutter_app/dtos/author_dto.dart';
import 'package:quotely_flutter_app/screen_arguments/author_detail_screen_arguments.dart';

import '../../screens/author_detail_screen.dart';

class SingleAuthorView extends StatelessWidget {
  final int index;
  final AuthorDto author;

  const SingleAuthorView({
    super.key,
    required this.index,
    required this.author,
  });

  @override
  Widget build(BuildContext context) {
    final kPrimaryColor = Theme.of(context).primaryColor;
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        const Positioned(
          top: 10,
          right: 10,
          child: Icon(
            Icons.open_in_new_outlined,
            size: 18,
          ),
        ),
        GestureDetector(
          onTap: () => context.push(
            AuthorDetailScreen.kRouteName,
            extra: AuthorDetailScreenArguments(author: author),
          ),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 3),
            padding: const EdgeInsets.symmetric(
              vertical: 15,
              horizontal: 15,
            ),
            width: double.infinity,
            decoration: BoxDecoration(
              color: kPrimaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: kPrimaryColor.withOpacity(0.10),
              ),
            ),
            child: Row(
              children: [
                Flexible(
                  child: CircleAvatarWithFallback(
                    name: author.name,
                    radius: 25,
                    imageUrl: author.imageUrl,
                  ),
                ),
                const SizedBox(width: 15),
                Flexible(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        author.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        author.description,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color:
                              isDarkTheme ? Colors.grey[400] : Colors.grey[800],
                        ),
                      ),
                      // const SizedBox(height: 5),
                      // AuthorBio(bio: author.bio),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class SingleAuthorViewSkeletor extends StatelessWidget {
  const SingleAuthorViewSkeletor({super.key});

  @override
  Widget build(BuildContext context) {
    final kPrimaryColor = Theme.of(context).primaryColor;
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        const Positioned(
          top: 10,
          right: 10,
          child: Icon(
            Icons.open_in_new_outlined,
            size: 18,
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.symmetric(
            vertical: 15,
            horizontal: 15,
          ),
          width: double.infinity,
          decoration: BoxDecoration(
            color: kPrimaryColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: kPrimaryColor.withOpacity(0.10),
            ),
          ),
          child: Row(
            children: [
              const Flexible(
                child: CircleAvatarWithFallback(
                  name: 'Abraham Lincoln',
                  radius: 25,
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'author.name',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'author.description zdfgdfgsdfg',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color:
                            isDarkTheme ? Colors.grey[300] : Colors.grey[700],
                      ),
                    ),
                    // const SizedBox(height: 5),
                    // const AuthorBio(
                    //     bio:
                    //         'gdfadfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasdf'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
