import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core.dart';
import 'learning_screens.dart';
import 'lessons_data.dart';

// ============================================================
// 1. ACHIEVEMENTS & BADGES
// ============================================================
class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: Progress.instance,
        builder: (context, _) {
          final p = Progress.instance;
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: topBar(
              context,
              title: 'Achievements & Badges',
              actions: [IconButton(icon: const Icon(Icons.ios_share_rounded), onPressed: () => showToast(context, 'Share your achievements'))],
            ),
            body: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  CardBox(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Avatar('img_girl_child.jpg', size: 60, ring: true),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Emma • Level ${p.level}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: kInk)),
                                  Text('Language Learner • ${p.xp} XP', style: const TextStyle(fontSize: 10.5, color: kMuted)),
                                ],
                              ),
                            ),
                            Pill('${p.streak} Day Streak', icon: Icons.local_fire_department_rounded),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text('${p.xpToNext} XP until Level ${p.level + 1}', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: kInk)),
                            const Spacer(),
                            Text('${(p.levelXp / 200 * 100).round()}%', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: kGreenDark)),
                          ],
                        ),
                        const SizedBox(height: 5),
                        ProgressBar(p.levelXp / 200, height: 8),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const SectionTitle('Your Badges'),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.93,
                    children: [
                      _Badge(
                        icon: Icons.chat_bubble_outline_rounded,
                        title: 'First Conversation',
                        description: 'Complete your first chat',
                        status: p.completed > 0 ? 'Earned today' : 'Locked',
                        earned: p.completed > 0,
                      ),
                      _Badge(
                        icon: Icons.local_fire_department_rounded,
                        title: '7 Day Streak',
                        description: 'Keep the streak going!',
                        status: p.streak >= 7 ? 'Earned' : '${p.streak}/7 days',
                        earned: p.streak >= 7,
                      ),
                      _Badge(
                        icon: Icons.menu_book_rounded,
                        title: 'Vocabulary Master',
                        description: 'Learn 50 new words',
                        status: p.words >= 50 ? 'Earned' : '${p.words}/50 words',
                        earned: p.words >= 50,
                      ),
                      _Badge(
                        icon: Icons.rule_rounded,
                        title: 'Grammar Guru',
                        description: 'Perfect quiz 10/10',
                        status: p.accuracy >= 90 ? 'Earned' : '${p.accuracy}% accuracy',
                        earned: p.accuracy >= 90,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const SectionTitle('Trophies & Medals'),
                  Row(
                    children: [
                      Expanded(child: _Trophy(icon: Icons.mic_rounded, title: 'Speaking Star', subtitle: '${p.pronunciation}% score', unlocked: p.pronunciation >= 85)),
                      const SizedBox(width: 8),
                      Expanded(child: _Trophy(icon: Icons.hearing_rounded, title: 'Listening Pro', subtitle: '${p.completed} lessons', unlocked: p.completed >= 5)),
                      const SizedBox(width: 8),
                      Expanded(child: _Trophy(icon: Icons.edit_rounded, title: 'Writing Champ', subtitle: '${p.completed} lessons', unlocked: p.completed >= 15)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  CardBox(
                    color: kGreenSoft,
                    child: Row(
                      children: [
                        const CircleIcon(Icons.workspace_premium_rounded, size: 42, background: Colors.white, foreground: kGreen),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'You have earned ${[p.completed > 0, p.streak >= 7, p.words >= 50, p.accuracy >= 90].where((e) => e).length} of 4 badges. Keep learning to unlock them all.',
                            style: const TextStyle(fontSize: 11, color: kInk, height: 1.45),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String status;
  final bool earned;
  const _Badge({required this.icon, required this.title, required this.description, required this.status, required this.earned});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: earned ? kGreenSoft : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: earned ? kGreen.withValues(alpha: .35) : kLine),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(color: earned ? kGreen : kCard, shape: BoxShape.circle, border: Border.all(color: earned ? kGreenDark : kLine, width: 2)),
              child: Icon(icon, size: 32, color: earned ? Colors.white : kMuted),
            ),
            const SizedBox(height: 8),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: kInk)),
            const SizedBox(height: 2),
            Text(description, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9.5, color: kMuted, height: 1.3)),
            const SizedBox(height: 4),
            Text(status, textAlign: TextAlign.center, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: earned ? kGreenDark : kMuted)),
          ],
        ),
      );
}

