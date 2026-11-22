import 'dart:js_interop';
import 'dart:math';

import 'package:flutter/material.dart';

import 'assets_manifest.dart';
import 'generated_assets.dart';

@JS('lingoTone')
external bool _lingoTone(int index);

void playTone(int index) {
  try {
    _lingoTone(index);
  } catch (_) {}
}

@JS('lingoSpeak')
external bool _lingoSpeak(String text);

@JS('lingoStartListening')
external bool _lingoStartListening();

@JS('lingoGetTranscript')
external String _lingoGetTranscript();

@JS('lingoLoadProgress')
external String _lingoLoadProgress();

@JS('lingoSaveProgress')
external void _lingoSaveProgress(int xp, int stars);

void speak(String text) {
  try {
    _lingoSpeak(text);
  } catch (_) {}
}

bool startListening() {
  try {
    return _lingoStartListening();
  } catch (_) {
    return false;
  }
}

String heardText() {
  try {
    return _lingoGetTranscript();
  } catch (_) {
    return '';
  }
}

({int xp, int stars}) loadSavedProgress() {
  try {
    final raw = _lingoLoadProgress();
    final parts = raw.split(':');
    if (parts.length == 2) {
      return (xp: int.tryParse(parts[0]) ?? 0, stars: int.tryParse(parts[1]) ?? 0);
    }
  } catch (_) {}
  return (xp: 0, stars: 0);
}

void saveProgress(int xp, int stars) {
  try {
    _lingoSaveProgress(xp, stars);
  } catch (_) {}
}

int simpleScore(String expected, String heard) {
  List<String> words(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r"[^a-z0-9 ]"), ' ')
      .split(RegExp(r'\s+'))
      .where((e) => e.isNotEmpty)
      .toList();
  final want = words(expected);
  final said = words(heard);
  if (want.isEmpty || said.isEmpty) return 0;
  final hits = want.where((w) => said.contains(w)).length;
  return (hits / want.length * 100).round();
}

void main() => runApp(const ReplicaApp());

const kGreen = Color(0xFF2E9E5B);
const kGreenDark = Color(0xFF1F7A44);
const kGreenSoft = Color(0xFFE9F7EF);
const kInk = Color(0xFF1F2328);
const kMuted = Color(0xFF6B7280);
const kCanvas = Color(0xFFF0EFEA);
const kLine = Color(0xFFD8D8D0);

const totalSteps = 40;

class PhotoPrompt {
  final String phrase;
  final String image;
  const PhotoPrompt(this.phrase, this.image);
}

/// In the reference course a lesson reuses the SAME six photos across its
/// steps, only shuffling their order. We reproduce that methodology with our
/// own photos, grouped into three six-photo sets.
const photoSets = <List<String>>[
  [
    'L153_the_dog.jpg', 'L152_the_cat.jpg', 'L165_a_blue_pen.jpg',
    'L220_a_red_car.jpg', 'L223_bicycle.jpg', 'L169_a_brown_egg.jpg',
  ],
  [
    'num_01.jpg', 'num_02.jpg', 'num_03.jpg',
    'num_04.jpg', 'num_05.jpg', 'num_06.jpg',
  ],
  [
    'L148_schoolboy.jpg', 'L149_schoolgirl.jpg', 'L164_a_green_book.jpg',
    'fox.jpg', 'cat_sleeping_window.jpg', 'market_morning.jpg',
  ],
];

const phraseFor = <String, String>{
  'num_01.jpg': 'one apple',
  'num_02.jpg': 'two apples',
  'num_03.jpg': 'three apples',
  'num_04.jpg': 'four apples',
  'num_05.jpg': 'five apples',
  'num_06.jpg': 'six apples',
  'L153_the_dog.jpg': 'a dog',
  'L152_the_cat.jpg': 'a cat',
  'L165_a_blue_pen.jpg': 'a pen',
  'L220_a_red_car.jpg': 'a car',
  'L223_bicycle.jpg': 'a bicycle',
  'L169_a_brown_egg.jpg': 'an egg',
  'L148_schoolboy.jpg': 'a schoolboy',
  'L149_schoolgirl.jpg': 'a schoolgirl',
  'L164_a_green_book.jpg': 'a book',
  'fox.jpg': 'a fox',
  'cat_sleeping_window.jpg': 'a sleeping cat',
  'market_morning.jpg': 'a market',
};

PhotoPrompt promptForStep(int step) {
  final set = photoSets[min(step ~/ 13, photoSets.length - 1)];
  final correct = set[step % set.length];
  return PhotoPrompt(phraseFor[correct] ?? 'a photo', correct);
}

