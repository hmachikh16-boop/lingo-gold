import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'core.dart';
import 'lessons_data.dart';

LearnItem itemAt(int index) => items[index % items.length];

LearnItem findItem(String needle) {
  final n = needle.toLowerCase();
  return items.firstWhere(
    (e) => e.word.toLowerCase().contains(n) || e.image.toLowerCase().contains(n),
    orElse: () => items.first,
  );
}

List<LearnItem> choicesFor(LearnItem correct, int seed, {int count = 3}) {
  final r = Random(seed);
  final pool = items.where((e) => e.word != correct.word).toList()..shuffle(r);
  return [correct, ...pool.take(count)]..shuffle(Random(seed + 1));
}

String letterFor(int i) => String.fromCharCode(65 + i);

String _normalize(String value) => value
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9 ]'), '')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

// ============================================================
// 1. CORE LESSON
// ============================================================
class CoreLessonScreen extends StatefulWidget {
  final int index;
  const CoreLessonScreen({super.key, required this.index});
  @override
  State<CoreLessonScreen> createState() => _CoreLessonScreenState();
}

class _CoreLessonScreenState extends State<CoreLessonScreen> {
  int _step = 0;
  int? _selected;
  bool _done = false;
  bool _awarded = false;

  late final LearnItem item;
  late final List<LearnItem> choices;

  @override
  void initState() {
    super.initState();
    item = itemAt(widget.index);
    choices = choicesFor(item, widget.index + 11);
  }

