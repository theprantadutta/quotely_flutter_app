import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/colors/app_colors.dart';
import '../../theme/neumorphic/neumorphic_decorations.dart';

/// A neumorphic bottom navigation bar with warm cozy styling
class WarmBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<WarmNavItem> items;

  const WarmBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: colors.shadowDark.withValues(alpha: isDark ? 0.6 : 0.35),
            offset: const Offset(6, 6),
            blurRadius: 12,
          ),
          BoxShadow(
            color: colors.shadowLight.withValues(alpha: isDark ? 0.1 : 0.8),
            offset: const Offset(-6, -6),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isSelected = index == currentIndex;

          return _NavItem(
            icon: item.icon,
            selectedIcon: item.selectedIcon,
            label: item.label,
            isSelected: isSelected,
            onTap: () {
              HapticFeedback.lightImpact();
              onTap(index);
            },
          );
        }).toList(),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final IconData icon;
  final IconData? selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> with SingleTickerProviderStateMixin {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: widget.isSelected
              ? colors.primary.withValues(alpha: 0.15)
              : (_isPressed ? colors.surfaceContainer : Colors.transparent),
          borderRadius: BorderRadius.circular(20),
        ),
        child: AnimatedScale(
          scale: _isPressed ? 0.9 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  widget.isSelected
                      ? (widget.selectedIcon ?? widget.icon)
                      : widget.icon,
                  key: ValueKey(widget.isSelected),
                  size: 24,
                  color: widget.isSelected
                      ? colors.primary
                      : colors.textMuted,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: widget.isSelected
                      ? FontWeight.w600
                      : FontWeight.w400,
                  color: widget.isSelected
                      ? colors.primary
                      : colors.textMuted,
                ),
                child: Text(widget.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Navigation item data
class WarmNavItem {
  final IconData icon;
  final IconData? selectedIcon;
  final String label;

  const WarmNavItem({
    required this.icon,
    this.selectedIcon,
    required this.label,
  });
}

/// Default navigation items for the quote app
class DefaultNavItems {
  static const List<WarmNavItem> items = [
    WarmNavItem(
      icon: Icons.format_quote_outlined,
      selectedIcon: Icons.format_quote_rounded,
      label: 'Quotes',
    ),
    WarmNavItem(
      icon: Icons.favorite_outline_rounded,
      selectedIcon: Icons.favorite_rounded,
      label: 'Favorites',
    ),
    WarmNavItem(
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      label: 'Authors',
    ),
    WarmNavItem(
      icon: Icons.lightbulb_outline_rounded,
      selectedIcon: Icons.lightbulb_rounded,
      label: 'Facts',
    ),
    WarmNavItem(
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings_rounded,
      label: 'Settings',
    ),
  ];
}

/// A more compact version of the bottom nav bar
class WarmBottomNavBarCompact extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const WarmBottomNavBarCompact({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: NeumorphicDecoration.convex(
        context,
        borderRadius: 25,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: DefaultNavItems.items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isSelected = index == currentIndex;

          return _CompactNavItem(
            icon: isSelected ? (item.selectedIcon ?? item.icon) : item.icon,
            isSelected: isSelected,
            onTap: () => onTap(index),
          );
        }).toList(),
      ),
    );
  }
}

class _CompactNavItem extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _CompactNavItem({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appColors = isDark ? AppColors.dark : AppColors.light;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isSelected
              ? appColors.primary.withValues(alpha: 0.2)
              : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            icon,
            size: 24,
            color: isSelected ? appColors.primary : appColors.textMuted,
          ),
        ),
      ),
    );
  }
}
