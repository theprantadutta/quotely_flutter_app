import 'package:flutter/material.dart';

class HomeScreenTopBar extends StatelessWidget {
  final bool isGridView;
  final VoidCallback onViewChanged;

  const HomeScreenTopBar({
    super.key,
    required this.isGridView,
    required this.onViewChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final iconColor = Theme.of(context).iconTheme.color;
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.06,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Image.asset(
                'assets/quotely_icon.png',
                height: MediaQuery.sizeOf(context).height * 0.04,
              ),
              SizedBox(width: 10),
              Text(
                'Quotely',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
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
              SizedBox(width: 10),
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
