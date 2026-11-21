import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'lessons_data.dart';

// ===== Palette: green / white / dark / light gray only =====
const kGreen = Color(0xFF2E9E5B);
const kGreenDark = Color(0xFF1F7A44);
const kInk = Color(0xFF14213D);
const kMuted = Color(0xFF6B7280);
const kCard = Color(0xFFF5F6F8);
const kLine = Color(0xFFE6E8EC);
const kSoft = Color(0xFFE9F7EF);

// ===== Data is in lessons_data.dart (253 lessons from project images) =====

class Tts {
  Tts._();
  static final Tts instance = Tts._();
  final FlutterTts _tts = FlutterTts();
  bool _ready = false;
  Future<void> speak(String text) async {
    try {
      if (!_ready) {
        await _tts.setLanguage('en-US');
        await _tts.setSpeechRate(0.5);
        _ready = true;
      }
      await _tts.speak(text);
    } catch (_) {}
  }
}

class Progress extends ChangeNotifier {
  Progress._();
  static final Progress instance = Progress._();

  int completed = 0;
  int stars = 0;
  int xp = 0;
  int streak = 0;
  int current = 0;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    completed = p.getInt('completed') ?? 0;
    stars = p.getInt('stars') ?? 0;
    xp = p.getInt('xp') ?? 0;
    streak = p.getInt('streak') ?? 0;
    current = p.getInt('current') ?? 0;
    notifyListeners();
  }

  Future<void> complete(int index, bool correct) async {
    if (index >= completed) completed = index + 1;
    if (correct) {
      stars += 3;
      xp += 20;
    } else {
      stars += 1;
      xp += 5;
    }
    current = (index + 1) % items.length;
    final p = await SharedPreferences.getInstance();
    await p.setInt('completed', completed);
    await p.setInt('stars', stars);
    await p.setInt('xp', xp);
    await p.setInt('current', current);
    notifyListeners();
  }
}

// ===== Reusable image =====
class Photo extends StatelessWidget {
  final String file;
  final BoxFit fit;
  const Photo(this.file, {super.key, this.fit = BoxFit.cover});
  @override
  Widget build(BuildContext context) => Image.asset(
        'assets/images/$file',
        fit: fit,
        errorBuilder: (_, __, ___) => const ColoredBox(color: kCard),
      );
}

// ===== Root =====
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Progress.instance.load();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lingo Gold',
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child ?? const SizedBox()),
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(seedColor: kGreen, primary: kGreen),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: kGreen,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
            textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
        ),
      ),
      home: const Shell(),
    );
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _tab = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: _tab,
        children: [
          HomeScreen(onStart: () => _open(Progress.instance.current)),
          const LessonsScreen(),
          const StoriesScreen(),
          const TrainingScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNav(index: _tab, onTap: (i) => setState(() => _tab = i)),
    );
  }

  Future<void> _open(int index) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LearningScreen(index: index % items.length),
      ),
    );
  }
}

class BottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const BottomNav({super.key, required this.index, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final labels = ['الرئيسية', 'الدروس', 'القصص', 'تدريب', 'ملفي'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      child: Container(
        height: 62,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(34),
          boxShadow: const [BoxShadow(color: Color(0x18000000), blurRadius: 12)],
        ),
        child: Row(
          children: [
            for (var i = 0; i < labels.length; i++)
              Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: index == i ? kGreen : kCard,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: FittedBox(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          labels[i],
                          style: TextStyle(
                            color: index == i ? Colors.white : kMuted,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ===== Home =====
class HomeScreen extends StatelessWidget {
  final VoidCallback onStart;
  const HomeScreen({super.key, required this.onStart});
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Progress.instance,
      builder: (context, _) {
        final p = Progress.instance;
        final item = items[p.current % items.length];
        final ratio = p.completed / items.length;
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
            children: [
              const Text('تقدمك اليوم', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: kInk)),
              const SizedBox(height: 10),
              Text('${p.completed} / ${items.length}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: kGreen)),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(value: ratio, color: kGreen, backgroundColor: kCard, minHeight: 9),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(Icons.star_rounded, color: kGreen, size: 20),
                  const SizedBox(width: 4),
                  Text('${p.stars} نجمة', style: const TextStyle(fontWeight: FontWeight.w800, color: kInk)),
                  const Spacer(),
                  Text('${p.xp} XP', style: const TextStyle(fontWeight: FontWeight.w800, color: kGreen)),
                ],
              ),
              const SizedBox(height: 22),
              const Text('الدرس الحالي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kInk)),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(height: 300, width: double.infinity, child: Photo(item.image)),
              ),
              const SizedBox(height: 14),
              Text(item.word, textAlign: TextAlign.center, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: kInk)),
              const SizedBox(height: 4),
              Text(item.sentence, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: kMuted)),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onStart,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('ابدأ الجلسة'),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ===== Lessons / Stories grids =====
class LessonsScreen extends StatelessWidget {
  const LessonsScreen({super.key});
  @override
  Widget build(BuildContext context) => _grid(context, 'الدروس');
}

class StoriesScreen extends StatelessWidget {
  const StoriesScreen({super.key});
  @override
  Widget build(BuildContext context) => _grid(context, 'القصص');
}

Widget _grid(BuildContext context, String title) {
  return SafeArea(
    child: ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 110),
      children: [
        Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: kInk)),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.82,
          ),
          itemCount: items.length,
          itemBuilder: (context, i) {
            final it = items[i];
            return GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => LearningScreen(index: i)),
              ),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: kLine)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    children: [
                      Expanded(child: Photo(it.image)),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(it.word, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, color: kInk)),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    ),
  );
}

// ===== Learning flow =====
class LearningScreen extends StatefulWidget {
  final int index;
  const LearningScreen({super.key, required this.index});
  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen> {
  int _phase = 0;
  int? _selected;
  bool _done = false;

  LearnItem get item => items[widget.index % items.length];

  List<String> get options {
    final r = Random(widget.index + 7);
    final pool = items.where((x) => x.image != item.image).map((x) => x.image).toList()..shuffle(r);
    return [item.image, ...pool.take(3)];
  }

  void _speak() => Tts.instance.speak(item.sentence);

  void _finish(bool correct) {
    Progress.instance.complete(widget.index, correct);
    setState(() => _done = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Core Lesson'),
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
      ),
      body: SafeArea(
        child: _done ? _result() : (_phase == 0 ? _learn() : _choose()),
      ),
    );
  }

  Widget _learn() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
          child: ClipRRect(borderRadius: BorderRadius.circular(20), child: SizedBox(height: 340, width: double.infinity, child: Photo(item.image))),
        ),
        const SizedBox(height: 16),
        Text(item.word, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: kInk)),
        const SizedBox(height: 4),
        Text(item.sentence, style: const TextStyle(fontSize: 15, color: kMuted)),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: OutlinedButton.icon(
            onPressed: _speak,
            icon: const Icon(Icons.volume_up_rounded),
            label: const Text('استمع'),
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 52), foregroundColor: kGreen, side: const BorderSide(color: kGreen)),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 22),
          child: FilledButton(onPressed: () => setState(() => _phase = 1), child: const Text('Continue')),
        ),
      ],
    );
  }

  Widget _choose() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 4),
          child: Text('Which picture is "${item.word}"?', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kInk)),
        ),
        IconButton(onPressed: _speak, icon: const Icon(Icons.volume_up_rounded, color: kGreen, size: 30)),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            itemCount: options.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.05),
            itemBuilder: (context, i) {
              final selected = _selected == i;
              final correct = options[i] == item.image;
              return GestureDetector(
                onTap: () => setState(() => _selected = i),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected ? (correct ? kGreen : kMuted) : kLine,
                      width: selected ? 4 : 2,
                    ),
                  ),
                  child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Photo(options[i])),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 22),
          child: FilledButton(
            onPressed: _selected == null ? null : () => _finish(options[_selected!] == item.image),
            child: const Text('Continue'),
          ),
        ),
      ],
    );
  }

  Widget _result() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_rounded, size: 86, color: kGreen),
            const SizedBox(height: 16),
            const Text('Great job!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: kInk)),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var i = 0; i < 3; i++) const Icon(Icons.star_rounded, color: kGreen, size: 32),
            ]),
            const SizedBox(height: 26),
            FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Continue')),
          ],
        ),
      ),
    );
  }
}

