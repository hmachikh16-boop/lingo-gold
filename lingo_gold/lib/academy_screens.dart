import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data.dart';
import 'immersion_flow_screen.dart';
import 'lesson_choice.dart';
import 'lesson_content_service.dart';
import 'lesson_speaking.dart';
import 'lesson_writing.dart';
import 'progress_service.dart';
import 'services/speech_service.dart';
import 'stories_screen.dart';
import 'theme.dart';
import 'user_profile.dart';
import 'widgets.dart';

/// صورة محلية فقط — لا روابط إنترنت ولا صور مولدة.
class LocalPhoto extends StatelessWidget {
  final Lesson lesson;
  final BoxFit fit;
  final double? height;
  final double? width;
  const LocalPhoto({
    super.key,
    required this.lesson,
    this.fit = BoxFit.cover,
    this.height,
    this.width,
  });

  String get _name {
    final url = (lesson.imageUrl ?? '').trim();
    if (url.isNotEmpty) return url.split('/').last;
    return '${lesson.imageFile}${lesson.isPack ? '_${lesson.indexInPack}' : ''}.jpg';
  }

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/$_name',
      width: width ?? double.infinity,
      height: height ?? double.infinity,
      fit: fit,
      errorBuilder: (_, __, ___) => const ColoredBox(color: kCard),
    );
  }
}

class AcademyScreen extends StatelessWidget {
  final ValueChanged<int> onLessonComplete;
  final VoidCallback onExit;
  const AcademyScreen({
    super.key,
    required this.onLessonComplete,
    required this.onExit,
  });

  static const learning = [
    'Core Lesson', 'Pronunciation / TruAccent', 'Vocabulary', 'Grammar',
    'Reading', 'Writing', 'Listening', 'Speaking', 'Choose an Image',
    'Choose a Prompt', 'Review / Adaptive Recall', 'Milestone Conversation',
    'Stories', 'Phrasebook', 'Flashcards', 'Chat Missions',
  ];
  static const tracking = [
    'Dashboard / Progress', 'Achievements', 'Weekly Report', 'Leaderboard',
    'Parent Dashboard', 'Goals', 'Profile', 'Quiz Result',
    'Vocabulary Review', 'Settings',
  ];

