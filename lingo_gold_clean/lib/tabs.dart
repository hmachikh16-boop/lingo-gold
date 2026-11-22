import 'dart:math';

import 'package:flutter/material.dart';

import 'core.dart';
import 'learning_screens.dart';
import 'lessons_data.dart';
import 'tracking_screens.dart';

// ============================================================
// HOME / DASHBOARD
// ============================================================
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) => const DashboardScreen();
}

class DashboardScreen extends StatelessWidget {
  final bool pushed;
  const DashboardScreen({super.key, this.pushed = false});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: Progress.instance,
        builder: (context, _) {
          final p = Progress.instance;
          final body = ListView(
            padding: EdgeInsets.fromLTRB(0, 0, 0, pushed ? 24 : 108),
            children: [
              _dashboardHeader(p),
              Transform.translate(
                offset: const Offset(0, -18),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _streakCard(p),
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _xpCard(p)),
                          const SizedBox(width: 10),
                          Expanded(child: _levelCard(p)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _levelProgressCard(p),
                      const SizedBox(height: 10),
                      _continueCard(p, context),
                      const SizedBox(height: 16),
                      _todaysProgress(p),
                      const SizedBox(height: 16),
                      _learningFocus(p, context),
                      const SizedBox(height: 16),
                      const SectionTitle('Quick Access'),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 2.25,
                        children: [
                          _QuickCard(icon: Icons.bar_chart_rounded, label: 'Weekly Report', onTap: () => openPage(context, const WeeklyReportScreen())),
                          _QuickCard(icon: Icons.emoji_events_rounded, label: 'Achievements', onTap: () => openPage(context, const AchievementsScreen())),
                          _QuickCard(icon: Icons.leaderboard_rounded, label: 'Leaderboard', onTap: () => openPage(context, const LeaderboardScreen())),
                          _QuickCard(icon: Icons.track_changes_rounded, label: 'Goals', onTap: () => openPage(context, const GoalsScreen())),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
          if (!pushed) return SafeArea(top: false, child: body);
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: topBar(context, title: 'Dashboard / Progress'),
            body: SafeArea(top: false, child: body),
          );
        },
      );

  Widget _dashboardHeader(Progress p) => Container(
        decoration: const BoxDecoration(
          color: kGreen,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
        child: SafeArea(
          bottom: false,
          child: Row(
            children: [
              const Avatar('img_girl_child.jpg', size: 58, ring: true),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Hi, Emma!', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 3),
                    Text('Level ${p.level} • Explorer', style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: .18), shape: BoxShape.circle, border: Border.all(color: Colors.white54)),
                child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 25),
              ),
            ],
          ),
        ),
      );

  Widget _streakCard(Progress p) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final todayIndex = DateTime.now().weekday - 1;
    return CardBox(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.local_fire_department_rounded, color: kGreen, size: 27),
              const SizedBox(width: 5),
              Text('${p.streak}-Day Streak', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: kInk)),
              const Spacer(),
              const Pill('Today', icon: Icons.check_circle_rounded),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < 7; i++)
                Column(
                  children: [
                    Text(days[i], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: kMuted)),
                    const SizedBox(height: 4),
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: p.week[i] > 0 ? kGreenSoft : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: i == todayIndex ? kGreen : kLine, width: i == todayIndex ? 2 : 1),
                      ),
                      child: p.week[i] > 0
                          ? const Icon(Icons.check_rounded, color: kGreen, size: 15)
                          : Text('${i + 1}', style: const TextStyle(fontSize: 8, color: kMuted)),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            p.streak >= 14 ? 'Two weeks strong! Keep the habit alive.' : 'Keep it up! ${max(0, 14 - p.streak)} more days to reach a 2-week streak',
            style: const TextStyle(fontSize: 10, color: kMuted, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _xpCard(Progress p) => Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(color: kGreenSoft, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            const CircleIcon(Icons.bolt_rounded, size: 38, background: Colors.white, foreground: kGreen),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${p.xp} XP', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: kInk)),
                  const Text('Total XP', style: TextStyle(fontSize: 9.5, color: kMuted)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _levelCard(Progress p) => Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            const CircleIcon(Icons.emoji_events_rounded, size: 38, background: Colors.white, foreground: kGreen),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Level ${p.level}', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: kInk)),
                  Text('${p.xpToNext} XP to Level ${p.level + 1}', style: const TextStyle(fontSize: 9.5, color: kMuted)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _levelProgressCard(Progress p) => CardBox(
        padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
        child: Column(
          children: [
            Row(
              children: [
                Text('Level ${p.level + 1} Progress', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: kInk)),
                const Spacer(),
                Text('${p.levelXp} / 200 XP', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: kGreenDark)),
              ],
            ),
            const SizedBox(height: 6),
            ProgressBar(p.levelXp / 200, height: 9),
          ],
        ),
      );

  Widget _continueCard(Progress p, BuildContext context) {
    final item = itemAt(p.current);
    return CardBox(
      padding: const EdgeInsets.all(9),
      onTap: () => openPage(context, LessonJourneyScreen(index: p.current)),
      child: Row(
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(12), child: SizedBox(width: 74, height: 74, child: Photo(item.image))),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Continue learning', style: TextStyle(fontSize: 9.5, color: kMuted, fontWeight: FontWeight.w700)),
                Text(item.word, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: kInk)),
                Text(item.sentence, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9.5, color: kMuted)),
              ],
            ),
          ),
          const CircleIcon(Icons.play_arrow_rounded, size: 36, background: kGreen, foreground: Colors.white),
        ],
      ),
    );
  }

  Widget _todaysProgress(Progress p) => CardBox(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Today's Progress", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: kInk)),
            const SizedBox(height: 6),
            ListRow(icon: Icons.menu_book_rounded, title: 'Lessons Completed: ${p.todayLessons}/5', subtitle: 'Keep your daily goal on track', trailing: '+${p.todayLessons * 20} XP'),
            const Divider(height: 1, color: kLine),
            ListRow(icon: Icons.mic_rounded, title: 'Speaking Practice: ${p.todayLessons > 0 ? 'Complete' : 'Not started'}', subtitle: 'Pronunciation score ${p.pronunciation}%', trailing: '+40 XP'),
            const Divider(height: 1, color: kLine),
            ListRow(icon: Icons.extension_rounded, title: 'Vocabulary: ${min(20, p.words)}/20 words', subtitle: 'Words learned so far', trailing: '+30 XP'),
          ],
        ),
      );

  Widget _learningFocus(Progress p, BuildContext context) => CardBox(
        color: kGreenSoft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                CircleIcon(Icons.language_rounded, size: 38, background: Colors.white, foreground: kGreen),
                SizedBox(width: 8),
                Text('English • Focus: Travel & Dining', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: kInk)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text('Course Progress', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: kMuted)),
                const Spacer(),
                Text('${(p.completed / items.length * 100).round()}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: kGreenDark)),
              ],
            ),
            const SizedBox(height: 4),
            ProgressBar(p.completed / items.length, height: 7),
            const SizedBox(height: 10),
            primaryButton('Practice Now', () => openPage(context, LessonJourneyScreen(index: p.current)), icon: Icons.play_arrow_rounded),
          ],
        ),
      );
}