class _Trophy extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool unlocked;
  const _Trophy({required this.icon, required this.title, required this.subtitle, required this.unlocked});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: unlocked ? kGreenSoft : kCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kLine),
        ),
        child: Column(
          children: [
            Icon(icon, color: unlocked ? kGreen : kMuted, size: 26),
            const SizedBox(height: 5),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: kInk)),
            const SizedBox(height: 2),
            Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 8.5, color: kMuted)),
            const SizedBox(height: 5),
            Icon(unlocked ? Icons.lock_open_rounded : Icons.lock_outline_rounded, size: 13, color: unlocked ? kGreen : kMuted),
          ],
        ),
      );
}

// ============================================================
// 2. WEEKLY PROGRESS REPORT
// ============================================================
class WeeklyReportScreen extends StatelessWidget {
  const WeeklyReportScreen({super.key});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: Progress.instance,
        builder: (context, _) {
          final p = Progress.instance;
          final now = DateTime.now();
          final monday = now.subtract(Duration(days: now.weekday - 1));
          final sunday = monday.add(const Duration(days: 6));
          final timeMinutes = p.weekTotal * 15;
          final timeLabel = timeMinutes >= 60 ? '${timeMinutes ~/ 60}h ${timeMinutes % 60}m' : '${timeMinutes}m';
          final maxDay = p.week.fold<int>(0, (a, b) => max(a, b));
          final bestIndex = p.week.indexOf(maxDay);
          const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: topBar(
              context,
              title: 'Weekly Progress',
              subtitle: 'Report',
              actions: [IconButton(icon: const Icon(Icons.calendar_month_rounded), onPressed: () => showToast(context, 'Week of ${_month(monday)} ${monday.day} – ${_month(sunday)} ${sunday.day}'))],
            ),
            body: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  Text(
                    'Week of ${_month(monday)} ${monday.day} – ${_month(sunday)} ${sunday.day}, ${sunday.year} • English • Beginner',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 10, color: kMuted, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(color: kGreenSoft, borderRadius: BorderRadius.circular(13)),
                    child: Row(
                      children: [
                        const Icon(Icons.local_fire_department_rounded, color: kGreen, size: 20),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text('${p.streak}-Day Streak! Keep going — you’re on fire!', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: kInk)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _ReportStat(icon: Icons.menu_book_rounded, title: 'Words Learned', value: '${p.words}', delta: '+18% from last week')),
                      const SizedBox(width: 10),
                      Expanded(child: _ReportStat(icon: Icons.schedule_rounded, title: 'Time Spent', value: timeLabel, delta: '+12% from last week')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  CardBox(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text("This Week's Activity", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5, color: kInk)),
                            const Spacer(),
                            Icon(Icons.info_outline_rounded, size: 17, color: kMuted),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 160,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              for (var i = 0; i < 7; i++)
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          _Bar(value: p.week[i], maxValue: maxDay, color: kGreen, height: 100),
                                          const SizedBox(width: 2),
                                          _Bar(value: p.week[i], maxValue: maxDay, color: kGreen.withValues(alpha: .45), height: 100),
                                        ],
                                      ),
                                      const SizedBox(height: 5),
                                      Text(dayNames[i], style: const TextStyle(fontSize: 9, color: kMuted)),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _LegendDot(color: kGreen, label: 'Words Learned'),
                            const SizedBox(width: 14),
                            _LegendDot(color: kGreen.withValues(alpha: .45), label: 'Time Spent'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  CardBox(
                    color: kGreenSoft,
                    child: Text(
                      'Insight: You learned the most on ${dayNames[bestIndex]} (${maxDay * 6} words) and practiced consistently this week. Great job!',
                      style: const TextStyle(fontSize: 11, color: kInk, height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 12),
                  primaryButton('View Full Report', () => _showFullReport(context), icon: Icons.arrow_forward_rounded),
                ],
              ),
            ),
          );
        },
      );

  static String _month(DateTime d) => const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][d.month - 1];

  void _showFullReport(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Full Report'),
        content: Text(
          'Lessons this week: ${Progress.instance.weekTotal}\nWords learned: ${Progress.instance.words}\nCurrent streak: ${Progress.instance.streak} days\nAccuracy: ${Progress.instance.accuracy}%',
          style: const TextStyle(height: 1.6),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }
}