// ===== Training / Profile =====
class TrainingScreen extends StatelessWidget {
  const TrainingScreen({super.key});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: Progress.instance,
        builder: (context, _) {
          final p = Progress.instance;
          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
              children: [
                const Text('تدريب', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: kInk)),
                const SizedBox(height: 14),
                _stat('${p.completed}', 'دروس مكتملة'),
                _stat('${p.stars}', 'نجوم'),
                _stat('${p.xp}', 'نقاط XP'),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => LearningScreen(index: p.current % items.length))),
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('مراجعة سريعة'),
                ),
                const SizedBox(height: 10),
                _navButton(context, 'Core Lesson', Icons.school_outlined, LearningScreen(index: p.current % items.length)),
                _navButton(context, 'Choose an Image', Icons.image_outlined, LearningScreen(index: p.current % items.length)),
                _navButton(context, 'Review • Adaptive Recall', Icons.replay_rounded, const AdaptiveRecallScreen()),
                _navButton(context, 'Milestone Conversation', Icons.chat_bubble_outline, const MilestoneConversationScreen()),
                _navButton(context, 'Achievements & Badges', Icons.emoji_events_outlined, const AchievementsScreen()),
                _navButton(context, 'Weekly Progress Report', Icons.bar_chart_rounded, const WeeklyReportScreen()),
                _navButton(context, 'Parent Dashboard', Icons.family_restroom_rounded, const ParentDashboardScreen()),
              ],
            ),
          );
        },
      );
}

Widget _navButton(BuildContext context, String title, IconData icon, Widget page) => Card(
      elevation: 0,
      color: kCard,
      child: ListTile(
        leading: Icon(icon, color: kGreen),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: kInk)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: kMuted),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => page)),
      ),
    );

Widget _stat(String value, String label) => Card(
      elevation: 0,
      color: kCard,
      child: ListTile(
        title: Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: kGreen)),
        subtitle: Text(label),
      ),
    );

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: Progress.instance,
        builder: (context, _) {
          final p = Progress.instance;
          return SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClipRRect(borderRadius: BorderRadius.circular(50), child: SizedBox(width: 100, height: 100, child: Photo('q0.jpg'))),
                  const SizedBox(height: 16),
                  const Text('Lingo Gold', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: kInk)),
                  const SizedBox(height: 8),
                  Text('${p.xp} XP • ${p.stars} stars • ${p.completed} lessons', style: const TextStyle(color: kMuted)),
                ],
              ),
            ),
          );
        },
      );
}

// ===== Extra interfaces (green palette only) =====
class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: Progress.instance,
        builder: (context, _) {
          final p = Progress.instance;
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(title: const Text('Achievements & Badges'), centerTitle: true),
            body: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
              children: [
                Card(
                  elevation: 0,
                  color: kCard,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    leading: ClipRRect(borderRadius: BorderRadius.circular(28), child: SizedBox(width: 56, height: 56, child: Photo('q0.jpg'))),
                    title: Text('Alex • Level ${p.xp ~/ 200 + 1}', style: const TextStyle(fontWeight: FontWeight.w900, color: kInk)),
                    subtitle: Text('${p.xp} XP • ${p.completed} lessons'),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Your Badges', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kInk)),
                const SizedBox(height: 8),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  children: [
                    _badge(Icons.chat_bubble_outline, 'First Conversation', p.completed > 0),
                    _badge(Icons.local_fire_department_rounded, '7 Day Streak', p.streak >= 7),
                    _badge(Icons.book_outlined, 'Vocabulary Master', p.completed >= 50),
                    _badge(Icons.rule_rounded, 'Grammar Guru', p.stars >= 100),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Trophies & Medals', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kInk)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _trophy(Icons.mic_rounded, 'Speaking Star')),
                    Expanded(child: _trophy(Icons.hearing_rounded, 'Listening Pro')),
                    Expanded(child: _trophy(Icons.edit_rounded, 'Writing Champ')),
                  ],
                ),
              ],
            ),
          );
        },
      );

  Widget _badge(IconData icon, String label, bool earned) => Card(
        elevation: 0,
        color: earned ? kSoft : kCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: kLine)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 38, color: earned ? kGreen : kMuted),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800, color: kInk)),
        ]),
      );

  Widget _trophy(IconData icon, String label) => Card(
        elevation: 0,
        color: kCard,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(children: [
            Icon(icon, color: kGreen, size: 28),
            const SizedBox(height: 6),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
          ]),
        ),
      );
}

