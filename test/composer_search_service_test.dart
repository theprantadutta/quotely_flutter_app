import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:quotely_flutter_app/components/thread/thread_message.dart';
import 'package:quotely_flutter_app/dtos/ask_answer_dto.dart';
import 'package:quotely_flutter_app/dtos/quote_dto.dart';
import 'package:quotely_flutter_app/services/ask_service.dart';
import 'package:quotely_flutter_app/services/composer_search_service.dart';

ThreadMessage _quote(String id, String content) => ThreadMessage.fromQuote(
  QuoteDto(
    id: id,
    author: 'Someone',
    content: content,
    tags: const ['Healing'],
    authorSlug: 'someone',
    length: content.length,
    dateAdded: DateTime.utc(2026),
    dateModified: DateTime.utc(2026),
  ),
);

final _serverAnswer = [
  _quote('s1', 'The wound is the place where the light enters you.'),
];
final _localAnswer = [_quote('l1', 'Courage is grace under pressure.')];

void main() {
  group('ComposerSearchService.askWith', () {
    var localCalls = 0;
    Future<List<ThreadMessage>> local(String _, int _) async {
      localCalls++;
      return _localAnswer;
    }

    setUp(() => localCalls = 0);

    test('online: the server answer is shown and local search is skipped', () async {
      final result = await ComposerSearchService.askWith(
        'something to get me through a breakup',
        limit: 3,
        server: (_, _) async => _serverAnswer,
        local: local,
      );
      expect(result.map((m) => m.itemId), ['s1']);
      expect(localCalls, 0);
    });

    test('offline or any server error falls back to the local search', () async {
      final result = await ComposerSearchService.askWith(
        'starting over',
        limit: 3,
        server: (_, _) async => throw Exception('SocketException: offline'),
        local: local,
      );
      expect(result.map((m) => m.itemId), ['l1']);
      expect(localCalls, 1);
    });

    test('an empty server answer falls back to the local search', () async {
      final result = await ComposerSearchService.askWith(
        'starting over',
        limit: 3,
        server: (_, _) async => const [],
        local: local,
      );
      expect(result.map((m) => m.itemId), ['l1']);
    });

    test('a server that never answers falls back after the timeout', () async {
      final never = Completer<List<ThreadMessage>>();
      final result = await ComposerSearchService.askWith(
        'starting over',
        limit: 3,
        server: (_, _) => never.future,
        local: local,
        timeout: const Duration(milliseconds: 50),
      );
      expect(result.map((m) => m.itemId), ['l1']);
    });

    test('profane server answers are dropped, then local is used', () async {
      final result = await ComposerSearchService.askWith(
        'anything',
        limit: 3,
        server: (_, _) async => [_quote('bad', 'What the fuck is this.')],
        local: local,
      );
      expect(result.map((m) => m.itemId), ['l1']);
    });

    test('the server answer is cut to the limit', () async {
      final result = await ComposerSearchService.askWith(
        'courage',
        limit: 1,
        server: (_, _) async => [
          ..._serverAnswer,
          _quote('s2', 'Hope is a good thing, maybe the best of things.'),
        ],
        local: local,
      );
      expect(result.map((m) => m.itemId), ['s1']);
    });

    test('without a server it is the local search alone', () async {
      final result = await ComposerSearchService.askWith(
        'courage',
        limit: 3,
        local: local,
      );
      expect(result.map((m) => m.itemId), ['l1']);
    });

    test('server and local both failing is an empty answer, not an error', () async {
      final result = await ComposerSearchService.askWith(
        'courage',
        limit: 3,
        server: (_, _) async => throw Exception('500'),
        local: (_, _) async => throw StateError('db closed'),
      );
      expect(result, isEmpty);
    });
  });

  group('AskService.normalize', () {
    test('matches the backend cache key', () {
      expect(
        AskService.normalize('  Quotes about   STARTING over!! '),
        'quotes about starting over',
      );
      expect(
        AskService.normalize('Something to get me through a break-up…'),
        'something to get me through a breakup',
      );
      expect(AskService.normalize('Don’t give up'), 'dont give up');
      expect(AskService.normalize('?!'), '');
    });
  });

  test('AskAnswerDto parses the backend response', () {
    final dto = AskAnswerDto.fromJson({
      'question': 'starting over',
      'source': 'cache',
      'tags': ['New beginnings', 'Moving on'],
      'quotes': [
        {
          'id': 'q1',
          'author': 'Someone',
          'provider': 'Quotable',
          'content': 'Every new beginning comes from some other beginning’s end.',
          'normalizedContent': 'every new beginning',
          'tags': ['New beginnings'],
          'authorSlug': 'someone',
          'length': 58,
          'dateAdded': '2026-01-01T00:00:00Z',
          'dateModified': '2026-01-01T00:00:00Z',
        },
      ],
      'facts': [
        {
          'id': 7,
          'content': 'The oldest known musical instrument is a flute.',
          'aiFactCategory': 'Music',
          'provider': 'Freeway Premium',
          'falseVariant': null,
          'dateAdded': '2026-01-01T00:00:00Z',
          'dateModified': '2026-01-01T00:00:00Z',
        },
      ],
    });
    expect(dto.source, 'cache');
    expect(dto.tags, ['New beginnings', 'Moving on']);
    expect(dto.quotes.single.id, 'q1');
    expect(dto.facts.single.aiFactCategory, 'Music');
  });
}