class _QuickCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickCard({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13), border: Border.all(color: kLine)),
          child: Row(
            children: [
              CircleIcon(icon, size: 31, background: kGreenSoft),
              const SizedBox(width: 6),
              Expanded(child: Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: kInk))),
              const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: kMuted),
            ],
          ),
        ),
      );
}

// ============================================================
// LESSON JOURNEY (one lesson = 4 skills + review)
// ============================================================
class LessonJourneyScreen extends StatelessWidget {
  final int index;
  const LessonJourneyScreen({super.key, required this.index});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: Progress.instance,
        builder: (context, _) {
          final p = Progress.instance;
          final item = itemAt(index);
          final unit = index ~/ 4;
          final lessonInUnit = index % 4 + 1;
          final unitEnd = min((unit + 1) * 4, items.length);
          final doneInUnit = (p.completed - unit * 4).clamp(0, 4);
          final lessonDone = index < p.completed;
          final unitDone = p.completed >= unitEnd;
          final steps = <_PlanStep>[
            _PlanStep('Core Lesson', 'الدرس الأساسي • صورة وكلمة وجملة', Icons.school_rounded, '30m', () => openPage(context, CoreLessonScreen(index: index))),
            _PlanStep('Pronunciation', 'النطق • TruAccent', Icons.record_voice_over_rounded, '10m', () => openPage(context, PronunciationScreen(index: index))),
            _PlanStep('Vocabulary', 'المفردات • كلمات جديدة', Icons.menu_book_rounded, '5m', () => openPage(context, const VocabularyScreen())),
            _PlanStep('Grammar', 'القواعد • تركيب الجملة', Icons.rule_rounded, '10m', () => openPage(context, GrammarScreen(index: index))),
          ];
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: topBar(
              context,
              green: true,
              title: 'Lesson ${index + 1}',
              subtitle: 'Unit ${unit + 1} • Lesson $lessonInUnit of 4',
            ),
            body: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                children: [
                  CardBox(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: SizedBox(width: 104, height: 104, child: Photo(item.image)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Pill(
                                lessonDone ? 'Lesson completed' : 'Lesson in progress',
                                icon: lessonDone ? Icons.check_circle_rounded : Icons.play_circle_outline_rounded,
                              ),
                              const SizedBox(height: 7),
                              Text(item.word, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: kInk)),
                              const SizedBox(height: 2),
                              Text(item.sentence, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: kMuted, height: 1.4)),
                              const SizedBox(height: 7),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => Tts.instance.speak(item.sentence),
                                    child: const CircleIcon(Icons.volume_up_rounded, size: 32, background: kGreenSoft, foreground: kGreen),
                                  ),
                                  const SizedBox(width: 6),
                                  Text('${lessonInUnit}/4 • ${item.sentence.split(' ').length} words', style: const TextStyle(fontSize: 9.5, color: kMuted, fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  CardBox(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Text('Unit progress', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: kInk)),
                            const Spacer(),
                            Text('$doneInUnit / 4 lessons', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: kGreenDark)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ProgressBar(doneInUnit / 4, height: 7),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SectionTitle('Lesson plan', trailing: lessonDone ? 'Completed' : '55 minutes'),
                  CardBox(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    child: Column(
                      children: [
                        for (var i = 0; i < steps.length; i++) ...[
                          ListRow(
                            icon: steps[i].icon,
                            title: steps[i].title,
                            subtitle: steps[i].subtitle,
                            trailing: steps[i].duration,
                            onTap: steps[i].onTap,
                          ),
                          if (i < steps.length - 1) const Divider(height: 1, color: kLine),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  CardBox(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    child: ListRow(
                      icon: Icons.psychology_alt_rounded,
                      title: 'Review • Adaptive Recall',
                      subtitle: 'مراجعة تكيفية لما تعلمته في هذا الدرس',
                      trailing: '5m',
                      onTap: () => openPage(context, AdaptiveRecallScreen(startIndex: index)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  CardBox(
                    color: lessonInUnit == 4 ? kGreenSoft : kCard,
                    child: Row(
                      children: [
                        CircleIcon(
                          lessonInUnit == 4 ? Icons.emoji_events_rounded : Icons.lock_outline_rounded,
                          size: 42,
                          background: Colors.white,
                          foreground: lessonInUnit == 4 ? kGreen : kMuted,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Unit milestone', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: kInk)),
                              Text(
                                lessonInUnit != 4
                                    ? 'محادثة الإنجاز تفتح بعد الدرس الرابع من الوحدة'
                                    : (unitDone ? 'الوحدة مكتملة — ابدأ محادثة الإنجاز' : 'أكمل دروس الوحدة الأربعة لفتح المحادثة'),
                                style: const TextStyle(fontSize: 10, color: kMuted, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (lessonInUnit == 4)
                          FilledButton(
                            onPressed: unitDone
                                ? () => openPage(context, const MilestoneConversationScreen())
                                : null,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 38),
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            child: Text(unitDone ? 'Start' : 'Locked', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  primaryButton(
                    lessonDone ? 'Practice Again' : 'Start Core Lesson',
                    () => openPage(context, CoreLessonScreen(index: index)),
                    icon: Icons.play_arrow_rounded,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Each lesson includes Core, Pronunciation, Vocabulary, Grammar and Review. The unit ends with a Milestone Conversation.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 9.5, color: kMuted, height: 1.45),
                  ),
                ],
              ),
            ),
          );
        },
      );
}

class _PlanStep {
  final String title;
  final String subtitle;
  final IconData icon;
  final String duration;
  final VoidCallback onTap;
  const _PlanStep(this.title, this.subtitle, this.icon, this.duration, this.onTap);
}

// ============================================================
// LESSONS
// ============================================================
class LessonsScreen extends StatefulWidget {
  const LessonsScreen({super.key});
  @override
  State<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends State<LessonsScreen> {
  int _filter = 0;
  static const themes = [
    'الأساسيات', 'الأشخاص', 'الطعام', 'المنزل', 'الحيوانات', 'الطبيعة',
    'المدينة', 'الأفعال', 'الألوان', 'الأرقام', 'السفر', 'المراجعة',
  ];

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: Progress.instance,
        builder: (context, _) {
          final p = Progress.instance;
          final unitCount = (items.length / 4).ceil();
          final indexes = List<int>.generate(unitCount, (i) => i).where((u) {
            final start = u * 4;
            if (_filter == 1) return start <= p.current && p.current < start + 4;
            if (_filter == 2) return start + 4 <= p.completed;
            return true;
          }).toList();
          return SafeArea(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 108),
              itemCount: indexes.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) return _header(p);
                final unit = indexes[index - 1];
                return _unitCard(context, p, unit);
              },
            ),
          );
        },
      );

  Widget _header(Progress p) {
    final current = itemAt(p.current);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('الدروس', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: kInk)),
            const Spacer(),
            Pill('${items.length} درسًا'),
          ],
        ),
        const SizedBox(height: 3),
        const Text('منهج Dynamic Immersion — كل وحدة من 4 دروس', style: TextStyle(fontSize: 11, color: kMuted)),
        const SizedBox(height: 12),
        CardBox(
          color: kGreenSoft,
          onTap: () => openPage(context, LessonJourneyScreen(index: p.current)),
          child: Row(
            children: [
              ClipRRect(borderRadius: BorderRadius.circular(12), child: SizedBox(width: 72, height: 72, child: Photo(current.image))),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('تابع من حيث توقفت', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: kMuted)),
                    Text(current.word, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: kInk)),
                    const SizedBox(height: 4),
                    ProgressBar(p.completed / items.length, height: 6),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const CircleIcon(Icons.play_arrow_rounded, size: 37, background: kGreen, foreground: Colors.white),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _LessonFilter(label: 'الكل', selected: _filter == 0, onTap: () => setState(() => _filter = 0)),
            const SizedBox(width: 6),
            _LessonFilter(label: 'الحالية', selected: _filter == 1, onTap: () => setState(() => _filter = 1)),
            const SizedBox(width: 6),
            _LessonFilter(label: 'المكتملة', selected: _filter == 2, onTap: () => setState(() => _filter = 2)),
          ],
        ),
        const SizedBox(height: 14),
        const SectionTitle('الوحدات'),
      ],
    );
  }