  void _go(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  Lesson get _current {
    final id = UserProfile.instance.currentLessonId.value.clamp(1, lessons.length);
    return lessons[id - 1];
  }

  Widget _card(String title, IconData icon, VoidCallback tap) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: kLine),
      ),
      child: ListTile(
        leading: CircleIcon(icon: icon, background: kSoftGreen, foreground: kPrimary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: kInk)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: kMuted),
        onTap: tap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('منهج Rosetta Stone'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          const Text('واجهات التعلّم', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: kInk)),
          const SizedBox(height: 10),
          for (final t in learning)
            _card(t, Icons.school_outlined, () => _openLearning(context, t)),
          const SizedBox(height: 20),
          const Text('واجهات المتابعة', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: kInk)),
          const SizedBox(height: 10),
          for (final t in tracking)
            _card(t, Icons.insights_outlined, () => _openTracking(context, t)),
        ],
      ),
    );
  }

  int get _start => UserProfile.instance.currentLessonId.value.clamp(1, lessons.length);

  void _openLearning(BuildContext context, String t) {
    final l = _current;
    switch (t) {
      case 'Core Lesson':
        _go(context, ImmersionFlowScreen(
          startId: _start, endId: _start,
          onLessonComplete: onLessonComplete,
          onExit: () => Navigator.of(context).pop(),
        ));
        break;
      case 'Pronunciation / TruAccent':
        _go(context, PronunciationScreen(lesson: l, onDone: onLessonComplete));
        break;
      case 'Vocabulary':
        _go(context, const VocabularyScreen());
        break;
      case 'Grammar':
        _go(context, GrammarScreen(lesson: l));
        break;
      case 'Reading':
        _go(context, ReadingScreen(lesson: l));
        break;
      case 'Writing':
        _go(context, SkillWrapper(
          title: 'Writing',
          child: WritingStep(lesson: l, targetWord: l.word, onComplete: (_) => onLessonComplete(_start)),
        ));
        break;
      case 'Listening':
        _go(context, SkillWrapper(
          title: 'Listening',
          child: ListeningStep(lesson: l, distractors: _others(l), onComplete: (_) => onLessonComplete(_start), showTranslation: false),
        ));
        break;
      case 'Speaking':
        _go(context, SkillWrapper(
          title: 'Speaking',
          child: SpeakingStep(lesson: l, onComplete: (_, __) => onLessonComplete(_start), showTranslation: false),
        ));
        break;
      case 'Choose an Image':
        _go(context, SkillWrapper(
          title: 'Choose an Image',
          child: ChooseStep(lesson: l, distractors: _others(l), onComplete: (_) => onLessonComplete(_start)),
        ));
        break;
      case 'Choose a Prompt':
        _go(context, ChoosePromptScreen(lesson: l, onDone: () => onLessonComplete(_start)));
        break;
      case 'Review / Adaptive Recall':
        _go(context, AdaptiveRecallScreen(lesson: l, onDone: () => onLessonComplete(_start)));
        break;
      case 'Milestone Conversation':
        _go(context, const MilestoneConversationScreen());
        break;
      case 'Stories':
        _go(context, StoriesScreen(
          completedLessons: UserProfile.instance.lessonsCompleted.value,
          onOpenStory: (_) => Navigator.of(context).pop(),
        ));
        break;
      case 'Phrasebook':
        _go(context, const PhrasebookScreen());
        break;
      case 'Flashcards':
        _go(context, const FlashcardsScreen());
        break;
      case 'Chat Missions':
        _go(context, const ChatMissionsScreen());
        break;
    }
  }

  void _openTracking(BuildContext context, String t) {
    switch (t) {
      case 'Dashboard / Progress':
        _go(context, const DashboardScreen());
        break;
      case 'Achievements':
        _go(context, const AchievementsScreen());
        break;
      case 'Weekly Report':
        _go(context, const WeeklyReportScreen());
        break;
      case 'Leaderboard':
        _go(context, const LeaderboardScreen());
        break;
      case 'Parent Dashboard':
        _go(context, const ParentDashboardScreen());
        break;
      case 'Goals':
        _go(context, const GoalsScreen());
        break;
      case 'Profile':
        _go(context, const ProfileSummaryScreen());
        break;
      case 'Quiz Result':
        _go(context, const QuizResultScreen());
        break;
      case 'Vocabulary Review':
        _go(context, const VocabularyReviewScreen());
        break;
      case 'Settings':
        _go(context, const SettingsScreen());
        break;
    }
  }

  List<Lesson> _others(Lesson l) {
    final idx = lessons.indexOf(l);
    final out = <Lesson>[];
    for (var d = 1; d <= 8 && out.length < 3; d++) {
      for (final j in [idx - d, idx + d]) {
        if (j < 0 || j >= lessons.length) continue;
        if (lessons[j].word == l.word) continue;
        out.add(lessons[j]);
        if (out.length >= 3) break;
      }
    }
    return out;
  }
}

class SkillWrapper extends StatelessWidget {
  final String title;
  final Widget child;
  const SkillWrapper({super.key, required this.title, required this.child});
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(title: Text(title), centerTitle: true),
        body: SafeArea(child: child),
      );
}

