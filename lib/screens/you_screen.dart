import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../components/thread/thread.dart';
import '../constants/notification_types.dart';
import '../constants/shared_preference_keys.dart';
import '../dtos/media_title_dto.dart';
import '../navigation/routes.dart';
import '../services/activity_service.dart';
import '../services/notification_service.dart';
import '../state_providers/profile.dart';
import '../state_providers/scene_state.dart';
import '../state_providers/user_interests.dart';
import 'offline_library_screen.dart';
import 'settings_notification_screen.dart' show formatMinutes;

/// You: streak, preferences and the app's small print. Replaces the old
/// Settings tab; reached from the avatar on Today.
class YouScreen extends ConsumerStatefulWidget {
  const YouScreen({super.key});

  @override
  ConsumerState<YouScreen> createState() => _YouScreenState();
}

class _YouScreenState extends ConsumerState<YouScreen> {
  ActivitySummary? _activity;
  String? _version;
  String _notificationSummary = '';
  double? _offline;

  @override
  void initState() {
    super.initState();
    ActivityService.instance.changes.addListener(_loadActivity);
    _loadActivity();
    _loadMeta();
  }

  @override
  void dispose() {
    ActivityService.instance.changes.removeListener(_loadActivity);
    super.dispose();
  }

  Future<void> _loadActivity() async {
    final a = await ActivityService.instance.summary();
    if (mounted) setState(() => _activity = a);
  }

  /// Re-read when coming back from a sub-screen (notifications, offline).
  Future<void> _loadMeta() async {
    final info = await PackageInfo.fromPlatform();
    final prefs = await SharedPreferences.getInstance();
    final quiet = await NotificationService.quietHours();
    final offline = await offlineLibraryProgress();
    if (!mounted) return;
    final master = prefs.getBool(kNotificationEnabled) ?? true;
    final on = master
        ? kNotificationTypes
              .where((t) => prefs.getBool(t.prefKey) ?? true)
              .length
        : 0;
    final quietText = quiet.enabled
        ? ' · quiet ${formatMinutes(context, quiet.start)} – ${formatMinutes(context, quiet.end)}'
        : '';
    setState(() {
      _version = 'v${info.version}';
      _notificationSummary = '$on of ${kNotificationTypes.length} on$quietText';
      _offline = offline;
    });
  }

  Future<void> _go(String route, {Object? extra}) async {
    await context.push(route, extra: extra);
    _loadMeta();
  }

  String _interestsSummary(List<String> interests, List<MediaType> screen) {
    final all = [for (final t in screen) t.plural, ...interests];
    if (all.isEmpty) return 'Pick what we talk about';
    final shown = all.take(3).map((s) => s[0].toUpperCase() + s.substring(1));
    final more = all.length > 3 ? '…' : '';
    return '${all.length} topics · ${shown.join(', ')}$more';
  }

  List<StreakDay> _week(ActivitySummary a) => [
    for (var i = 0; i < 7; i++)
      if (a.week[i])
        StreakDay.done
      else if (i == a.todayIndex)
        StreakDay.today
      else if (i < a.todayIndex)
        StreakDay.missed
      else
        StreakDay.future,
  ];

