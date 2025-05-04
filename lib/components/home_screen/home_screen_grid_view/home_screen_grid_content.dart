import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../dtos/quote_dto.dart';
import '../../../screens/author_detail_screen.dart';

class HomeScreenGridContent extends StatelessWidget {
  final QuoteDto quote;
  final double minFontSize = 16.0;
  final double maxFontSizePercentage = 0.08;

  const HomeScreenGridContent({super.key, required this.quote});

  double _calculateFontSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final baseFontSize = screenWidth * maxFontSizePercentage;

    // Adjust based on quote length (more characters = smaller font)
    final lengthFactor = quote.content.length.clamp(0, 200) / 200;
    final adjustedFontSize = baseFontSize * (1 - lengthFactor * 0.5);

    return adjustedFontSize.clamp(minFontSize, baseFontSize);
  }

  @override
  Widget build(BuildContext context) {
    final imageSize = MediaQuery.sizeOf(context).width * 0.2;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final authorColor = isDarkMode
        ? theme.colorScheme.secondary
        : theme.primaryColor.withValues(alpha: 0.8);
    final quoteColor = theme.colorScheme.onSurface.withValues(alpha: 0.9);
    return Padding(
      padding: EdgeInsets.all(5.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 10,
        children: [
          _buildLogo(imageSize),
          _buildQuoteText(context, quoteColor),
          GestureDetector(
            onTap: () => context.push(
              '${AuthorDetailScreen.kRouteName}/${quote.authorSlug}',
            ),
            child: _buildAuthorText(authorColor),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo(double size) {
    return Image.asset(
      'assets/quotely_icon.png',
      height: size * 0.3, // Maintain aspect ratio
      width: size,
      fit: BoxFit.contain,
    );
  }

  Widget _buildQuoteText(BuildContext context, Color quoteColor) {
    return Text(
      quote.content,
      style: TextStyle(
        fontSize: _calculateFontSize(context),
        fontStyle: FontStyle.italic,
        color: quoteColor,
        overflow: TextOverflow.ellipsis,
      ),
      maxLines: 10,
    );
  }

  Widget _buildAuthorText(
    Color authorColor,
  ) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: EdgeInsets.only(right: 8.0, top: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 2,
              color: authorColor,
              margin: const EdgeInsets.only(bottom: 6),
            ),
            Text(
              '— ${quote.author}',
              style: GoogleFonts.raleway(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: authorColor,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreenGridContentSkeletor extends StatelessWidget {
  final double minFontSize = 16.0;
  final double maxFontSizePercentage = 0.08;

  const HomeScreenGridContentSkeletor({super.key});

  @override
  Widget build(BuildContext context) {
    final imageSize = MediaQuery.sizeOf(context).width * 0.2;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final authorColor = isDarkMode
        ? theme.colorScheme.secondary
        : theme.primaryColor.withValues(alpha: 0.8);

    return Padding(
      padding: EdgeInsets.all(5.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 10,
        children: [
          _buildLogo(imageSize),
          _buildQuoteText(context),
          _buildAuthorText(authorColor),
        ],
      ),
    );
  }

  Widget _buildLogo(double size) {
    return Image.asset(
      'assets/quotely_icon.png',
      height: size * 0.3, // Maintain aspect ratio
      width: size,
      fit: BoxFit.contain,
    );
  }

  Widget _buildQuoteText(BuildContext context) {
    return Text(
      'You will never find the same person twice, not even in the same person',
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        overflow: TextOverflow.ellipsis,
      ),
      maxLines: 10,
    );
  }

  Widget _buildAuthorText(Color authorColor) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: EdgeInsets.only(right: 8.0, top: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 2,
              color: authorColor,
              margin: const EdgeInsets.only(bottom: 6),
            ),
            Text(
              '— Rumy',
              style: GoogleFonts.raleway(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: authorColor,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