class PronunciationScreen extends StatefulWidget {
  final Lesson lesson;
  final ValueChanged<int> onDone;
  const PronunciationScreen({super.key, required this.lesson, required this.onDone});
  @override
  State<PronunciationScreen> createState() => _PronunciationScreenState();
}
class _PronunciationScreenState extends State<PronunciationScreen> {
  int _score = 0;
  bool _listening = false;
  Future<void> _listen() async {
    setState(() => _listening = true);
    await SpeechService.listenEnglish((heard) {
      final target = widget.lesson.spokenText.toLowerCase().replaceAll(RegExp(r'[^a-z ]'), '');
      final words = target.split(' ').where((w) => w.isNotEmpty && !{'a','an','the'}.contains(w)).toList();
      final got = heard.toLowerCase().split(' ');
      final hit = words.where((w) => got.contains(w)).length;
      final s = words.isEmpty ? 100 : (hit * 100 / words.length).round();
      setState(() {
        _score = s;
        _listening = false;
      });
      widget.onDone(widget.lesson.order);
    });
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(title: const Text('Pronunciation / TruAccent'), centerTitle: true),
    body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      ClipRRect(borderRadius: BorderRadius.circular(18), child: SizedBox(height: 220, width: 280, child: LocalPhoto(lesson: widget.lesson))),
      const SizedBox(height: 22),
      Text(widget.lesson.spokenText, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: kInk)),
      const SizedBox(height: 26),
      SizedBox(width: 110, height: 110, child: FilledButton(
        onPressed: _listening ? null : _listen,
        style: FilledButton.styleFrom(shape: const CircleBorder()),
        child: const Icon(Icons.mic_rounded, size: 44),
      )),
      const SizedBox(height: 18),
      Text('$_score%', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: kPrimary)),
      const SizedBox(height: 6),
      const Text('TruAccent', style: TextStyle(color: kMuted)),
    ])),
  );
}

class VocabularyScreen extends StatelessWidget {
  const VocabularyScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(title: const Text('Vocabulary'), centerTitle: true),
    body: ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: min(30, lessons.length),
      itemBuilder: (_, i) {
        final l = lessons[i];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: kLine)),
          child: ListTile(
            leading: ClipRRect(borderRadius: BorderRadius.circular(10), child: SizedBox(width: 56, height: 56, child: LocalPhoto(lesson: l))),
            title: Text(l.word, style: const TextStyle(fontWeight: FontWeight.w800, color: kInk)),
            subtitle: Text(l.sentence, maxLines: 1),
            trailing: IconButton(icon: const Icon(Icons.volume_up_rounded, color: kPrimary), onPressed: () => TtsService.instance.speak(l.spokenText)),
          ),
        );
      },
    ),
  );
}

class GrammarScreen extends StatelessWidget {
  final Lesson lesson;
  const GrammarScreen({super.key, required this.lesson});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(title: const Text('Grammar'), centerTitle: true),
    body: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
      ClipRRect(borderRadius: BorderRadius.circular(18), child: SizedBox(height: 190, width: double.infinity, child: LocalPhoto(lesson: lesson))),
      const SizedBox(height: 20),
      Text(lesson.sentence, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: kInk)),
      const SizedBox(height: 12),
      const Text('Pattern', style: TextStyle(color: kMuted)),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(14)),
        child: Text(
          lesson.sentence.replaceAll(RegExp(r'\b[a-z]+\b'), '____'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kPrimaryDark),
        ),
      ),
    ])),
  );
}

class ReadingScreen extends StatefulWidget {
  final Lesson lesson;
  const ReadingScreen({super.key, required this.lesson});
  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}
class _ReadingScreenState extends State<ReadingScreen> {
  int? _sel;
  late final List<String> _opts;
  late final int _correct;
  @override
  void initState() {
    super.initState();
    final pool = lessons.where((l) => l.word != widget.lesson.word).take(3).map((l) => l.sentence).toList();
    _opts = [widget.lesson.sentence, ...pool]..shuffle(Random(widget.lesson.word.hashCode));
    _correct = _opts.indexOf(widget.lesson.sentence);
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(title: const Text('Reading'), centerTitle: true),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      ClipRRect(borderRadius: BorderRadius.circular(18), child: SizedBox(height: 200, width: double.infinity, child: LocalPhoto(lesson: widget.lesson))),
      const SizedBox(height: 20),
      const Text('Choose the matching sentence', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: kInk)),
      const SizedBox(height: 12),
      for (var i = 0; i < _opts.length; i++)
        Padding(padding: const EdgeInsets.only(bottom: 10), child: OutlinedButton(
          onPressed: () => setState(() => _sel = i),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: _sel == i ? kPrimary : kLine, width: _sel == i ? 2 : 1),
            minimumSize: const Size(0, 54),
          ),
          child: Text(_opts[i], textAlign: TextAlign.center),
        )),
      const SizedBox(height: 10),
      FilledButton(onPressed: _sel == null ? null : () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_sel == _correct ? 'Correct' : 'Try again'))), child: const Text('Continue')),
    ]),
  );
}

