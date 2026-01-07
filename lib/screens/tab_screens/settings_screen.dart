// ignore_for_file: use_build_context_synchronously

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../components/settings_screen/appearance/appearance_screen.dart';
import '../../components/shared/neumorphic_card.dart';
import '../../theme/colors/app_colors.dart';
import '../../theme/gradients/app_gradients.dart';
import '../settings_download_everything_screen.dart';
import '../settings_notification_screen.dart';
import '../support_us_screen.dart';

class SettingsScreen extends StatelessWidget {
  static const kRouteName = '/settings';
  const SettingsScreen({super.key});

  void _gotoScreen(BuildContext context, String route) {
    try {
      Future.delayed(Duration.zero, () async {
        context.push(route);
      });
    } catch (e) {
      if (kDebugMode) {
        print('Something Went Wrong when going to screen: $route');
        print(e);
      }
    }
  }

  Future<void> _showLegalDialog(
    BuildContext context, {
    required String title,
    required String filePath,
  }) async {
    final String markdownContent = await rootBundle.loadString(filePath);
    final theme = Theme.of(context);

    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20.0,
            vertical: 24.0,
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: MediaQuery.of(context).size.height * 0.6,
            child: SingleChildScrollView(
              child: MarkdownBody(
                data: markdownContent,
                styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                  p: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                  h1: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
          actionsPadding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 8.0,
          ),
        );
      },
    );
  }

  Future<void> _showAboutSheet(BuildContext context) async {
    final platform = await PackageInfo.fromPlatform();
    final version = platform.version;
    final currentYear = DateFormat('yyyy').format(DateTime.now());
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            // App icon with glow
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppGradients.sunsetWarmth(context),
                boxShadow: [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Image.asset(
                'assets/play_store_icon.png',
                height: 64,
                width: 64,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Quotely',
              style: GoogleFonts.playfairDisplay(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Version $version',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Daily doses of wisdom and inspiration',
              style: TextStyle(
                fontSize: 14,
                color: colors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Developer credit
            GestureDetector(
              onTap: () async {
                final url = Uri.parse('https://pranta.dev');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: AppGradients.warmPrimary(context),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Made with ',
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.onSurface,
                      ),
                    ),
                    Icon(
                      Icons.favorite,
                      size: 16,
                      color: colors.error,
                    ),
                    Text(
                      ' by Pranta Dutta',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.open_in_new_rounded,
                      size: 14,
                      color: colors.primary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '© $currentYear Pranta Dutta. All rights reserved.',
              style: TextStyle(
                fontSize: 11,
                color: colors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header ---
            _buildHeader(context, colors),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Profile Card Placeholder ---
                  _buildProfileCard(context, colors, isDark),
                  const SizedBox(height: 32),

                  // --- Personalization Section ---
                  _buildSectionTitle(context, 'Personalization'),
                  const SizedBox(height: 12),
                  _buildSettingsGroup(
                    context,
                    colors,
                    isDark,
                    children: [
                      NeumorphicSettingsTile(
                        icon: Icons.palette_outlined,
                        title: 'Appearance',
                        subtitle: 'Theme, typography, layout',
                        iconColor: colors.primary,
                        onTap: () => _gotoScreen(context, AppearanceScreen.kRouteName),
                      ),
                      _buildDivider(colors),
                      NeumorphicSettingsTile(
                        icon: Icons.notifications_none_rounded,
                        title: 'Notifications',
                        subtitle: 'Manage daily reminders',
                        iconColor: colors.accent,
                        onTap: () => _gotoScreen(context, SettingsNotificationScreen.kRouteName),
                      ),
                      _buildDivider(colors),
                      NeumorphicSettingsTile(
                        icon: Icons.cloud_download_outlined,
                        title: 'Offline Mode',
                        subtitle: 'Download for offline use',
                        iconColor: colors.secondary,
                        onTap: () => _gotoScreen(context, SettingsDownloadEverythingScreen.kRouteName),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // --- Support & Info Section ---
                  _buildSectionTitle(context, 'Support & Info'),
                  const SizedBox(height: 12),
                  _buildSettingsGroup(
                    context,
                    colors,
                    isDark,
                    children: [
                      NeumorphicSettingsTile(
                        icon: Icons.favorite_border_rounded,
                        title: 'Support Quotely',
                        subtitle: 'Help us grow',
                        iconColor: colors.error,
                        onTap: () => _gotoScreen(context, SupportUsScreen.kRouteName),
                      ),
                      _buildDivider(colors),
                      NeumorphicSettingsTile(
                        icon: Icons.article_outlined,
                        title: 'Terms & Conditions',
                        subtitle: 'Our terms of service',
                        iconColor: colors.onSurfaceVariant,
                        onTap: () => _showLegalDialog(
                          context,
                          title: 'Terms & Conditions',
                          filePath: 'assets/legal/terms.md',
                        ),
                      ),
                      _buildDivider(colors),
                      NeumorphicSettingsTile(
                        icon: Icons.shield_outlined,
                        title: 'Privacy Policy',
                        subtitle: 'How we handle your data',
                        iconColor: colors.onSurfaceVariant,
                        onTap: () => _showLegalDialog(
                          context,
                          title: 'Privacy Policy',
                          filePath: 'assets/legal/privacy.md',
                        ),
                      ),
                      _buildDivider(colors),
                      NeumorphicSettingsTile(
                        icon: Icons.info_outline_rounded,
                        title: 'About Quotely',
                        subtitle: 'Version info & credits',
                        iconColor: colors.primary,
                        onTap: () => _showAboutSheet(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // --- Footer ---
                  _buildFooter(context, colors),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppColorScheme colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      decoration: BoxDecoration(
        gradient: AppGradients.sunsetWarmth(context),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.settings_rounded,
            size: 40,
            color: colors.primary.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 8),
          Text(
            'Settings',
            style: GoogleFonts.playfairDisplay(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(
    BuildContext context,
    AppColorScheme colors,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.shadowDark.withValues(alpha: isDark ? 0.5 : 0.25),
            offset: const Offset(5, 5),
            blurRadius: 10,
          ),
          BoxShadow(
            color: colors.shadowLight.withValues(alpha: isDark ? 0.08 : 0.7),
            offset: const Offset(-5, -5),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colors.primary, colors.accentSecondary],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                Icons.format_quote_rounded,
                size: 28,
                color: colors.onPrimary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, Seeker',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '"Discover your daily wisdom"',
                  style: GoogleFonts.lora(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;

    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
          color: colors.textMuted,
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(
    BuildContext context,
    AppColorScheme colors,
    bool isDark, {
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.shadowDark.withValues(alpha: isDark ? 0.5 : 0.25),
            offset: const Offset(5, 5),
            blurRadius: 10,
          ),
          BoxShadow(
            color: colors.shadowLight.withValues(alpha: isDark ? 0.08 : 0.7),
            offset: const Offset(-5, -5),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildDivider(AppColorScheme colors) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 76,
      color: colors.outlineVariant.withValues(alpha: 0.5),
    );
  }

  Widget _buildFooter(BuildContext context, AppColorScheme colors) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final version = snapshot.data?.version ?? '...';
        return Center(
          child: Column(
            children: [
              Icon(
                Icons.format_quote_rounded,
                size: 24,
                color: colors.textMuted.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 8),
              Text(
                'Quotely v$version',
                style: TextStyle(
                  fontSize: 12,
                  color: colors.textMuted,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Made with love for quote enthusiasts',
                style: TextStyle(
                  fontSize: 11,
                  color: colors.textMuted.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
