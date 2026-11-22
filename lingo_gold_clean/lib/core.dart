import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'lessons_data.dart';

/// Lingo Gold palette — green, white, dark gray and light gray only.
const kGreen = Color(0xFF2E9E5B);
const kGreenDark = Color(0xFF1F7A44);
const kGreenSoft = Color(0xFFE9F7EF);
const kInk = Color(0xFF1F2328);
const kMuted = Color(0xFF6B7280);
const kCard = Color(0xFFF5F6F8);
const kLine = Color(0xFFE6E8EC);

String dayKey([DateTime? date]) {
  final d = date ?? DateTime.now();
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

DateTime _mondayOf(DateTime d) {
  final day = DateTime(d.year, d.month, d.day);
  return day.subtract(Duration(days: day.weekday - 1));
}

String weekKey([DateTime? date]) => dayKey(_mondayOf(date ?? DateTime.now()));

class Tts {
  Tts._();
  static final Tts instance = Tts._();
  final FlutterTts _tts = FlutterTts();
  bool _ready = false;

  Future<void> speak(String text, {double rate = 0.48}) async {
    try {
      if (!_ready) {
        await _tts.setLanguage('en-US');
        await _tts.setSpeechRate(rate);
        _ready = true;
      }
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {}
  }
}

/// Real, persisted learning progress. Everything on the tracking screens
/// reads from this single source of truth.
class Progress extends ChangeNotifier {
  Progress._();
  static final Progress instance = Progress._();

  int completed = 0;
  int stars = 0;
  int xp = 0;
  int streak = 0;
  int current = 0;
  int words = 0;
  int todayLessons = 0;
  int quizCorrect = 0;
  int quizTotal = 0;
  int pronunciation = 92;
  int dailyGoalMinutes = 10;
  String lastDay = '';
  String weekStart = '';
  List<int> week = List<int>.filled(7, 0);

  int get level => xp ~/ 200 + 1;
  int get levelXp => xp % 200;
  int get xpToNext => 200 - levelXp;
  int get accuracy => quizTotal == 0 ? pronunciation : (quizCorrect * 100 / quizTotal).round();
  int get wordsLearned => words;
  int get weekTotal => week.fold<int>(0, (a, b) => a + b);

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    completed = p.getInt('completed') ?? 0;
    stars = p.getInt('stars') ?? 0;
    xp = p.getInt('xp') ?? 0;
    streak = p.getInt('streak') ?? 0;
    current = (p.getInt('current') ?? 0) % items.length;
    words = p.getInt('words') ?? completed * 4;
    todayLessons = p.getInt('today_lessons') ?? 0;
    quizCorrect = p.getInt('quiz_correct') ?? 0;
    quizTotal = p.getInt('quiz_total') ?? 0;
    pronunciation = p.getInt('pronunciation') ?? 92;
    dailyGoalMinutes = p.getInt('daily_goal_minutes') ?? 10;
    lastDay = p.getString('last_day') ?? '';
    weekStart = p.getString('week_start') ?? '';
    final rawWeek = p.getString('week_activity') ?? '';
    if (rawWeek.isNotEmpty) {
      final parsed = rawWeek.split(',').map(int.tryParse).toList();
      if (parsed.length == 7 && parsed.every((e) => e != null)) {
        week = parsed.cast<int>();
      }
    }
    if (lastDay != dayKey()) todayLessons = 0;
    final yesterday = dayKey(DateTime.now().subtract(const Duration(days: 1)));
    if (lastDay != dayKey() && lastDay != yesterday) streak = 0;
    if (weekStart.isNotEmpty && weekStart != weekKey()) {
      week = List<int>.filled(7, 0);
      weekStart = weekKey();
    }
    notifyListeners();
  }

  Future<void> complete(int index, bool correct) async {
    final today = dayKey();
    if (lastDay != today) {
      final yesterday = dayKey(DateTime.now().subtract(const Duration(days: 1)));
      streak = lastDay == yesterday ? streak + 1 : 1;
      lastDay = today;
      todayLessons = 0;
    }
    if (streak == 0) streak = 1;
    if (weekStart != weekKey()) {
      week = List<int>.filled(7, 0);
      weekStart = weekKey();
    }
    if (index + 1 > completed) {
      completed = index + 1;
      words += 4;
    }
    stars += correct ? 3 : 1;
    xp += correct ? 20 : 5;
    todayLessons += 1;
    week[DateTime.now().weekday - 1] += 1;
    quizTotal += 1;
    if (correct) quizCorrect += 1;
    current = (index + 1) % items.length;
    await _save();
    notifyListeners();
  }

  Future<void> recordAnswer(bool correct) async {
    quizTotal += 1;
    if (correct) quizCorrect += 1;
    final p = await SharedPreferences.getInstance();
    await p.setInt('quiz_total', quizTotal);
    await p.setInt('quiz_correct', quizCorrect);
    notifyListeners();
  }

  Future<void> setPronunciation(int score) async {
    pronunciation = score.clamp(0, 100);
    final p = await SharedPreferences.getInstance();
    await p.setInt('pronunciation', pronunciation);
    notifyListeners();
  }

  Future<void> setDailyGoal(int minutes) async {
    dailyGoalMinutes = minutes.clamp(5, 60);
    final p = await SharedPreferences.getInstance();
    await p.setInt('daily_goal_minutes', dailyGoalMinutes);
    notifyListeners();
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('completed', completed);
    await p.setInt('stars', stars);
    await p.setInt('xp', xp);
    await p.setInt('streak', streak);
    await p.setInt('current', current);
    await p.setInt('words', words);
    await p.setInt('today_lessons', todayLessons);
    await p.setInt('quiz_correct', quizCorrect);
    await p.setInt('quiz_total', quizTotal);
    await p.setInt('pronunciation', pronunciation);
    await p.setString('last_day', lastDay);
    await p.setString('week_start', weekStart);
    await p.setString('week_activity', week.join(','));
  }
}

class Photo extends StatelessWidget {
  final String file;
  final BoxFit fit;
  final double? width;
  final double? height;
  const Photo(this.file, {super.key, this.fit = BoxFit.cover, this.width, this.height});

  @override
  Widget build(BuildContext context) => Image.asset(
        'assets/images/$file',
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, __, ___) => const ColoredBox(color: kCard),
      );
}

