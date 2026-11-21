import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lingo_gold/academy_screens.dart';
import 'package:lingo_gold/data.dart';
import 'package:lingo_gold/lesson_choice.dart';
import 'package:lingo_gold/lesson_speaking.dart';
import 'package:lingo_gold/lesson_writing.dart';
import 'package:lingo_gold/stories_screen.dart';
import 'package:lingo_gold/training_screen.dart';
import 'package:lingo_gold/widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  Widget wrap(Widget child) => MaterialApp(home: child);

  Future<void> open(WidgetTester tester, Widget page, String name) async {
    await tester.pumpWidget(wrap(page));
    await tester.pump(const Duration(milliseconds: 300));
    final error = tester.takeException();
    if (error != null) {
      fail('$name threw: $error');
    }
    expect(find.byType(Scaffold), findsWidgets, reason: '$name has no Scaffold');
  }

  testWidgets('all 25 academy screens open without exceptions', (tester) async {
    final l = lessons.first;

    // Learning interfaces
    await open(tester, AcademyScreen(onLessonComplete: (_) {}, onExit: () {}), 'Academy hub');
    await open(tester, PronunciationScreen(lesson: l, onDone: (_) {}), 'Pronunciation');
    await open(tester, const VocabularyScreen(), 'Vocabulary');
    await open(tester, GrammarScreen(lesson: l), 'Grammar');
    await open(tester, ReadingScreen(lesson: l), 'Reading');
    await open(tester, SkillWrapper(title: 'Writing', child: WritingStep(lesson: l, targetWord: l.word, onComplete: (_) {})), 'Writing');
    await open(tester, SkillWrapper(title: 'Listening', child: ListeningStep(lesson: l, distractors: lessons.skip(1).take(3).toList(), onComplete: (_) {}, showTranslation: false)), 'Listening');
    await open(tester, SkillWrapper(title: 'Speaking', child: SpeakingStep(lesson: l, onComplete: (_, __) {}, showTranslation: false)), 'Speaking');
    await open(tester, SkillWrapper(title: 'Choose an Image', child: ChooseStep(lesson: l, distractors: lessons.skip(1).take(3).toList(), onComplete: (_) {})), 'Choose an Image');
    await open(tester, ChoosePromptScreen(lesson: l, onDone: () {}), 'Choose a Prompt');
    await open(tester, AdaptiveRecallScreen(lesson: l, onDone: () {}), 'Adaptive Recall');
    await open(tester, const MilestoneConversationScreen(), 'Milestone Conversation');
    await open(tester, StoriesScreen(completedLessons: 0, onOpenStory: (_) {}), 'Stories');
    await open(tester, const PhrasebookScreen(), 'Phrasebook');
    await open(tester, const FlashcardsScreen(), 'Flashcards');
    await open(tester, const ChatMissionsScreen(), 'Chat Missions');

    // Tracking interfaces
    await open(tester, const DashboardScreen(), 'Dashboard');
    await open(tester, const AchievementsScreen(), 'Achievements');
    await open(tester, const WeeklyReportScreen(), 'Weekly Report');
    await open(tester, const LeaderboardScreen(), 'Leaderboard');
    await open(tester, const ParentDashboardScreen(), 'Parent Dashboard');
    await open(tester, const GoalsScreen(), 'Goals');
    await open(tester, const ProfileSummaryScreen(), 'Profile');
    await open(tester, const QuizResultScreen(), 'Quiz Result');
    await open(tester, const VocabularyReviewScreen(), 'Vocabulary Review');
    await open(tester, const SettingsScreen(), 'Settings');
  });

  testWidgets('training hub links to academy and bottom nav has 5 tabs', (tester) async {
    var opened = false;
    await tester.pumpWidget(wrap(TrainingScreen(
      currentLessonId: 1,
      onOpenLesson: (_) {},
      onOpenStory: (_) {},
      onReview: () {},
      onOpenAcademy: () => opened = true,
    )));
    expect(find.text('منهج Rosetta Stone'), findsOneWidget);
    await tester.tap(find.text('منهج Rosetta Stone'));
    await tester.pump();
    expect(opened, isTrue);

    await tester.pumpWidget(wrap(BottomNavBar(index: 0, onTap: (_) {})));
    expect(find.text('الرئيسية'), findsOneWidget);
    expect(find.text('الدروس'), findsOneWidget);
    expect(find.text('القصص'), findsOneWidget);
    expect(find.text('تدريب'), findsOneWidget);
    expect(find.text('ملفي'), findsOneWidget);
  });
}