  Widget _unitCard(BuildContext context, Progress p, int unit) {
    final start = unit * 4;
    final end = min(start + 4, items.length);
    final unitItems = items.sublist(start, end);
    final done = List<int>.generate(end - start, (i) => start + i).where((i) => i < p.completed).length;
    final theme = themes[unit % themes.length];
    return CardBox(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleIcon(Icons.layers_rounded, size: 34, background: kGreenSoft),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('الوحدة ${unit + 1} • $theme', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: kInk)),
                    Text('$done / ${unitItems.length} دروس مكتملة', style: const TextStyle(fontSize: 9.5, color: kMuted)),
                  ],
                ),
              ),
              Pill(done == unitItems.length ? 'مكتملة' : (start <= p.current && p.current < end ? 'الحالية' : 'قادمة')),
            ],
          ),
          const SizedBox(height: 7),
          ProgressBar(unitItems.isEmpty ? 0 : done / unitItems.length, height: 5),
          const SizedBox(height: 9),
          Row(
            children: [
              for (var i = 0; i < unitItems.length; i++) ...[
                Expanded(child: _lessonTile(context, p, start + i)),
                if (i < unitItems.length - 1) const SizedBox(width: 6),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _lessonTile(BuildContext context, Progress p, int index) {
    final it = items[index];
    final completed = index < p.completed;
    final current = index == p.current;
    return GestureDetector(
      onTap: () => openPage(context, LessonJourneyScreen(index: index)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: current ? kGreen : kLine, width: current ? 2 : 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: Column(
            children: [
              SizedBox(
                height: 68,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Photo(it.image),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        width: 19,
                        height: 19,
                        decoration: BoxDecoration(
                          color: completed ? kGreen : Colors.white.withValues(alpha: .92),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(completed ? Icons.check : Icons.lock_outline_rounded, size: 11, color: completed ? Colors.white : kMuted),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                child: Text(it.word, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: kInk)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LessonFilter extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _LessonFilter({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
          decoration: BoxDecoration(color: selected ? kGreen : kCard, borderRadius: BorderRadius.circular(16)),
          child: Text(label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: selected ? Colors.white : kMuted)),
        ),
      );
}

// ============================================================
// STORIES
// ============================================================
class StoryData {
  final String title;
  final String image;
  final String text;
  final String word;
  final String sentence;
  final String duration;
  const StoryData(this.title, this.image, this.text, this.word, this.sentence, this.duration);
}

const stories = <StoryData>[
  StoryData(
    'The Boy and the Lion',
    'boy_lion.jpg',
    'Once upon a time, a kind boy found a lion cub hurt in the forest. He helped the cub, and they became friends. Now they explore the forest together, trusting each other every day. The boy learned that kindness can turn a stranger into a friend.',
    'Lion',
    'The boy hugs the lion cub.',
    '5 min',
  ),
  StoryData(
    'The Sleeping Cat',
    'cat_sleeping_window.jpg',
    'The orange cat sleeps on the windowsill every afternoon. The sun warms her fur, and the garden is quiet. When the children come home, she opens one eye and stretches. Then she follows them into the kitchen for a small bowl of milk.',
    'Cat',
    'The cat is sleeping on the windowsill.',
    '4 min',
  ),
  StoryData(
    'The Clever Fox',
    'fox.jpg',
    'A fox lives near the edge of the forest. He is quiet and clever. One morning, he sees a basket of fruit near the market. He waits, watches, and finds a safe path home. The fox knows that patience is a kind of wisdom.',
    'Fox',
    'The fox sits in the forest.',
    '4 min',
  ),
  StoryData(
    'A Morning at the Market',
    'market_morning.jpg',
    'The market opens early in the morning. Vendors arrange apples, tomatoes, and fresh herbs in neat baskets. People walk between the stalls and greet each other with smiles. The smell of bread fills the air, and the whole street feels awake.',
    'Market',
    'The market is full of fresh vegetables.',
    '6 min',
  ),
  StoryData(
    'The Lost Puppy',
    'L153_the_dog.jpg',
    'A little dog runs away from the garden. He follows a butterfly down the street and forgets the way home. A girl finds him near the park and reads the name on his collar. She walks him home, and his family thanks her with a warm smile.',
    'Dog',
    'The dog lies down.',
    '4 min',
  ),
  StoryData(
    'A Day at the Zoo',
    'L205_zoo.jpg',
    'The children visit the zoo with their teacher. They see a big elephant, a tall giraffe, and a sleepy lion. The teacher asks them to listen to the sounds of the animals. On the bus home, they draw their favorite animal.',
    'Zoo',
    'The children visit the zoo.',
    '5 min',
  ),
];

class StoriesScreen extends StatelessWidget {
  const StoriesScreen({super.key});

  @override
  Widget build(BuildContext context) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 108),
          children: [
            Row(
              children: [
                const Text('القصص', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: kInk)),
                const Spacer(),
                Pill('${stories.length} قصص'),
              ],
            ),
            const SizedBox(height: 3),
            const Text('اقرأ، استمع، وتعلّم كلمات جديدة من صور المشروع', style: TextStyle(fontSize: 11, color: kMuted)),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => openPage(context, const StoryReaderScreen(index: 0)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  height: 220,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Photo(stories[0].image),
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.transparent, Color(0xCC000000)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                      const Positioned(
                        left: 14,
                        right: 14,
                        bottom: 14,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Pill('Interactive Story • 5 min', background: Colors.white, foreground: kGreenDark),
                            SizedBox(height: 6),
                            Text('The Boy and the Lion', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900)),
                            Text('Listen to the story and discover new words.', style: TextStyle(color: Colors.white70, fontSize: 10.5)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const SectionTitle('كل القصص', trailing: 'Read • Listen • Quiz'),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: stories.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.82,
              ),
              itemBuilder: (context, i) {
                final s = stories[i];
                return GestureDetector(
                  onTap: () => openPage(context, StoryReaderScreen(index: i)),
                  child: Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: kLine)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: Photo(s.image)),
                          Padding(
                            padding: const EdgeInsets.all(9),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: kInk)),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(Icons.schedule_rounded, size: 11, color: kMuted),
                                    const SizedBox(width: 3),
                                    Text(s.duration, style: const TextStyle(fontSize: 9, color: kMuted)),
                                    const Spacer(),
                                    const Icon(Icons.volume_up_rounded, size: 13, color: kGreen),
                                  ],
                                ),
                              ],
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
      );
}

class StoryReaderScreen extends StatefulWidget {
  final int index;
  const StoryReaderScreen({super.key, required this.index});
  @override
  State<StoryReaderScreen> createState() => _StoryReaderScreenState();
}

class _StoryReaderScreenState extends State<StoryReaderScreen> {
  late int _index;
  int _tab = 0;
  int? _quizSel;
  bool _quizChecked = false;

  @override
  void initState() {
    super.initState();
    _index = widget.index;
  }

  StoryData get story => stories[_index];

  void _next() {
    if (_index + 1 >= stories.length) {
      Progress.instance.complete(Progress.instance.current, true);
      Navigator.pop(context);
      return;
    }
    setState(() {
      _index++;
      _tab = 0;
      _quizSel = null;
      _quizChecked = false;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        appBar: topBar(
          context,
          green: true,
          title: 'Lingo Gold Stories',
          subtitle: 'Interactive Story Reading • ${_index + 1} of ${stories.length}',
          actions: [IconButton(icon: const Icon(Icons.bookmark_border_rounded), onPressed: () => showToast(context, 'Story saved'))],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Row(
                children: [
                  Text('Story ${_index + 1} of ${stories.length}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: kMuted)),
                  const Spacer(),
                  Text('${story.duration} • English', style: const TextStyle(fontSize: 10, color: kMuted)),
                ],
              ),
              const SizedBox(height: 5),
              ProgressBar((_index + 1) / stories.length, height: 6),
              const SizedBox(height: 12),
              ClipRRect(borderRadius: BorderRadius.circular(20), child: SizedBox(height: 230, width: double.infinity, child: Photo(story.image))),
              const SizedBox(height: 12),
              Text(story.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: kInk)),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => Tts.instance.speak(story.text),
                borderRadius: BorderRadius.circular(13),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: kGreenSoft, borderRadius: BorderRadius.circular(13)),
                  child: Row(
                    children: [
                      const CircleIcon(Icons.volume_up_rounded, size: 38, background: Colors.white, foreground: kGreen),
                      const SizedBox(width: 9),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Listen to story', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: kInk)),
                            Text('Tap to hear narration • English', style: TextStyle(fontSize: 9.5, color: kMuted)),
                          ],
                        ),
                      ),
                      const Icon(Icons.graphic_eq_rounded, color: kGreen, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (_tab == 0) ...[
                Text(story.text, style: const TextStyle(fontSize: 13, color: kInk, height: 1.7)),
                const SizedBox(height: 14),
                outlineButton('Continue Reading', _next, icon: Icons.arrow_forward_rounded),
              ] else if (_tab == 1) ...[
                CardBox(
                  color: kGreenSoft,
                  child: Column(
                    children: [
                      const CircleIcon(Icons.headphones_rounded, size: 58, background: Colors.white, foreground: kGreen),
                      const SizedBox(height: 8),
                      Text(story.title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: kInk)),
                      const SizedBox(height: 10),
                      const Waveform(height: 54, progress: 0.7),
                      const SizedBox(height: 8),
                      primaryButton('Play Narration', () => Tts.instance.speak(story.text), icon: Icons.play_arrow_rounded),
                    ],
                  ),
                ),
              ] else if (_tab == 2) ...[
                CardBox(
                  child: Row(
                    children: [
                      ClipRRect(borderRadius: BorderRadius.circular(12), child: SizedBox(width: 100, height: 100, child: Photo(story.image))),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(story.word, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: kInk)),
                            Text(story.sentence, style: const TextStyle(fontSize: 11, color: kMuted, height: 1.4)),
                            const SizedBox(height: 8),
                            Pill('Tap to listen', icon: Icons.volume_up_rounded),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                primaryButton('Hear the Word', () => Tts.instance.speak(story.word), icon: Icons.volume_up_rounded),
              ] else ...[
                const Text('What is the story about?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: kInk)),
                const SizedBox(height: 8),
                for (var i = 0; i < 3; i++)
                  GestureDetector(
                    onTap: () => setState(() => _quizSel = i),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: _quizSel == i ? kGreenSoft : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _quizSel == i ? kGreen : kLine),
                      ),
                      child: Text(
                        ['Kindness and friendship', 'A day at school', 'Cooking dinner'][i],
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kInk),
                      ),
                    ),
                  ),
                primaryButton('Check Answer', _quizSel == null ? null : () {
                  setState(() => _quizChecked = true);
                  showToast(context, _quizSel == 0 ? 'Correct! Kindness and friendship.' : 'The story is about kindness and friendship.');
                }),
                if (_quizChecked) ...[
                  const SizedBox(height: 8),
                  Text(_quizSel == 0 ? 'Correct!' : 'The correct answer is kindness and friendship.', textAlign: TextAlign.center, style: const TextStyle(fontSize: 10.5, color: kGreenDark, fontWeight: FontWeight.w800)),
                ],
              ],
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(14)),
                child: Row(
                  children: [
                    _StoryTab(label: 'Read', icon: Icons.menu_book_rounded, selected: _tab == 0, onTap: () => setState(() => _tab = 0)),
                    _StoryTab(label: 'Listen', icon: Icons.headphones_rounded, selected: _tab == 1, onTap: () => setState(() => _tab = 1)),
                    _StoryTab(label: 'Words', icon: Icons.lightbulb_outline_rounded, selected: _tab == 2, onTap: () => setState(() => _tab = 2)),
                    _StoryTab(label: 'Quiz', icon: Icons.check_box_rounded, selected: _tab == 3, onTap: () => setState(() => _tab = 3)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _StoryTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _StoryTab({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(color: selected ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(11)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: selected ? kGreen : kMuted),
                const SizedBox(width: 4),
                Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: selected ? kGreenDark : kMuted)),
              ],
            ),
          ),
        ),
      );
}

// ============================================================
// TRAINING HUB
// ============================================================
class TrainingScreen extends StatelessWidget {
  const TrainingScreen({super.key});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: Progress.instance,
        builder: (context, _) {
          final p = Progress.instance;
          final current = itemAt(p.current);
          final learning = <_Skill>[
            _Skill('Core Lesson', 'الدرس الأساسي', Icons.school_rounded, () => openPage(context, LessonJourneyScreen(index: p.current))),
            _Skill('Pronunciation', 'النطق • TruAccent', Icons.record_voice_over_rounded, () => openPage(context, PronunciationScreen(index: p.current))),
            _Skill('Vocabulary', 'المفردات', Icons.menu_book_rounded, () => openPage(context, const VocabularyScreen())),
            _Skill('Grammar', 'القواعد', Icons.rule_rounded, () => openPage(context, GrammarScreen(index: p.current))),
            _Skill('Reading', 'القراءة', Icons.auto_stories_rounded, () => openPage(context, ReadingScreen(index: p.current))),
            _Skill('Writing', 'الكتابة', Icons.edit_note_rounded, () => openPage(context, WritingScreen(index: p.current))),
            _Skill('Listening', 'الاستماع', Icons.hearing_rounded, () => openPage(context, ListeningScreen(index: p.current))),
            _Skill('Speaking', 'المحادثة', Icons.mic_rounded, () => openPage(context, SpeakingScreen(index: p.current))),
            _Skill('Choose an Image', 'اختر الصورة', Icons.image_rounded, () => openPage(context, ChooseImageScreen(index: p.current))),
            _Skill('Choose a Prompt', 'اختر الوصف', Icons.notes_rounded, () => openPage(context, ChoosePromptScreen(index: p.current))),
            _Skill('Adaptive Recall', 'المراجعة التكيفية', Icons.psychology_alt_rounded, () => openPage(context, const AdaptiveRecallScreen())),
            _Skill('Milestone', 'محادثة الإنجاز', Icons.chat_bubble_rounded, () => openPage(context, const MilestoneConversationScreen())),
            _Skill('Stories', 'القصص', Icons.book_rounded, () => openPage(context, const StoryReaderScreen(index: 0))),
            _Skill('Phrasebook', 'كتاب العبارات', Icons.translate_rounded, () => openPage(context, const PhrasebookScreen())),
            _Skill('Flashcards', 'البطاقات', Icons.style_rounded, () => openPage(context, const FlashcardsScreen())),
            _Skill('Chat Missions', 'مهام المحادثة', Icons.forum_rounded, () => openPage(context, const ChatMissionsScreen())),
          ];
          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 108),
              children: [
                Row(
                  children: [
                    const Text('تدريب', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: kInk)),
                    const Spacer(),
                    Pill('${learning.length} مهارة'),
                  ],
                ),
                const SizedBox(height: 3),
                const Text('كل واجهات Rosetta Stone في مكان واحد', style: TextStyle(fontSize: 11, color: kMuted)),
                const SizedBox(height: 12),
                CardBox(
                  color: kGreenSoft,
                  child: Row(
                    children: [
                      ClipRRect(borderRadius: BorderRadius.circular(12), child: SizedBox(width: 76, height: 76, child: Photo(current.image))),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('جلسة تدريب سريعة', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: kMuted)),
                            Text(current.word, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: kInk)),
                            const SizedBox(height: 3),
                            const Text('Core + Pronunciation + Vocabulary + Grammar', style: TextStyle(fontSize: 9, color: kMuted)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 42,
                        height: 42,
                        child: FilledButton(
                          onPressed: () => openPage(context, LessonJourneyScreen(index: p.current)),
                          style: FilledButton.styleFrom(shape: const CircleBorder(), padding: EdgeInsets.zero),
                          child: const Icon(Icons.play_arrow_rounded),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const SectionTitle('واجهات التعلم'),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: learning.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.55,
                  ),
                  itemBuilder: (context, i) => _SkillCard(skill: learning[i]),
                ),
                const SizedBox(height: 16),
                const SectionTitle('واجهات المتابعة'),
                CardBox(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                  child: Column(
                    children: [
                      ListRow(icon: Icons.dashboard_rounded, title: 'Dashboard / Progress', subtitle: 'لوحة التقدم', onTap: () => openPage(context, const DashboardScreen(pushed: true))),
                      const Divider(height: 1, color: kLine),
                      ListRow(icon: Icons.emoji_events_rounded, title: 'Achievements', subtitle: 'الإنجازات والأوسمة', onTap: () => openPage(context, const AchievementsScreen())),
                      const Divider(height: 1, color: kLine),
                      ListRow(icon: Icons.bar_chart_rounded, title: 'Weekly Report', subtitle: 'التقرير الأسبوعي', onTap: () => openPage(context, const WeeklyReportScreen())),
                      const Divider(height: 1, color: kLine),
                      ListRow(icon: Icons.leaderboard_rounded, title: 'Leaderboard', subtitle: 'المتصدرون', onTap: () => openPage(context, const LeaderboardScreen())),
                      const Divider(height: 1, color: kLine),
                      ListRow(icon: Icons.family_restroom_rounded, title: 'Parent Dashboard', subtitle: 'لوحة ولي الأمر', onTap: () => openPage(context, const ParentDashboardScreen())),
                      const Divider(height: 1, color: kLine),
                      ListRow(icon: Icons.track_changes_rounded, title: 'Goals', subtitle: 'الأهداف والتذكير', onTap: () => openPage(context, const GoalsScreen())),
                      const Divider(height: 1, color: kLine),
                      ListRow(icon: Icons.person_rounded, title: 'Profile', subtitle: 'الملف الشخصي', onTap: () => openPage(context, const ProfileScreen(pushed: true))),
                      const Divider(height: 1, color: kLine),
                      ListRow(icon: Icons.quiz_rounded, title: 'Quiz Result', subtitle: 'نتيجة الاختبار', onTap: () => openPage(context, const QuizResultScreen())),
                      const Divider(height: 1, color: kLine),
                      ListRow(icon: Icons.style_rounded, title: 'Vocabulary Review', subtitle: 'مراجعة المفردات', onTap: () => openPage(context, const VocabularyReviewScreen())),
                      const Divider(height: 1, color: kLine),
                      ListRow(icon: Icons.settings_rounded, title: 'Settings', subtitle: 'الإعدادات', onTap: () => openPage(context, const SettingsScreen())),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
}

class _Skill {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  const _Skill(this.title, this.subtitle, this.icon, this.onTap);
}

class _SkillCard extends StatelessWidget {
  final _Skill skill;
  const _SkillCard({required this.skill});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: skill.onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: kLine)),
          child: Row(
            children: [
              CircleIcon(skill.icon, size: 37, background: kGreenSoft),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(skill.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: kInk)),
                    Text(skill.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 8.5, color: kMuted)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 9, color: kMuted),
            ],
          ),
        ),
      );
}

