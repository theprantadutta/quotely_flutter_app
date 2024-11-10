import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class HomeScreenTopBar extends StatelessWidget {
  final bool isGridView;
  final VoidCallback onViewChanged;
  final bool loading;

  const HomeScreenTopBar({
    super.key,
    required this.isGridView,
    required this.onViewChanged,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final iconColor = Theme.of(context).iconTheme.color;
    final kPrimaryColor = Theme.of(context).primaryColor;
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.06,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Image.asset(
                'assets/quotely_icon.png',
                height: MediaQuery.sizeOf(context).height * 0.03,
              ),
              const SizedBox(width: 10),
              const Text(
                'Quotely',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 10),
              if (loading)
                LoadingAnimationWidget.hexagonDots(
                  color: kPrimaryColor,
                  size: 20,
                ),
            ],
          ),
          Row(
            children: [
              GestureDetector(
                onTap: onViewChanged,
                child: Icon(
                  Icons.view_agenda_outlined,
                  color: !isGridView
                      ? iconColor
                      : isDarkTheme
                          ? Colors.grey.shade700
                          : Colors.grey.shade400,
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: onViewChanged,
                child: Icon(
                  Icons.crop_square,
                  size: 28,
                  color: isGridView
                      ? iconColor
                      : isDarkTheme
                          ? Colors.grey.shade700
                          : Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
