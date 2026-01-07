import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quotely_flutter_app/constants/notification_keys.dart';
import 'package:quotely_flutter_app/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/shared_preference_keys.dart';
import '../theme/colors/app_colors.dart';
import '../theme/gradients/app_gradients.dart';
import 'daily_brain_food_screen.dart';
import 'daily_inspiration_screen.dart';
import 'fact_of_the_day_screen.dart';
import 'motivation_monday_screen.dart';
import 'quote_of_the_day_screen.dart';
import 'weird_fact_wednesday_screen.dart';

class SettingsNotificationScreen extends StatefulWidget {
  static const kRouteName = '/settings-notification';
  const SettingsNotificationScreen({super.key});

  @override
  State<SettingsNotificationScreen> createState() =>
      _SettingsNotificationState();
}

class _SettingsNotificationState extends State<SettingsNotificationScreen> {
  final Map<String, bool> _notifications = {
    kNotificationEnabled: true,
    kNotificationMotivation: true,
    kNotificationDailyInspiration: true,
    kNotificationQuoteOfTheDay: true,
    kNotificationFactOfTheDay: true,
    kNotificationDailyBrainFood: true,
    kNotificationWeirdFactWednesday: true,
  };

  SharedPreferences? _sharedPreferences;

  @override
  void initState() {
    super.initState();
    _initializeSharedPreferences();
  }

  Future<void> _initializeSharedPreferences() async {
    _sharedPreferences = await SharedPreferences.getInstance();
    setState(() {
      _notifications.forEach((key, _) {
        _notifications[key] =
            _sharedPreferences?.getBool(key) ?? _notifications[key]!;
      });
    });
  }

  Future<void> _onNotificationSwitched(
    String key,
    String topic,
    bool value,
  ) async {
    HapticFeedback.lightImpact();
    final service = NotificationService();

    if (key == kNotificationEnabled) {
      setState(() {
        _notifications.forEach((notificationKey, _) {
          _notifications[notificationKey] = value;
        });
      });
      await _sharedPreferences?.setBool(kNotificationEnabled, value);

      if (value) {
        await service.subscribeToAllTopic();
      } else {
        await service.unsubscribeFromAllTopic();
      }

      for (final notificationKey in _notifications.keys) {
        await _sharedPreferences?.setBool(notificationKey, value);
      }
    } else {
      setState(() {
        _notifications[key] = value;
      });
      await _sharedPreferences?.setBool(key, value);

      if (value) {
        await service.subscribeToTopic(topic);
      } else {
        await service.unsubscribeFromTopic(topic);
      }
    }
  }

