import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingo_gold/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Progress.instance.reset();
  });

  testWidgets('curriculum contains 4 lessons of 30 steps', (tester) async {
    final c = await Curriculum.load();
    expect(c.lessons.length, 4);
    final total = c.lessons.fold<int>(0, (sum, l) => sum + l.steps.length);
    expect(total, 120);
    expect(c.srsIntervals, [1, 2, 4, 8, 16]);
  });

  testWidgets('lesson card advances after a correct answer', (tester) async {
    final c = await Curriculum.load();
    await tester.pumpWidget(MaterialApp(
      home: LessonScreen(curriculum: c, lessonIndex: 0),
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('1 / 30'), findsOneWidget);

    final first = c.lessons[0].steps[0];
    await tester.tap(find.text(first.options[first.correct]));
    await tester.pumpAndSettle();
    await tester.tap(find.text(c.t('continue')));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(find.textContaining('2 / 30'), findsOneWidget);
  });

  testWidgets('bottom navigation switches tabs', (tester) async {
    final c = await Curriculum.load();
    await tester.pumpWidget(LingoApp(curriculum: c));
    await tester.pumpAndSettle();

    expect(find.text(c.t('dashboard')), findsWidgets);
    await tester.tap(find.text(c.t('lessons')));
    await tester.pumpAndSettle();
    expect(find.text(c.lessons[0].title), findsOneWidget);
  });
}
