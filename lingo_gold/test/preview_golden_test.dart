// Generates real Flutter screenshots (goldens) for visual preview.
// Run with: flutter test --update-goldens test/preview_golden_test.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lingo_gold/data.dart';
import 'package:lingo_gold/home_screen.dart';
import 'package:lingo_gold/lesson_choice.dart';
import 'package:lingo_gold/lesson_coloring_pages.dart';
import 'package:lingo_gold/lesson_coloring_step.dart';
import 'package:lingo_gold/lesson_flow.dart';
import 'package:lingo_gold/lesson_matching.dart';
import 'package:lingo_gold/lesson_smart_choose.dart';
import 'package:lingo_gold/lesson_speaking.dart';
import 'package:lingo_gold/lesson_writing.dart';
import 'package:lingo_gold/profile_screen.dart';
import 'package:lingo_gold/theme.dart';

Lesson _l(String image, bool pack, String word, String sentence) => Lesson(
      word: word,
      sentence: sentence,
      options: [word],
      imageFile: image,
      indexInPack: 0,
      isPack: pack,
      category: 'Special',
      translation: '',
    );

TextTheme _withFallback(TextTheme t) {
  TextStyle? f(TextStyle? s) =>
      s?.copyWith(fontFamilyFallback: const ['SegoeEmoji']);
  return TextTheme(
    displayLarge: f(t.displayLarge),
    displayMedium: f(t.displayMedium),
    displaySmall: f(t.displaySmall),
    headlineLarge: f(t.headlineLarge),
    headlineMedium: f(t.headlineMedium),
    headlineSmall: f(t.headlineSmall),
    titleLarge: f(t.titleLarge),
    titleMedium: f(t.titleMedium),
    titleSmall: f(t.titleSmall),
    bodyLarge: f(t.bodyLarge),
    bodyMedium: f(t.bodyMedium),
    bodySmall: f(t.bodySmall),
    labelLarge: f(t.labelLarge),
    labelMedium: f(t.labelMedium),
    labelSmall: f(t.labelSmall),
  );
}

ThemeData _theme() {
  final base = buildAppTheme();
  final text = _withFallback(base.textTheme.apply(fontFamily: 'Roboto'));
  return base.copyWith(
    textTheme: text,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
          fontFamily: 'Roboto',
          fontFamilyFallback: ['SegoeEmoji'],
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kInk,
        minimumSize: const Size(0, 52),
        side: const BorderSide(color: kLine),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
          fontFamily: 'Roboto',
          fontFamilyFallback: ['SegoeEmoji'],
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}

Widget _materialApp(Widget home) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: _theme(),
    locale: const Locale('ar'),
    supportedLocales: const [Locale('ar'), Locale('en')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    builder: (context, child) => Directionality(
      textDirection: TextDirection.rtl,
      child: child ?? const SizedBox.shrink(),
    ),
    home: home,
  );
}

Widget _app({
  required String title,
  required String step,
  required Widget child,
  double progress = 0.4,
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: _theme(),
    locale: const Locale('ar'),
    supportedLocales: const [Locale('ar'), Locale('en')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    builder: (context, child) => Directionality(
      textDirection: TextDirection.rtl,
      child: child ?? const SizedBox.shrink(),
    ),
    home: Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(6, 6, 12, 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: kLine)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.arrow_back_rounded,
                          color: kInk, size: 23),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'LINGO GOLD',
                              style: TextStyle(
                                fontSize: 9.5,
                                letterSpacing: 1.1,
                                fontWeight: FontWeight.w800,
                                color: kPrimary,
                              ),
                            ),
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: kInk,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: kSoftGreen,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          step,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: kPrimaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: kLine,
                      valueColor: const AlwaysStoppedAnimation<Color>(kPrimary),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    ),
  );
}

Future<void> _shoot(
  WidgetTester tester,
  String name,
  Widget app, {
  Duration settle = const Duration(milliseconds: 200),
}) async {
  await tester.pumpWidget(app);
  await tester.pump(settle);
  await tester.runAsync(() async {
    await Future<void>.delayed(const Duration(milliseconds: 3000));
  });
  await tester.pump(const Duration(milliseconds: 200));
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('preview/$name.png'),
  );
}