  void _gotoScreen(BuildContext context, String route) {
    try {
      HapticFeedback.lightImpact();
      context.push(route);
    } catch (e) {
      if (kDebugMode) {
        print('Error navigating to: $route - $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;
    final bool areNotificationsEnabled = _notifications[kNotificationEnabled]!;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppGradients.scaffoldBackground(context),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(context, colors, isDark),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),

                      // Master switch
                      _NeumorphicMasterSwitch(
                        title: 'Enable Notifications',
                        subtitle: 'Master switch for all Quotely alerts',
                        value: areNotificationsEnabled,
                        onChanged: (value) => _onNotificationSwitched(
                          kNotificationEnabled,
                          kNotificationAllTopic,
                          value,
                        ),
                        colors: colors,
                        isDark: isDark,
                      ),

                      const SizedBox(height: 24),

                      // Quote toggles
                      _buildSectionHeader('Quote Notifications', colors),
                      const SizedBox(height: 12),
                      IgnorePointer(
                        ignoring: !areNotificationsEnabled,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: areNotificationsEnabled ? 1.0 : 0.5,
                          child: _NeumorphicToggleGroup(
                            colors: colors,
                            isDark: isDark,
                            items: [
                              _ToggleItem(
                                title: 'Quote of the Day',
                                icon: Icons.format_quote_rounded,
                                value: _notifications[kNotificationQuoteOfTheDay]!,
                                onChanged: (v) => _onNotificationSwitched(
                                  kNotificationQuoteOfTheDay,
                                  kNotificationQuoteOfTheDayTopic,
                                  v,
                                ),
                              ),
                              _ToggleItem(
                                title: 'Daily Inspiration',
                                icon: Icons.wb_sunny_rounded,
                                value: _notifications[kNotificationDailyInspiration]!,
                                onChanged: (v) => _onNotificationSwitched(
                                  kNotificationDailyInspiration,
                                  kNotificationDailyInspirationTopic,
                                  v,
                                ),
                              ),
                              _ToggleItem(
                                title: 'Motivation Monday',
                                icon: Icons.rocket_launch_rounded,
                                value: _notifications[kNotificationMotivation]!,
                                onChanged: (v) => _onNotificationSwitched(
                                  kNotificationMotivation,
                                  kNotificationMotivationMondayTopic,
                                  v,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Fact toggles
                      _buildSectionHeader('Fact Notifications', colors),
                      const SizedBox(height: 12),
                      IgnorePointer(
                        ignoring: !areNotificationsEnabled,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: areNotificationsEnabled ? 1.0 : 0.5,
                          child: _NeumorphicToggleGroup(
                            colors: colors,
                            isDark: isDark,
                            items: [
                              _ToggleItem(
                                title: 'Fact of the Day',
                                icon: Icons.lightbulb_rounded,
                                value: _notifications[kNotificationFactOfTheDay]!,
                                onChanged: (v) => _onNotificationSwitched(
                                  kNotificationFactOfTheDay,
                                  kNotificationFactOfTheDayTopic,
                                  v,
                                ),
                              ),
                              _ToggleItem(
                                title: 'Daily Brain Food',
                                icon: Icons.psychology_rounded,
                                value: _notifications[kNotificationDailyBrainFood]!,
                                onChanged: (v) => _onNotificationSwitched(
                                  kNotificationDailyBrainFood,
                                  kNotificationDailyBrainFoodTopic,
                                  v,
                                ),
                              ),
                              _ToggleItem(
                                title: 'Weird Fact Wednesday',
                                icon: Icons.science_rounded,
                                value: _notifications[kNotificationWeirdFactWednesday]!,
                                onChanged: (v) => _onNotificationSwitched(
                                  kNotificationWeirdFactWednesday,
                                  kNotificationWeirdFactWednesdayTopic,
                                  v,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Quick access
                      _buildSectionHeader('Quick Access', colors),
                      const SizedBox(height: 12),
                      _NeumorphicQuickAccessGroup(
                        colors: colors,
                        isDark: isDark,
                        items: [
                          _QuickAccessItem(
                            title: 'Quote of the Day',
                            icon: Icons.format_quote_rounded,
                            onTap: () => _gotoScreen(context, QuoteOfTheDayScreen.kRouteName),
                          ),
                          _QuickAccessItem(
                            title: 'Daily Inspiration',
                            icon: Icons.wb_sunny_rounded,
                            onTap: () => _gotoScreen(context, DailyInspirationScreen.kRouteName),
                          ),
                          _QuickAccessItem(
                            title: 'Motivation Monday',
                            icon: Icons.rocket_launch_rounded,
                            onTap: () => _gotoScreen(context, MotivationMondayScreen.kRouteName),
                          ),
                          _QuickAccessItem(
                            title: 'Fact of the Day',
                            icon: Icons.lightbulb_rounded,
                            onTap: () => _gotoScreen(context, FactOfTheDayScreen.kRouteName),
                          ),
                          _QuickAccessItem(
                            title: 'Daily Brain Food',
                            icon: Icons.psychology_rounded,
                            onTap: () => _gotoScreen(context, DailyBrainFoodScreen.kRouteName),
                          ),
                          _QuickAccessItem(
                            title: 'Weird Fact Wednesday',
                            icon: Icons.science_rounded,
                            onTap: () => _gotoScreen(context, WeirdFactWednesdayScreen.kRouteName),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppColorScheme colors, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 16, 20, 16),
      child: Row(
        children: [
          _NeumorphicBackButton(
            colors: colors,
            isDark: isDark,
            onTap: () {
              HapticFeedback.lightImpact();
              context.pop();
            },
          ),
          const SizedBox(width: 12),
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
                Icons.notifications_rounded,
                color: colors.onPrimary,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notifications',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
                Text(
                  'Manage your alerts',
                  style: GoogleFonts.lora(
                    fontSize: 12,
                    color: colors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, AppColorScheme colors) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.lora(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: colors.textMuted,
      ),
    );
  }
}

class _NeumorphicBackButton extends StatefulWidget {
  final AppColorScheme colors;
  final bool isDark;
  final VoidCallback onTap;

  const _NeumorphicBackButton({
    required this.colors,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_NeumorphicBackButton> createState() => _NeumorphicBackButtonState();
}

class _NeumorphicBackButtonState extends State<_NeumorphicBackButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: widget.colors.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          boxShadow: _isPressed
              ? []
              : [
                  BoxShadow(
                    color: widget.colors.shadowDark
                        .withValues(alpha: widget.isDark ? 0.5 : 0.25),
                    offset: const Offset(3, 3),
                    blurRadius: 6,
                  ),
                  BoxShadow(
                    color: widget.colors.shadowLight
                        .withValues(alpha: widget.isDark ? 0.08 : 0.7),
                    offset: const Offset(-3, -3),
                    blurRadius: 6,
                  ),
                ],
        ),
        child: Center(
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: widget.colors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _NeumorphicMasterSwitch extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final AppColorScheme colors;
  final bool isDark;

  const _NeumorphicMasterSwitch({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.colors,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.primary.withValues(alpha: 0.15),
            colors.primaryDark.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colors.primary, colors.primaryDark],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.notifications_active_rounded,
              color: colors.onPrimary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.lora(
                    fontSize: 12,
                    color: colors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: colors.primary,
            activeTrackColor: colors.primary.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }
}

class _ToggleItem {
  final String title;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  _ToggleItem({
    required this.title,
    required this.icon,
    required this.value,
    required this.onChanged,
  });
}

class _NeumorphicToggleGroup extends StatelessWidget {
  final AppColorScheme colors;
  final bool isDark;
  final List<_ToggleItem> items;

  const _NeumorphicToggleGroup({
    required this.colors,
    required this.isDark,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.shadowDark.withValues(alpha: isDark ? 0.4 : 0.2),
            offset: const Offset(4, 4),
            blurRadius: 8,
          ),
          BoxShadow(
            color: colors.shadowLight.withValues(alpha: isDark ? 0.06 : 0.6),
            offset: const Offset(-4, -4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isLast = index == items.length - 1;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      item.icon,
                      size: 20,
                      color: item.value ? colors.primary : colors.textMuted,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.title,
                        style: GoogleFonts.lora(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: colors.onSurface,
                        ),
                      ),
                    ),
                    Switch(
                      value: item.value,
                      onChanged: item.onChanged,
                      activeThumbColor: colors.primary,
                      activeTrackColor: colors.primary.withValues(alpha: 0.3),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  indent: 52,
                  color: colors.textMuted.withValues(alpha: 0.2),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _QuickAccessItem {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  _QuickAccessItem({
    required this.title,
    required this.icon,
    required this.onTap,
  });
}

class _NeumorphicQuickAccessGroup extends StatelessWidget {
  final AppColorScheme colors;
  final bool isDark;
  final List<_QuickAccessItem> items;

  const _NeumorphicQuickAccessGroup({
    required this.colors,
    required this.isDark,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.shadowDark.withValues(alpha: isDark ? 0.4 : 0.2),
            offset: const Offset(4, 4),
            blurRadius: 8,
          ),
          BoxShadow(
            color: colors.shadowLight.withValues(alpha: isDark ? 0.06 : 0.6),
            offset: const Offset(-4, -4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isLast = index == items.length - 1;

          return Column(
            children: [
              InkWell(
                onTap: item.onTap,
                borderRadius: isLast
                    ? const BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      )
                    : index == 0
                        ? const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          )
                        : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Icon(
                        item.icon,
                        size: 20,
                        color: colors.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.title,
                          style: GoogleFonts.lora(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: colors.onSurface,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: colors.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  indent: 52,
                  color: colors.textMuted.withValues(alpha: 0.2),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
