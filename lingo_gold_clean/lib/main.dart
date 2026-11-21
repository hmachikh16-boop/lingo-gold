import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ===== Palette: green / white / dark / light gray only =====
const kGreen = Color(0xFF2E9E5B);
const kGreenDark = Color(0xFF1F7A44);
const kInk = Color(0xFF14213D);
const kMuted = Color(0xFF6B7280);
const kCard = Color(0xFFF5F6F8);
const kLine = Color(0xFFE6E8EC);
const kSoft = Color(0xFFE9F7EF);

// ===== Data =====
class LearnItem {
  final String word;
  final String sentence;
  final String image;
  const LearnItem(this.word, this.sentence, this.image);
}

const items = <LearnItem>[
  LearnItem('A boy', 'The boy smiles.', 'q0.jpg'),
  LearnItem('A girl', 'The girl smiles.', 'img_girl_child.jpg'),
  LearnItem('A dog', 'The dog sits.', 'q2.jpg'),
  LearnItem('A cat', 'The cat sits.', 'q6.jpg'),
  LearnItem('An apple', 'The apple is red.', 'q4.jpg'),
  LearnItem('A car', 'The car is blue.', 'q5.jpg'),
  LearnItem('A house', 'This is a house.', 'q7.jpg'),
  LearnItem('A man', 'The man eats.', 'q8.jpg'),
  LearnItem('The sun', 'The sun is bright.', 'q9.jpg'),
  LearnItem('A baker', 'He is a baker.', 'job_baker.jpg'),
  LearnItem('A chef', 'He is a chef.', 'job_chef.jpg'),
  LearnItem('A teacher', 'She is a teacher.', 'job_teacher.jpg'),
  LearnItem('An artist', 'He is an artist.', 'job_artist.jpg'),
  LearnItem('A doctor', 'He is a doctor.', 'job_doctor.jpg'),
  LearnItem('A nurse', 'She is a nurse.', 'job_nurse.jpg'),
  LearnItem('A police officer', 'He is a police officer.', 'job_police.jpg'),
  LearnItem('A student', 'She is a student.', 'job_student.jpg'),
  LearnItem('A firefighter', 'He is a firefighter.', 'job_firefighter.jpg'),
  LearnItem('A farmer', 'He is a farmer.', 'job_farmer.jpg'),
  LearnItem('A pilot', 'He is a pilot.', 'job_pilot.jpg'),
  LearnItem('Flowers', 'These are flowers.', 'nat_flower.jpg'),
  LearnItem('A leaf', 'This is a leaf.', 'nat_leaf.jpg'),
  LearnItem('Snow', 'The snow is white.', 'nat_snow.jpg'),
  LearnItem('A wave', 'This is a wave.', 'nat_wave.jpg'),
];

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
              ],
            ),
          );
        },
      );
}

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