class _ReportStat extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String delta;
  const _ReportStat({required this.icon, required this.title, required this.value, required this.delta});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: kLine)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleIcon(icon, size: 38, background: kGreenSoft, foreground: kGreen),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: kInk)),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: kInk)),
            Text(delta, style: const TextStyle(fontSize: 9, color: kGreenDark, fontWeight: FontWeight.w700)),
          ],
        ),
      );
}

class _Bar extends StatelessWidget {
  final int value;
  final int maxValue;
  final Color color;
  final double height;
  const _Bar({required this.value, required this.maxValue, required this.color, required this.height});

  @override
  Widget build(BuildContext context) {
    final ratio = maxValue == 0 ? 0.0 : value / maxValue;
    return Container(
      width: 8,
      height: max(6.0, height * ratio),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 9, color: kMuted)),
        ],
      );
}

// ============================================================
// 3. LEADERBOARD
// ============================================================
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});
  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  bool _weekly = true;

  static const peers = [
    {'name': 'Sofia Chen', 'xp': 2480, 'img': 'native_speaker_woman.jpg', 'streak': 14},
    {'name': 'Marcus Lee', 'xp': 2210, 'img': 'L148_schoolboy.jpg', 'streak': 9},
    {'name': 'Aisha Patel', 'xp': 1980, 'img': 'img_girl_child.jpg', 'streak': 7},
    {'name': 'Leo Kim', 'xp': 1745, 'img': 'L150_the_man.jpg', 'streak': 5},
    {'name': 'Emma Davis', 'xp': 1620, 'img': 'L244_the_woman.jpg', 'streak': 4},
    {'name': 'Diego Martínez', 'xp': 1450, 'img': 'job_doctor.jpg', 'streak': 3},
    {'name': 'Nora Ahmed', 'xp': 1310, 'img': 'job_teacher.jpg', 'streak': 6},
    {'name': 'Omar Hassan', 'xp': 1180, 'img': 'job_farmer.jpg', 'streak': 2},
    {'name': 'Lina Park', 'xp': 1100, 'img': 'job_nurse.jpg', 'streak': 4},
    {'name': 'Mateo Ruiz', 'xp': 1020, 'img': 'job_pilot.jpg', 'streak': 3},
    {'name': 'Sara Ali', 'xp': 950, 'img': 'job_police.jpg', 'streak': 1},
  ];

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: Progress.instance,
        builder: (context, _) {
          final p = Progress.instance;
          final userXp = _weekly ? p.xp : p.xp * 4;
          final rows = [
            ...peers.map((e) => {...e, 'me': false}),
            {'name': 'You', 'xp': userXp, 'img': 'img_girl_child.jpg', 'streak': p.streak, 'me': true},
          ]..sort((a, b) => (b['xp'] as int).compareTo(a['xp'] as int));
          final rank = rows.indexWhere((e) => e['me'] == true) + 1;
          final top = rows.take(3).toList();
          final rest = rows.skip(3).toList();
          final nextXp = rank > 1 ? (rows[rank - 2]['xp'] as int) : userXp;
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: topBar(context, title: 'Leaderboard', actions: [IconButton(icon: const Icon(Icons.info_outline_rounded), onPressed: () => showToast(context, 'Ranking is based on your real XP'))]),
            body: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(13)),
                    child: Row(
                      children: [
                        _Segment(label: 'Weekly', selected: _weekly, onTap: () => setState(() => _weekly = true)),
                        _Segment(label: 'All Time', selected: !_weekly, onTap: () => setState(() => _weekly = false)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(color: kGreenSoft, borderRadius: BorderRadius.circular(13)),
                    child: const Column(
                      children: [
                        Text('Top Learners This Week', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: kInk)),
                        Text('Keep learning to climb the ranks!', style: TextStyle(fontSize: 10, color: kMuted)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final i in [1, 0, 2])
                        Expanded(
                          child: _Podium(
                            name: top[i]['name'] as String,
                            xp: top[i]['xp'] as int,
                            image: top[i]['img'] as String,
                            streak: top[i]['streak'] as int,
                            place: i + 1,
                            me: top[i]['me'] == true,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  CardBox(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Column(
                      children: [
                        for (var i = 0; i < rest.length; i++) ...[
                          _LeaderRow(
                            place: i + 4,
                            name: rest[i]['name'] as String,
                            xp: rest[i]['xp'] as int,
                            image: rest[i]['img'] as String,
                            streak: rest[i]['streak'] as int,
                            me: rest[i]['me'] == true,
                          ),
                          if (i < rest.length - 1) const Divider(height: 1, color: kLine),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: kGreenDark, borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      children: [
                        const Avatar('img_girl_child.jpg', size: 44),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('You — #$rank', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                              Text(
                                rank == 1 ? 'You are at the top!' : 'Just ${max(0, nextXp - userXp + 1)} XP to reach #${rank - 1}!',
                                style: const TextStyle(color: Colors.white70, fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                        Text('$userXp XP', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Local leaderboard — your real XP is used.', textAlign: TextAlign.center, style: TextStyle(fontSize: 9, color: kMuted)),
                ],
              ),
            ),
          );
        },
      );
}

class _Segment extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Segment({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(color: selected ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(10)),
            child: Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: selected ? kInk : kMuted)),
          ),
        ),
      );
}

class _Podium extends StatelessWidget {
  final String name;
  final int xp;
  final String image;
  final int streak;
  final int place;
  final bool me;
  const _Podium({required this.name, required this.xp, required this.image, required this.streak, required this.place, required this.me});

  @override
  Widget build(BuildContext context) {
    final first = place == 1;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 3),
      padding: EdgeInsets.fromLTRB(6, first ? 16 : 22, 6, 10),
      decoration: BoxDecoration(
        color: first ? kGreenSoft : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border.all(color: first ? kGreen.withValues(alpha: .45) : kLine),
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Avatar(image, size: first ? 66 : 54),
              Positioned(
                top: -10,
                left: -4,
                right: -4,
                child: Center(
                  child: Container(
                    width: 25,
                    height: 25,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: first ? kGreenDark : kMuted, shape: BoxShape.circle),
                    child: Text('$place', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(name, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: me ? kGreenDark : kInk)),
          Text('$xp XP', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: kGreenDark)),
          Text('${streak} day streak', style: const TextStyle(fontSize: 8.5, color: kMuted)),
        ],
      ),
    );
  }
}

class _LeaderRow extends StatelessWidget {
  final int place;
  final String name;
  final int xp;
  final String image;
  final int streak;
  final bool me;
  const _LeaderRow({required this.place, required this.name, required this.xp, required this.image, required this.streak, required this.me});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Text('$place', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: me ? kGreen : kMuted)),
            ),
            Avatar(image, size: 36),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: me ? kGreenDark : kInk)),
                  Text('English • $streak day streak', style: const TextStyle(fontSize: 9, color: kMuted)),
                ],
              ),
            ),
            Text('$xp XP', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: kGreenDark)),
          ],
        ),
      );
}

