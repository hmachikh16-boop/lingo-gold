import 'package:flutter/material.dart';

import '../core.dart';
import '../models/curriculum.dart';
import 'lesson_screen.dart';
import 'result_screen.dart';

class DashboardScreen extends StatelessWidget {
  final Curriculum curriculum;
  const DashboardScreen({super.key, required this.curriculum});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: Progress.instance,
        builder: (context, _) {
          final p = Progress.instance;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: kGreen, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${curriculum.t('app_name')}  ${curriculum.t('dashboard')}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
                          const SizedBox(height: 8),
                          Text('🔥 ${p.streak}  •  ⚡ ${p.xp} XP  •  ⭐ ${p.stars}', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                    const Icon(Icons.eco_rounded, color: Colors.white, size: 48),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _Stat(icon: Icons.check_circle_rounded, value: '${p.completedLessons}', label: 'Lessons'),
                  _Stat(icon: Icons.abc_rounded, value: '${p.wordsLearned}', label: 'Words'),
                  _Stat(icon: Icons.percent_rounded, value: '${p.accuracy}%', label: 'Accuracy'),
                ],
              ),
              const SizedBox(height: 16),
              if (p.dueWords.isNotEmpty)
                CardBox(
                  color: kGreenSoft,
                  onTap: () => openPage(context, ReviewScreen(curriculum: curriculum)),
                  child: Row(
                    children: [
                      const CircleAvatar(backgroundColor: kGreen, child: Icon(Icons.replay_rounded, color: Colors.white)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(curriculum.t('review_today'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                            Text('${p.dueWords.length} words ready', style: const TextStyle(fontSize: 11, color: kMuted)),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: kGreen),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              CardBox(
                onTap: () => openPage(context, LessonScreen(curriculum: curriculum, lessonIndex: p.currentLesson)),
                child: Row(
                  children: [
                    Container(width: 58, height: 58, decoration: BoxDecoration(color: kGreenSoft, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.play_arrow_rounded, color: kGreen, size: 30)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(curriculum.lessons[p.currentLesson].title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                          Text('${curriculum.stepsPerLesson} steps • 30 min', style: const TextStyle(fontSize: 11, color: kMuted)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: kGreen),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SectionTitle('Leaderboard'),
              CardBox(
                child: Column(
                  children: [
                    for (var i = 0; i < curriculum.leaderboard.length; i++)
                      ListTile(
                        leading: CircleAvatar(backgroundColor: i == 3 ? kGreen : kCard, child: Text('${i + 1}', style: TextStyle(fontWeight: FontWeight.w900, color: i == 3 ? Colors.white : kInk))),
                        title: Text(curriculum.leaderboard[i]['name'] as String, style: const TextStyle(fontWeight: FontWeight.w800)),
                        trailing: Text('${curriculum.leaderboard[i]['xp']} XP', style: const TextStyle(color: kGreenDark, fontWeight: FontWeight.w900)),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      );
}

class ReviewScreen extends StatefulWidget {
  final Curriculum curriculum;
  const ReviewScreen({super.key, required this.curriculum});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  late List<String> _words;
  int _i = 0;
  int? _selected;
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _words = Progress.instance.dueWords;
    if (_words.isEmpty) _words = widget.curriculum.lessons.first.steps.take(5).map((e) => e.word).toList();
  }

  @override
  Widget build(BuildContext context) {
    final word = _words[_i];
    final options = <String>[word, ..._words.where((w) => w != word).take(2)];
    options.shuffle();
    final correct = options.indexOf(word);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: kGreen, foregroundColor: Colors.white, title: Text(widget.curriculum.t('review_today'), style: const TextStyle(fontWeight: FontWeight.w900))),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Text('Which word is “$word”?', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: kInk)),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                children: [
                  for (var i = 0; i < options.length; i++)
                    ActionChip(
                      backgroundColor: _selected == i ? kGreenSoft : Colors.white,
                      side: BorderSide(color: _checked && i == correct ? kGreen : kLine, width: 2),
                      label: Text(options[i], style: const TextStyle(fontWeight: FontWeight.w900)),
                      onPressed: _checked ? null : () => setState(() => _selected = i),
                    ),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _selected == null
                      ? null
                      : () async {
                          final ok = _selected == correct;
                          await Progress.instance.answer(word, ok);
                          setState(() => _checked = true);
                          await Future<void>.delayed(const Duration(milliseconds: 600));
                          if (!mounted) return;
                          if (_i < _words.length - 1) {
                            setState(() {
                              _i++;
                              _selected = null;
                              _checked = false;
                            });
                          } else {
                            Navigator.pop(context);
                          }
                        },
                  style: FilledButton.styleFrom(backgroundColor: kGreen, minimumSize: const Size(0, 52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: Text(widget.curriculum.t('continue'), style: const TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  final Curriculum curriculum;
  const SettingsScreen({super.key, required this.curriculum});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(backgroundColor: kGreen, foregroundColor: Colors.white, title: Text(curriculum.t('settings'), style: const TextStyle(fontWeight: FontWeight.w900))),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            CardBox(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.record_voice_over_rounded, color: kGreen),
                    title: const Text('Voice speed'),
                    subtitle: Text('${Tts.instance.rate.toStringAsFixed(2)}x'),
                    trailing: Slider(
                      value: Tts.instance.rate,
                      min: 0.5,
                      max: 1.2,
                      onChanged: (v) => Tts.instance.rate = v,
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.volume_up_rounded, color: kGreen),
                    title: const Text('Test voice'),
                    onTap: () => Tts.instance.speak('Hello. Goodbye.'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            CardBox(
              child: ListTile(
                leading: const Icon(Icons.restart_alt_rounded, color: kGreen),
                title: const Text('Reset progress'),
                onTap: () async {
                  await Progress.instance.reset();
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      );
}

class LeaderboardScreen extends StatelessWidget {
  final Curriculum curriculum;
  const LeaderboardScreen({super.key, required this.curriculum});
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(backgroundColor: kGreen, foregroundColor: Colors.white, title: const Text('Leaderboard', style: TextStyle(fontWeight: FontWeight.w900))),
        body: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: curriculum.leaderboard.length,
          itemBuilder: (context, i) => CardBox(
            child: ListTile(
              leading: CircleAvatar(backgroundColor: kGreen, child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900))),
              title: Text(curriculum.leaderboard[i]['name'] as String, style: const TextStyle(fontWeight: FontWeight.w900)),
              trailing: Text('${curriculum.leaderboard[i]['xp']} XP', style: const TextStyle(color: kGreenDark, fontWeight: FontWeight.w900)),
            ),
          ),
        ),
      );
}

class WeeklyReportScreen extends StatelessWidget {
  final Curriculum curriculum;
  const WeeklyReportScreen({super.key, required this.curriculum});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: Progress.instance,
        builder: (context, _) {
          final p = Progress.instance;
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(backgroundColor: kGreen, foregroundColor: Colors.white, title: const Text('Weekly Report', style: TextStyle(fontWeight: FontWeight.w900))),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                CardBox(
                  child: Column(
                    children: [
                      for (var i = 0; i < 7; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              SizedBox(width: 28, child: Text('${i + 1}', style: const TextStyle(color: kMuted))),
                              Expanded(child: LinearProgressIndicator(value: (p.week[i] / 10).clamp(0.0, 1.0), color: kGreen, backgroundColor: kLine, minHeight: 10)),
                              const SizedBox(width: 10),
                              Text('${p.week[i]}', style: const TextStyle(fontWeight: FontWeight.w900)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
}

class CardBox extends StatelessWidget {
  final Widget child;
  final Color color;
  final VoidCallback? onTap;
  const CardBox({super.key, required this.child, this.color = Colors.white, this.onTap});
  @override
  Widget build(BuildContext context) {
    final box = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16), border: Border.all(color: kLine)),
      child: child,
    );
    if (onTap == null) return box;
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: box);
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: kInk)),
      );
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _Stat({required this.icon, required this.value, required this.label});
  @override
  Widget build(BuildContext context) => Expanded(
        child: CardBox(
          child: Column(
            children: [
              Icon(icon, color: kGreen),
              const SizedBox(height: 6),
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              Text(label, style: const TextStyle(fontSize: 10, color: kMuted)),
            ],
          ),
        ),
      );
}
