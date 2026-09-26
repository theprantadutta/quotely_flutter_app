import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../components/thread/thread.dart';
import '../dtos/media_title_dto.dart';
import '../dtos/quote_dto.dart';
import '../dtos/scene_quote_dto.dart';
import '../navigation/routes.dart';

/// Welcome: three pages, each a small live preview that builds itself.
class OnboardingScreen extends StatefulWidget {
  static const kRouteName = Routes.onboarding;
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pages = PageController();
  int _page = 0;
  Timer? _auto;
  bool _touched = false;

  static const _copy = [
    (
      'Wisdom, one line at a time.',
      'Quotes from thinkers, and lines from films, shows, anime and games.',
    ),
    (
      'Every screen has a line worth keeping.',
      'Movies, TV, anime and games, with a spoiler shield that has your back.',
    ),
    (
      'A line a day, right on time.',
      'Quote of the day, Friday night lines and a weird fact on Wednesdays. You choose.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    FlutterNativeSplash.remove();
    // Gently show the other pages until the user takes over.
    _auto = Timer.periodic(const Duration(seconds: 6), (_) {
      if (_touched || !_pages.hasClients) return;
      final next = (_page + 1) % _copy.length;
      _pages.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _auto?.cancel();
    _pages.dispose();
    super.dispose();
  }

  // Marks onboarding complete and moves on to the interest picker.
  Future<void> _finish() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('hasSeenOnboarding', true);
    await preferences.setBool('onboardingShown', true);
    if (mounted) context.pushReplacement(Routes.interests);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    final copy = _copy[_page];
    return PageBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ThreadColumn(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 4, 12, 0),
                    child: QTextButton(label: 'Skip', onPressed: _finish),
                  ),
                ),
                Expanded(
                  child: Listener(
                    onPointerDown: (_) => _touched = true,
                    child: PageView(
                      controller: _pages,
                      onPageChanged: (i) => setState(() => _page = i),
                      children: const [
                        _MiniThread(page: 0),
                        _MiniThread(page: 1),
                        _MiniThread(page: 2),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Column(
                          key: ValueKey(_page),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Semantics(
                              header: true,
                              child: Text(
                                copy.$1,
                                style: context.qt.displayOnboarding,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              copy.$2,
                              style: context.qt.body.copyWith(fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      Semantics(
                        label: 'Page ${_page + 1} of ${_copy.length}',
                        child: Row(
                          children: [
                            for (var i = 0; i < _copy.length; i++) ...[
                              if (i > 0) const SizedBox(width: 6),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                width: i == _page ? 22 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: i == _page ? t.acc : t.line,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      PrimaryButton(label: 'Get started', onPressed: _finish),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

SceneQuoteDto _scene(
  String line,
  String character,
  String title,
  MediaType type,
  int year,
) {
  final d = DateTime.utc(2026);
  return SceneQuoteDto(
    id: 'onboarding-$character',
    content: line,
    titleId: 'onboarding',
    titleName: title,
    titleType: type,
    titleYear: year,
    characterId: character,
    characterName: character,
    tags: const [],
    dateAdded: d,
    dateModified: d,
  );
}

QuoteDto _quote(String text, String author) {
  final d = DateTime.utc(2026);
  return QuoteDto(
    id: 'onboarding-$author',
    author: author,
    content: text,
    tags: const [],
    authorSlug: '',
    length: text.length,
    dateAdded: d,
    dateModified: d,
  );
}

/// A static demo thread. Not interactive: taps would lead into the app
/// before onboarding is done.
class _MiniThread extends StatelessWidget {
  final int page;
  const _MiniThread({required this.page});

  @override
  Widget build(BuildContext context) {
    final items = switch (page) {
      0 => <Widget>[
        MessageBubble(
          message: ThreadMessage.fromQuote(
            _quote(
              'It always seems impossible until it’s done.',
              'Nelson Mandela',
            ),
          ),
          showSender: false,
          trackView: false,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 24),
          child: MessageBubble(
            message: ThreadMessage.fromScene(
              _scene(
                'Just keep swimming.',
                'Dory',
                'Finding Nemo',
                MediaType.movie,
                2003,
              ),
            ),
            showSender: false,
            trackView: false,
          ),
        ),
        const SystemPill('True or false? Today’s weird law is in'),
      ],
      1 => <Widget>[
        MessageBubble(
          message: ThreadMessage.fromScene(
            _scene(
              'Do or do not. There is no try.',
              'Yoda',
              'The Empire Strikes Back',
              MediaType.movie,
              1980,
            ),
          ),
          trackView: false,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 24),
          child: MessageBubble(
            message: ThreadMessage.fromScene(
              _scene(
                'I’m going to be King of the Pirates!',
                'Luffy',
                'One Piece',
                MediaType.anime,
                1999,
              ),
            ),
            trackView: false,
          ),
        ),
        const SystemPill('Spoiler shield on', icon: Icons.shield_rounded),
      ],
      _ => <Widget>[
        const TimeDivider('8:00 AM · Quote of the day'),
        MessageBubble(
          message: ThreadMessage.fromQuote(
            _quote('Well done is better than well said.', 'Benjamin Franklin'),
          ),
          trackView: false,
        ),
        const TimeDivider('7:00 PM · Friday night lines'),
        MessageBubble(
          message: ThreadMessage.fromScene(
            _scene(
              'Life moves pretty fast.',
              'Ferris Bueller',
              'Ferris Bueller’s Day Off',
              MediaType.movie,
              1986,
            ),
          ),
          trackView: false,
        ),
      ],
    };
    return IgnorePointer(
      child: Center(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < items.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Entrance(
                    index: i + 1,
                    stagger: const Duration(milliseconds: 380),
                    child: items[i],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