// ============================================================
// 4. PARENT DASHBOARD
// ============================================================
class ParentDashboardScreen extends StatelessWidget {
  const ParentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: Progress.instance,
        builder: (context, _) {
          final p = Progress.instance;
          final percent = (p.completed / items.length * 100).round();
          final remaining = max(0, items.length - p.completed);
          final recent = [
            {'title': 'Reading: Animals & Habitats', 'sub': 'Completed • Today, 10:32 AM • 100% accuracy', 'badge': 'Perfect Score', 'icon': Icons.menu_book_rounded, 'img': findItem('lion').image},
            {'title': 'Speaking: Animal Sounds', 'sub': 'Completed • Today, 10:20 AM • Pronunciation', 'badge': 'Improved +5%', 'icon': Icons.mic_rounded, 'img': findItem('bird').image},
            {'title': 'Vocabulary: Forest Words', 'sub': 'Completed • Yesterday • 9/10 words', 'badge': 'Good', 'icon': Icons.abc_rounded, 'img': findItem('fox').image},
          ];
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: topBar(
              context,
              title: 'Parent Dashboard',
              actions: [IconButton(icon: const Icon(Icons.notifications_none_rounded), onPressed: () => showToast(context, 'No new parent notifications'))],
            ),
            body: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  Row(
                    children: [
                      const Avatar('img_girl_child.jpg', size: 78, ring: true),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Emma • Age 6', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: kInk)),
                            const Text('Grade 1 • St. Mary’s Elementary', style: TextStyle(fontSize: 10.5, color: kMuted)),
                            const SizedBox(height: 6),
                            const Pill('Active Learner', icon: Icons.star_rounded),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: kGreenSoft, borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      children: [
                        Expanded(child: _ParentStat(icon: Icons.emoji_events_rounded, label: 'Lessons Completed', value: '${p.completed}/${items.length}')),
                        Container(width: 1, height: 58, color: kGreen.withValues(alpha: .2)),
                        Expanded(child: _ParentStat(icon: Icons.bar_chart_rounded, label: 'This Week', value: '+${p.weekTotal}')),
                        Container(width: 1, height: 58, color: kGreen.withValues(alpha: .2)),
                        Expanded(child: _ParentStat(icon: Icons.mic_rounded, label: 'Pronunciation', value: '${p.pronunciation}%')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const SectionTitle('Progress Overview'),
                  Row(
                    children: [
                      Text('$percent% complete', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: kInk)),
                      const Spacer(),
                      Text('$remaining lessons remaining', style: const TextStyle(fontSize: 10, color: kMuted)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ProgressBar(p.completed / items.length, height: 10),
                  const SizedBox(height: 16),
                  const SectionTitle('Recent Lessons'),
                  for (final r in recent)
                    CardBox(
                      padding: const EdgeInsets.all(9),
                      child: Row(
                        children: [
                          ClipRRect(borderRadius: BorderRadius.circular(10), child: SizedBox(width: 50, height: 50, child: Photo(r['img'] as String))),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r['title'] as String, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: kInk)),
                                Text(r['sub'] as String, style: const TextStyle(fontSize: 9, color: kMuted, height: 1.4)),
                              ],
                            ),
                          ),
                          Pill(r['badge'] as String, background: kGreenSoft),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  primaryButton('View Full Report', () => openPage(context, const WeeklyReportScreen())),
                  const SizedBox(height: 8),
                  outlineButton('Message Tutor', () => openPage(context, const MilestoneConversationScreen())),
                ],
              ),
            ),
          );
        },
      );
}