class ChoosePromptScreen extends StatefulWidget {
  final Lesson lesson;
  final VoidCallback onDone;
  const ChoosePromptScreen({super.key, required this.lesson, required this.onDone});
  @override
  State<ChoosePromptScreen> createState() => _ChoosePromptScreenState();
}
class _ChoosePromptScreenState extends State<ChoosePromptScreen> {
  int? _sel;
  late final List<String> _opts;
  @override
  void initState() {
    super.initState();
    final pool = lessons.where((l) => l.word != widget.lesson.word).take(3).map((l) => l.word).toList();
    _opts = [widget.lesson.word, ...pool]..shuffle(Random(widget.lesson.word.hashCode + 3));
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(title: const Text('Choose a Prompt'), centerTitle: true),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      ClipRRect(borderRadius: BorderRadius.circular(18), child: SizedBox(height: 210, width: double.infinity, child: LocalPhoto(lesson: widget.lesson))),
      const SizedBox(height: 20),
      const Text('Choose the correct word', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: kInk)),
      const SizedBox(height: 16),
      Wrap(spacing: 10, runSpacing: 10, children: [
        for (var i = 0; i < _opts.length; i++)
          ChoiceChip(
            label: Text(_opts[i]),
            selected: _sel == i,
            onSelected: (_) => setState(() => _sel = i),
            selectedColor: kSoftGreen,
          ),
      ]),
      const SizedBox(height: 24),
      FilledButton(onPressed: _sel == null ? null : () { widget.onDone(); Navigator.pop(context); }, child: const Text('Continue')),
    ]),
  );
}

class AdaptiveRecallScreen extends StatefulWidget {
  final Lesson lesson;
  final VoidCallback onDone;
  const AdaptiveRecallScreen({super.key, required this.lesson, required this.onDone});
  @override
  State<AdaptiveRecallScreen> createState() => _AdaptiveRecallScreenState();
}
class _AdaptiveRecallScreenState extends State<AdaptiveRecallScreen> {
  int _q = 0;
  int _correct = 0;
  late final List<Lesson> _items;
  @override
  void initState() {
    super.initState();
    final due = LessonContentService.instance.lessonsForIds(ProgressService.instance.dueIds());
    _items = (due.length >= 4 ? due : lessons.take(8).toList()).take(8).toList();
  }
  @override
  Widget build(BuildContext context) {
    if (_q >= _items.length) {
      return Scaffold(backgroundColor: Colors.white, appBar: AppBar(title: const Text('Review'), centerTitle: true), body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.check_circle_rounded, size: 76, color: kPrimary),
        const SizedBox(height: 16),
        Text('$_correct / ${_items.length}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: kInk)),
        const SizedBox(height: 20),
        FilledButton(onPressed: () { widget.onDone(); Navigator.pop(context); }, child: const Text('Continue')),
      ])));
    }
    final l = _items[_q];
    final others = lessons.where((x) => x.word != l.word).take(3).toList();
    final opts = [l, ...others]..shuffle(Random(l.word.hashCode + _q));
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Review • Adaptive Recall'), centerTitle: true),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Text('Question ${_q + 1} of ${_items.length}', style: const TextStyle(fontWeight: FontWeight.w900, color: kInk)),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: (_q + 1) / _items.length, color: kPrimary, backgroundColor: kCard),
        const SizedBox(height: 20),
        Text('Which photo shows "${l.word}"?', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: kInk)),
        const SizedBox(height: 14),
        GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: opts.length, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.3), itemBuilder: (_, i) => GestureDetector(
          onTap: () {
            final ok = opts[i].word == l.word;
            if (ok) _correct++;
            ProgressService.instance.record(l.id.isNotEmpty ? l.id : 'L${l.order}', ok);
            setState(() => _q++);
          },
          child: ClipRRect(borderRadius: BorderRadius.circular(14), child: LocalPhoto(lesson: opts[i])),
        )),
      ]),
    );
  }
}

