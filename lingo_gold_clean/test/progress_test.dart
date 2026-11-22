import 'package:flutter_test/flutter_test.dart';
import 'package:lingo_gold/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    Progress.instance.resetForTests();
  });

  test('lesson completion is recorded by id, not by max index', () async {
    final p = Progress.instance;
    await p.complete(5, true);
    expect(p.completed, 1);
    expect(p.words, 4);
    expect(p.isCompleted(5), isTrue);

    await p.complete(5, true);
    expect(p.completed, 1);
    expect(p.words, 4);
  });

  test('later units stay locked until the previous unit is complete', () async {
    final p = Progress.instance;
    expect(p.isUnlocked(0), isTrue);
    expect(p.isUnlocked(4), isFalse);
    for (var i = 0; i < 4; i++) {
      await p.complete(i, true);
    }
    expect(p.isUnlocked(4), isTrue);
    expect(p.current, 4);
  });

  test('pronunciation score comes from recognized speech only', () {
    expect(speechScore('cat', 'cat'), 100);
    expect(speechScore('cat', ''), 0);
    expect(speechScore('the cat is sleeping', 'the cat is sleeping'), 100);
    expect(speechScore('cat', 'dog') < 100, isTrue);
  });

  test('spaced repetition follows 1, 3, 7, 14 day intervals', () async {
    final p = Progress.instance;
    for (final expected in [1, 3, 7, 14]) {
      await p.recordReview(3, true);
      expect(p.reviewIntervalOf(3), expected);
    }
    await p.recordReview(3, false);
    expect(p.reviewLapsesOf(3), 1);
    expect(p.weakItems(), contains(3));
  });

  test('daily goal uses real minutes spent in lessons', () async {
    final p = Progress.instance;
    await p.addLearningSeconds(150);
    expect(p.todayMinutes, 2);
  });
}