// ============================================================
// PROFILE
// ============================================================
class ProfileScreen extends StatelessWidget {
  final bool pushed;
  const ProfileScreen({super.key, this.pushed = false});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: Progress.instance,
        builder: (context, _) {
          final p = Progress.instance;
          final body = ListView(
            padding: EdgeInsets.fromLTRB(16, pushed ? 12 : 16, 16, pushed ? 24 : 108),
            children: [
              if (!pushed)
                Row(
                  children: [
                    const Text('Profile', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: kInk)),
                    const Spacer(),
                    IconButton(icon: const Icon(Icons.settings_outlined, color: kInk), onPressed: () => openPage(context, const SettingsScreen())),
                  ],
                ),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: kGreen,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Avatar('img_girl_child.jpg', size: 76, ring: true),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Emma', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                              const Text('@emma_learns', style: TextStyle(color: Colors.white70, fontSize: 11)),
                              const SizedBox(height: 5),
                              Pill('Level ${p.level} • Explorer', background: Colors.white, foreground: kGreenDark),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Level Progress — ${p.levelXp} / 200 XP to Level ${p.level + 1}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text('${(p.levelXp / 200 * 100).round()}%', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: LinearProgressIndicator(value: p.levelXp / 200, minHeight: 7, color: Colors.white, backgroundColor: Colors.white24),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              CardBox(
                color: kGreenSoft,
                child: Row(
                  children: [
                    const Icon(Icons.local_fire_department_rounded, color: kGreen, size: 30),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Streak', style: TextStyle(fontSize: 10, color: kMuted)),
                          Text('${p.streak} Day Streak!', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kInk)),
                          const Text('Keep learning daily to keep your streak alive.', style: TextStyle(fontSize: 9.5, color: kMuted)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: StatBox(value: '${p.words}', label: 'Words Learned', icon: Icons.menu_book_rounded)),
                  const SizedBox(width: 8),
                  Expanded(child: StatBox(value: '${p.completed}', label: 'Lessons Completed', icon: Icons.check_circle_rounded)),
                  const SizedBox(width: 8),
                  Expanded(child: StatBox(value: '${p.accuracy}%', label: 'Accuracy', icon: Icons.gps_fixed_rounded)),
                ],
              ),
              const SizedBox(height: 16),
              const SectionTitle('Your Languages'),
              CardBox(
                child: Column(
                  children: [
                    _LanguageRow(flag: 'EN', name: 'English', value: (p.completed / items.length).clamp(0.05, 1.0), label: 'Intermediate'),
                    const SizedBox(height: 10),
                    _LanguageRow(flag: 'AR', name: 'Arabic', value: 1, label: 'Native'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const SectionTitle('Recent Activity'),
              CardBox(
                child: Column(
                  children: [
                    ListRow(icon: Icons.check_circle_rounded, title: "Completed lesson: ${itemAt(max(0, p.current - 1)).word}", subtitle: 'Today • +20 XP', trailing: ''),
                    const Divider(height: 1, color: kLine),
                    ListRow(icon: Icons.emoji_events_rounded, title: 'Achievement unlocked', subtitle: 'Yesterday • First Conversation', trailing: ''),
                    const Divider(height: 1, color: kLine),
                    ListRow(icon: Icons.trending_up_rounded, title: 'Weekly progress updated', subtitle: '${p.weekTotal} lessons this week', trailing: ''),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const SectionTitle('More'),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 2.1,
                children: [
                  _QuickCard(icon: Icons.emoji_events_rounded, label: 'Achievements', onTap: () => openPage(context, const AchievementsScreen())),
                  _QuickCard(icon: Icons.bar_chart_rounded, label: 'Weekly Report', onTap: () => openPage(context, const WeeklyReportScreen())),
                  _QuickCard(icon: Icons.leaderboard_rounded, label: 'Leaderboard', onTap: () => openPage(context, const LeaderboardScreen())),
                  _QuickCard(icon: Icons.family_restroom_rounded, label: 'Parent Dashboard', onTap: () => openPage(context, const ParentDashboardScreen())),
                  _QuickCard(icon: Icons.track_changes_rounded, label: 'Goals', onTap: () => openPage(context, const GoalsScreen())),
                  _QuickCard(icon: Icons.quiz_rounded, label: 'Quiz Result', onTap: () => openPage(context, const QuizResultScreen())),
                  _QuickCard(icon: Icons.style_rounded, label: 'Vocabulary Review', onTap: () => openPage(context, const VocabularyReviewScreen())),
                  _QuickCard(icon: Icons.settings_outlined, label: 'Settings', onTap: () => openPage(context, const SettingsScreen())),
                ],
              ),
            ],
          );
          if (!pushed) return SafeArea(child: body);
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: topBar(context, title: 'Profile'),
            body: SafeArea(child: body),
          );
        },
      );
}

class _LanguageRow extends StatelessWidget {
  final String flag;
  final String name;
  final double value;
  final String label;
  const _LanguageRow({required this.flag, required this.name, required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: kGreenSoft, borderRadius: BorderRadius.circular(8)),
            child: Text(flag, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: kGreenDark)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: kInk)),
                    const Spacer(),
                    Text('${(value * 100).round()}% • $label', style: const TextStyle(fontSize: 9, color: kMuted)),
                  ],
                ),
                const SizedBox(height: 4),
                ProgressBar(value, height: 6),
              ],
            ),
          ),
        ],
      );
}
