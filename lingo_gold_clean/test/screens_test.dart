import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingo_gold/main.dart';

Future<void> loadRoboto() async {
  final file = File(r'C:\Windows\Fonts\segoeui.ttf');
  if (!file.existsSync()) return;
  final bytes = await file.readAsBytes();
  final loader = FontLoader('Roboto')
    ..addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
  await loader.load();
}

Widget host(Widget child) => MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, page) =>
          Directionality(textDirection: TextDirection.rtl, child: page ?? const SizedBox()),
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(seedColor: kGreen, primary: kGreen),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: kGreen,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
          ),
        ),
      ),
      home: Scaffold(backgroundColor: Colors.white, body: child),
    );

void main() {
  setUpAll(() async {
    await loadRoboto();
  });

  final screens = <String, Widget>{
    'Dashboard': const DashboardScreen(pushed: true),
    'Lessons': const LessonsScreen(),
    'Stories': const StoriesScreen(),
    'Training': const TrainingScreen(),
    'Profile': const ProfileScreen(),
    'CoreLesson': const CoreLessonScreen(index: 0),
    'LessonJourney': const LessonJourneyScreen(index: 0),
    'Pronunciation': const PronunciationScreen(index: 0),
    'Vocabulary': const VocabularyScreen(),
    'Grammar': const GrammarScreen(index: 0),
    'Reading': const ReadingScreen(index: 0),
    'Writing': const WritingScreen(index: 0),
    'Listening': const ListeningScreen(index: 0),
    'Speaking': const SpeakingScreen(index: 0),
    'ChooseImage': const ChooseImageScreen(index: 0),
    'ChoosePrompt': const ChoosePromptScreen(index: 0),
    'AdaptiveRecall': const AdaptiveRecallScreen(),
    'Milestone': const MilestoneConversationScreen(),
    'Phrasebook': const PhrasebookScreen(),
    'Flashcards': const FlashcardsScreen(),
    'ChatMissions': const ChatMissionsScreen(),
    'StoryReader': const StoryReaderScreen(index: 0),
    'Achievements': const AchievementsScreen(),
    'WeeklyReport': const WeeklyReportScreen(),
    'Leaderboard': const LeaderboardScreen(),
    'ParentDashboard': const ParentDashboardScreen(),
    'Goals': const GoalsScreen(),
    'QuizResult': const QuizResultScreen(),
    'VocabularyReview': const VocabularyReviewScreen(),
    'Settings': const SettingsScreen(),
  };

  for (final entry in screens.entries) {
    testWidgets('${entry.key} builds without layout errors', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(host(entry.value));
      await tester.pump(const Duration(milliseconds: 120));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('bottom tabs switch without layout errors', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();
    for (var i = 1; i < 5; i++) {
      await tester.tap(find.text(BottomNav.labels[i]));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}