List<String> gridForStep(int step) {
  final set = photoSets[min(step ~/ 13, photoSets.length - 1)];
  return List<String>.from(set)..shuffle(Random(step + 37));
}

enum AppScreen { course, lesson, context, assetLab, read, write, listen, speak }

class ReplicaApp extends StatefulWidget {
  const ReplicaApp({super.key});

  @override
  State<ReplicaApp> createState() => _ReplicaAppState();
}

class _ReplicaAppState extends State<ReplicaApp> {
  bool _classic = false;

  void _toggleTheme() => setState(() => _classic = !_classic);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lingo Gold — Language Training',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Nunito',
        textTheme: ThemeData(useMaterial3: true).textTheme.apply(
              fontFamily: 'Nunito',
              fontFamilyFallback: const ['Cairo'],
            ),
        colorScheme: ColorScheme.fromSeed(seedColor: kGreen, primary: kGreen),
        scaffoldBackgroundColor: _classic ? const Color(0xFFE8E6DE) : kCanvas,
      ),
      home: ReplicaShell(classic: _classic, onToggleTheme: _toggleTheme),
    );
  }
}

class ReplicaShell extends StatefulWidget {
  final bool classic;
  final VoidCallback onToggleTheme;
  const ReplicaShell({super.key, required this.classic, required this.onToggleTheme});

  @override
  State<ReplicaShell> createState() => _ReplicaShellState();
}

class _ReplicaShellState extends State<ReplicaShell> {
  AppScreen _screen = _initialScreen();

  static AppScreen _initialScreen() {
    final value = Uri.base.queryParameters['screen'];
    if (value == 'lesson') return AppScreen.lesson;
    if (value == 'context') return AppScreen.context;
    if (value == 'asset') return AppScreen.assetLab;
    if (value == 'read') return AppScreen.read;
    if (value == 'write') return AppScreen.write;
    if (value == 'listen') return AppScreen.listen;
    if (value == 'speak') return AppScreen.speak;
    return AppScreen.course;
  }
  int _step = 0;
  int? _selected;
  bool _checked = false;
  bool _lastCorrect = false;
  int _right = 0;
  int _wrong = 0;
  bool _finished = false;
  int _xp = 0;
  int _stars = 0;

  @override
  void initState() {
    super.initState();
    final saved = loadSavedProgress();
    _xp = saved.xp;
    _stars = saved.stars;
  }

  void _openLesson() {
    playTone(0);
    setState(() {
      _screen = AppScreen.lesson;
      _step = 0;
      _selected = null;
      _checked = false;
      _right = 0;
      _wrong = 0;
      _finished = false;
    });
  }

  void _openCourse() => setState(() => _screen = AppScreen.course);

  void _openContext() => setState(() => _screen = AppScreen.context);

  void _checkAnswer(String correctImage) {
    final correct = _selected != null && gridForStep(_step)[_selected!] == correctImage;
    playTone(correct ? 1 : 2);
    setState(() {
      _checked = true;
      _lastCorrect = correct;
      if (correct) {
        _right++;
        _xp += 10;
      } else {
        _wrong++;
        _xp += 2;
      }
      saveProgress(_xp, _stars);
    });
  }

  void _advance() {
    if (!_checked) return;
    playTone(3);
    if (_step < totalSteps - 1) {
      setState(() {
        _step++;
        _selected = null;
        _checked = false;
      });
      return;
    }
    final earned = _wrong == 0 ? 3 : (_wrong <= 3 ? 2 : 1);
    playTone(4);
    setState(() {
      _stars = earned > _stars ? earned : _stars;
      _finished = true;
      saveProgress(_xp, _stars);
    });
  }

