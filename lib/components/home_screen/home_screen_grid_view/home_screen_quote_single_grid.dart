import 'package:flutter/material.dart';
import 'package:quotely_flutter_app/dtos/quote_dto.dart';
import 'package:quotely_flutter_app/services/common_service.dart';

import '../../../services/isar_service.dart';
import 'home_screen_grid_content.dart';
import 'home_screen_grid_view_button.dart';

class HomeScreenQuoteSingleGrid extends StatefulWidget {
  final double defaultHeight;
  final QuoteDto currentQuote;

  const HomeScreenQuoteSingleGrid({
    super.key,
    required this.defaultHeight,
    required this.currentQuote,
  });

  @override
  State<HomeScreenQuoteSingleGrid> createState() =>
      _HomeScreenQuoteSingleGridState();
}

class _HomeScreenQuoteSingleGridState extends State<HomeScreenQuoteSingleGrid>
    with AutomaticKeepAliveClientMixin {
  bool selectedQuote = false;

  @override
  void initState() {
    selectedQuote = widget.currentQuote.isFavourite;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final kPrimaryColor = Theme.of(context).primaryColor;
    return Container(
      height: widget.defaultHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          colors: [
            kPrimaryColor.withValues(alpha: 0.3),
            kPrimaryColor.withValues(alpha: 0.2),
            kPrimaryColor.withValues(alpha: 0.1),
            kPrimaryColor.withValues(alpha: 0.4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.1, 0.4, 0.9, 1.0],
        ),
      ),
      child: Stack(
        children: [
          HomeScreenGridViewButton(
            bottom: 5,
            right: 20,
            title: 'Share',
            iconData: Icons.share_outlined,
            onTap: () => CommonService.showNotImplementedDialog(context),
          ),
          HomeScreenGridViewButton(
            bottom: 5,
            left: 20,
            title: 'Like',
            iconData: Icons.favorite_outline,
            isSelected: selectedQuote,
            onTap: () {
              debugPrint(
                  "Making Quote with ID ${widget.currentQuote.id} as ${!selectedQuote}");
              setState(() {
                selectedQuote = !selectedQuote;
              });
              IsarService().changeQuoteUpdateStatus(
                widget.currentQuote,
                selectedQuote,
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: HomeScreenGridContent(
              quote: widget.currentQuote,
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class HomeScreenQuoteSingleGridSkeletor extends StatelessWidget {
  final double defaultHeight;

  const HomeScreenQuoteSingleGridSkeletor({
    super.key,
    required this.defaultHeight,
  });

  @override
  Widget build(BuildContext context) {
    final kPrimaryColor = Theme.of(context).primaryColor;
    return Container(
      height: defaultHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          colors: [
            kPrimaryColor.withValues(alpha: 0.3),
            kPrimaryColor.withValues(alpha: 0.2),
            kPrimaryColor.withValues(alpha: 0.1),
            kPrimaryColor.withValues(alpha: 0.4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.1, 0.4, 0.9, 1.0],
        ),
      ),
      child: const Stack(
        children: [
          HomeScreenGridViewButton(
            bottom: 5,
            right: 20,
            title: 'Share',
            iconData: Icons.share_outlined,
          ),
          HomeScreenGridViewButton(
            bottom: 5,
            left: 20,
            title: 'Like',
            iconData: Icons.favorite_outline,
          ),
          HomeScreenGridContentSkeletor(),
        ],
      ),
    );
  }
}