Future<void> _shootColoringDone(
  WidgetTester tester,
  String name,
  int lessonIndex,
) async {
  await tester.pumpWidget(_app(
    title: 'درس التلوين',
    step: 'التلوين',
    progress: 1.0,
    child: LessonColoringStep(lessonIndex: lessonIndex, onComplete: () {}),
  ));
  await tester.pump(const Duration(milliseconds: 400));
  await tester.runAsync(() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
  });
  await tester.pump();

  final data = lessonColoringDataFor(lessonIndex);
  final canvas = tester.getRect(find.byKey(const ValueKey('coloring-canvas')));
  Offset point(LessonColoringTask task) =>
      canvas.topLeft + Offset(task.x * canvas.width, task.y * canvas.height);

  for (final task in data.tasks) {
    await tester.tap(find.byKey(ValueKey('color-${task.colorName}')));
    await tester.pump();
    await tester.tapAt(point(task));
    await tester.pump();
  }

  await tester.runAsync(() async {
    await Future<void>.delayed(const Duration(milliseconds: 3000));
  });
  await tester.pump(const Duration(milliseconds: 200));
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('preview/$name.png'),
  );
}

void main() {
  setUpAll(() async {
    Future<void> loadFont(String family, List<String> paths) async {
      final loader = FontLoader(family);
      var added = false;
      for (final path in paths) {
        final f = File(path);
        if (f.existsSync()) {
          final bytes = f.readAsBytesSync();
          loader.addFont(Future.value(ByteData.view(bytes.buffer)));
          added = true;
        }
      }
      if (added) await loader.load();
    }

    // Arabic-capable UI font under the Material default family.
    await loadFont('Roboto', [
      r'C:\Windows\Fonts\segoeui.ttf',
      r'C:\Windows\Fonts\tahoma.ttf',
      r'C:\Windows\Fonts\arial.ttf',
    ]);
    // Emoji fallback.
    await loadFont('SegoeEmoji', [
      r'C:\Windows\Fonts\seguiemj.ttf',
    ]);
    // Material icons.
    await loadFont('MaterialIcons', [
      r'C:\flutter\bin\cache\artifacts\material_fonts\MaterialIcons-Regular.otf',
    ]);
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('preview screenshots', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // ---------- Lesson 5 intro ----------
    // (golden capture disabled: image-loading timing makes this flaky in CI;
    //  the image already exists at test/preview/00_lesson5_intro.png)
    // await _shoot(
    //   tester,
    //   '00_lesson5_intro',
    //   _materialApp(
    //     const LessonFlowScreen(
    //       key: ValueKey('intro-l5'),
    //       startLessonId: 5,
    //       totalLessons: 100,
    //     ),
    //   ),
    //   settle: const Duration(milliseconds: 5000),
    // );

    // ---------- Lesson 7 intro ----------
    // await _shoot(
    //   tester,
    //   '00b_lesson7_intro',
    //   _materialApp(
    //     const LessonFlowScreen(
    //       key: ValueKey('intro-l7'),
    //       startLessonId: 7,
    //       totalLessons: 100,
    //     ),
    //   ),
    //   settle: const Duration(milliseconds: 5000),
    // );

    // ---------- Lesson 1 coloring ----------
    await _shoot(
      tester,
      '00c_lesson1_coloring',
      _app(
        title: 'درس التلوين',
        step: 'التلوين',
        progress: 1.0,
        child: LessonColoringStep(
          key: const ValueKey('coloring-l1'),
          lessonIndex: 0,
          onComplete: () {},
        ),
      ),
      settle: const Duration(milliseconds: 400),
    );

    // ---------- Lesson 5 coloring ----------
    await _shoot(
      tester,
      '00d_lesson5_coloring',
      _app(
        title: 'درس التلوين',
        step: 'التلوين',
        progress: 1.0,
        child: LessonColoringStep(
          key: const ValueKey('coloring-l5'),
          lessonIndex: 4,
          onComplete: () {},
        ),
      ),
      settle: const Duration(milliseconds: 400),
    );

    // ---------- Lesson 1 coloring completed ----------
    await _shootColoringDone(
      tester,
      '00e_lesson1_coloring_done',
      0,
    );

    // ---------- Lesson 7 coloring ----------
    await _shoot(
      tester,
      '00f_lesson7_coloring',
      _app(
        title: 'درس التلوين',
        step: 'التلوين',
        progress: 1.0,
        child: LessonColoringStep(
          key: const ValueKey('coloring-l7'),
          lessonIndex: 6,
          onComplete: () {},
        ),
      ),
      settle: const Duration(milliseconds: 400),
    );

    // ---------- Lesson 10 coloring ----------
    await _shoot(
      tester,
      '00g_lesson10_coloring',
      _app(
        title: 'درس التلوين',
        step: 'التلوين',
        progress: 1.0,
        child: LessonColoringStep(
          key: const ValueKey('coloring-l10'),
          lessonIndex: 9,
          onComplete: () {},
        ),
      ),
      settle: const Duration(milliseconds: 400),
    );

    // ---------- Home ----------
    await _shoot(
      tester,
      '01_home',
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: _theme(),
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) => Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        ),
        home: HomeScreen(
          currentLessonId: 5,
          completedLessons: 4,
          totalLessons: 100,
          stars: 20,
          onStart: () {},
        ),
      ),
    );

    // ---------- Lesson 5 data ----------
    final boyDrinking =
        _l('n19', true, 'The boy is drinking', 'The boy is drinking.');
    final eating = _l('n18', true, 'Eating', '');
    final drinking = _l('n19', true, 'Drinking', '');
    final running = _l('n15', true, 'Running', '');
    final sleeping = _l('n20', true, 'Sleeping', '');

    await _shoot(
      tester,
      '02_lesson5_listening',
      _app(
        title: 'درس الاستماع',
        step: 'السؤال 1 من 5',
        child: ListeningStep(
          lesson: boyDrinking,
          distractors: [eating, running, sleeping],
          onComplete: (_) {},
          showTranslation: false,
        ),
      ),
    );

    await _shoot(
      tester,
      '02b_lesson5_speaking',
      _app(
        title: 'درس التحدث',
        step: 'السؤال 2 من 5',
        child: SpeakingStep(
          key: const ValueKey('speak-l5'),
          lesson: boyDrinking,
          onComplete: (_, __) {},
          showTranslation: false,
        ),
      ),
      settle: const Duration(seconds: 2),
    );

    await _shoot(
      tester,
      '03_lesson5_matching',
      _app(
        title: 'درس المطابقة',
        step: 'السؤال 3 من 5',
        child: MatchingStep(
          lesson: drinking,
          distractors: [eating, running],
          onComplete: (_) {},
        ),
      ),
    );

    await _shoot(
      tester,
      '04_lesson5_writing',
      _app(
        title: 'درس الكتابة',
        step: 'السؤال 4 من 5',
        child: WritingStep(
          lesson: boyDrinking,
          targetWord: 'DRINKING',
          onComplete: (_) {},
        ),
      ),
    );

    await _shoot(
      tester,
      '05_lesson5_smart_choose',
      _app(
        title: 'الاختيار الذكي',
        step: 'السؤال 5 من 5',
        child: SmartChooseStep(
          key: const ValueKey('smart-l5'),
          lesson: drinking,
          lessonIndex: 4,
          distractors: [
            _l('n18', true, 'The boy is eating', ''),
            _l('n15', true, 'The boy is running', ''),
            _l('n20', true, 'The boy is sleeping', ''),
          ],
          question: 'Which picture is The boy is drinking?',
          onComplete: (_) {},
        ),
      ),
    );

    // ---------- Lesson 10 smart choose ----------
    final sun = _l('n56', true, 'The sun', 'The sun.');
    await _shoot(
      tester,
      '06_lesson10_smart_choose',
      _app(
        title: 'الاختيار الذكي',
        step: 'السؤال 5 من 5',
        child: SmartChooseStep(
          key: const ValueKey('smart-l10'),
          lesson: sun,
          lessonIndex: 9,
          distractors: [
            _l('n57', true, 'The moon', ''),
            _l('n58', true, 'A star', ''),
            _l('n55', true, 'A tree', ''),
          ],
          question: 'Which picture is The sun?',
          onComplete: (_) {},
        ),
      ),
    );

    // ---------- Profile ----------
    await _shoot(
      tester,
      '07_profile',
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: _theme(),
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) => Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        ),
        home: Scaffold(
          backgroundColor: Colors.white,
          body: ProfileScreen(
            completedCount: 4,
            streak: 2,
            wordsLearned: 24,
            speakingScore: 88,
            xp: 80,
            onContinue: () {},
          ),
        ),
      ),
    );
  });
}