  @override
  Widget build(BuildContext context) {
    final breadcrumb = switch (_screen) {
      AppScreen.course => 'Language Basics',
      AppScreen.lesson => 'Unit 1  >  Lesson 4  >  Core Lesson',
      AppScreen.assetLab => 'Asset Lab  >  Structure',
      AppScreen.read => 'Unit 1  >  Lesson 4  >  Read',
      AppScreen.write => 'Unit 1  >  Lesson 4  >  Write',
      AppScreen.listen => 'Unit 1  >  Lesson 4  >  Listen',
      AppScreen.speak => 'Unit 1  >  Lesson 4  >  Speak',
      _ => 'Unit 1  >  Lesson 4  >  Pronunciation',
    };

    return Scaffold(
      backgroundColor: widget.classic ? const Color(0xFFE8E6DE) : kCanvas,
      body: Column(
        children: [
          _Header(
            breadcrumb: breadcrumb,
            onHome: _openCourse,
            xp: _xp,
            stars: _stars,
            classic: widget.classic,
            onToggle: widget.onToggleTheme,
          ),
          Expanded(
            child: _screen == AppScreen.course
                ? CourseMap(
                    onStart: _openLesson,
                    onContext: _openContext,
                    onAssetLab: () => setState(() => _screen = AppScreen.assetLab),
                    onActivity: (kind) => setState(() => _screen = kind),
                    xp: _xp,
                    stars: _stars,
                    classic: widget.classic,
                  )
                : _screen == AppScreen.lesson
                    ? LessonScreen(
                        step: _step,
                        selected: _selected,
                        checked: _checked,
                        lastCorrect: _lastCorrect,
                        finished: _finished,
                        right: _right,
                        wrong: _wrong,
                        onSelect: (i) => setState(() => _selected = i),
                        onCheck: _checkAnswer,
                        onAdvance: _advance,
                        onHome: _openCourse,
                      )
                    : _screen == AppScreen.assetLab
                        ? AssetLabScreen(onHome: _openCourse)
                        : (_screen == AppScreen.read ||
                                _screen == AppScreen.write ||
                                _screen == AppScreen.listen ||
                                _screen == AppScreen.speak)
                            ? ActivityScreen(kind: _screen, onHome: _openCourse)
                            : ContextScreen(
                                onHome: _openCourse,
                                onLesson: _openLesson,
                                onXp: (amount) {
                                  setState(() {
                                    _xp += amount;
                                    saveProgress(_xp, _stars);
                                  });
                                },
                              ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String breadcrumb;
  final VoidCallback onHome;
  final int xp;
  final int stars;
  final bool classic;
  final VoidCallback onToggle;
  const _Header({
    required this.breadcrumb,
    required this.onHome,
    required this.xp,
    required this.stars,
    required this.classic,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      color: classic ? const Color(0xFF1F2328) : kGreenDark,
      child: Row(
        children: [
          Container(
            width: 190,
            height: 52,
            color: kGreen,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: const [
                Icon(Icons.eco_rounded, color: Colors.white, size: 21),
                SizedBox(width: 7),
                Text(
                  'Lingo Gold',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            'English (American)',
            style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          Text(
            breadcrumb,
            style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w800),
          ),
          const Spacer(),
          Row(
            children: [
              const Icon(Icons.bolt_rounded, color: Colors.white, size: 16),
              const SizedBox(width: 3),
              Text('$xp', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
              const SizedBox(width: 12),
              const Icon(Icons.star_rounded, color: Colors.white, size: 16),
              const SizedBox(width: 3),
              Text('$stars', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
            ],
          ),
          const SizedBox(width: 10),
          IconButton(
            icon: Icon(classic ? Icons.light_mode_rounded : Icons.auto_awesome_rounded, color: Colors.white, size: 20),
            tooltip: classic ? 'Green theme' : 'Original-style theme',
            onPressed: onToggle,
          ),
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: Colors.white, size: 20),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.volume_up_rounded, color: Colors.white, size: 20),
            onPressed: () => speak('English American'),
          ),
          IconButton(
            icon: const Icon(Icons.home_rounded, color: Colors.white, size: 20),
            onPressed: onHome,
          ),
        ],
      ),
    );
  }
}

class LessonScreen extends StatelessWidget {
  final int step;
  final int? selected;
  final bool checked;
  final bool lastCorrect;
  final bool finished;
  final int right;
  final int wrong;
  final ValueChanged<int> onSelect;
  final ValueChanged<String> onCheck;
  final VoidCallback onAdvance;
  final VoidCallback onHome;

  const LessonScreen({
    super.key,
    required this.step,
    required this.selected,
    required this.checked,
    required this.lastCorrect,
    required this.finished,
    required this.right,
    required this.wrong,
    required this.onSelect,
    required this.onCheck,
    required this.onAdvance,
    required this.onHome,
  });

  @override
  Widget build(BuildContext context) {
    final prompt = promptForStep(step);
    final images = gridForStep(step);
    return Column(
      children: [
        const SizedBox(height: 18),
        Center(
          child: Container(
            width: 460,
            height: 62,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 8)],
            ),
            child: Row(
              children: [
                const SizedBox(width: 22),
                Expanded(
                  child: Text(
                    prompt.phrase,
                    style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: kInk),
                  ),
                ),
                GestureDetector(
                  onTap: () => speak(prompt.phrase),
                  child: Container(
                    width: 27,
                    height: 27,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 3)]),
                    child: const Icon(Icons.volume_up_rounded, color: kGreen, size: 19),
                  ),
                ),
                const SizedBox(width: 18),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: finished
                  ? _FinishedCard(right: right, wrong: wrong, onHome: onHome)
                  : GridView.count(
                      crossAxisCount: 3,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.98,
                      children: [
                        for (var i = 0; i < images.length; i++)
                          AnimatedScale(
                            scale: selected == i ? motionScale(step + i) : 1.0,
                            duration: motionDuration(step + i),
                            curve: shapeCurve(step + i),
                            child: _PhotoTile(
                              image: images[i],
                              selected: selected == i,
                              checked: checked,
                              correct: checked && images[i] == prompt.image,
                              radius: shapeRadius(step + i),
                              onTap: checked ? null : () => onSelect(i),
                            ),
                          ),
                      ],
                    ),
            ),
          ),
        ),
        _StepBar(
          step: step,
          right: right,
          wrong: wrong,
          label: checked ? 'Continue' : 'Check',
          onCheck: checked ? onAdvance : (selected == null ? null : () => onCheck(prompt.image)),
          onHome: onHome,
        ),
      ],
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final String image;
  final bool selected;
  final bool checked;
  final bool correct;
  final double radius;
  final VoidCallback? onTap;
  const _PhotoTile({
    super.key,
    required this.image,
    required this.selected,
    required this.checked,
    required this.correct,
    required this.radius,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: correct ? kGreen : (selected ? kGreen : const Color(0xFFC9C9C2)),
            width: correct || selected ? 4 : 2,
          ),
          boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 5)],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Column(
                children: [
                  Container(height: 48, color: kCanvas),
                  Expanded(
                    child: Image.asset('assets/images/$image', fit: BoxFit.cover, width: double.infinity),
                  ),
                ],
              ),
            ),
            if (checked && (correct || selected))
              Positioned.fill(
                child: Container(
                  color: const Color(0x22000000),
                  alignment: Alignment.center,
                  child: Icon(
                    correct ? Icons.check_circle_rounded : Icons.cancel_outlined,
                    size: 52,
                    color: correct ? kGreen : kMuted,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FinishedCard extends StatelessWidget {
  final int right;
  final int wrong;
  final VoidCallback onHome;
  const _FinishedCard({required this.right, required this.wrong, required this.onHome});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 560,
        padding: const EdgeInsets.all(34),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: kLine)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events_rounded, size: 70, color: kGreen),
            const SizedBox(height: 14),
            const Text('Core Lesson Complete', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: kInk)),
            const SizedBox(height: 10),
            Text('$right correct  •  $wrong to repeat', style: const TextStyle(fontSize: 14, color: kMuted)),
            const SizedBox(height: 22),
            FilledButton(onPressed: onHome, child: const Text('Back to course map')),
          ],
        ),
      ),
    );
  }
}

