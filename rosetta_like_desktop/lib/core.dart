import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

const kGreen = Color(0xFF1DB954);
const kGreenDark = Color(0xFF168A3E);
const kGreenSoft = Color(0xFFE9F9EF);
const kInk = Color(0xFF111111);
const kMuted = Color(0xFF666666);
const kCard = Color(0xFFF6F8F6);
const kLine = Color(0xFFE4E8E4);
const kWrong = Color(0xFFFF3B30);

String dayKey([DateTime? d]) {
  final x = d ?? DateTime.now();
  return '${x.year}-${x.month.toString().padLeft(2, '0')}-${x.day.toString().padLeft(2, '0')}';
}

class Tts {
  Tts._();
  static final Tts instance = Tts._();
  final FlutterTts _tts = FlutterTts();
  bool _ready = false;
  double rate = 0.85;

  Future<void> speak(String text) async {
    try {
      if (!_ready) {
        await _tts.setLanguage('en-US');
        _ready = true;
      }
      await _tts.setSpeechRate(rate);
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {}
  }
}

class WordMemory {
  int level;
  int reps;
  int wrong;
  DateTime due;
  WordMemory({this.level = 0, this.reps = 0, this.wrong = 0, required this.due});

  Map<String, dynamic> toJson() => {
        'level': level,
        'reps': reps,
        'wrong': wrong,
        'due': due.millisecondsSinceEpoch,
      };
  factory WordMemory.fromJson(Map<String, dynamic> j) => WordMemory(
        level: j['level'] as int? ?? 0,
        reps: j['reps'] as int? ?? 0,
        wrong: j['wrong'] as int? ?? 0,
        due: DateTime.fromMillisecondsSinceEpoch(j['due'] as int? ?? 0),
      );
}

class Progress extends ChangeNotifier {
  Progress._();
  static final Progress instance = Progress._();

  int xp = 0;
  int streak = 1;
  int stars = 0;
  int completedLessons = 0;
  int currentLesson = 0;
  int todayCorrect = 0;
  int totalCorrect = 0;
  int totalAnswers = 0;
  String lastDay = '';
  List<int> week = List<int>.filled(7, 0);
  final Map<String, WordMemory> srs = {};
  List<int> lastResult = List<int>.filled(3, 0); // correct, xp, stars

  List<int> get intervals => const [1, 2, 4, 8, 16];

  int get accuracy => totalAnswers == 0 ? 0 : (totalCorrect * 100 / totalAnswers).round();
  int get level => xp ~/ 200 + 1;
  int get wordsLearned => completedLessons * 8;
  List<String> get dueWords {
    final now = DateTime.now();
    return srs.entries
        .where((e) => !e.value.due.isAfter(now))
        .map((e) => e.key)
        .toList()
      ..sort();
  }

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    xp = p.getInt('xp') ?? 0;
    streak = p.getInt('streak') ?? 1;
    stars = p.getInt('stars') ?? 0;
    completedLessons = p.getInt('completed_lessons') ?? 0;
    currentLesson = p.getInt('current_lesson') ?? 0;
    todayCorrect = p.getInt('today_correct') ?? 0;
    totalCorrect = p.getInt('total_correct') ?? 0;
    totalAnswers = p.getInt('total_answers') ?? 0;
    lastDay = p.getString('last_day') ?? '';
    final rawWeek = p.getString('week') ?? '';
    if (rawWeek.isNotEmpty) {
      final parts = rawWeek.split(',').map(int.tryParse).toList();
      if (parts.length == 7 && parts.every((e) => e != null)) week = parts.cast<int>();
    }
    final rawSrs = p.getString('srs') ?? '';
    if (rawSrs.isNotEmpty) {
      try {
        final decoded = json.decode(rawSrs) as Map<String, dynamic>;
        decoded.forEach((k, v) {
          srs[k] = WordMemory.fromJson(Map<String, dynamic>.from(v as Map));
        });
      } catch (_) {}
    }
    if (lastDay != dayKey()) todayCorrect = 0;
    notifyListeners();
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('xp', xp);
    await p.setInt('streak', streak);
    await p.setInt('stars', stars);
    await p.setInt('completed_lessons', completedLessons);
    await p.setInt('current_lesson', currentLesson);
    await p.setInt('today_correct', todayCorrect);
    await p.setInt('total_correct', totalCorrect);
    await p.setInt('total_answers', totalAnswers);
    await p.setString('last_day', dayKey());
    await p.setString('week', week.join(','));
    await p.setString('srs', json.encode(srs.map((k, v) => MapEntry(k, v.toJson()))));
  }

  Future<void> answer(String word, bool correct) async {
    totalAnswers++;
    if (lastDay != dayKey()) {
      final yesterday = dayKey(DateTime.now().subtract(const Duration(days: 1)));
      streak = lastDay == yesterday ? streak + 1 : 1;
      lastDay = dayKey();
      todayCorrect = 0;
    }
    if (correct) {
      totalCorrect++;
      todayCorrect++;
      xp += 10;
      week[DateTime.now().weekday - 1]++;
    } else {
      xp += 2;
    }
    reviewWord(word, correct);
    await save();
    notifyListeners();
  }

  void reviewWord(String word, bool correct) {
    final now = DateTime.now();
    final m = srs.putIfAbsent(word, () => WordMemory(due: now));
    m.reps++;
    if (correct) {
      m.level = (m.level + 1).clamp(0, intervals.length - 1);
      m.due = now.add(Duration(days: intervals[m.level]));
    } else {
      m.wrong++;
      m.level = 0;
      m.due = now.add(const Duration(minutes: 2));
    }
  }

  Future<void> completeLesson(int index, int correctCount) async {
    final earnedStars = correctCount >= 27 ? 3 : (correctCount >= 22 ? 2 : 1);
    final bonus = correctCount >= 27 ? 50 : 30;
    xp += bonus;
    stars = stars > earnedStars ? stars : earnedStars;
    if (index + 1 > completedLessons) completedLessons = index + 1;
    currentLesson = completedLessons % 4;
    lastResult = [correctCount, bonus, earnedStars];
    await save();
    notifyListeners();
  }

  Future<void> reset() async {
    xp = 0;
    streak = 1;
    stars = 0;
    completedLessons = 0;
    currentLesson = 0;
    todayCorrect = 0;
    totalCorrect = 0;
    totalAnswers = 0;
    lastDay = '';
    week = List<int>.filled(7, 0);
    srs.clear();
    lastResult = List<int>.filled(3, 0);
    await save();
    notifyListeners();
  }
}

void openPage(BuildContext context, Widget page) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
}
