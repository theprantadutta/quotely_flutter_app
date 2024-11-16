import 'package:flutter/material.dart';

// TODO: Keep this for future preference
// class AuthorBio extends StatefulWidget {
//   final bool showAllFirst;
//   final String bio;
//   final double defaultFontSize;

//   const AuthorBio({
//     super.key,
//     required this.bio,
//     this.showAllFirst = false,
//     this.defaultFontSize = 13,
//   });

//   @override
//   State<AuthorBio> createState() => _AuthorBioState();
// }

// class _AuthorBioState extends State<AuthorBio> {
//   bool isExpanded = false;

//   @override
//   void initState() {
//     super.initState();
//     isExpanded = widget.showAllFirst;
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
//     return LayoutBuilder(
//       builder: (context, constraints) {
//         // Calculate if the bio text fits in four lines
//         final span = TextSpan(
//           text: widget.bio,
//           style: TextStyle(
//             fontSize: widget.defaultFontSize,
//             fontWeight: FontWeight.w400,
//             color: isDarkTheme ? Colors.grey[400] : Colors.grey[800],
//           ),
//         );
//         final tp = TextPainter(
//           text: span,
//           maxLines: isExpanded ? null : 4,
//           textDirection: TextDirection.ltr,
//         )..layout(maxWidth: constraints.maxWidth);

//         final isOverflowing = tp.didExceedMaxLines;

//         return Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text.rich(
//               TextSpan(
//                 children: [
//                   TextSpan(
//                     text: widget.bio,
//                     style: TextStyle(
//                       fontSize: widget.defaultFontSize,
//                       fontWeight: FontWeight.w400,
//                       color: isDarkTheme ? Colors.grey[300] : Colors.grey[700],
//                     ),
//                   ),
//                   if (isOverflowing && !isExpanded)
//                     TextSpan(
//                       text: '... ',
//                       style: TextStyle(
//                         fontSize: widget.defaultFontSize,
//                         fontWeight: FontWeight.w400,
//                       ),
//                     ),
//                 ],
//               ),
//               maxLines: isExpanded ? null : 4,
//               overflow: TextOverflow.clip,
//             ),
//             if (isOverflowing)
//               GestureDetector(
//                 onTap: () {
//                   setState(() {
//                     isExpanded = !isExpanded;
//                   });
//                 },
//                 child: Text(
//                   isExpanded ? 'Show less' : 'Show more',
//                   style: TextStyle(
//                     color: Theme.of(context).primaryColor,
//                     fontWeight: FontWeight.bold,
//                     fontSize: widget.defaultFontSize,
//                   ),
//                 ),
//               ),
//           ],
//         );
//       },
//     );
//   }
// }

class AuthorBio extends StatelessWidget {
  final String bio;

  const AuthorBio({
    super.key,
    required this.bio,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    return Text(
      bio,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: isDarkTheme ? Colors.grey[300] : Colors.grey[700],
      ),
    );
  }
}