class _StepBar extends StatelessWidget {
  final int step;
  final int right;
  final int wrong;
  final VoidCallback? onCheck;
  final VoidCallback onHome;
  final String label;
  const _StepBar({
    super.key,
    required this.step,
    required this.right,
    required this.wrong,
    required this.onCheck,
    required this.onHome,
    this.label = 'Continue',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      color: const Color(0xFFE4E2D9),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.home_rounded, color: kGreenDark, size: 22), onPressed: onHome),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: totalSteps,
              itemBuilder: (context, i) {
                final current = i == step;
                final done = i < step;
                return Container(
                  width: 30,
                  alignment: Alignment.center,
                  child: current
                      ? Container(
                          width: 27,
                          height: 27,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: kGreenSoft, borderRadius: BorderRadius.circular(7), border: Border.all(color: kGreen, width: 2)),
                          child: Text('${i + 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: kGreenDark)),
                        )
                      : Text(
                          '${i + 1}',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: done ? kGreenDark : kMuted),
                        ),
                );
              },
            ),
          ),
          _SmallCount(icon: Icons.check_rounded, value: right, color: kGreen),
          const SizedBox(width: 8),
          _SmallCount(icon: Icons.close_rounded, value: wrong, color: kMuted),
          const SizedBox(width: 8),
          Container(
            height: 40,
            decoration: BoxDecoration(color: onCheck == null ? const Color(0xFFCFCFC7) : kGreen, borderRadius: BorderRadius.circular(10)),
            child: FilledButton.icon(
              onPressed: onCheck,
              icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
              label: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                minimumSize: const Size(0, 40),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}

class _SmallCount extends StatelessWidget {
  final IconData icon;
  final int value;
  final Color color;
  const _SmallCount({required this.icon, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 2),
          Text('$value', style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 13)),
        ],
      );
}

