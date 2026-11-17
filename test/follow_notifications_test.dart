import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quotely_flutter_app/constants/notification_keys.dart';
import 'package:quotely_flutter_app/constants/notification_types.dart';
import 'package:quotely_flutter_app/constants/shared_preference_keys.dart';
import 'package:quotely_flutter_app/services/notification_service.dart';
import 'package:quotely_flutter_app/state_providers/scene_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Records topic calls instead of talking to FCM.
class _Topics {
  final subscribed = <String>[];
  final unsubscribed = <String>[];

  NotificationService get service => NotificationService(
    subscribe: (t) async => subscribed.add(t),
    unsubscribe: (t) async => unsubscribed.add(t),
  );
}

void main() {
  late _Topics topics;

  setUp(() {
    topics = _Topics();
    FollowedAuthors.notifications = () => topics.service;
  });
  tearDown(() => FollowedAuthors.notifications = NotificationService.new);

  Future<FollowedAuthors> notifier(ProviderContainer c) async {
    final n = c.read(followedAuthorsProvider.notifier);
    await n.ready;
    return n;
  }

  group('following an author', () {
    test('subscribes to author_<slug> and unfollowing leaves it', () async {
      SharedPreferences.setMockInitialValues({
        kNotificationDefaultsKey: 'calm',
      });
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final n = await notifier(c);

      await n.toggle('maya-angelou');
      expect(topics.subscribed, ['author_maya-angelou']);
      expect(c.read(followedAuthorsProvider), {'maya-angelou'});
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList(kFollowedAuthorsKey), ['maya-angelou']);

      await n.toggle('maya-angelou');
      expect(topics.unsubscribed, ['author_maya-angelou']);
      expect(c.read(followedAuthorsProvider), isEmpty);
    });

    test('"People you follow" is on by default, even for calm installs', () {
      SharedPreferences.setMockInitialValues({
        kNotificationDefaultsKey: 'calm',
      });
      return SharedPreferences.getInstance().then(
        (prefs) => expect(
          NotificationService.isEnabled(prefs, kNotificationFollowedPeople),
          isTrue,
        ),
      );
    });

    for (final (label, prefs) in [
      ('notifications are off', {kNotificationEnabled: false}),
      ('"People you follow" is off', {kNotificationFollowedPeople: false}),
    ]) {
      test('follows without a push when $label', () async {
        SharedPreferences.setMockInitialValues({
          kNotificationDefaultsKey: 'calm',
          ...prefs,
        });
        final c = ProviderContainer();
        addTearDown(c.dispose);
        final n = await notifier(c);

        await n.toggle('rumi');
        expect(c.read(followedAuthorsProvider), {'rumi'});
        expect(topics.subscribed, isEmpty);

        // Unfollowing always leaves the topic, whatever the switches say.
        await n.toggle('rumi');
        expect(topics.unsubscribed, ['author_rumi']);
      });
    }

    test('a slug FCM would refuse is followed but never subscribed', () async {
      SharedPreferences.setMockInitialValues({});
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final n = await notifier(c);

      await n.toggle('has space');
      expect(c.read(followedAuthorsProvider), {'has space'});
      expect(topics.subscribed, isEmpty);
      expect(NotificationService.authorTopic('has space'), isNull);
      expect(NotificationService.authorTopic('seneca'), 'author_seneca');
    });

    test('a failing FCM call never breaks following', () async {
      SharedPreferences.setMockInitialValues({});
      FollowedAuthors.notifications = () => NotificationService(
        subscribe: (_) => Future.error(Exception('offline')),
      );
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final n = await notifier(c);

      await n.toggle('seneca');
      expect(c.read(followedAuthorsProvider), {'seneca'});
    });
  });

  group('re-sync', () {
    const followed = ['seneca', 'rumi', 'bad slug'];

    test(
      'launch subscribes every followed author when the kind is on',
      () async {
        SharedPreferences.setMockInitialValues({
          kNotificationDefaultsKey: 'calm',
          kFollowedAuthorsKey: followed,
        });
        await topics.service.enableNotificationsBasedOnPreferences();
        expect(
          topics.subscribed,
          containsAll(['author_seneca', 'author_rumi']),
        );
        expect(
          topics.subscribed.where((t) => t.startsWith('author_')),
          hasLength(2),
        );
      },
    );

    test('launch subscribes none when the kind is off', () async {
      SharedPreferences.setMockInitialValues({
        kNotificationDefaultsKey: 'calm',
        kFollowedAuthorsKey: followed,
        kNotificationFollowedPeople: false,
      });
      await topics.service.enableNotificationsBasedOnPreferences();
      expect(topics.subscribed.where((t) => t.startsWith('author_')), isEmpty);
    });

    test('the master switch takes the author topics with it', () async {
      SharedPreferences.setMockInitialValues({
        kNotificationDefaultsKey: 'calm',
        kFollowedAuthorsKey: followed,
      });
      await topics.service.unsubscribeFromAllTopic();
      expect(
        topics.unsubscribed,
        containsAll(['author_seneca', 'author_rumi']),
      );
      await topics.service.subscribeToAllTopic();
      expect(topics.subscribed, containsAll(['author_seneca', 'author_rumi']));
    });

    test('the Settings switch syncs only the author topics', () async {
      SharedPreferences.setMockInitialValues({kFollowedAuthorsKey: followed});
      await topics.service.syncFollowedAuthorTopics(false);
      expect(topics.unsubscribed, ['author_seneca', 'author_rumi']);
      expect(topics.subscribed, isEmpty);
    });
  });

  test('"People you follow" is a quotes kind, kept out of the primer', () {
    final type = kNotificationTypes.singleWhere(
      (t) => t.prefKey == kNotificationFollowedPeople,
    );
    expect(type.group, NotificationGroup.quote);
    expect(type.topic, isNull);
    expect(type.inPrimer, isFalse);
    expect(kNotificationAuthorTopicPrefix, 'author_');
  });
}