class MilestoneConversationScreen extends StatefulWidget {
  const MilestoneConversationScreen({super.key});
  @override
  State<MilestoneConversationScreen> createState() => _MilestoneConversationScreenState();
}
class _MilestoneConversationScreenState extends State<MilestoneConversationScreen> {
  final _ctrl = TextEditingController();
  final _msgs = <Map<String, String>>[
    {'who': 'them', 'text': 'Hello! Welcome. What would you like today?'},
  ];
  void _send() {
    final t = _ctrl.text.trim();
    if (t.isEmpty) return;
    setState(() {
      _msgs.add({'who': 'me', 'text': t});
      _msgs.add({'who': 'them', 'text': 'Great choice! Continue please.'});
      _ctrl.clear();
    });
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(title: const Text('Milestone • Conversation'), centerTitle: true),
    body: Column(children: [
      Padding(padding: const EdgeInsets.all(16), child: Row(children: [
        ClipRRect(borderRadius: BorderRadius.circular(30), child: Image.asset('assets/images/native_speaker_woman.jpg', width: 58, height: 58, fit: BoxFit.cover)),
        const SizedBox(width: 12),
        const Expanded(child: Text('Ana • Native Speaker', style: TextStyle(fontWeight: FontWeight.w900, color: kInk))),
      ])),
      Expanded(child: ListView.builder(padding: const EdgeInsets.all(16), itemCount: _msgs.length, itemBuilder: (_, i) {
        final m = _msgs[i];
        final me = m['who'] == 'me';
        return Align(alignment: me ? Alignment.centerRight : Alignment.centerLeft, child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: me ? kPrimary : kCard, borderRadius: BorderRadius.circular(14)),
          child: Text(m['text']!, style: TextStyle(color: me ? Colors.white : kInk)),
        ));
      })),
      Padding(padding: const EdgeInsets.all(12), child: Row(children: [
        Expanded(child: TextField(controller: _ctrl, decoration: const InputDecoration(hintText: 'Type your answer…'))),
        const SizedBox(width: 8),
        SizedBox(width: 56, height: 56, child: FilledButton(onPressed: _send, style: FilledButton.styleFrom(shape: const CircleBorder()), child: const Icon(Icons.send_rounded))),
      ])),
    ]),
  );
}

class PhrasebookScreen extends StatelessWidget {
  const PhrasebookScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(title: const Text('Phrasebook'), centerTitle: true),
    body: ListView.builder(padding: const EdgeInsets.all(16), itemCount: min(20, lessons.length), itemBuilder: (_, i) {
      final l = lessons[i];
      return ListTile(
        title: Text(l.sentence, style: const TextStyle(fontWeight: FontWeight.w800, color: kInk)),
        subtitle: Text(l.word),
        trailing: IconButton(icon: const Icon(Icons.volume_up_rounded, color: kPrimary), onPressed: () => TtsService.instance.speak(l.spokenText)),
      );
    }),
  );
}

class FlashcardsScreen extends StatefulWidget {
  const FlashcardsScreen({super.key});
  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}
class _FlashcardsScreenState extends State<FlashcardsScreen> {
  int _i = 0;
  bool _show = false;
  @override
  Widget build(BuildContext context) {
    final l = lessons[_i.clamp(0, lessons.length - 1)];
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Flashcards'), centerTitle: true),
      body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        GestureDetector(
          onTap: () => setState(() => _show = !_show),
          child: ClipRRect(borderRadius: BorderRadius.circular(20), child: SizedBox(width: 300, height: 360, child: LocalPhoto(lesson: l))),
        ),
        const SizedBox(height: 18),
        Text(_show ? l.word : 'Tap the card', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: kInk)),
        const SizedBox(height: 20),
        FilledButton(onPressed: () { setState(() { _i = (_i + 1) % min(30, lessons.length); _show = false; }); }, child: const Text('Next')),
      ])),
    );
  }
}