class CourseMap extends StatelessWidget {
  final VoidCallback onStart;
  final VoidCallback onContext;
  final VoidCallback onAssetLab;
  final ValueChanged<AppScreen> onActivity;
  final int xp;
  final int stars;
  final bool classic;
  const CourseMap({
    super.key,
    required this.onStart,
    required this.onContext,
    required this.onAssetLab,
    required this.onActivity,
    required this.xp,
    required this.stars,
    required this.classic,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(40, 20, 40, 30),
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: kGreenDark, borderRadius: BorderRadius.circular(8)),
              child: const Text('LINGO COURSE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
            ),
            const SizedBox(width: 14),
            const Spacer(),
            for (var level = 1; level <= 5; level++) ...[
              _LevelTab(level: level, active: level == 1),
              if (level < 5) const SizedBox(width: 8),
            ],
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            const Text('Language Basics', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: kInk)),
            const SizedBox(width: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: kGreenSoft, borderRadius: BorderRadius.circular(14)),
              child: Text('${photoPool.length} local photos', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: kGreenDark)),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: kGreenSoft, borderRadius: BorderRadius.circular(14)),
              child: Text('$xp XP  •  $stars ★', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: kGreenDark)),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _Path(onStart: onStart),
        const SizedBox(height: 26),
        Center(
          child: Container(
            width: 720,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: kLine)),
            child: Row(
              children: [
                ClipRRect(borderRadius: BorderRadius.circular(10), child: SizedBox(width: 96, height: 74, child: Image.asset('assets/images/L152_the_cat.jpg', fit: BoxFit.cover))),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Unit 1, Lesson 4', style: TextStyle(fontSize: 13, color: kMuted, fontWeight: FontWeight.w700)),
                      Text('Core Lesson', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: kInk)),
                      Text('In Progress', style: TextStyle(fontSize: 11, color: kGreenDark, fontWeight: FontWeight.w800)),
                      Text('About 30 minutes', style: TextStyle(fontSize: 11, color: kMuted)),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: onStart,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Start'),
                  style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 30),
        Center(
          child: SizedBox(
            width: 860,
            height: 150,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final img in [
                  'L148_schoolboy.jpg',
                  'L164_a_green_book.jpg',
                  'fish_placeholder',
                  'L149_schoolgirl.jpg',
                  'market_morning.jpg',
                ])
                  Transform.rotate(
                    angle: (img.hashCode % 3 - 1) * 0.07,
                    child: Container(
                      width: 150,
                      height: 132,
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(color: Colors.white, boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 8)]),
                      child: img == 'fish_placeholder'
                          ? const ColoredBox(color: kCanvas)
                          : Image.asset('assets/images/$img', fit: BoxFit.cover),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        Center(
          child: TextButton.icon(
            onPressed: onContext,
            icon: const Icon(Icons.volume_up_rounded, color: kGreenDark),
            label: const Text('Explore all activities for Unit 1', style: TextStyle(color: kGreenDark, fontWeight: FontWeight.w800)),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Wrap(
            spacing: 8,
            children: [
              _ActivityChip(label: 'Read', icon: Icons.menu_book_rounded, onTap: () => onActivity(AppScreen.read)),
              _ActivityChip(label: 'Write', icon: Icons.edit_rounded, onTap: () => onActivity(AppScreen.write)),
              _ActivityChip(label: 'Listen', icon: Icons.hearing_rounded, onTap: () => onActivity(AppScreen.listen)),
              _ActivityChip(label: 'Speak', icon: Icons.mic_rounded, onTap: () => onActivity(AppScreen.speak)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: TextButton.icon(
            onPressed: onAssetLab,
            icon: const Icon(Icons.category_rounded, color: kGreenDark),
            label: const Text('Asset Lab — 683 motions • 256 shapes • 10 photos • 8 sounds', style: TextStyle(color: kGreenDark, fontWeight: FontWeight.w800)),
          ),
        ),
      ],
    );
  }
}

class _LevelTab extends StatelessWidget {
  final int level;
  final bool active;
  const _LevelTab({required this.level, required this.active});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text('Level $level', style: const TextStyle(color: kMuted, fontSize: 9.5, fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          Row(
            children: [
              for (var i = 1; i <= 4; i++)
                Container(
                  width: 17,
                  height: 17,
                  margin: const EdgeInsets.only(right: 2),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: active && i == 4 ? kGreen : (active ? kGreenSoft : const Color(0xFFD7D7CF)),
                    shape: BoxShape.circle,
                  ),
                  child: Text('$i', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: active ? kGreenDark : kMuted)),
                ),
            ],
          ),
        ],
      );
}

