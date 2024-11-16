import 'package:flutter/material.dart';
import 'package:quotely_flutter_app/components/shared/circle_avatar_with_fallback.dart';
import 'package:quotely_flutter_app/dtos/author_dto.dart';

class AuthorDetailAuthorBio extends StatelessWidget {
  final AuthorDto author;

  const AuthorDetailAuthorBio({super.key, required this.author});

  @override
  Widget build(BuildContext context) {
    final kPrimaryColor = Theme.of(context).primaryColor;
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.8,
      width: MediaQuery.sizeOf(context).width * 0.92,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        border: Border.all(
          color: kPrimaryColor.withOpacity(0.2),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatarWithFallback(
            name: author.name,
            radius: 60,
            imageUrl: author.imageUrl,
          ),
          const SizedBox(height: 10),
          Text(
            author.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            author.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            author.bio,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: isDarkTheme ? Colors.grey[300] : Colors.grey[700],
            ),
          )
        ],
      ),
    );
  }
}
