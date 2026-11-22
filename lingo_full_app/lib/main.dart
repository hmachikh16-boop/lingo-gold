import 'package:flutter/material.dart';

import 'core.dart';
import 'models/curriculum.dart';
import 'screens/app_screens.dart';
import 'screens/lesson_screen.dart';

export 'core.dart';
export 'models/curriculum.dart';
export 'screens/app_screens.dart';
export 'screens/lesson_screen.dart';
export 'screens/result_screen.dart';
export 'screens/milestone_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final curriculum = await Curriculum.load();
  await Progress.instance.load();
  runApp(LingoApp(curriculum: curriculum));
}

class LingoApp extends StatelessWidget {
  final Curriculum curriculum;
  const LingoApp({super.key, required this.curriculum});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: curriculum.t('app_name'),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: kGreen, primary: kGreen),
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Nunito',
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(backgroundColor: kGreen, foregroundColor: Colors.white),
        ),
      ),
      home: Shell(curriculum: curriculum),
    );
  }
}

class Shell extends StatefulWidget {
  final Curriculum curriculum;
  const Shell({super.key, required this.curriculum});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _tab = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    final c = widget.curriculum;
    _pages = [
      DashboardScreen(curriculum: c),
      LessonsScreen(curriculum: c),
      StoriesScreen(curriculum: c),
      TrainingScreen(curriculum: c),
      ProfileScreen(curriculum: c),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.curriculum;
    return Scaffold(
      body: IndexedStack(index: _tab, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        selectedItemColor: kGreen,
        unselectedItemColor: kMuted,
        onTap: (i) => setState(() => _tab = i),
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.home_rounded), label: c.t('home')),
          BottomNavigationBarItem(icon: const Icon(Icons.menu_book_rounded), label: c.t('lessons')),
          BottomNavigationBarItem(icon: const Icon(Icons.auto_stories_rounded), label: c.t('stories')),
          BottomNavigationBarItem(icon: const Icon(Icons.fitness_center_rounded), label: c.t('training')),
          BottomNavigationBarItem(icon: const Icon(Icons.person_rounded), label: c.t('profile')),
        ],
      ),
    );
  }
}

class LessonsScreen extends StatelessWidget {
  final Curriculum curriculum;
  const LessonsScreen({super.key, required this.curriculum});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: Progress.instance,
        builder: (context, _) {
          final p = Progress.instance;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(curriculum.t('lessons'), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
              const SizedBox(height: 14),
              for (var i = 0; i < curriculum.lessons.length; i++)
                CardBox(
                  onTap: () => openPage(context, LessonScreen(curriculum: curriculum, lessonIndex: i)),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(color: i < p.completedLessons ? kGreen : kGreenSoft, borderRadius: BorderRadius.circular(12)),
                        child: Icon(i < p.completedLessons ? Icons.check_rounded : Icons.play_arrow_rounded, color: i < p.completedLessons ? Colors.white : kGreen),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(curriculum.lessons[i].title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                            Text('${curriculum.stepsPerLesson} ${curriculum.t('check')}', style: const TextStyle(fontSize: 11, color: kMuted)),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: kGreen),
                    ],
                  ),
                ),
            ],
          );
        },
      );
}

class StoriesScreen extends StatelessWidget {
  final Curriculum curriculum;
  const StoriesScreen({super.key, required this.curriculum});
  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(curriculum.t('stories'), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
          const SizedBox(height: 14),
          for (final lesson in curriculum.lessons)
            CardBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lesson.title, style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: 150,
                      width: double.infinity,
                      child: Image.asset(
                        'assets/images/${lesson.steps.first.image}',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(child: Text('📖', style: TextStyle(fontSize: 50))),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
}

class TrainingScreen extends StatelessWidget {
  final Curriculum curriculum;
  const TrainingScreen({super.key, required this.curriculum});
  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(curriculum.t('training'), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
          const SizedBox(height: 14),
          CardBox(
            onTap: () => openPage(context, ReviewScreen(curriculum: curriculum)),
            child: ListTile(
              leading: const CircleAvatar(backgroundColor: kGreen, child: Icon(Icons.replay_rounded, color: Colors.white)),
              title: Text(curriculum.t('review_today')),
            ),
          ),
          CardBox(
            onTap: () => openPage(context, LeaderboardScreen(curriculum: curriculum)),
            child: const ListTile(
              leading: CircleAvatar(backgroundColor: kGreen, child: Icon(Icons.leaderboard_rounded, color: Colors.white)),
              title: Text('Leaderboard'),
            ),
          ),
          CardBox(
            onTap: () => openPage(context, WeeklyReportScreen(curriculum: curriculum)),
            child: const ListTile(
              leading: CircleAvatar(backgroundColor: kGreen, child: Icon(Icons.bar_chart_rounded, color: Colors.white)),
              title: Text('Weekly Report'),
            ),
          ),
        ],
      );
}

class ProfileScreen extends StatelessWidget {
  final Curriculum curriculum;
  const ProfileScreen({super.key, required this.curriculum});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: Progress.instance,
        builder: (context, _) {
          final p = Progress.instance;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              CircleAvatar(radius: 42, backgroundColor: kGreen, child: const Icon(Icons.person_rounded, color: Colors.white, size: 42)),
              const SizedBox(height: 12),
              Center(child: Text('${curriculum.t('app_name')} • Lv ${p.level}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900))),
              const SizedBox(height: 18),
              CardBox(
                child: Column(
                  children: [
                    ListTile(title: const Text('XP'), trailing: Text('${p.xp}', style: const TextStyle(fontWeight: FontWeight.w900, color: kGreen))),
                    ListTile(title: const Text('Stars'), trailing: Text('${p.stars}', style: const TextStyle(fontWeight: FontWeight.w900, color: kGreen))),
                    ListTile(title: const Text('Streak'), trailing: Text('${p.streak}', style: const TextStyle(fontWeight: FontWeight.w900, color: kGreen))),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              CardBox(
                onTap: () => openPage(context, SettingsScreen(curriculum: curriculum)),
                child: ListTile(
                  leading: const Icon(Icons.settings_rounded, color: kGreen),
                  title: Text(curriculum.t('settings')),
                ),
              ),
            ],
          );
        },
      );
}
