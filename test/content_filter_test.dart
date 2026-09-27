import 'package:flutter_test/flutter_test.dart';
import 'package:quotely_flutter_app/util/profanity.dart';

void main() {
  group('isClean rejects broken AI output seen in production', () {
    const broken = [
      'factFactFactFactFactFactFactFactFactFactFact هاري ورزشگاه```json{',
      '{"{":"{","FactFactFactFactFactFactFactńskiegoтельностительности}}}}```json{":"fact: "',
      'Fact‬‬Fact‬ fact‬ **',
      '{"fact": "The first powered, controlled, and sustained flight was made by the Wright brothers."}',
    ];
    for (final text in broken) {
      test(text.length > 20 ? text.substring(0, 20) : text, () => expect(isClean(text), isFalse));
    }

    test('a runaway answer thousands of characters long', () {
      expect(isClean('The first commercial airliner was indeed ' * 60), isFalse);
    });
  });

  group('isClean keeps real content', () {
    const good = [
      'Never, never, never give up.',
      'And yet it moves.',
      "The Canadian city of Lloydminster straddles the border between Alberta and Saskatchewan, so it has two provincial governments, two area codes and a border that runs down its main street; residents pay Alberta's lower taxes.",
      'Bananas are berries, but strawberries are not.',
      'I am not in danger, Skyler. I am the danger.',
      "Hope is a good thing, maybe the best of things, and no good thing ever dies.",
    ];
    for (final text in good) {
      test(text.length > 20 ? text.substring(0, 20) : text, () => expect(isClean(text), isTrue));
    }
  });

  test('masked profanity is caught', () {
    expect(isClean("So let's kick the sh** out of option B."), isFalse);
  });
}