class _Path extends StatelessWidget {
  final VoidCallback onStart;
  const _Path({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < 14; i++) ...[
            if (i == 1 || i == 5 || i == 9)
              _Diamond(number: [1, 2, 3][[1, 5, 9].indexOf(i)], active: i == 9, onTap: onStart)
            else
              Container(width: 12, height: 10, color: const Color(0xFFCFCFC7)),
            if (i < 13) const SizedBox(width: 3),
          ],
        ],
      ),
    );
  }
}

class _Diamond extends StatelessWidget {
  final int number;
  final bool active;
  final VoidCallback onTap;
  const _Diamond({required this.number, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: active ? onTap : null,
        child: Transform.rotate(
          angle: pi / 4,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: active ? kGreen : kGreenSoft,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: kGreenDark, width: 2),
            ),
            child: Transform.rotate(
              angle: -pi / 4,
              child: Center(
                child: Text('$number', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: active ? Colors.white : kGreenDark)),
              ),
            ),
          ),
        ),
      );
}

class ContextScreen extends StatefulWidget {
  final VoidCallback onHome;
  final VoidCallback onLesson;
  final ValueChanged<int> onXp;
  const ContextScreen({super.key, required this.onHome, required this.onLesson, required this.onXp});

  @override
  State<ContextScreen> createState() => _ContextScreenState();
}

class _ContextScreenState extends State<ContextScreen> {
  int _right = 0;
  int _wrong = 0;
  int? _selected;
  bool _checked = false;
  bool _listening = false;
  int? _pronScore;
  String? _heard;

  Future<void> _checkPronunciation() async {
    if (_listening) return;
    if (!startListening()) {
      setState(() => _heard = 'Speech recognition is not available in this browser.');
      return;
    }
    setState(() {
      _listening = true;
      _heard = null;
    });
    await Future<void>.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    final heard = heardText();
    final score = heard.isEmpty ? 0 : simpleScore('Hello', heard);
    setState(() {
      _listening = false;
      _heard = heard.isEmpty ? 'No speech detected. Try again.' : 'Heard: “$heard”';
      _pronScore = score;
    });
    if (score >= 70) {
      playTone(5);
      widget.onXp(10);
    }
  }

  void _choose(bool correct) {
    playTone(correct ? 1 : 2);
    setState(() {
      _selected = correct ? 0 : 1;
      _checked = true;
      if (correct) {
        _right++;
      } else {
        _wrong++;
      }
    });
  }

  void _retry() {
    playTone(6);
    setState(() {
      _right = 0;
      _wrong = 0;
      _selected = null;
      _checked = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 46),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 60),
          child: Row(
            children: [
              _ContextCard(
                image: 'img_girl_child.jpg',
                phrase: 'Hello.',
                selected: _selected == 0,
                showCorrect: _checked && _selected == 0,
                onTap: () => _choose(true),
              ),
              const SizedBox(width: 16),
              _ContextCard(
                image: 'L152_the_cat.jpg',
                phrase: 'Hello.',
                selected: _selected == 1,
                showCorrect: false,
                onTap: () => _choose(false),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: kLine)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_rounded, color: kGreen, size: 22),
                Text('$_right', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kGreen)),
                const SizedBox(width: 12),
                Container(width: 1, height: 26, color: kLine),
                const SizedBox(width: 12),
                const Icon(Icons.close_rounded, color: kMuted, size: 22),
                Text('$_wrong', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kMuted)),
                const SizedBox(width: 16),
                FilledButton.icon(
                  onPressed: _retry,
                  icon: const Icon(Icons.replay_rounded, size: 17),
                  label: const Text('Try again'),
                  style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), minimumSize: const Size(0, 40)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Container(
            width: 560,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: kLine)),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(color: kGreenSoft, shape: BoxShape.circle),
                      child: const Icon(Icons.mic_rounded, color: kGreen, size: 19),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pronunciation check', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: kInk)),
                          Text('Say “Hello.” and let the browser score it.', style: TextStyle(fontSize: 10.5, color: kMuted)),
                        ],
                      ),
                    ),
                    Text(
                      _pronScore == null ? '—' : '$_pronScore%',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: kGreenDark),
                    ),
                  ],
                ),
                if (_heard != null) ...[
                  const SizedBox(height: 8),
                  Text(_heard!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: kMuted)),
                ],
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: _checkPronunciation,
                  icon: Icon(_listening ? Icons.graphic_eq_rounded : Icons.mic_rounded, size: 17),
                  label: Text(_listening ? 'Listening…' : 'Check pronunciation'),
                  style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), minimumSize: const Size(0, 40)),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        _StepBar(step: 3, right: _right, wrong: _wrong, onCheck: null, onHome: widget.onHome),
      ],
    );
  }
}