  Future<void> _editNickname() async {
    final controller = TextEditingController(text: ref.read(nicknameProvider));
    final value = await showQSheet<String>(
      context,
      builder: (sheet) => QSheetFrame(
        title: 'What should we call you?',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Only used for the avatar on Today. Stays on this device.',
              style: sheet.qt.body,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              onSubmitted: (v) => Navigator.of(sheet).pop(v),
              decoration: const InputDecoration(hintText: 'Nickname'),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Save',
              onPressed: () => Navigator.of(sheet).pop(controller.text),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (value != null) await ref.read(nicknameProvider.notifier).set(value);
  }

  @override
  Widget build(BuildContext context) {
    final a = _activity;
    final interests = ref.watch(userInterestsProvider);
    final screen = ref.watch(screenInterestsProvider);
    final nickname = ref.watch(nicknameProvider);
    final nf = NumberFormat.decimalPattern();

    return ThreadPage(
      title: 'You',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          if (a != null)
            StreakCard(
              streak: a.streak,
              summary:
                  '${nf.format(a.quotes)} quotes, ${nf.format(a.scenes)} scenes and ${nf.format(a.facts)} facts read',
              week: _week(a),
            )
          else
            const SizedBox(height: 150),
          const SizedBox(height: 14),
          GroupedList(
            children: [
              GroupedRow(
                title: 'Your name',
                description: nickname ?? 'Add a nickname for your avatar',
                chevron: true,
                onTap: _editNickname,
              ),
              GroupedRow(
                title: 'Your interests',
                description: _interestsSummary(interests, screen),
                chevron: true,
                onTap: () => _go(Routes.interests, extra: true),
              ),
              GroupedRow(
                title: 'Appearance',
                description: 'Theme, accent, text size',
                chevron: true,
                onTap: () => _go(Routes.appearance),
              ),
              GroupedRow(
                title: 'Notifications',
                description: _notificationSummary,
                chevron: true,
                onTap: () => _go(Routes.notifications),
              ),
              GroupedRow(
                title: 'Offline library',
                description: _offline == null
                    ? ''
                    : '${(_offline! * 100).round()}% downloaded',
                chevron: true,
                onTap: () => _go(Routes.offlineLibrary),
              ),
              GroupedRow(
                title: 'Support Quotely',
                description: 'Buy the maker a coffee',
                chevron: true,
                onTap: () => _go(Routes.support),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GroupedList(
            children: [
              GroupedRow(
                title: 'Past messages',
                chevron: true,
                onTap: () => _go(Routes.pastMessages),
              ),
              GroupedRow(
                title: 'Terms & conditions',
                chevron: true,
                onTap: () => showLegalSheet(
                  context,
                  title: 'Terms & conditions',
                  file: kTermsFile,
                ),
              ),
              GroupedRow(
                title: 'Privacy policy',
                chevron: true,
                onTap: () => showLegalSheet(
                  context,
                  title: 'Privacy policy',
                  file: kPrivacyFile,
                ),
              ),
              GroupedRow(
                title: 'About Quotely',
                trailing: Text(
                  _version ?? '',
                  style: context.qt.rowTitle.copyWith(color: context.q.mute),
                ),
                onTap: () => showAboutQuotely(context),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Center(
            child: GestureDetector(
              // Debug builds: long-press for the component gallery.
              onLongPress: kDebugMode
                  ? () => context.push(Routes.debugComponents)
                  : null,
              child: Text(
                'Made by Pranta Dutta',
                style: context.qt.label.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// About sheet: icon, version, blurb, maker link, image credits, ©.
Future<void> showAboutQuotely(BuildContext context) async {
  final info = await PackageInfo.fromPlatform();
  if (!context.mounted) return;
  final year = DateFormat('yyyy').format(DateTime.now());
  await showQSheet(
    context,
    builder: (sheet) {
      final t = sheet.q;
      return QSheetFrame(
        child: Column(
          children: [
            const BrandIcon(size: 84, radius: 19),
            const SizedBox(height: 16),
            Text('Quotely', style: sheet.qt.titleDetail),
            const SizedBox(height: 4),
            Text('VERSION ${info.version}', style: sheet.qt.overline),
            const SizedBox(height: 16),
            Text(
              'Wisdom, one line at a time. Quotes from thinkers, and lines '
              'from films, shows, anime and games.',
              textAlign: TextAlign.center,
              style: sheet.qt.body,
            ),
            const SizedBox(height: 6),
            HitTarget(
              semanticLabel: 'Made by Pranta Dutta, opens pranta.dev',
              onTap: () => launchUrl(
                Uri.parse('https://pranta.dev'),
                mode: LaunchMode.externalApplication,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Made by Pranta Dutta',
                    style: sheet.qt.chip.copyWith(color: t.accInk),
                  ),
                  const SizedBox(width: 5),
                  Icon(Icons.north_east_rounded, size: 15, color: t.accInk),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Poster and cover art credits, as each provider's terms require.
            Text(
              'This product uses the TMDB API but is not endorsed or certified by TMDB. '
              'Anime data and cover art from AniList.',
              textAlign: TextAlign.center,
              style: sheet.qt.caption,
            ),
            GestureDetector(
              onTap: () => launchUrl(
                Uri.parse('https://rawg.io'),
                mode: LaunchMode.externalApplication,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  'Game data and images from RAWG',
                  style: sheet.qt.caption.copyWith(
                    color: t.accInk,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '© $year Pranta Dutta. All rights reserved.',
              style: sheet.qt.caption.copyWith(color: t.mute),
            ),
            const SizedBox(height: 16),
            SecondaryButton(
              label: 'Close',
              onPressed: () => Navigator.of(sheet).pop(),
            ),
          ],
        ),
      );
    },
  );
}