class WeeklyReportScreen extends StatelessWidget {
  const WeeklyReportScreen({super.key});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: Progress.instance,
        builder: (context, _) {
          final p = Progress.instance;
          final bars = [0.4, 0.7, 0.5, 0.9, 0.65, 0.8, 0.55];
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(title: const Text('Weekly Progress Report'), centerTitle: true),
            body: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: kSoft, borderRadius: BorderRadius.circular(14)),
                  child: Text('${p.streak}-Day Streak! Keep it going.', style: const TextStyle(fontWeight: FontWeight.w900, color: kGreenDark)),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _card('Words Learned', '${p.completed * 6}')),
                  const SizedBox(width: 10),
                  Expanded(child: _card('Lessons', '${p.completed}')),
                ]),
                const SizedBox(height: 14),
                Card(
                  elevation: 0,
                  color: kCard,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 16, 14, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text("This Week's Activity", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: kInk)),
                        const SizedBox(height: 18),
                        SizedBox(
                          height: 120,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              for (var i = 0; i < 7; i++)
                                Column(children: [
                                  Container(width: 20, height: 20 + bars[i] * 80, decoration: BoxDecoration(color: kGreen.withValues(alpha: 0.55 + i * 0.05), borderRadius: BorderRadius.circular(6))),
                                  const SizedBox(height: 5),
                                  Text(['M','T','W','T','F','S','S'][i], style: const TextStyle(fontSize: 10)),
                                ]),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: kSoft, borderRadius: BorderRadius.circular(14)),
                  child: const Text('Insight: You are learning consistently. Keep your streak alive!', style: TextStyle(color: kInk)),
                ),
              ],
            ),
          );
        },
      );

  Widget _card(String label, String value) => Card(
        elevation: 0,
        color: kCard,
        child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: kGreen)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: kMuted)),
        ])),
      );
}

class ParentDashboardScreen extends StatelessWidget {
  const ParentDashboardScreen({super.key});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: Progress.instance,
        builder: (context, _) {
          final p = Progress.instance;
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(title: const Text('Parent Dashboard'), centerTitle: true),
            body: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
              children: [
                Row(children: [
                  ClipRRect(borderRadius: BorderRadius.circular(40), child: SizedBox(width: 80, height: 80, child: Photo('img_girl_child.jpg'))),
                  const SizedBox(width: 12),
                  const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Emma • Age 6', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: kInk)),
                    Text('Active Learner', style: TextStyle(color: kMuted)),
                  ])),
                ]),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: _stat('${p.completed}/${items.length}', 'Lessons Completed')),
                  Expanded(child: _stat('${p.stars}', 'Stars')),
                  Expanded(child: _stat('${p.xp}', 'XP')),
                ]),
                const SizedBox(height: 14),
                const Text('Progress Overview', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: kInk)),
                const SizedBox(height: 8),
                ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: p.completed / items.length, color: kGreen, backgroundColor: kCard, minHeight: 10)),
                const SizedBox(height: 18),
                const Text('Recent Lessons', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: kInk)),
                const SizedBox(height: 8),
                for (var i = 0; i < 3; i++)
                  Card(
                    elevation: 0,
                    color: kSoft,
                    child: ListTile(
                      leading: const Icon(Icons.check_circle_rounded, color: kGreen),
                      title: Text(items[(p.current + i) % items.length].word, style: const TextStyle(fontWeight: FontWeight.w900)),
                      subtitle: const Text('Completed • Today'),
                    ),
                  ),
              ],
            ),
          );
        },
      );

  Widget _stat(String v, String l) => Card(
        elevation: 0,
        color: kCard,
        child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [
          Text(v, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kGreen)),
          const SizedBox(height: 4),
          Text(l, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: kMuted)),
        ])),
      );
}