void openPage(BuildContext context, Widget page) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
}

void showToast(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(text),
      backgroundColor: kInk,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}

PreferredSizeWidget topBar(
  BuildContext context, {
  required String title,
  String? subtitle,
  bool green = false,
  bool back = true,
  List<Widget>? actions,
}) {
  final fg = green ? Colors.white : kInk;
  return AppBar(
    backgroundColor: green ? kGreen : Colors.white,
    foregroundColor: fg,
    surfaceTintColor: Colors.transparent,
    scrolledUnderElevation: 0,
    elevation: 0,
    centerTitle: true,
    automaticallyImplyLeading: back,
    leading: back
        ? IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.of(context).maybePop(),
          )
        : null,
    title: subtitle == null
        ? Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: fg))
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: fg)),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: green ? Colors.white70 : kMuted),
              ),
            ],
          ),
    actions: actions,
    bottom: green
        ? PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: Colors.white24),
          )
        : null,
  );
}

Widget primaryButton(String label, VoidCallback? onPressed, {IconData? icon, bool expand = true}) {
  final child = icon == null
      ? FilledButton(onPressed: onPressed, child: Text(label))
      : FilledButton.icon(onPressed: onPressed, icon: Icon(icon, size: 20), label: Text(label));
  return expand ? SizedBox(width: double.infinity, child: child) : child;
}

Widget outlineButton(String label, VoidCallback? onPressed, {IconData? icon, bool expand = true}) {
  final child = icon == null
      ? OutlinedButton(onPressed: onPressed, child: Text(label))
      : OutlinedButton.icon(onPressed: onPressed, icon: Icon(icon, size: 20), label: Text(label));
  return expand ? SizedBox(width: double.infinity, child: child) : child;
}

class SectionTitle extends StatelessWidget {
  final String text;
  final String? trailing;
  final VoidCallback? onTrailing;
  const SectionTitle(this.text, {super.key, this.trailing, this.onTrailing});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Expanded(child: Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: kInk))),
            if (trailing != null)
              GestureDetector(
                onTap: onTrailing,
                child: Text(trailing!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: kGreen)),
              ),
          ],
        ),
      );
}

class CardBox extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final VoidCallback? onTap;
  const CardBox({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.color = Colors.white,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kLine),
      ),
      child: child,
    );
    if (onTap == null) return card;
    return InkWell(borderRadius: BorderRadius.circular(18), onTap: onTap, child: card);
  }
}