class _ParentStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _ParentStat({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Icon(icon, size: 22, color: kGreenDark),
          const SizedBox(height: 5),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 8.5, color: kMuted)),
          Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: kInk)),
        ],
      );
}

// ============================================================
// 5. GOALS & DAILY REMINDER
// ============================================================
class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});
  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  bool _reminder = true;
  bool _practice = true;
  bool _streakReminder = true;
  bool _weeklySummary = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _reminder = p.getBool('goal_reminder') ?? true;
      _practice = p.getBool('goal_practice') ?? true;
      _streakReminder = p.getBool('goal_streak') ?? true;
      _weeklySummary = p.getBool('goal_weekly') ?? false;
    });
  }

  Future<void> _save(String key, bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(key, value);
  }

  Future<void> _editGoal() async {
    var value = Progress.instance.dailyGoalMinutes.toDouble();
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModal) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Daily Goal', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: kInk)),
              Text('${value.round()} minutes a day', style: const TextStyle(color: kMuted)),
              Slider(
                value: value,
                min: 5,
                max: 60,
                divisions: 11,
                activeColor: kGreen,
                label: '${value.round()} min',
                onChanged: (v) => setModal(() => value = v),
              ),
              primaryButton('Save Goal', () async {
                await Progress.instance.setDailyGoal(value.round());
                if (context.mounted) Navigator.pop(context);
              }),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: Progress.instance,
        builder: (context, _) {
          final p = Progress.instance;
          final goal = p.dailyGoalMinutes;
          final ratio = (p.todayLessons / max(1, goal ~/ 5)).clamp(0.0, 1.0);
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: topBar(
              context,
              title: 'Goals & Daily Reminder',
              actions: [IconButton(icon: const Icon(Icons.notifications_none_rounded), onPressed: () => showToast(context, 'Reminder set for 6:30 PM'))],
            ),
            body: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  CardBox(
                    color: kGreenSoft,
                    child: Column(
                      children: [
                        SizedBox(
                          width: 112,
                          height: 112,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CircularProgressIndicator(value: ratio, strokeWidth: 9, color: kGreen, backgroundColor: Colors.white),
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('$goal', style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w900, color: kInk)),
                                    const Text('min', style: TextStyle(fontSize: 10, color: kMuted, fontWeight: FontWeight.w800)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text('Daily Goal • Completed today', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: kInk)),
                        const SizedBox(height: 5),
                        const Pill('Goal met! Great work', icon: Icons.check_circle_rounded, background: Colors.white),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  CardBox(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Daily Goal', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: kInk)),
                              Text('Set goal: $goal minutes a day', style: const TextStyle(fontSize: 11, color: kMuted)),
                            ],
                          ),
                        ),
                        const Pill('On track', icon: Icons.auto_awesome_rounded),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  CardBox(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Daily Reminder', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: kInk)),
                                  Text('Reminder set for 6:30 PM daily', style: TextStyle(fontSize: 11, color: kMuted)),
                                  Text('We’ll notify you to practice your lesson.', style: TextStyle(fontSize: 9.5, color: kMuted)),
                                ],
                              ),
                            ),
                            Switch(value: _reminder, activeColor: kGreen, onChanged: (v) {
                              setState(() => _reminder = v);
                              _save('goal_reminder', v);
                            }),
                          ],
                        ),
                        const Divider(height: 18, color: kLine),
                        const Align(alignment: Alignment.centerLeft, child: Text('Notifications', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: kInk))),
                        _SwitchRow(title: 'Practice Reminder', subtitle: 'Daily at 6:30 PM', value: _practice, onChanged: (v) {
                          setState(() => _practice = v);
                          _save('goal_practice', v);
                        }),
                        _SwitchRow(title: 'Streak Reminder', subtitle: 'Keep your ${p.streak}-day streak alive', value: _streakReminder, onChanged: (v) {
                          setState(() => _streakReminder = v);
                          _save('goal_streak', v);
                        }),
                        _SwitchRow(title: 'Weekly Progress Summary', subtitle: 'Every Sunday at 8:00 PM', value: _weeklySummary, onChanged: (v) {
                          setState(() => _weeklySummary = v);
                          _save('goal_weekly', v);
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  CardBox(
                    color: kGreenSoft,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const CircleIcon(Icons.star_rounded, size: 42, background: Colors.white, foreground: kGreen),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text('Learning Focus', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: kInk)),
                                  Text('English • Beginner', style: TextStyle(fontSize: 11, color: kMuted)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        outlineButton('Change Language', () => showToast(context, 'English is the active course')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  primaryButton('Edit Goal', _editGoal),
                ],
              ),
            ),
          );
        },
      );
}