class _ContextCard extends StatelessWidget {
  final String image;
  final String phrase;
  final bool selected;
  final bool showCorrect;
  final VoidCallback onTap;
  const _ContextCard({
    required this.image,
    required this.phrase,
    required this.selected,
    required this.showCorrect,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: showCorrect || selected ? kGreen : kLine,
                width: showCorrect || selected ? 4 : 1,
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(child: Text(phrase, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: kInk))),
                      GestureDetector(
                        onTap: () => speak(phrase),
                        child: const Icon(Icons.volume_up_rounded, color: kGreen, size: 24),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 330,
                  child: Image.asset('assets/images/$image', fit: BoxFit.cover, width: double.infinity),
                ),
              ],
            ),
          ),
        ),
      );
}

/// A visible inventory of the original elements created for this replica,
/// matching the categories and counts found in the SWF structure table.
class AssetLabScreen extends StatefulWidget {
  final VoidCallback onHome;
  const AssetLabScreen({super.key, required this.onHome});

  @override
  State<AssetLabScreen> createState() => _AssetLabScreenState();
}

class _AssetLabScreenState extends State<AssetLabScreen> {
  int _motionIndex = 0;
  bool _big = false;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(40, 24, 40, 40),
      children: [
        Row(
          children: [
            const Text('Asset Lab', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: kInk)),
            const Spacer(),
            TextButton.icon(onPressed: widget.onHome, icon: const Icon(Icons.home_rounded), label: const Text('Back')),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _StatCard(label: 'Motion presets', value: '$motionCount', icon: Icons.animation_rounded),
            _StatCard(label: 'Vector shapes', value: '$shapeCount', icon: Icons.category_rounded),
            _StatCard(label: 'Photos', value: '${featuredPhotos.length}', icon: Icons.photo_rounded),
            _StatCard(label: 'Sounds', value: '$soundCount', icon: Icons.audiotrack_rounded),
          ],
        ),
        const SizedBox(height: 26),
        const Text('683 motion presets', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kInk)),
        const SizedBox(height: 10),
        Row(
          children: [
            AnimatedScale(
              scale: _big ? motionScale(_motionIndex) : 1.0,
              duration: motionDuration(_motionIndex),
              curve: shapeCurve(_motionIndex),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(color: kGreen, borderRadius: BorderRadius.circular(shapeRadius(_motionIndex))),
                child: Center(
                  child: Text('${_motionIndex + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                ),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Preset ${_motionIndex + 1} of $motionCount', style: const TextStyle(fontSize: 13, color: kMuted)),
                  Text('Duration ${motionDuration(_motionIndex).inMilliseconds} ms', style: const TextStyle(fontSize: 12, color: kMuted)),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () {
                      playTone(0);
                      setState(() {
                        _big = !_big;
                        _motionIndex = (_motionIndex + 1) % motionCount;
                      });
                    },
                    child: const Text('Play next motion'),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 26),
        const Text('256 vector shapes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kInk)),
        const SizedBox(height: 10),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: shapeCount,
            itemBuilder: (context, i) => Container(
              width: 62,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(color: shapeTint(i), borderRadius: BorderRadius.circular(shapeRadius(i)), border: Border.all(color: kLine)),
              child: Center(child: Text('$i', style: const TextStyle(fontSize: 10, color: kGreenDark, fontWeight: FontWeight.w900))),
            ),
          ),
        ),
        const SizedBox(height: 26),
        const Text('10 photos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kInk)),
        const SizedBox(height: 10),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: featuredPhotos.length,
            itemBuilder: (context, i) => Container(
              width: 150,
              margin: const EdgeInsets.only(right: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset('assets/images/${featuredPhotos[i]}', fit: BoxFit.cover),
              ),
            ),
          ),
        ),
        const SizedBox(height: 26),
        const Text('8 generated sounds', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kInk)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          children: [
            for (var i = 0; i < soundCount; i++)
              OutlinedButton(
                onPressed: () => playTone(i),
                child: Text('Tone ${i + 1}'),
              ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
        width: 170,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: kLine)),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(color: kGreenSoft, shape: BoxShape.circle),
              child: Icon(icon, color: kGreen, size: 19),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: kInk)),
                  Text(label, style: const TextStyle(fontSize: 10, color: kMuted)),
                ],
              ),
            ),
          ],
        ),
      );
}