class MilestoneConversationScreen extends StatefulWidget {
  const MilestoneConversationScreen({super.key});
  @override
  State<MilestoneConversationScreen> createState() => _MilestoneConversationScreenState();
}
class _MilestoneConversationScreenState extends State<MilestoneConversationScreen> {
  final _ctrl = TextEditingController();
  final _msgs = <Map<String, String>>[
    {'who': 'them', 'text': '¡Hola! Welcome. What would you like today?'},
  ];
  void _send() {
    final t = _ctrl.text.trim();
    if (t.isEmpty) return;
    setState(() {
      _msgs.add({'who': 'me', 'text': t});
      _msgs.add({'who': 'them', 'text': 'Great! Continue please.'});
      _ctrl.clear();
    });
  }
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(title: const Text('Milestone 3 • Conversation'), centerTitle: true),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              ClipRRect(borderRadius: BorderRadius.circular(28), child: SizedBox(width: 56, height: 56, child: Photo('native_speaker_woman.jpg'))),
              const SizedBox(width: 12),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Ana • Native Speaker', style: TextStyle(fontWeight: FontWeight.w900, color: kInk)),
                Text('Online • Speaks from Madrid', style: TextStyle(color: kMuted, fontSize: 11)),
              ])),
            ]),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: _msgs.length,
              itemBuilder: (_, i) {
                final m = _msgs[i];
                final me = m['who'] == 'me';
                return Align(
                  alignment: me ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: me ? kGreen : kCard, borderRadius: BorderRadius.circular(14)),
                    child: Text(m['text']!, style: TextStyle(color: me ? Colors.white : kInk)),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Expanded(child: TextField(controller: _ctrl, decoration: const InputDecoration(hintText: 'Type your response...'))),
              const SizedBox(width: 8),
              SizedBox(width: 52, height: 52, child: FilledButton(onPressed: _send, style: FilledButton.styleFrom(shape: const CircleBorder()), child: const Icon(Icons.send_rounded))),
            ]),
          ),
        ]),
      );
}

class AdaptiveRecallScreen extends StatefulWidget {
  const AdaptiveRecallScreen({super.key});
  @override
  State<AdaptiveRecallScreen> createState() => _AdaptiveRecallScreenState();
}
class _AdaptiveRecallScreenState extends State<AdaptiveRecallScreen> {
  int _q = 0;
  int _correct = 0;
  static const total = 10;
  LearnItem get item => items[(_q * 7 + 3) % items.length];
  List<String> get options {
    final r = Random(_q + 11);
    final pool = items.where((x) => x.image != item.image).map((x) => x.image).toList()..shuffle(r);
    return [item.image, ...pool.take(3)];
  }
  @override
  Widget build(BuildContext context) {
    if (_q >= total) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(title: const Text('Review • Adaptive Recall'), centerTitle: true),
        body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.check_circle_rounded, size: 76, color: kGreen),
          const SizedBox(height: 14),
          Text('$_correct / $total', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: kInk)),
          const SizedBox(height: 18),
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Continue')),
        ])),
      );
    }
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Review • Adaptive Recall'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          Text('Question ${_q + 1} of $total', style: const TextStyle(fontWeight: FontWeight.w900, color: kInk)),
          const SizedBox(height: 6),
          ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: (_q + 1) / total, color: kGreen, backgroundColor: kCard, minHeight: 8)),
          const SizedBox(height: 16),
          Text('Which photo shows "${item.word}"?', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: kInk)),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: options.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.05),
            itemBuilder: (context, i) {
              return GestureDetector(
                onTap: () {
                  if (options[i] == item.image) _correct++;
                  setState(() => _q++);
                },
                child: ClipRRect(borderRadius: BorderRadius.circular(14), child: Photo(options[i])),
              );
            },
          ),
          const SizedBox(height: 14),
          const Text('Adaptive Recall • Streak: 4 days', textAlign: TextAlign.center, style: TextStyle(color: kMuted)),
        ],
      ),
    );
  }
}