  void _finish(bool correct) {
    if (!_awarded) {
      Progress.instance.complete(widget.index, correct);
      _awarded = true;
    }
    setState(() => _done = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_done) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircleIcon(Icons.check_rounded, size: 96, background: kGreen, foreground: Colors.white),
                  const SizedBox(height: 20),
                  const Text('Lesson Complete', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: kInk)),
                  const SizedBox(height: 10),
                  Text(item.word, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, color: kMuted)),
                  const SizedBox(height: 14),
                  const StarRow(count: 3, size: 34),
                  const SizedBox(height: 10),
                  const Pill('+20 XP', icon: Icons.bolt_rounded),
                  const SizedBox(height: 30),
                  primaryButton('Continue', () => Navigator.pop(context)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: topBar(
        context,
        green: true,
        title: 'Core Lesson',
        subtitle: 'Dynamic Immersion • Unit ${widget.index ~/ 4 + 1} • Lesson ${widget.index % 4 + 1} of 4',
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up_rounded),
            onPressed: () => Tts.instance.speak(item.sentence),
          ),
        ],
      ),
      body: SafeArea(
        child: _step == 0 ? _learn() : _match(),
      ),
    );
  }

  Widget _learn() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Column(
            children: [
              Row(
                children: [
                  const Text('Progress', style: TextStyle(fontSize: 11, color: kMuted, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  const Text('20%', style: TextStyle(fontSize: 11, color: kGreen, fontWeight: FontWeight.w900)),
                ],
              ),
              const SizedBox(height: 5),
              const ProgressBar(0.2, height: 7),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: SizedBox(height: 330, width: double.infinity, child: Photo(item.image)),
              ),
              const SizedBox(height: 16),
              Text(item.word, textAlign: TextAlign.center, style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w900, color: kInk)),
              const SizedBox(height: 4),
              Text(item.sentence, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14.5, color: kMuted)),
              const SizedBox(height: 10),
              Center(
                child: InkWell(
                  onTap: () => Tts.instance.speak(item.sentence),
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(color: kGreenSoft, borderRadius: BorderRadius.circular(30)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.volume_up_rounded, color: kGreen, size: 19),
                        SizedBox(width: 7),
                        Text('Listen', style: TextStyle(fontWeight: FontWeight.w900, color: kGreenDark, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 18),
          child: primaryButton('Continue', () => setState(() => _step = 1)),
        ),
      ],
    );
  }

  Widget _match() {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            children: [
              const Text('Match the word to the image', textAlign: TextAlign.center, style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: kInk)),
              const SizedBox(height: 4),
              Text('Choose the photo that matches “${item.word}”', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12.5, color: kMuted)),
              const SizedBox(height: 14),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: choices.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.86,
                ),
                itemBuilder: (context, i) {
                  final selected = _selected == i;
                  final picked = choices[i];
                  return GestureDetector(
                    onTap: () => setState(() => _selected = i),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: selected ? kGreen : kLine, width: selected ? 3 : 1.5),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: Column(
                          children: [
                            Expanded(child: Photo(picked.image)),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 6),
                              color: selected ? kGreenSoft : Colors.white,
                              child: Text(
                                picked.word,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: selected ? kGreenDark : kInk),
                              ),
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
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
          child: primaryButton(
            'Check Answer',
            _selected == null ? null : () => _finish(choices[_selected!].image == item.image),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// 2. PRONUNCIATION / TRUACCENT
// ============================================================
class PronunciationScreen extends StatefulWidget {
  final int index;
  const PronunciationScreen({super.key, required this.index});
  @override
  State<PronunciationScreen> createState() => _PronunciationScreenState();
}

class _PronunciationScreenState extends State<PronunciationScreen> {
  int _score = 92;
  bool _recording = false;
  late final LearnItem item;

  @override
  void initState() {
    super.initState();
    item = itemAt(widget.index);
  }

  Future<void> _record() async {
    if (_recording) return;
    setState(() => _recording = true);
    await Tts.instance.speak(item.word);
    await Future<void>.delayed(const Duration(milliseconds: 950));
    if (!mounted) return;
    final score = 88 + (item.word.length * 3) % 9;
    setState(() {
      _score = score;
      _recording = false;
    });
    await Progress.instance.setPronunciation(score);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: topBar(
        context,
        green: true,
        title: 'TruAccent • Pronunciation',
        subtitle: 'TruAccent • Unit ${widget.index ~/ 4 + 1} • Lesson ${widget.index % 4 + 1} of 4',
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
          children: [
            Text('Say: ${item.word}', style: const TextStyle(fontSize: 29, fontWeight: FontWeight.w900, color: kInk)),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: SizedBox(
                height: 305,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Photo('native_speaker_woman.jpg'),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(12, 40, 12, 12),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.transparent, Color(0x99000000)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: Column(
                          children: [
                            const Waveform(height: 50, progress: 0.72, color: Colors.white),
                            const SizedBox(height: 6),
                            Text(item.sentence, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      right: 10,
                      bottom: 82,
                      child: Container(
                        width: 86,
                        height: 86,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: kGreen, width: 4),
                          boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 12)],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('$_score%', style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: kGreenDark)),
                            const Text('score', style: TextStyle(fontSize: 8, color: kMuted, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            CardBox(
              color: kGreenSoft,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleIcon(Icons.check_rounded, size: 40, background: kGreen, foreground: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Excellent!', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: kInk)),
                        const Text('Your pronunciation is clear', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: kInk)),
                        const SizedBox(height: 4),
                        Text(
                          _score >= 92
                              ? "Great enunciation. Keep practicing to improve to 95%+."
                              : "Good effort. Slow down and stress the first syllable.",
                          style: const TextStyle(fontSize: 11.5, color: kMuted, height: 1.45),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Center(
              child: SizedBox(
                width: 78,
                height: 78,
                child: FilledButton(
                  onPressed: _record,
                  style: FilledButton.styleFrom(
                    shape: const CircleBorder(),
                    backgroundColor: _recording ? kGreenDark : kGreen,
                    padding: EdgeInsets.zero,
                  ),
                  child: Icon(_recording ? Icons.graphic_eq_rounded : Icons.mic_rounded, size: 34),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(_recording ? 'Listening…' : 'Tap to record • Try again', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: kMuted)),
            const SizedBox(height: 18),
            outlineButton('Continue to Next Word', () {
              Progress.instance.complete(widget.index, _score >= 80);
              Navigator.pop(context);
            }),
            const SizedBox(height: 8),
            const Text('Your score is saved to your weekly pronunciation report.', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: kMuted)),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 3. VOCABULARY
// ============================================================
class VocabularyScreen extends StatelessWidget {
  const VocabularyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final words = List<LearnItem>.generate(15, (i) => items[(8 + i) % items.length]);
    final featured = [findItem('apple'), findItem('banana'), findItem('pear')];
    const arabic = ['تفاحة', 'موزة', 'كمثرى'];
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: topBar(context, green: true, title: 'Vocabulary', subtitle: 'Focused Activity • Fruits • 15 New Words'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 22),
          children: [
            CardBox(
              color: kGreenSoft,
              child: Row(
                children: [
                  const CircleIcon(Icons.volume_up_rounded, size: 46, background: Colors.white, foreground: kGreen),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Listen & Repeat', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: kInk)),
                        SizedBox(height: 2),
                        Text('Tap the audio to hear each word. Practice pronunciation.', style: TextStyle(fontSize: 10.5, color: kMuted, height: 1.4)),
                      ],
                    ),
                  ),
                  const Pill('Audio On', icon: Icons.volume_up_rounded),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const SectionTitle('Learn: Fruits', trailing: '3 / 3 items shown'),
            Row(
              children: [
                for (var i = 0; i < featured.length; i++) ...[
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: kLine)),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                            child: SizedBox(height: 104, width: double.infinity, child: Photo(featured[i].image)),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
                            child: Column(
                              children: [
                                Text(featured[i].word, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: kInk)),
                                Text(arabic[i], style: const TextStyle(fontSize: 10, color: kMuted)),
                              ],
                            ),
                          ),
                          InkWell(
                            onTap: () => Tts.instance.speak(featured[i].word),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              decoration: const BoxDecoration(color: kGreenSoft, borderRadius: BorderRadius.vertical(bottom: Radius.circular(13))),
                              child: const Icon(Icons.volume_up_rounded, size: 16, color: kGreen),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (i < featured.length - 1) const SizedBox(width: 8),
                ],
              ],
            ),
            const SizedBox(height: 18),
            const SectionTitle('15 New Words • This Lesson', trailing: 'Progress 20%'),
            for (final w in words)
              InkWell(
                onTap: () => Tts.instance.speak(w.word),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Row(
                    children: [
                      const CircleIcon(Icons.volume_up_rounded, size: 26, background: kGreenSoft, foreground: kGreen),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(w.word, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: kInk)),
                            Text(w.sentence, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: kMuted)),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 11, color: kLine),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 14),
            primaryButton('Continue Practice', () {
              Progress.instance.complete(Progress.instance.current, true);
              Navigator.pop(context);
            }, icon: Icons.play_arrow_rounded),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 4. GRAMMAR
// ============================================================
class GrammarScreen extends StatefulWidget {
  final int index;
  const GrammarScreen({super.key, required this.index});
  @override
  State<GrammarScreen> createState() => _GrammarScreenState();
}

class _GrammarScreenState extends State<GrammarScreen> {
  int _selected = 0;
  bool _checked = false;
  bool _awarded = false;

  static const options = [
    'The boy is running while the girl is reading.',
    'The boy is reading while the girl is running.',
    'The boy and girl are both running.',
  ];

  @override
  Widget build(BuildContext context) {
    final run = findItem('run');
    final read = findItem('read');
    final correct = _selected == 0;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: topBar(
        context,
        green: true,
        title: 'Grammar Lesson',
        subtitle: 'Sentence Structure • Unit ${widget.index ~/ 4 + 1} • Lesson ${widget.index % 4 + 1} of 4',
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 22),
          children: [
            Row(
              children: [
                const Text('72% complete', style: TextStyle(fontSize: 11, color: kMuted, fontWeight: FontWeight.w700)),
                const Spacer(),
                const Text('72%', style: TextStyle(fontSize: 12, color: kGreenDark, fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: 5),
            const ProgressBar(0.72, height: 7),
            const SizedBox(height: 16),
            CardBox(
              child: Column(
                children: [
                  const Text('Choose the sentence that matches both photos', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5, color: kInk)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            ClipRRect(borderRadius: BorderRadius.circular(13), child: SizedBox(height: 170, width: double.infinity, child: Photo(run.image))),
                            const SizedBox(height: 6),
                            const Pill('Boy is running', background: kGreenSoft),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          children: [
                            ClipRRect(borderRadius: BorderRadius.circular(13), child: SizedBox(height: 170, width: double.infinity, child: Photo(read.image))),
                            const SizedBox(height: 6),
                            const Pill('Girl is reading', background: kGreenSoft),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Select the correct sentence:', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: kInk)),
            const SizedBox(height: 10),
            for (var i = 0; i < options.length; i++)
              GestureDetector(
                onTap: _checked ? null : () => setState(() => _selected = i),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 9),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _selected == i ? kGreenSoft : Colors.white,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: _checked && i == 0 ? kGreen : (_selected == i ? kGreen : kLine),
                      width: _selected == i ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 19,
                        height: 19,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: _selected == i ? kGreen : kMuted, width: 2),
                          color: _selected == i ? kGreen : Colors.white,
                        ),
                        child: _selected == i ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(options[i], style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: kInk, height: 1.35))),
                    ],
                  ),
                ),
              ),
            if (_checked)
              CardBox(
                color: correct ? kGreenSoft : kCard,
                child: Row(
                  children: [
                    Icon(correct ? Icons.check_circle_rounded : Icons.info_outline_rounded, color: correct ? kGreen : kMuted),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        correct ? 'Correct! “While” connects two actions happening at the same time.' : 'Not quite. The photos show a boy running and a girl reading.',
                        style: const TextStyle(fontSize: 11.5, color: kInk, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            primaryButton('Check Answer', _checked ? null : () {
              setState(() => _checked = true);
              if (!_awarded) {
                Progress.instance.complete(widget.index, correct);
                _awarded = true;
              }
            }),
            const SizedBox(height: 10),
            const Text(
              'Tip: Use “while” to connect two actions happening at the same time.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10.5, color: kMuted, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 5. READING
// ============================================================
class ReadingScreen extends StatefulWidget {
  final int index;
  const ReadingScreen({super.key, required this.index});
  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  int _tab = 0;
  bool _awarded = false;

  static const story =
      'In the morning, the market is busy and full of life. Local vendors set up their stalls early to sell fresh produce to the community. You can see baskets of golden apples, ripe tomatoes, and bunches of herbs neatly arranged. The customers walk through the market, speaking with the vendors and choosing the best ingredients for the day. The smell of fresh bread fills the air as people greet each other with smiles.';

  static const meanings = {
    'market': 'السوق',
    'vendors': 'البائعون',
    'community': 'المجتمع',
    'apples': 'التفاح',
    'tomatoes': 'الطماطم',
    'herbs': 'الأعشاب',
    'bread': 'الخبز',
    'fresh': 'طازج',
  };

  List<InlineSpan> _spans() {
    final spans = <InlineSpan>[];
    for (final word in story.split(' ')) {
      final clean = word.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
      final highlight = meanings.containsKey(clean);
      final recognizer = TapGestureRecognizer()
        ..onTap = () {
          Tts.instance.speak(clean);
          showToast(context, '$clean — ${meanings[clean]}');
        };
      spans.add(TextSpan(
        text: '$word ',
        recognizer: highlight ? recognizer : null,
        style: highlight
            ? const TextStyle(backgroundColor: kGreenSoft, color: kGreenDark, fontWeight: FontWeight.w800)
            : const TextStyle(color: kInk, height: 1.65),
      ));
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: topBar(
        context,
        green: true,
        title: 'Reading Lesson',
        subtitle: 'The Market in the Morning',
        actions: [
          IconButton(icon: const Icon(Icons.headphones_rounded), onPressed: () => Tts.instance.speak(story)),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: kGreenDark, borderRadius: BorderRadius.circular(14)),
              child: const Row(
                children: [
                  CircleIcon(Icons.menu_book_rounded, size: 34, background: Colors.white, foreground: kGreenDark),
                  SizedBox(width: 10),
                  Expanded(child: Text('LINGO GOLD • READING', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 12))),
                  Pill('B1', background: Colors.white, foreground: kGreenDark),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text('UNIT ${widget.index ~/ 4 + 1} • LESSON ${widget.index % 4 + 1} • READING • THE MARKET IN THE MORNING', style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: kMuted, letterSpacing: .4)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Progress 60%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: kInk)),
                const Spacer(),
                const Text('8 min left', style: TextStyle(fontSize: 11, color: kMuted)),
              ],
            ),
            const SizedBox(height: 5),
            const ProgressBar(0.6, height: 7),
            const SizedBox(height: 14),
            ClipRRect(borderRadius: BorderRadius.circular(18), child: SizedBox(height: 195, width: double.infinity, child: Photo('market_morning.jpg'))),
            const SizedBox(height: 12),
            CardBox(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('The Story', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: kInk)),
                  const SizedBox(height: 8),
                  Text.rich(TextSpan(children: _spans()), style: const TextStyle(fontSize: 12.5)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            CardBox(
              color: kGreenSoft,
              child: const Row(
                children: [
                  Icon(Icons.lightbulb_outline_rounded, color: kGreenDark, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tap any highlighted word to hear its pronunciation and see the Arabic meaning.',
                      style: TextStyle(fontSize: 11, color: kInk, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: outlineButton('Listen', () => Tts.instance.speak(story), icon: Icons.volume_up_rounded),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: primaryButton('Continue', () {
                    if (!_awarded) {
                      Progress.instance.complete(widget.index, true);
                      _awarded = true;
                    }
                    Navigator.pop(context);
                  }, icon: Icons.arrow_forward_rounded),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  _ReadingTab(label: 'Read', icon: Icons.menu_book_rounded, selected: _tab == 0, onTap: () => setState(() => _tab = 0)),
                  _ReadingTab(label: 'Practice', icon: Icons.edit_rounded, selected: _tab == 1, onTap: () => setState(() => _tab = 1)),
                  _ReadingTab(label: 'Quiz', icon: Icons.check_circle_rounded, selected: _tab == 2, onTap: () => setState(() => _tab = 2)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadingTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _ReadingTab({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: selected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 15, color: selected ? kGreen : kMuted),
                const SizedBox(width: 5),
                Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: selected ? kGreenDark : kMuted)),
              ],
            ),
          ),
        ),
      );
}

// ============================================================
// 6. WRITING
// ============================================================
class WritingScreen extends StatefulWidget {
  final int index;
  const WritingScreen({super.key, required this.index});
  @override
  State<WritingScreen> createState() => _WritingScreenState();
}

class _WritingScreenState extends State<WritingScreen> {
  final _controller = TextEditingController();
  bool _checked = false;
  bool _correct = false;
  bool _awarded = false;
  late final LearnItem item;

  @override
  void initState() {
    super.initState();
    item = findItem('dog');
    _controller.text = 'The dog is sleeping';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _check() {
    final correct = _normalize(_controller.text) == _normalize('The dog is sleeping');
    setState(() {
      _checked = true;
      _correct = correct;
    });
    if (!_awarded) {
      Progress.instance.complete(widget.index, correct);
      _awarded = true;
    }
  }

  void _addWord(String word) {
    final text = _controller.text.trim();
    _controller.text = text.isEmpty ? word : '$text $word';
    _controller.selection = TextSelection.fromPosition(TextPosition(offset: _controller.text.length));
    setState(() => _checked = false);
  }

  @override
  Widget build(BuildContext context) {
    final chips = ['The', 'dog', 'is', 'sleeping', 'sleep', 'running'];
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: topBar(context, green: true, title: 'Writing Practice', subtitle: 'Unit ${widget.index ~/ 4 + 1} • Lesson ${widget.index % 4 + 1} of 4'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
          children: [
            Row(
              children: [
                const Text('Writing Practice', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: kInk)),
                const Spacer(),
                Text('${widget.index % 10 + 2} / 10', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: kGreenDark)),
              ],
            ),
            const SizedBox(height: 6),
            ProgressBar((widget.index % 10 + 2) / 10, height: 7),
            const SizedBox(height: 14),
            CardBox(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  ClipRRect(borderRadius: BorderRadius.circular(14), child: SizedBox(height: 185, width: double.infinity, child: Photo(item.image))),
                  const SizedBox(height: 12),
                  const Text('Look at the photo and type the phrase:', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, color: kInk)),
                  const SizedBox(height: 4),
                  const Text('The dog is sleeping', style: TextStyle(fontSize: 12, color: kMuted, fontStyle: FontStyle.italic)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _controller,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: kInk),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: kGreenSoft,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kGreen)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kGreen)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kGreen, width: 2)),
                    ),
                    onChanged: (_) => setState(() => _checked = false),
                  ),
                  const SizedBox(height: 10),
                  primaryButton('Check Answer', _check, expand: false),
                  if (_checked) ...[
                    const SizedBox(height: 8),
                    Text(
                      _correct ? 'Correct! The dog is sleeping.' : 'Try again. Use the words from the photo.',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: _correct ? kGreenDark : kMuted),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              alignment: WrapAlignment.center,
              children: [
                for (final c in chips)
                  GestureDetector(
                    onTap: () => _addWord(c),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(color: kGreenSoft, borderRadius: BorderRadius.circular(18)),
                      child: Text(c, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: kGreenDark)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Tap a word chip to add it to your answer.', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: kMuted)),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 7. LISTENING
// ============================================================
class ListeningScreen extends StatefulWidget {
  final int index;
  const ListeningScreen({super.key, required this.index});
  @override
  State<ListeningScreen> createState() => _ListeningScreenState();
}

class _ListeningScreenState extends State<ListeningScreen> {
  bool _playing = false;
  int? _selected;
  bool _checked = false;
  bool _awarded = false;

  static const prompt = 'The cat is sleeping on the windowsill';

  @override
  Widget build(BuildContext context) {
    final options = [
      {'label': 'Dog', 'image': 'L153_the_dog.jpg'},
      {'label': 'Bird', 'image': 'L155_the_bird.jpg'},
      {'label': 'Cat', 'image': 'cat_sleeping_window.jpg'},
      {'label': 'Fox', 'image': 'fox.jpg'},
    ];
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: topBar(context, green: true, title: 'Listening Activity', subtitle: 'Unit ${widget.index ~/ 4 + 1} • Lesson ${widget.index % 4 + 1} of 4 • Animals'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
          children: [
            CardBox(
              color: kGreenSoft,
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() => _playing = !_playing);
                          Tts.instance.speak(prompt);
                        },
                        child: CircleIcon(
                          _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          size: 44,
                          background: kGreen,
                          foreground: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Listen carefully', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: kInk)),
                            Text('Tap play to hear the sentence', style: TextStyle(fontSize: 10, color: kMuted)),
                          ],
                        ),
                      ),
                      const Text('0:07 / 0:12', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: kMuted)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Waveform(height: 42, progress: _playing ? 0.8 : 0.6),
                  const SizedBox(height: 6),
                  const ProgressBar(0.6, height: 5),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text('Choose the image that matches:', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: kInk)),
            const SizedBox(height: 4),
            const Text('“$prompt”', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: kGreenDark)),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: options.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.02,
              ),
              itemBuilder: (context, i) {
                final selected = _selected == i;
                final isCorrect = i == 2;
                return GestureDetector(
                  onTap: () => setState(() => _selected = i),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: _checked && isCorrect ? kGreen : (selected ? kGreen : kLine),
                        width: selected || (_checked && isCorrect) ? 3 : 1.5,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Column(
                        children: [
                          Expanded(child: Photo(options[i]['image']!)),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            color: selected ? kGreenSoft : Colors.white,
                            child: Text(
                              options[i]['label']!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: kInk),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            primaryButton('Check Answer', _selected == null ? null : () {
              final correct = _selected == 2;
              setState(() {
                _checked = true;
                _playing = false;
              });
              if (!_awarded) {
                Progress.instance.complete(widget.index, correct);
                _awarded = true;
              }
            }),
            const SizedBox(height: 7),
            Text(
              _checked ? (_selected == 2 ? 'Correct! The cat is sleeping.' : 'The correct answer is Cat.') : 'Tap the correct image to continue',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10.5, color: _checked && _selected == 2 ? kGreenDark : kMuted, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 8. SPEAKING
// ============================================================
class SpeakingScreen extends StatefulWidget {
  final int index;
  const SpeakingScreen({super.key, required this.index});
  @override
  State<SpeakingScreen> createState() => _SpeakingScreenState();
}

class _SpeakingScreenState extends State<SpeakingScreen> {
  bool _listening = false;
  bool _tried = false;

  static const phrase = 'The library is on the left';

  Future<void> _listen() async {
    if (_listening) return;
    setState(() {
      _listening = true;
      _tried = true;
    });
    await Tts.instance.speak(phrase);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (mounted) setState(() => _listening = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: topBar(context, title: 'Speaking Practice', subtitle: 'Unit ${widget.index ~/ 4 + 1} • Lesson ${widget.index % 4 + 1} of 4 • Pronunciation'),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: CardBox(
                color: kGreenSoft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Speak the phrase', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: kMuted)),
                    const SizedBox(height: 2),
                    const Text('“$phrase”', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kInk)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        CircleIcon(Icons.mic_rounded, size: 36, background: Colors.white, foreground: kGreen),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_listening ? 'Listening…' : 'Tap to speak', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: kGreenDark)),
                              Text(_tried ? 'Great pronunciation! Keep speaking.' : 'Say the phrase clearly.', style: const TextStyle(fontSize: 10, color: kMuted)),
                            ],
                          ),
                        ),
                        const Pill('A2', background: Colors.white),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ProgressBar(_tried ? 0.84 : 0.35, height: 7),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: SizedBox(
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Photo('L151_kid.jpg'),
                        Positioned(
                          left: 10,
                          right: 10,
                          bottom: 10,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.94), borderRadius: BorderRadius.circular(13)),
                            child: Row(
                              children: [
                                const CircleIcon(Icons.graphic_eq_rounded, size: 32, background: kGreenSoft, foreground: kGreen),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text('Listening to your voice…', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: kInk)),
                                ),
                                Text(_tried ? '84%' : '—', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: kGreenDark)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
              child: Row(
                children: [
                  Expanded(child: outlineButton('Try again', _listen)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: primaryButton('Continue', () {
                      Progress.instance.complete(widget.index, _tried);
                      Navigator.pop(context);
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 9. CHOOSE AN IMAGE
// ============================================================
class ChooseImageScreen extends StatefulWidget {
  final int index;
  const ChooseImageScreen({super.key, required this.index});
  @override
  State<ChooseImageScreen> createState() => _ChooseImageScreenState();
}

class _ChooseImageScreenState extends State<ChooseImageScreen> {
  int? _selected;
  bool _checked = false;
  bool _awarded = false;
  late final LearnItem item;
  late final List<LearnItem> choices;

  @override
  void initState() {
    super.initState();
    item = itemAt(widget.index);
    choices = choicesFor(item, widget.index + 21);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: topBar(context, green: true, title: 'Choose an Image', subtitle: 'What matches the spoken word?'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 22),
          children: [
            GestureDetector(
              onTap: () => Tts.instance.speak(item.word),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: kGreenSoft, borderRadius: BorderRadius.circular(30), border: Border.all(color: kGreen.withValues(alpha: .35))),
                child: Row(
                  children: [
                    const Icon(Icons.mic_rounded, color: kGreen, size: 20),
                    const SizedBox(width: 8),
                    const Text('spoken word', style: TextStyle(fontWeight: FontWeight.w900, color: kGreenDark, fontSize: 12)),
                    const SizedBox(width: 8),
                    const Expanded(child: Waveform(height: 26, progress: 0.7)),
                    const Icon(Icons.volume_up_rounded, color: kGreen, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text('Choose the matching image', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: kInk)),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: choices.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.86,
              ),
              itemBuilder: (context, i) {
                final selected = _selected == i;
                final correct = choices[i].image == item.image;
                return GestureDetector(
                  onTap: () => setState(() => _selected = i),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: _checked && correct ? kGreen : (selected ? kGreen : kLine),
                        width: selected || (_checked && correct) ? 3 : 1.5,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Column(
                        children: [
                          Expanded(
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Photo(choices[i].image),
                                if (selected || (_checked && correct))
                                  Positioned(
                                    top: 6,
                                    right: 6,
                                    child: Container(
                                      width: 22,
                                      height: 22,
                                      decoration: const BoxDecoration(color: kGreen, shape: BoxShape.circle),
                                      child: const Icon(Icons.check, color: Colors.white, size: 14),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            color: selected ? kGreenSoft : Colors.white,
                            child: Text(
                              choices[i].word,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5, color: kInk),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            primaryButton('Check', _selected == null ? null : () {
              final correct = choices[_selected!].image == item.image;
              setState(() => _checked = true);
              if (!_awarded) {
                Progress.instance.complete(widget.index, correct);
                _awarded = true;
              }
            }),
            if (_checked) ...[
              const SizedBox(height: 8),
              Text(
                choices[_selected!].image == item.image ? 'Correct!' : 'The correct image is ${item.word}.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: kGreenDark),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 10. CHOOSE A PROMPT
// ============================================================
class ChoosePromptScreen extends StatefulWidget {
  final int index;
  const ChoosePromptScreen({super.key, required this.index});
  @override
  State<ChoosePromptScreen> createState() => _ChoosePromptScreenState();
}

class _ChoosePromptScreenState extends State<ChoosePromptScreen> {
  int? _selected;
  bool _checked = false;
  bool _awarded = false;

  static const prompt = 'The man is drinking coffee at the café';
  static const options = [
    {'image': 'act_drink.jpg', 'label': 'A man drinking coffee at the café'},
    {'image': 'job_student.jpg', 'label': 'A woman working on a laptop'},
    {'image': 'act_read.jpg', 'label': 'A man reading a book on a park bench'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: topBar(context, green: true, title: 'Choose a Prompt', subtitle: 'Match the photo to the prompt • Unit ${widget.index ~/ 4 + 1}'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
          children: [
            const ProgressBar(0.2, height: 5),
            const SizedBox(height: 14),
            const Text('Choose a Prompt', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: kInk)),
            const Text('Match the photo to the prompt below', style: TextStyle(fontSize: 12, color: kMuted)),
            const SizedBox(height: 12),
            CardBox(
              color: kGreenSoft,
              child: Row(
                children: [
                  ClipRRect(borderRadius: BorderRadius.circular(11), child: SizedBox(width: 78, height: 78, child: Photo('act_drink.jpg'))),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('PROMPT', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: kGreenDark, letterSpacing: 1)),
                        const SizedBox(height: 3),
                        const Text(prompt, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: kInk, height: 1.4)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Choose the photo that matches', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: kInk)),
            const SizedBox(height: 10),
            for (var i = 0; i < options.length; i++)
              GestureDetector(
                onTap: () => setState(() => _selected = i),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _checked && i == 0 ? kGreen : (_selected == i ? kGreen : kLine),
                      width: _selected == i || (_checked && i == 0) ? 3 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                        child: SizedBox(
                          width: 112,
                          height: 92,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Photo(options[i]['image']!),
                              Positioned(
                                top: 5,
                                left: 5,
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(color: kGreen.withValues(alpha: .9), borderRadius: BorderRadius.circular(6)),
                                  child: Text(letterFor(i), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text(options[i]['label']!, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: kInk, height: 1.35)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            primaryButton('Check Answer', _selected == null ? null : () {
              setState(() => _checked = true);
              if (!_awarded) {
                Progress.instance.complete(widget.index, _selected == 0);
                _awarded = true;
              }
            }),
            if (_checked) ...[
              const SizedBox(height: 8),
              Text(
                _selected == 0 ? 'Correct! The prompt matches photo A.' : 'The prompt matches photo A.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: kGreenDark),
              ),
            ],
            const SizedBox(height: 8),
            const Text('Need a hint? Tap the speaker on the prompt card.', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: kMuted)),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 11. ADAPTIVE RECALL
// ============================================================
class AdaptiveRecallScreen extends StatefulWidget {
  final int? startIndex;
  const AdaptiveRecallScreen({super.key, this.startIndex});
  @override
  State<AdaptiveRecallScreen> createState() => _AdaptiveRecallScreenState();
}

class _AdaptiveRecallScreenState extends State<AdaptiveRecallScreen> {
  int _q = 0;
  int _score = 0;
  int? _selected;
  bool _checked = false;
  bool _done = false;
  bool _awarded = false;
  late final List<LearnItem> _questions;

  @override
  void initState() {
    super.initState();
    final first = widget.startIndex == null ? findItem('baker') : itemAt(widget.startIndex!);
    _questions = [first];
    for (var i = 1; i < 10; i++) {
      _questions.add(items[(items.indexOf(first) + i * 17) % items.length]);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_done) {
      final p = Progress.instance;
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: topBar(context, green: true, title: 'Review • Adaptive Recall'),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircleIcon(Icons.psychology_alt_rounded, size: 92, background: kGreenSoft, foreground: kGreen),
                const SizedBox(height: 16),
                Text('$_score / 10', style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: kInk)),
                const Text('Adaptive review complete', style: TextStyle(color: kMuted)),
                const SizedBox(height: 14),
                const StarRow(count: 3, size: 30),
                const SizedBox(height: 14),
                Text('${p.streak}-day streak • +20 XP', style: const TextStyle(fontWeight: FontWeight.w800, color: kGreenDark)),
                const SizedBox(height: 26),
                primaryButton('Continue', () => Navigator.pop(context)),
              ],
            ),
          ),
        ),
      );
    }

    final q = _questions[_q];
    final options = choicesFor(q, q.word.hashCode + _q, count: 3);
    final percent = ((_q + 1) / 10 * 100).round();
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: topBar(context, green: true, title: 'Review • Adaptive Recall', subtitle: 'Reinforce what you learned with adaptive review'),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                children: [
                  Row(
                    children: [
                      Text('Question ${_q + 1} of 10', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: kInk)),
                      const Spacer(),
                      Text('$percent%', style: const TextStyle(fontWeight: FontWeight.w900, color: kGreenDark)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ProgressBar((_q + 1) / 10, height: 9),
                  const SizedBox(height: 18),
                  Text('Which photo shows “${q.word}”?', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: kInk)),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: options.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.9,
                    ),
                    itemBuilder: (context, i) {
                      final selected = _selected == i;
                      final correct = options[i].image == q.image;
                      return GestureDetector(
                        onTap: () => setState(() => _selected = i),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: _checked && correct ? kGreen : (selected ? kGreen : kLine),
                              width: selected || (_checked && correct) ? 3 : 1.5,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Column(
                              children: [
                                Expanded(
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Photo(options[i].image),
                                      Positioned(
                                        top: 6,
                                        left: 6,
                                        child: Container(
                                          width: 22,
                                          height: 22,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(color: kGreen.withValues(alpha: .9), borderRadius: BorderRadius.circular(6)),
                                          child: Text(letterFor(i), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11)),
                                        ),
                                      ),
                                      if (_checked && correct)
                                        const Positioned(
                                          top: 6,
                                          right: 6,
                                          child: Icon(Icons.check_circle_rounded, color: kGreen, size: 22),
                                        ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  color: selected ? kGreenSoft : Colors.white,
                                  child: Text(
                                    '${letterFor(i)}. ${options[i].word}',
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5, color: kInk),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Pill('Adaptive Recall', icon: Icons.star_rounded),
                      const SizedBox(width: 8),
                      Text('Streak: ${Progress.instance.streak} days', style: const TextStyle(fontSize: 11, color: kMuted, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Column(
                children: [
                  primaryButton('Continue', _selected == null ? null : () {
                    final correct = options[_selected!].image == q.image;
                    if (correct) _score++;
                    Progress.instance.recordAnswer(correct);
                    setState(() {
                      _checked = true;
                    });
                    Future<void>.delayed(const Duration(milliseconds: 350), () {
                      if (!mounted) return;
                      if (_q == 9) {
                        if (!_awarded) {
                          Progress.instance.complete(Progress.instance.current, _score >= 7);
                          _awarded = true;
                        }
                        setState(() => _done = true);
                      } else {
                        setState(() {
                          _q++;
                          _selected = null;
                          _checked = false;
                        });
                      }
                    });
                  }),
                  const SizedBox(height: 5),
                  const Text('Answer saved • Moving to the next review item', textAlign: TextAlign.center, style: TextStyle(fontSize: 9.5, color: kMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 12. MILESTONE CONVERSATION
// ============================================================
class MilestoneConversationScreen extends StatefulWidget {
  const MilestoneConversationScreen({super.key});
  @override
  State<MilestoneConversationScreen> createState() => _MilestoneConversationScreenState();
}

class _MilestoneConversationScreenState extends State<MilestoneConversationScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final _messages = <Map<String, String>>[
    {'who': 'them', 'text': 'Hello! Welcome to the café. What would you like to order today?'},
  ];
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future<void>.delayed(const Duration(milliseconds: 120), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() {
      _messages.add({'who': 'me', 'text': text});
      _controller.clear();
      _sending = true;
    });
    _scrollToBottom();
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    setState(() {
      _messages.add({'who': 'them', 'text': 'Great choice! Would you like anything else with that?'});
      _sending = false;
    });
    _scrollToBottom();
    Tts.instance.speak('Great choice! Would you like anything else with that?');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: topBar(context, green: true, title: 'LINGO GOLD', subtitle: 'Unit Milestone • Conversation'),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: kGreenSoft, borderRadius: BorderRadius.circular(13)),
                child: const Row(
                  children: [
                    Icon(Icons.chat_bubble_outline_rounded, color: kGreenDark, size: 17),
                    SizedBox(width: 7),
                    Expanded(
                      child: Text('You are practicing conversation. Reply as if you are at a café.', style: TextStyle(fontSize: 10.5, color: kInk, height: 1.4)),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              child: Row(
                children: [
                  const Avatar('native_speaker_woman.jpg', size: 52),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ana • Native English Speaker', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: kInk)),
                        Text('Online • Speaks from London', style: TextStyle(fontSize: 10, color: kMuted)),
                      ],
                    ),
                  ),
                  const Pill('B1', background: kGreenSoft),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                children: [
                  for (final m in _messages) _Bubble(me: m['who'] == 'me', text: m['text'] ?? ''),
                  Container(
                    margin: const EdgeInsets.only(bottom: 10, top: 2),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: kGreenSoft, borderRadius: BorderRadius.circular(11)),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lightbulb_outline_rounded, color: kGreenDark, size: 17),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text('Tip: Use polite ordering phrases like “I would like…” or “Could I have…?”', style: TextStyle(fontSize: 10.5, color: kInk, height: 1.4)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              decoration: const BoxDecoration(color: kCard, border: Border(top: BorderSide(color: kLine))),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _send(),
                          decoration: InputDecoration(
                            hintText: 'Type your response…',
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: kLine)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: kLine)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: kGreen)),
                            suffixIcon: const Icon(Icons.mic_none_rounded, color: kGreen, size: 20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: FilledButton(
                          onPressed: _send,
                          style: FilledButton.styleFrom(shape: const CircleBorder(), padding: EdgeInsets.zero),
                          child: const Icon(Icons.send_rounded, size: 20),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      _ChatChip(icon: Icons.lightbulb_outline_rounded, label: 'Hint', onTap: () => showToast(context, 'Try: “I would like a coffee, please.”')),
                      const SizedBox(width: 6),
                      _ChatChip(icon: Icons.mic_none_rounded, label: 'Practice Speaking', onTap: () => Tts.instance.speak('I would like a coffee, please.')),
                      const SizedBox(width: 6),
                      _ChatChip(icon: Icons.translate_rounded, label: 'Translate', onTap: () => showToast(context, 'أود طلب قهوة من فضلك.')),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final bool me;
  final String text;
  const _Bubble({required this.me, required this.text});

  @override
  Widget build(BuildContext context) => Align(
        alignment: me ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 290),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: me ? kGreen : kCard,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(14),
              topRight: const Radius.circular(14),
              bottomLeft: Radius.circular(me ? 14 : 3),
              bottomRight: Radius.circular(me ? 3 : 14),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(text, style: TextStyle(color: me ? Colors.white : kInk, fontSize: 12, height: 1.45)),
              const SizedBox(height: 3),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(me ? '10:03 AM' : '10:02 AM', style: TextStyle(fontSize: 8, color: me ? Colors.white70 : kMuted)),
                  if (!me) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.volume_up_rounded, size: 11, color: me ? Colors.white70 : kMuted),
                  ],
                ],
              ),
            ],
          ),
        ),
      );
}

class _ChatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ChatChip({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 7),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: kLine)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 13, color: kGreenDark),
                const SizedBox(width: 4),
                Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: kInk))),
              ],
            ),
          ),
        ),
      );
}

// ============================================================
// 13. PHRASEBOOK
// ============================================================
class PhrasebookScreen extends StatelessWidget {
  const PhrasebookScreen({super.key});

  static const phrases = [
    {'title': 'The bill, please', 'sub': 'الحساب من فضلك • Tap to play audio', 'image': 'job_chef.jpg'},
    {'title': 'I have a reservation', 'sub': 'لدي حجز • Booked for 2 people', 'image': 'L167_table.jpg'},
    {'title': 'Can I see the menu, please?', 'sub': 'هل يمكنني رؤية القائمة؟ • Polite request', 'image': 'L164_a_green_book.jpg'},
    {'title': 'Where is the restroom?', 'sub': 'أين دورة المياه؟ • Essential', 'image': 'L162_a_green_door.jpg'},
    {'title': 'A table for two, please', 'sub': 'طاولة لشخصين من فضلك', 'image': 'L166_a_wooden_chair.jpg'},
    {'title': 'Water, please', 'sub': 'ماء من فضلك • Tap to play audio', 'image': 'L170_a_glass_of_milk.jpg'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: topBar(
        context,
        green: true,
        title: 'Phrasebook',
        subtitle: 'Restaurant • Travel',
        actions: [IconButton(icon: const Icon(Icons.search_rounded), onPressed: () => showToast(context, 'Search phrases'))],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: kGreenSoft, borderRadius: BorderRadius.circular(14), border: Border.all(color: kGreen.withValues(alpha: .25))),
              child: const Row(
                children: [
                  Icon(Icons.restaurant_rounded, color: kGreenDark, size: 21),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Restaurant • Travel', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: kInk)),
                        Text('Common phrases — speak confidently while dining out', style: TextStyle(fontSize: 10.5, color: kMuted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const SectionTitle('Common Phrases', trailing: '12 phrases'),
            for (final p in phrases)
              CardBox(
                padding: const EdgeInsets.all(9),
                child: Row(
                  children: [
                    ClipRRect(borderRadius: BorderRadius.circular(10), child: SizedBox(width: 72, height: 64, child: Photo(p['image']!))),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p['title']!, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5, color: kInk)),
                          const SizedBox(height: 2),
                          Text(p['sub']!, style: const TextStyle(fontSize: 10, color: kMuted, height: 1.35)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.volume_up_rounded, color: kGreen),
                      onPressed: () => Tts.instance.speak(p['title']!),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                _FilterPill(label: 'All', selected: true),
                const SizedBox(width: 6),
                _FilterPill(label: 'Saved', selected: false),
                const SizedBox(width: 6),
                _FilterPill(label: 'Practice', selected: false),
                const SizedBox(width: 6),
                _FilterPill(label: 'Favorites', selected: false),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  const _FilterPill({required this.label, required this.selected});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(color: selected ? kGreen : kCard, borderRadius: BorderRadius.circular(16)),
        child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: selected ? Colors.white : kMuted)),
      );
}

// ============================================================
// 14. FLASHCARDS
// ============================================================
class FlashcardsScreen extends StatefulWidget {
  const FlashcardsScreen({super.key});
  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  int _tab = 0;
  int _known = 12;
  int _i = 0;
  late final List<LearnItem> _cards;

  @override
  void initState() {
    super.initState();
    final apple = findItem('apple');
    _cards = [apple, ...items.where((e) => e.image != apple.image).take(49)];
  }

  void _advance(bool known) {
    setState(() {
      if (known) _known = (_known + 1).clamp(0, 50);
      _i = (_i + 1) % _cards.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final card = _cards[_i];
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: topBar(
        context,
        title: 'Lingo Gold',
        back: false,
        actions: [
          IconButton(icon: const Icon(Icons.search_rounded), onPressed: () => showToast(context, 'Search cards')),
          IconButton(icon: const Icon(Icons.person_outline_rounded), onPressed: () => showToast(context, 'Profile')),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 22),
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(13)),
              child: Row(
                children: [
                  _Segmented(label: 'Flashcards', selected: _tab == 0, onTap: () => setState(() => _tab = 0)),
                  _Segmented(label: 'Chat Missions', selected: _tab == 1, onTap: () => setState(() => _tab = 1)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (_tab == 0) ...[
              SectionTitle('Flashcards', trailing: '$_known/50 learned'),
              CardBox(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    ClipRRect(borderRadius: BorderRadius.circular(14), child: SizedBox(height: 240, width: double.infinity, child: Photo(card.image))),
                    const SizedBox(height: 10),
                    Align(alignment: Alignment.centerLeft, child: Text(card.word, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: kInk))),
                    Align(alignment: Alignment.centerLeft, child: Text('${card.sentence} • noun', style: const TextStyle(fontSize: 11, color: kMuted))),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => _advance(true),
                            icon: const Icon(Icons.check_circle_outline_rounded, size: 17),
                            label: const Text('I know it'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _advance(false),
                            icon: const Icon(Icons.sync_rounded, size: 17),
                            label: const Text('Still learning'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const SectionTitle('Chat Missions', trailing: 'Active mission • 1/3 complete'),
              _MissionCard(onTap: () => openPage(context, const MilestoneConversationScreen())),
            ] else ...[
              const SectionTitle('Chat Missions', trailing: '1/3 complete'),
              _MissionCard(onTap: () => openPage(context, const MilestoneConversationScreen())),
              const SizedBox(height: 12),
              CardBox(
                child: ListRow(
                  icon: Icons.storefront_rounded,
                  title: 'At the market',
                  subtitle: 'Buy fruit and ask for the price',
                  trailing: 'Locked',
                  onTap: () => showToast(context, 'Complete the café mission first'),
                ),
              ),
              CardBox(
                child: ListRow(
                  icon: Icons.directions_rounded,
                  title: 'Asking for directions',
                  subtitle: 'Find the library and the station',
                  trailing: 'Locked',
                  onTap: () => showToast(context, 'Complete the café mission first'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Segmented extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Segmented({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(color: selected ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(10)),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: selected ? kInk : kMuted),
            ),
          ),
        ),
      );
}

class _MissionCard extends StatelessWidget {
  final VoidCallback onTap;
  const _MissionCard({required this.onTap});

  @override
  Widget build(BuildContext context) => CardBox(
        color: kGreenSoft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Pill('ORDERING FOOD • Level A1', background: Colors.white),
                Spacer(),
                Icon(Icons.chat_bubble_outline_rounded, color: kGreenDark, size: 18),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Practice ordering at a café', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: kInk)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Barista', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10.5, color: kGreenDark)),
                  Text('“Welcome! What would you like to order?”', style: TextStyle(fontSize: 11, color: kInk)),
                  SizedBox(height: 6),
                  Text('You', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10.5, color: kGreenDark)),
                  Text('“I would like a coffee, please.”', style: TextStyle(fontSize: 11, color: kInk)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const ProgressBar(0.33, height: 6),
            const SizedBox(height: 5),
            const Text('Respond correctly to continue', style: TextStyle(fontSize: 9.5, color: kMuted)),
            const SizedBox(height: 8),
            primaryButton('Continue Mission', onTap, icon: Icons.arrow_forward_rounded),
          ],
        ),
      );
}

// ============================================================
// 15. CHAT MISSIONS
// ============================================================
class ChatMissionsScreen extends StatelessWidget {
  const ChatMissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: topBar(context, green: true, title: 'Chat Missions', subtitle: 'Practice real conversations'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 22),
          children: [
            _MissionCard(onTap: () => openPage(context, const MilestoneConversationScreen())),
            const SizedBox(height: 16),
            const SectionTitle('More Missions', trailing: '2 locked'),
            CardBox(
              child: ListRow(
                icon: Icons.storefront_rounded,
                title: 'At the market',
                subtitle: 'Buy fruit and ask for the price',
                trailing: 'Locked',
                onTap: () => showToast(context, 'Complete the café mission first'),
              ),
            ),
            CardBox(
              child: ListRow(
                icon: Icons.directions_rounded,
                title: 'Asking for directions',
                subtitle: 'Find the library and the station',
                trailing: 'Locked',
                onTap: () => showToast(context, 'Complete the café mission first'),
              ),
            ),
            const SizedBox(height: 12),
            CardBox(
              color: kGreenSoft,
              child: const Row(
                children: [
                  CircleIcon(Icons.emoji_events_rounded, size: 38, background: Colors.white, foreground: kGreen),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text('Complete all 3 missions to unlock a conversation badge.', style: TextStyle(fontSize: 11, color: kInk, height: 1.4)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