class _ActivityChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _ActivityChip({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => ActionChip(
        backgroundColor: Colors.white,
        side: const BorderSide(color: kLine),
        onPressed: onTap,
        avatar: Icon(icon, color: kGreen, size: 17),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: kInk)),
      );
}

/// Read / Write / Listen / Speak activities in the same visual language.
class ActivityScreen extends StatefulWidget {
  final AppScreen kind;
  final VoidCallback onHome;
  const ActivityScreen({super.key, required this.kind, required this.onHome});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  final _controller = TextEditingController();
  int? _selected;
  bool _checked = false;
  bool _correct = false;
  bool _listening = false;
  int? _score;

  static const item = PhotoPrompt('a dog', 'L153_the_dog.jpg');
  static const choices = <String>[
    'L153_the_dog.jpg',
    'L152_the_cat.jpg',
    'L220_a_red_car.jpg',
    'L223_bicycle.jpg',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _speakCheck() async {
    if (_listening) return;
    if (!startListening()) return;
    setState(() => _listening = true);
    await Future<void>.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    final heard = heardText();
    setState(() {
      _listening = false;
      _score = heard.isEmpty ? 0 : simpleScore(item.phrase, heard);
    });
    if ((_score ?? 0) >= 70) playTone(5);
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (widget.kind) {
      AppScreen.read => 'Read',
      AppScreen.write => 'Write',
      AppScreen.listen => 'Listen',
      _ => 'Speak',
    };
    return Column(
      children: [
        const SizedBox(height: 30),
        Center(
          child: Container(
            width: 520,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: kLine)),
            child: Row(
              children: [
                Expanded(child: Text(title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: kInk))),
                GestureDetector(
                  onTap: () => speak(item.phrase),
                  child: const Icon(Icons.volume_up_rounded, color: kGreen, size: 24),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(height: 260, width: double.infinity, child: Image.asset('assets/images/${item.image}', fit: BoxFit.cover)),
                  ),
                  const SizedBox(height: 16),
                  if (widget.kind == AppScreen.read) ...[
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: kLine)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.phrase, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: kInk)),
                          const SizedBox(height: 8),
                          const Text('Look at the photo and listen. Then say the phrase out loud.', style: TextStyle(fontSize: 13, color: kMuted, height: 1.5)),
                        ],
                      ),
                    ),
                  ] else if (widget.kind == AppScreen.write) ...[
                    TextField(
                      controller: _controller,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: 'Type the phrase…',
                        filled: true,
                        fillColor: kGreenSoft,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kGreen)),
                      ),
                    ),
                    if (_checked)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          _correct ? 'Correct!' : 'Correct phrase: ${item.phrase}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w900, color: kGreenDark),
                        ),
                      ),
                  ] else if (widget.kind == AppScreen.listen) ...[
                    const Text('Choose the photo you hear:', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: kInk)),
                    const SizedBox(height: 12),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 4,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      children: [
                        for (var i = 0; i < choices.length; i++)
                          GestureDetector(
                            onTap: _checked ? null : () => setState(() => _selected = i),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: _checked && i == 0 ? kGreen : (_selected == i ? kGreen : kLine),
                                    width: _selected == i || (_checked && i == 0) ? 3 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Image.asset('assets/images/${choices[i]}', fit: BoxFit.cover),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ] else ...[
                    Text('“${item.phrase}”', textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: kInk)),
                    const SizedBox(height: 12),
                    Text(_score == null ? 'Score —' : 'Score $_score%', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kGreenDark)),
                  ],
                  const SizedBox(height: 18),
                  Center(
                    child: FilledButton.icon(
                      onPressed: () {
                        if (widget.kind == AppScreen.write) {
                          playTone(3);
                          setState(() {
                            _checked = true;
                            _correct = _normalize(_controller.text) == _normalize(item.phrase);
                          });
                        } else if (widget.kind == AppScreen.listen) {
                          if (_selected == null) return;
                          playTone(_selected == 0 ? 1 : 2);
                          setState(() => _checked = true);
                        } else if (widget.kind == AppScreen.speak) {
                          _speakCheck();
                        } else {
                          playTone(3);
                          speak(item.phrase);
                        }
                      },
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: Text(widget.kind == AppScreen.speak ? 'Check pronunciation' : 'Continue'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        _StepBar(step: 3, right: _selected == 0 || _correct ? 1 : 0, wrong: _selected != null && _selected != 0 ? 1 : 0, onCheck: null, onHome: widget.onHome),
      ],
    );
  }
}

String _normalize(String v) => v.toLowerCase().replaceAll(RegExp(r'[^a-z0-9 ]'), '').replaceAll(RegExp(r'\s+'), ' ').trim();