class Pill extends StatelessWidget {
  final String text;
  final Color background;
  final Color foreground;
  final IconData? icon;
  const Pill(this.text, {super.key, this.background = kGreenSoft, this.foreground = kGreenDark, this.icon});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 13, color: foreground), const SizedBox(width: 4)],
            Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: foreground)),
          ],
        ),
      );
}

class Avatar extends StatelessWidget {
  final String file;
  final double size;
  final bool ring;
  const Avatar(this.file, {super.key, this.size = 54, this.ring = false});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        padding: ring ? const EdgeInsets.all(3) : EdgeInsets.zero,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: ring ? Border.all(color: Colors.white, width: 2) : null,
        ),
        child: ClipOval(child: Photo(file, fit: BoxFit.cover)),
      );
}

class StatBox extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color background;
  const StatBox({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    this.background = kGreenSoft,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Icon(icon, color: kGreenDark, size: 22),
            const SizedBox(height: 6),
            Text(value, textAlign: TextAlign.center, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: kInk)),
            const SizedBox(height: 3),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10.5, color: kMuted, height: 1.3)),
          ],
        ),
      );
}

class StarRow extends StatelessWidget {
  final int count;
  final int total;
  final double size;
  const StarRow({super.key, this.count = 3, this.total = 3, this.size = 26});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < total; i++)
            Icon(
              i < count ? Icons.star_rounded : Icons.star_outline_rounded,
              color: i < count ? kGreen : kLine,
              size: size,
            ),
        ],
      );
}

class Waveform extends StatelessWidget {
  final double height;
  final double progress;
  final Color color;
  const Waveform({super.key, this.height = 54, this.progress = 0.65, this.color = kGreen});

  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(painter: _WavePainter(progress: progress, color: color)),
      );
}

class _WavePainter extends CustomPainter {
  final double progress;
  final Color color;
  _WavePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final barWidth = 2.4;
    final gap = 3.2;
    final count = (size.width / (barWidth + gap)).floor();
    final active = (count * progress).round();
    for (var i = 0; i < count; i++) {
      final t = i / max(1, count - 1);
      final envelope = 0.35 + 0.65 * sin(t * pi);
      final detail = 0.45 + 0.55 * sin(i * 0.9) * cos(i * 0.37);
      final h = (size.height * envelope * detail.abs()).clamp(3.0, size.height);
      final x = i * (barWidth + gap);
      final paint = Paint()
        ..color = i < active ? color : color.withValues(alpha: 0.22)
        ..strokeWidth = barWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(x, size.height / 2 - h / 2), Offset(x, size.height / 2 + h / 2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter old) => old.progress != progress || old.color != color;
}

class ProgressBar extends StatelessWidget {
  final double value;
  final double height;
  final Color color;
  const ProgressBar(this.value, {super.key, this.height = 9, this.color = kGreen});

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(height),
        child: LinearProgressIndicator(
          value: value.clamp(0.0, 1.0),
          minHeight: height,
          color: color,
          backgroundColor: kCard,
        ),
      );
}

class CircleIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color background;
  final Color foreground;
  const CircleIcon(this.icon, {super.key, this.size = 42, this.background = kGreenSoft, this.foreground = kGreen});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: background, shape: BoxShape.circle),
        child: Icon(icon, color: foreground, size: size * 0.48),
      );
}

class ListRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? trailing;
  final Widget? trailingWidget;
  final VoidCallback? onTap;
  final Color iconBackground;
  const ListRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle = '',
    this.trailing,
    this.trailingWidget,
    this.onTap,
    this.iconBackground = kGreenSoft,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
          child: Row(
            children: [
              CircleIcon(icon, size: 38, background: iconBackground),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: kInk)),
                    if (subtitle.isNotEmpty)
                      Text(subtitle, style: const TextStyle(fontSize: 11, color: kMuted, height: 1.35)),
                  ],
                ),
              ),
              if (trailing != null)
                Text(trailing!, style: const TextStyle(fontWeight: FontWeight.w900, color: kGreen, fontSize: 13)),
              if (trailingWidget != null) trailingWidget!,
              if (onTap != null && trailing == null && trailingWidget == null)
                const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: kMuted),
            ],
          ),
        ),
      );
}
