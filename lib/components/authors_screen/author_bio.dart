import 'package:flutter/material.dart';

class AuthorBio extends StatefulWidget {
  final String bio;

  const AuthorBio({super.key, required this.bio});

  @override
  _AuthorBioState createState() => _AuthorBioState();
}

class _AuthorBioState extends State<AuthorBio> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate if the bio text fits in four lines
        final span = TextSpan(
          text: widget.bio,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
        );
        final tp = TextPainter(
          text: span,
          maxLines: isExpanded ? null : 4,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: constraints.maxWidth);

        final isOverflowing = tp.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: widget.bio,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey[700],
                    ),
                  ),
                  if (isOverflowing && !isExpanded)
                    TextSpan(
                      text: '... ',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey[700],
                      ),
                    ),
                ],
              ),
              maxLines: isExpanded ? null : 4,
              overflow: TextOverflow.clip,
            ),
            if (isOverflowing)
              GestureDetector(
                onTap: () {
                  setState(() {
                    isExpanded = !isExpanded;
                  });
                },
                child: Text(
                  isExpanded ? 'Show less' : 'Show more',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
