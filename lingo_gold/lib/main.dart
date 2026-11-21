import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home_screen.dart';
import 'lessons_screen.dart';
import 'level_select_screen.dart';
import 'lesson_content_service.dart';
import 'profile_screen.dart';
import 'review_screen.dart';
import 'training_screen.dart';
import 'stories_screen.dart';
import 'immersion_flow_screen.dart';
import 'progress_service.dart';
import 'user_profile.dart';
import 'update_service.dart';
import 'widgets.dart';
import 'theme.dart';
import 'data.dart' as app_data;

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Firebase is not configured yet (missing google-services.json).
    // The app still runs; Firestore features are disabled until configured.
  }
  await ProgressService.instance.init();
  // Start listening for admin edits (sentences/images) from Firestore.
  LessonContentService.instance.start();
  runApp(const LingoGoldApp());
}

class LingoGoldApp extends StatelessWidget {
  const LingoGoldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'تعلم',
      theme: buildAppTheme(),
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
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tab = 0;
  Timer? _updateTimer;

  static int get _totalLessons => app_data.lessons.length;

  @override
  void initState() {
    super.initState();
    UserProfile.instance.load().then((_) {
      if (!mounted) return;
      setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getInt('lingo_selected_level_v1') == null && mounted) {
        rootNavigatorKey.currentState?.pushReplacement(
          MaterialPageRoute(
            builder: (_) => LevelSelectScreen(
              onDone: () {
                rootNavigatorKey.currentState?.pushReplacement(
                  MaterialPageRoute(builder: (_) => const MainShell()),
                );
              },
            ),
          ),
        );
        return;
      }
      _updateTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) UpdateService.checkAndPrompt(context, silent: true);
      });
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  bool _stageUnlocked(int lessonId) {
    final cfg = LessonContentService.instance.curriculumConfig;
    if (cfg == null || cfg['unlockRule'] != 'stageMastery') return true;
    final idx = lessonId - 1;
    if (idx < 0 || idx >= app_data.lessons.length) return true;
    final level = app_data.lessons[idx].level;
    if (level <= 1) return true;
    final mastery = cfg['mastery'];
    final required = (mastery is Map && mastery['accuracy'] is num)
        ? (mastery['accuracy'] as num).toDouble() / 100.0
        : 0.7;
    for (var lv = 1; lv < level; lv++) {
      final ids = <String>[];
      for (var i = 0; i < app_data.lessons.length; i++) {
        if (app_data.lessons[i].level == lv) {
          ids.addAll(LessonContentService.instance.targetItemIds(i));
        }
      }
      if (ids.isEmpty) continue;
      final ratio = ProgressService.instance.masteryRatio(ids);
      if (ratio < required) return false;
    }
    return true;
  }

  Future<void> _startLesson() async {
    final up = UserProfile.instance;
    final restart = up.lessonsCompleted.value >= _totalLessons;
    final start = restart ? 1 : up.currentLessonId.value.clamp(1, _totalLessons);
    if (!_stageUnlocked(start)) {
      final openAnyway = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('المستوى التالي مغلق'),
          content: const Text(
            'أتقن المستوى السابق أولاً، أو افتح هذا الدرس للتدريب.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('رجوع'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('فتح للتدريب'),
            ),
          ],
        ),
      );
      if (openAnyway != true) return;
    }
    await _launchSession(start);
  }

  Future<void> _launchImmersion(int start, int end) async {
    final up = UserProfile.instance;
    if (up.lessonsCompleted.value >= _totalLessons) {
      await up.saveCourseProgress(
        lessonId: 1,
        completed: 0,
        newStars: up.stars.value,
        xp: up.totalXP.value,
      );
    }
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ImmersionFlowScreen(
          startId: start,
          endId: end.clamp(start, _totalLessons),
          onLessonComplete: _onLessonComplete,
          onExit: () => setState(() => _tab = 0),
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _launchLesson(int start) =>
      _launchImmersion(start, start);

  Future<void> _launchSession(int start) =>
      _launchImmersion(start, start + 3);

  Future<void> _openLevelSelect() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('lingo_selected_level_v1');
    rootNavigatorKey.currentState?.pushReplacement(
      MaterialPageRoute(
        builder: (_) => LevelSelectScreen(
          onDone: () {
            rootNavigatorKey.currentState?.pushReplacement(
              MaterialPageRoute(builder: (_) => const MainShell()),
            );
          },
        ),
      ),
    );
  }

  Future<void> _openLessonAt(int id) async {
    if (!_stageUnlocked(id)) {
      final openAnyway = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('المستوى التالي مغلق'),
          content: const Text('أتقن المستوى السابق أولاً، أو افتح للتدريب.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('رجوع'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('فتح للتدريب'),
            ),
          ],
        ),
      );
      if (openAnyway != true) return;
    }
    await _launchLesson(id);
  }

  Future<void> _openReview() async {
    final ids = ProgressService.instance.dueIds();
    if (ids.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا توجد مراجعة مستحقة الآن.')),
        );
      }
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReviewScreen(
          itemIds: ids,
          onExit: () => Navigator.of(context).pop(),
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openStory(String storyId) async {
    final group = app_data.lessons
        .where((l) => l.storyId.trim() == storyId)
        .toList()
      ..sort((a, b) => a.storyOrder.compareTo(b.storyOrder));
    if (group.isEmpty) return;
    await _launchImmersion(
      group.first.order,
      group.last.order,
    );
  }

  void _onLessonComplete(int id) {
    final up = UserProfile.instance;
    final newCompleted =
        id > up.lessonsCompleted.value ? id : up.lessonsCompleted.value;
    final newStars = up.stars.value + 5;
    final newXp = up.totalXP.value + 20;
    final next = (id + 1).clamp(1, _totalLessons);
    up.saveCourseProgress(
      lessonId: next,
      completed: newCompleted,
      newStars: newStars,
      xp: newXp,
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final up = UserProfile.instance;
    final reviewDue = ProgressService.instance.dueIds().length;
    return Scaffold(
      backgroundColor: Colors.white,
      body: ValueListenableBuilder<int>(
        valueListenable: LessonContentService.instance.revision,
        builder: (context, _lessonRev, __) {
          return ValueListenableBuilder<int>(
            valueListenable: up.currentLessonId,
            builder: (context, currentLesson, _) {
          return ValueListenableBuilder<int>(
            valueListenable: up.lessonsCompleted,
            builder: (context, completed, _) {
              return ValueListenableBuilder<int>(
                valueListenable: up.stars,
                builder: (context, stars, _) {
                  return ValueListenableBuilder<int>(
                    valueListenable: up.totalXP,
                    builder: (context, xp, _) {
                      return IndexedStack(
                        index: _tab,
                        children: [
                          HomeScreen(
                            currentLessonId: currentLesson,
                            completedLessons: completed,
                            totalLessons: _totalLessons,
                            stars: stars,
                            onStart: _startLesson,
                            onReview: reviewDue > 0 ? _openReview : null,
                            reviewDue: reviewDue,
                          ),
                          LessonsScreen(
                            onStartLesson: (id) => _openLessonAt(id),
                            onStartCourse: () =>
                                _launchImmersion(1, _totalLessons),
                          ),
                          StoriesScreen(
                            completedLessons: completed,
                            onOpenStory: _openStory,
                          ),
                          TrainingScreen(
                            currentLessonId: currentLesson,
                            onOpenLesson: (id) => _openLessonAt(id),
                            onOpenStory: _openStory,
                            onReview: _openReview,
                          ),
                          ProfileScreen(
                            completedCount: completed,
                            streak: up.streak.value,
                            wordsLearned: completed * 6,
                            speakingScore: up.pronunciationScore.value,
                            xp: xp,
                            onContinue: () => _startLesson(),
                            onChangeLevel: _openLevelSelect,
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          );
            },
          );
        },
      ),
      bottomNavigationBar: BottomNavBar(
        index: _tab,
        onTap: (index) => setState(() => _tab = index),
      ),
    );
  }
}