class _SwitchRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchRow({required this.title, required this.subtitle, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: kInk)),
                  Text(subtitle, style: const TextStyle(fontSize: 9.5, color: kMuted)),
                ],
              ),
            ),
            Switch(value: value, activeColor: kGreen, onChanged: onChanged),
          ],
        ),
      );
}

// ============================================================
// 6. QUIZ RESULT
// ============================================================
class QuizResultScreen extends StatelessWidget {
  const QuizResultScreen({super.key});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: Progress.instance,
        builder: (context, _) {
          final p = Progress.instance;
          final score = p.accuracy;
          final stars = (score / 20).round().clamp(1, 5);
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: topBar(context, title: 'Quiz Result'),
            body: SafeArea(
              child: Stack(
                children: [
                  Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _ConfettiPainter()))),
                  ListView(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                    children: [
                      const Text('Quiz Result', textAlign: TextAlign.center, style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900, color: kInk)),
                      const SizedBox(height: 16),
                      Center(
                        child: SizedBox(
                          width: 180,
                          height: 180,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CircularProgressIndicator(value: score / 100, strokeWidth: 13, color: kGreen, backgroundColor: kLine),
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('$score%', style: const TextStyle(fontSize: 45, fontWeight: FontWeight.w900, color: kInk)),
                                    Text('$score/100 • Excellent!', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: kMuted)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(child: StarRow(count: stars, total: 5, size: 30)),
                      const SizedBox(height: 10),
                      Center(child: Pill('Green Badge Earned!', icon: Icons.workspace_premium_rounded, background: kGreenSoft)),
                      const SizedBox(height: 16),
                      CardBox(
                        color: kGreenSoft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                CircleIcon(Icons.mic_rounded, size: 38, background: Colors.white, foreground: kGreen),
                                SizedBox(width: 8),
                                Text('Pronunciation Feedback', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: kInk)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Clear and natural pronunciation. Your stress on syllables is accurate.\nTip: Keep a steady pace and connect the words smoothly.',
                              style: TextStyle(fontSize: 11, color: kInk, height: 1.5),
                            ),
                            const SizedBox(height: 7),
                            const Text('+10 pronunciation points', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: kGreenDark)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle_rounded, color: kGreen, size: 16),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text('Fluency: Confident • Clarity: $score% • Pace: Just right', style: const TextStyle(fontSize: 9.5, color: kInk, fontWeight: FontWeight.w600)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      primaryButton('Continue', () => Navigator.pop(context)),
                      const SizedBox(height: 8),
                      outlineButton('Review Answers', () => _showReview(context)),
                      const SizedBox(height: 8),
                      Text(
                        'You’re ${max(1, 4 - p.level % 4)} quizzes away from Level ${p.level + 1}!',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 10, color: kMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );

  void _showReview(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Review Answers'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('1. The cat is sleeping. ✓', style: TextStyle(height: 1.8)),
            Text('2. He is a baker. ✓', style: TextStyle(height: 1.8)),
            Text('3. The boy is running. ✓', style: TextStyle(height: 1.8)),
            Text('4. I would like a coffee. ✓', style: TextStyle(height: 1.8)),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = Random(7);
    final colors = [kGreen, kGreenSoft, kGreenDark, kLine];
    for (var i = 0; i < 46; i++) {
      final x = r.nextDouble() * size.width;
      final y = r.nextDouble() * min(160, size.height * .35);
      final w = 3.0 + r.nextDouble() * 4;
      final h = 6.0 + r.nextDouble() * 8;
      final paint = Paint()..color = colors[i % colors.length];
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(r.nextDouble() * pi);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: w, height: h), const Radius.circular(1.5)), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================
// 7. VOCABULARY REVIEW
// ============================================================
class VocabularyReviewScreen extends StatelessWidget {
  const VocabularyReviewScreen({super.key});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: Progress.instance,
        builder: (context, _) {
          final p = Progress.instance;
          final mastered = p.words;
          final flashcards = min(30, max(0, p.completed * 2));
          final remaining = 30 - flashcards;
          final apple = findItem('apple');
          final dog = findItem('dog');
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: topBar(
              context,
              title: 'Vocabulary Review',
              actions: [IconButton(icon: const Icon(Icons.bookmark_border_rounded), onPressed: () => showToast(context, 'Saved to your review list'))],
            ),
            body: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(color: kGreenSoft, borderRadius: BorderRadius.circular(13)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Great work! ${p.streak}-day streak', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: kInk)),
                        const SizedBox(width: 4),
                        const Icon(Icons.local_fire_department_rounded, color: kGreen, size: 17),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _VocabStat(
                          icon: Icons.workspace_premium_rounded,
                          title: 'WORDS MASTERED',
                          value: '$mastered',
                          subtitle: '+3 this week',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _VocabStat(
                          icon: Icons.style_rounded,
                          title: 'FLASHCARDS PROGRESS',
                          value: '$flashcards/30',
                          subtitle: '${(flashcards / 30 * 100).round()}% complete • $remaining remaining',
                          progress: flashcards / 30,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const SectionTitle("Today's Review", trailing: '2 cards'),
                  _WordReviewCard(item: apple, status: 'Mastered', mastered: true),
                  _WordReviewCard(item: dog, status: 'In Progress 75%', mastered: false),
                  const SizedBox(height: 12),
                  primaryButton('Review Now', () => openPage(context, const FlashcardsScreen()), icon: Icons.play_arrow_rounded),
                  const SizedBox(height: 8),
                  outlineButton('Practice Quiz', () => openPage(context, const QuizResultScreen())),
                ],
              ),
            ),
          );
        },
      );
}

class _VocabStat extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final double? progress;
  const _VocabStat({required this.icon, required this.title, required this.value, required this.subtitle, this.progress});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: kLine)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: kGreen, size: 19),
                const SizedBox(width: 5),
                Expanded(child: Text(title, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: kMuted, letterSpacing: .3))),
              ],
            ),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: kInk)),
            Text(subtitle, style: const TextStyle(fontSize: 9, color: kMuted)),
            if (progress != null) ...[
              const SizedBox(height: 6),
              ProgressBar(progress!, height: 6),
            ],
          ],
        ),
      );
}

