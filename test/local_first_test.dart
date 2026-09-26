import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:quotely_flutter_app/services/local_first.dart';

void main() {
  test('local data is returned at once and refreshed in the background', () async {
    final remote = Completer<List<int>>();
    var remoteCalls = 0;
    final result = await LocalFirst.load<List<int>>(
      key: 'test:cached',
      local: () async => [1, 2],
      remote: () {
        remoteCalls++;
        return remote.future;
      },
      isEmpty: (v) => v.isEmpty,
    );
    // Returned without waiting for the backend...
    expect(result, [1, 2]);
    // ...which was still asked, in the background.
    expect(remoteCalls, 1);
    remote.complete([3]);
  });

  test('an empty local copy waits for the backend', () async {
    final result = await LocalFirst.load<List<int>>(
      key: 'test:empty',
      local: () async => [],
      remote: () async => [7, 8],
      isEmpty: (v) => v.isEmpty,
    );
    expect(result, [7, 8]);
  });

  test('a failed local read falls through to the backend', () async {
    final result = await LocalFirst.load<List<int>>(
      key: 'test:local-throws',
      local: () async => throw StateError('db closed'),
      remote: () async => [5],
      isEmpty: (v) => v.isEmpty,
    );
    expect(result, [5]);
  });

  test('backend failure with an empty local copy returns it', () async {
    // Same as the old fallback: the screen shows its empty state.
    final result = await LocalFirst.load<List<int>>(
      key: 'test:empty-offline',
      local: () async => [],
      remote: () async => throw Exception('offline'),
      isEmpty: (v) => v.isEmpty,
    );
    expect(result, isEmpty);
  });

  test('local and backend both failing surfaces the error', () async {
    expect(
      LocalFirst.load<List<int>>(
        key: 'test:both-fail',
        local: () async => throw StateError('db closed'),
        remote: () async => throw Exception('offline'),
        isEmpty: (v) => v.isEmpty,
      ),
      throwsException,
    );
  });

  test('background refreshes are throttled per key', () async {
    var remoteCalls = 0;
    Future<List<int>> load() => LocalFirst.load<List<int>>(
      key: 'test:throttle',
      local: () async => [1],
      remote: () async {
        remoteCalls++;
        return [2];
      },
      isEmpty: (v) => v.isEmpty,
    );
    await load();
    await Future<void>.delayed(Duration.zero);
    await load();
    await load();
    expect(remoteCalls, 1);
  });
}
