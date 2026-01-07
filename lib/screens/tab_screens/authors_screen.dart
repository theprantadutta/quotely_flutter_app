import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quotely_flutter_app/components/authors_screen/author_list.dart';

import '../../theme/colors/app_colors.dart';
import '../../theme/gradients/app_gradients.dart';

class AuthorsScreen extends StatefulWidget {
  static const kRouteName = '/authors';
  const AuthorsScreen({super.key});

  @override
  State<AuthorsScreen> createState() => _AuthorsScreenState();
}

class _AuthorsScreenState extends State<AuthorsScreen> {
  final authorSearchController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    authorSearchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;

    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.scaffoldBackground(context),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(colors),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _NeumorphicSearchBar(
                controller: authorSearchController,
                focusNode: _focusNode,
                isFocused: _isFocused,
                colors: colors,
                isDark: isDark,
                hintText: 'Search authors...',
              ),
            ),

            const SizedBox(height: 16),

            // Author list
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AuthorList(authorSearchController: authorSearchController),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppColorScheme colors) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppGradients.warmPrimary(context),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.3),
                  offset: const Offset(0, 4),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.person_rounded,
                color: colors.onPrimary,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Authors',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
              Text(
                'Discover great minds',
                style: GoogleFonts.lora(
                  fontSize: 12,
                  color: colors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NeumorphicSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isFocused;
  final AppColorScheme colors;
  final bool isDark;
  final String hintText;

  const _NeumorphicSearchBar({
    required this.controller,
    required this.focusNode,
    required this.isFocused,
    required this.colors,
    required this.isDark,
    required this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: isFocused
            ? Border.all(color: colors.primary, width: 2)
            : null,
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.2),
                  offset: const Offset(0, 4),
                  blurRadius: 12,
                ),
              ]
            : [
                BoxShadow(
                  color: colors.shadowDark.withValues(alpha: isDark ? 0.5 : 0.25),
                  offset: const Offset(4, 4),
                  blurRadius: 8,
                ),
                BoxShadow(
                  color: colors.shadowLight.withValues(alpha: isDark ? 0.08 : 0.7),
                  offset: const Offset(-4, -4),
                  blurRadius: 8,
                ),
              ],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        style: GoogleFonts.lora(
          fontSize: 14,
          color: colors.onSurface,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.lora(
            fontSize: 14,
            color: colors.textMuted,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: isFocused ? colors.primary : colors.textMuted,
            size: 22,
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear_rounded,
                    color: colors.textMuted,
                    size: 20,
                  ),
                  onPressed: () {
                    controller.clear();
                    // Trigger rebuild
                    (context as Element).markNeedsBuild();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        onChanged: (_) {
          // Trigger rebuild for suffix icon
          (context as Element).markNeedsBuild();
        },
      ),
    );
  }
}
