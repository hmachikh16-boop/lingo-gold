import 'dart:js_interop';
import 'dart:math';

import 'package:flutter/material.dart';

import 'assets_manifest.dart';

@JS('lingoSpeak')
external bool _lingoSpeak(String text);

void speak(String text) {
  try {
    _lingoSpeak(text);
  } catch (_) {}
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

const prompts = <PhotoPrompt>[
  PhotoPrompt('one apple', 'num_01.jpg'),
  PhotoPrompt('two apples', 'num_02.jpg'),
  PhotoPrompt('three apples', 'num_03.jpg'),
  PhotoPrompt('four apples', 'num_04.jpg'),
  PhotoPrompt('five apples', 'num_05.jpg'),
  PhotoPrompt('six apples', 'num_06.jpg'),
  PhotoPrompt('a dog', 'L153_the_dog.jpg'),
  PhotoPrompt('a cat', 'L152_the_cat.jpg'),
  PhotoPrompt('a pen', 'L165_a_blue_pen.jpg'),
  PhotoPrompt('a car', 'L220_a_red_car.jpg'),
  PhotoPrompt('a bicycle', 'L223_bicycle.jpg'),
  PhotoPrompt('an egg', 'L169_a_brown_egg.jpg'),
];

List<String> gridFor(int step, String correct) {
  final others = photoPool.where((p) => p != correct).toList()..shuffle(Random(step + 7));
  final chosen = <String>[correct, ...others.take(5)];
  return chosen..shuffle(Random(step + 19));
}

enum AppScreen { course, lesson, context }

class ReplicaApp extends StatelessWidget {
  const ReplicaApp({super.key});

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
        scaffoldBackgroundColor: kCanvas,
      ),
      home: const ReplicaShell(),
    );
  }
}

class ReplicaShell extends StatefulWidget {
  const ReplicaShell({super.key});

  @override
  State<ReplicaShell> createState() => _ReplicaShellState();
}

class _ReplicaShellState extends State<ReplicaShell> {
  AppScreen _screen = _initialScreen();

  static AppScreen _initialScreen() {
    final value = Uri.base.queryParameters['screen'];
    if (value == 'lesson') return AppScreen.lesson;
    if (value == 'context') return AppScreen.context;
    return AppScreen.course;
  }
  int _step = 0;
  int? _selected;
  bool _checked = false;
  bool _lastCorrect = false;
  int _right = 0;
  int _wrong = 0;
  bool _finished = false;

  void _openLesson() {
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
    final correct = _selected != null && gridFor(_step, correctImage)[_selected!] == correctImage;
    setState(() {
      _checked = true;
      _lastCorrect = correct;
      if (correct) _right++;
    });
    Future<void>.delayed(const Duration(milliseconds: 750), () {
      if (!mounted) return;
      setState(() {
        _checked = false;
        _selected = null;
        if (!correct) _wrong++;
        if (_step < totalSteps - 1) {
          _step++;
        } else {
          _finished = true;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCanvas,
      body: Column(
        children: [
          _Header(
            breadcrumb: _screen == AppScreen.course
                ? 'Language Basics'
                : _screen == AppScreen.lesson
                    ? 'Unit 1  >  Lesson 4  >  Core Lesson'
                    : 'Unit 1  >  Lesson 4  >  Pronunciation',
            onHome: _openCourse,
          ),
          Expanded(
            child: _screen == AppScreen.course
                ? CourseMap(onStart: _openLesson, onContext: _openContext)
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
                        onHome: _openCourse,
                      )
                    : ContextScreen(onHome: _openCourse, onLesson: _openLesson),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String breadcrumb;
  final VoidCallback onHome;
  const _Header({required this.breadcrumb, required this.onHome});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      color: kGreenDark,
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
    required this.onHome,
  });

  @override
  Widget build(BuildContext context) {
    final prompt = prompts[step % prompts.length];
    final images = gridFor(step, prompt.image);
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
                          _PhotoTile(
                            image: images[i],
                            selected: selected == i,
                            checked: checked,
                            correct: checked && images[i] == prompt.image,
                            onTap: checked ? null : () => onSelect(i),
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
          onCheck: selected == null || checked ? null : () => onCheck(prompt.image),
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
  final VoidCallback? onTap;
  const _PhotoTile({
    super.key,
    required this.image,
    required this.selected,
    required this.checked,
    required this.correct,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: correct ? kGreen : (selected ? kGreen : const Color(0xFFC9C9C2)),
            width: correct || selected ? 4 : 2,
          ),
          boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 5)],
        ),
        child: ClipRRect(
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
  const _StepBar({
    super.key,
    required this.step,
    required this.right,
    required this.wrong,
    required this.onCheck,
    required this.onHome,
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
            width: 44,
            height: 40,
            decoration: BoxDecoration(color: onCheck == null ? const Color(0xFFCFCFC7) : kGreen, borderRadius: BorderRadius.circular(10)),
            child: IconButton(
              icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 22),
              onPressed: onCheck,
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
  const CourseMap({super.key, required this.onStart, required this.onContext});

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
        const Text('Language Basics', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: kInk)),
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

class ContextScreen extends StatelessWidget {
  final VoidCallback onHome;
  final VoidCallback onLesson;
  const ContextScreen({super.key, required this.onHome, required this.onLesson});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 60),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 60),
          child: Row(
            children: [
              _ContextCard(image: 'img_girl_child.jpg', phrase: 'Hello.', correct: true, onHome: onHome),
              const SizedBox(width: 16),
              _ContextCard(image: 'L152_the_cat.jpg', phrase: 'Hello.', correct: false, onHome: onHome),
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
                const Text('1', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kGreen)),
                const SizedBox(width: 12),
                Container(width: 1, height: 26, color: kLine),
                const SizedBox(width: 12),
                const Icon(Icons.close_rounded, color: kMuted, size: 22),
                const Text('0', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kMuted)),
                const SizedBox(width: 16),
                FilledButton.icon(
                  onPressed: onLesson,
                  icon: const Icon(Icons.replay_rounded, size: 17),
                  label: const Text('Try again'),
                  style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), minimumSize: const Size(0, 40)),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        _StepBar(step: 3, right: 1, wrong: 0, onCheck: null, onHome: onHome),
      ],
    );
  }
}

class _ContextCard extends StatelessWidget {
  final String image;
  final String phrase;
  final bool correct;
  final VoidCallback onHome;
  const _ContextCard({required this.image, required this.phrase, required this.correct, required this.onHome});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: kLine)),
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
      );
}