class ChatMissionsScreen extends StatelessWidget {
  const ChatMissionsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(title: const Text('Chat Missions'), centerTitle: true),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      _mission(context, 'Ordering at a café', 'Ana • Native Speaker'),
      _mission(context, 'At the market', 'Teacher • Native Speaker'),
      _mission(context, 'Asking for directions', 'Pilot • Native Speaker'),
    ]),
  );
  Widget _mission(BuildContext context, String title, String sub) => Card(
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: kLine)),
    child: ListTile(
      leading: ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.asset('assets/images/native_speaker_woman.jpg', width: 44, height: 44, fit: BoxFit.cover)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: kInk)),
      subtitle: Text(sub),
      trailing: const Icon(Icons.chat_bubble_outline, color: kPrimary),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MilestoneConversationScreen())),
    ),
  );
}

// ============ METABOOK ============

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(title: const Text('Dashboard / Progress'), centerTitle: true),
    body: ValueListenableBuilder<int>(
      valueListenable: UserProfile.instance.lessonsCompleted,
      builder: (_, done, __) => Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('${done + 1} / ${lessons.length}', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: kInk)),
        const SizedBox(height: 10),
        LinearProgressIndicator(value: done / lessons.length, color: kPrimary, backgroundColor: kCard),
        const SizedBox(height: 22),
        _stat('${UserProfile.instance.stars.value}', 'Stars'),
        _stat('${UserProfile.instance.totalXP.value}', 'XP'),
        _stat('${UserProfile.instance.streak.value}', 'Day streak'),
      ])),
    ),
  );
  Widget _stat(String v, String l) => Card(elevation: 0, color: kCard, child: ListTile(title: Text(v, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: kPrimary)), subtitle: Text(l)));
}

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(title: const Text('Achievements'), centerTitle: true),
    body: GridView.count(crossAxisCount: 2, padding: const EdgeInsets.all(16), children: [
      _badge(Icons.check_circle_rounded, 'First Lesson', true),
      _badge(Icons.local_fire_department_rounded, '7 Day Streak', UserProfile.instance.streak.value >= 7),
      _badge(Icons.record_voice_over_rounded, 'Speaking Star', UserProfile.instance.pronunciationScore.value >= 80),
      _badge(Icons.auto_stories_rounded, 'Story Reader', UserProfile.instance.lessonsCompleted.value >= 20),
    ]),
  );
  Widget _badge(IconData i, String t, bool on) => Card(elevation: 0, color: on ? kSoftGreen : kCard, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(i, size: 42, color: on ? kPrimary : kMuted),
    const SizedBox(height: 8),
    Text(t, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800, color: kInk)),
  ]));
}

class WeeklyReportScreen extends StatelessWidget {
  const WeeklyReportScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(title: const Text('Weekly Report'), centerTitle: true),
    body: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
      const Text('This Week', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: kInk)),
      const SizedBox(height: 20),
      Expanded(child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, crossAxisAlignment: CrossAxisAlignment.end, children: [
        for (var i = 0; i < 7; i++)
          Column(children: [
            Container(width: 22, height: 40.0 + (i * 18 % 120), decoration: BoxDecoration(color: kPrimary.withValues(alpha: 0.5 + i * 0.06), borderRadius: BorderRadius.circular(6))),
            const SizedBox(height: 6),
            Text(['S','M','T','W','T','F','S'][i]),
          ]),
      ])),
    ])),
  );
}

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(title: const Text('Leaderboard'), centerTitle: true),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      for (var i = 0; i < 6; i++) ListTile(
        leading: CircleAvatar(child: Text('${i + 1}')),
        title: Text(i == 0 ? 'You' : 'Learner ${i + 1}', style: const TextStyle(fontWeight: FontWeight.w800, color: kInk)),
        trailing: Text('${1500 - i * 120} XP', style: const TextStyle(color: kPrimary, fontWeight: FontWeight.w900)),
      ),
    ]),
  );
}