class _WordReviewCard extends StatelessWidget {
  final LearnItem item;
  final String status;
  final bool mastered;
  const _WordReviewCard({required this.item, required this.status, required this.mastered});

  @override
  Widget build(BuildContext context) => CardBox(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            ClipRRect(borderRadius: BorderRadius.circular(12), child: SizedBox(width: 105, height: 100, child: Photo(item.image))),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.word, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: kInk)),
                  Text(item.sentence, style: const TextStyle(fontSize: 10.5, color: kMuted, height: 1.35)),
                  const SizedBox(height: 9),
                  Pill(
                    status,
                    icon: mastered ? Icons.check_circle_rounded : Icons.timelapse_rounded,
                    background: mastered ? kGreenSoft : kCard,
                    foreground: mastered ? kGreenDark : kMuted,
                  ),
                ],
              ),
            ),
            IconButton(icon: const Icon(Icons.volume_up_rounded, color: kGreen), onPressed: () => Tts.instance.speak(item.word)),
          ],
        ),
      );
}

// ============================================================
// 8. SETTINGS
// ============================================================
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _sound = true;
  bool _notifications = true;
  bool _reminders = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _sound = p.getBool('lingo_sound_on') ?? true;
      _notifications = p.getBool('lingo_reminder_on') ?? true;
      _reminders = p.getBool('lingo_learning_reminders') ?? true;
    });
  }

  Future<void> _save(String key, bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: topBar(context, title: 'Settings'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 26),
          children: [
            CardBox(
              child: Row(
                children: [
                  const Avatar('img_girl_child.jpg', size: 54, ring: true),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Emma', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: kInk)),
                        Text('Young learner • English', style: TextStyle(fontSize: 10.5, color: kMuted)),
                      ],
                    ),
                  ),
                  Pill('Level ${Progress.instance.level}', background: kGreenSoft),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const _SectionLabel('GENERAL'),
            CardBox(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: ListRow(
                icon: Icons.language_rounded,
                title: 'Language',
                subtitle: 'English • Arabic',
                trailing: 'Change',
                onTap: () => _showLanguage(context),
              ),
            ),
            const SizedBox(height: 12),
            const _SectionLabel('NOTIFICATIONS'),
            CardBox(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Column(
                children: [
                  _SettingSwitch(icon: Icons.notifications_none_rounded, title: 'Notifications', value: _notifications, onChanged: (v) {
                    setState(() => _notifications = v);
                    _save('lingo_reminder_on', v);
                  }),
                  const Divider(height: 1, color: kLine),
                  _SettingSwitch(icon: Icons.calendar_month_rounded, title: 'Learning Reminders', value: _reminders, onChanged: (v) {
                    setState(() => _reminders = v);
                    _save('lingo_learning_reminders', v);
                  }),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const _SectionLabel('AUDIO & DISPLAY'),
            CardBox(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Column(
                children: [
                  _SettingSwitch(icon: Icons.volume_up_rounded, title: 'Sound', value: _sound, onChanged: (v) {
                    setState(() => _sound = v);
                    _save('lingo_sound_on', v);
                    showToast(context, v ? 'Sound on' : 'Sound off');
                  }),
                  const Divider(height: 1, color: kLine),
                  const ListRow(
                    icon: Icons.dark_mode_outlined,
                    title: 'Dark Mode',
                    subtitle: 'Light theme is active',
                    trailing: 'Off',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const _SectionLabel('SUPPORT'),
            CardBox(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Column(
                children: [
                  ListRow(icon: Icons.shield_outlined, title: 'Privacy & Security', subtitle: 'Your progress stays on this device', onTap: () => showToast(context, 'All data is stored locally')),
                  const Divider(height: 1, color: kLine),
                  ListRow(icon: Icons.help_outline_rounded, title: 'Help & Support', subtitle: 'FAQ and learning tips', onTap: () => showToast(context, 'Support: help@lingogold.app')),
                  const Divider(height: 1, color: kLine),
                  ListRow(icon: Icons.info_outline_rounded, title: 'About Lingo Gold', subtitle: 'Version 2.4.1', onTap: () => showToast(context, 'Lingo Gold 2.4.1 • 256 lessons')),
                ],
              ),
            ),
            const SizedBox(height: 16),
            outlineButton('Log Out', () => _logout(context)),
          ],
        ),
      ),
    );
  }

  void _showLanguage(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Language'),
        content: const Text('English • Arabic\n\nYour course is English. Arabic is used for hints and translations.', style: TextStyle(height: 1.6)),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  void _logout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log Out'),
        content: const Text('Your progress is saved on this device. You can sign back in at any time.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () {
            Navigator.pop(context);
            showToast(context, 'Logged out (demo)');
          }, child: const Text('Log Out')),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 6),
        child: Text(text, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: kMuted, letterSpacing: 1)),
      );
}

class _SettingSwitch extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SettingSwitch({required this.icon, required this.title, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            CircleIcon(icon, size: 38, background: kGreenSoft),
            const SizedBox(width: 10),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: kInk))),
            Switch(value: value, activeColor: kGreen, onChanged: onChanged),
          ],
        ),
      );
}
