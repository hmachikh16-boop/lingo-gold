import 'package:flutter_test/flutter_test.dart';
import 'package:lingo_gold/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Progress.instance.reset();
  });

  test('curriculum contains 4 lessons of 30 steps', () async {
    final c = await Curriculum.load();
    expect(c.lessons.length, 4);
    expect(c.lessons.fold<int>(0, (s, l) => s + l.steps.length), 120);
    expect(c.srsIntervals, [1, 2, 4, 8, 16]);
    expect(c.lessons.first.steps.first.type, 'choose_image');
    expect(c.lessons.first.steps.first.options.length, 2);
  });

  test('SRS levels grow to the 5th interval', () {
    final p = Progress.instance;
    for (final level in [1, 2, 3, 4, 4]) {
      p.reviewWord('word', true);
      expect(p.srs['word']!.level, level);
    }
    p.reviewWord('word', false);
    expect(p.srs['word']!.level, 0);
    expect(p.srs['word']!.wrong, 1);
  });

  test('progress records answers, xp and lesson completion', () async {
    final p = Progress.instance;
    await p.answer('Hello.', true);
    await p.answer('Goodbye.', false);
    expect(p.totalAnswers, 2);
    expect(p.totalCorrect, 1);
    expect(p.xp, 12);
    await p.completeLesson(0, 27);
    expect(p.completedLessons, 1);
    expect(p.stars, 3);
    expect(p.xp, 62);
  });
}