class ParentDashboardScreen extends StatelessWidget {
  const ParentDashboardScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(title: const Text('Parent Dashboard'), centerTitle: true),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      Row(children: [
        ClipRRect(borderRadius: BorderRadius.circular(40), child: Image.asset('assets/images/img_girl_child.jpg', width: 86, height: 86, fit: BoxFit.cover)),
        const SizedBox(width: 14),
        const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Emma', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: kInk)),
          Text('Active Learner', style: TextStyle(color: kMuted)),
        ]),
      ]),
      const SizedBox(height: 20),
      Card(elevation: 0, color: kCard, child: Padding(padding: const EdgeInsets.all(16), child: Text('Lessons completed: ${UserProfile.instance.lessonsCompleted.value}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)))),
      const SizedBox(height: 10),
      Card(elevation: 0, color: kCard, child: Padding(padding: const EdgeInsets.all(16), child: Text('Pronunciation: ${UserProfile.instance.pronunciationScore.value}%', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)))),
    ]),
  );
}

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});
  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}
class _GoalsScreenState extends State<GoalsScreen> {
  int _goal = 5;
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    setState(() => _goal = p.getInt('lingo_daily_goal') ?? 5);
  }
  Future<void> _save(int v) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('lingo_daily_goal', v);
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(title: const Text('Goals'), centerTitle: true),
    body: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
      Text('Daily goal: $_goal lessons', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: kInk)),
      Slider(value: _goal.toDouble(), min: 1, max: 20, divisions: 19, activeColor: kPrimary, onChanged: (v) { setState(() => _goal = v.round()); _save(_goal); }),
    ])),
  );
}

class ProfileSummaryScreen extends StatelessWidget {
  const ProfileSummaryScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(title: const Text('Profile'), centerTitle: true),
    body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      ClipRRect(borderRadius: BorderRadius.circular(50), child: Image.asset('assets/images/q0.jpg', width: 100, height: 100, fit: BoxFit.cover)),
      const SizedBox(height: 16),
      Text('Level ${UserProfile.instance.totalXP.value ~/ 200 + 1}', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: kInk)),
      const SizedBox(height: 8),
      Text('${UserProfile.instance.totalXP.value} XP • ${UserProfile.instance.streak.value} day streak', style: const TextStyle(color: kMuted)),
    ])),
  );
}

class QuizResultScreen extends StatelessWidget {
  const QuizResultScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(title: const Text('Quiz Result'), centerTitle: true),
    body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.check_circle_rounded, size: 80, color: kPrimary),
      const SizedBox(height: 16),
      const Text('Great job!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: kInk)),
      const SizedBox(height: 8),
      const Text('9 / 10 correct', style: TextStyle(fontSize: 20, color: kMuted)),
      const SizedBox(height: 24),
      FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Continue')),
    ])),
  );
}

class VocabularyReviewScreen extends StatelessWidget {
  const VocabularyReviewScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(title: const Text('Vocabulary Review'), centerTitle: true),
    body: ListView.builder(padding: const EdgeInsets.all(16), itemCount: min(20, lessons.length), itemBuilder: (_, i) {
      final l = lessons[i];
      return ListTile(
        leading: ClipRRect(borderRadius: BorderRadius.circular(10), child: SizedBox(width: 50, height: 50, child: LocalPhoto(lesson: l))),
        title: Text(l.word, style: const TextStyle(fontWeight: FontWeight.w800, color: kInk)),
        trailing: IconButton(icon: const Icon(Icons.volume_up_rounded, color: kPrimary), onPressed: () => TtsService.instance.speak(l.spokenText)),
      );
    }),
  );
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}
class _SettingsScreenState extends State<SettingsScreen> {
  bool _sound = true;
  bool _notifications = true;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(title: const Text('Settings'), centerTitle: true),
    body: ListView(children: [
      SwitchListTile(title: const Text('Sound effects'), value: _sound, activeColor: kPrimary, onChanged: (v) => setState(() => _sound = v)),
      SwitchListTile(title: const Text('Daily reminder'), value: _notifications, activeColor: kPrimary, onChanged: (v) => setState(() => _notifications = v)),
      const ListTile(title: Text('Language: English'), subtitle: Text('Immersion mode')),
    ]),
  );
}
