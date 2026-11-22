import 'dart:convert';

import 'package:flutter/services.dart';

class LearnStep {
  final String id;
  final int step;
  final String type;
  final String word;
  final String image;
  final String audio;
  final String audioText;
  final String prompt;
  final String hint;
  final List<String> options;
  final int correct;

  const LearnStep({
    required this.id,
    required this.step,
    required this.type,
    required this.word,
    required this.image,
    required this.audio,
    required this.audioText,
    required this.prompt,
    required this.hint,
    required this.options,
    required this.correct,
  });

  factory LearnStep.fromJson(Map<String, dynamic> j) => LearnStep(
        id: j['id'] as String,
        step: j['step'] as int,
        type: j['type'] as String,
        word: j['word'] as String,
        image: j['image'] as String,
        audio: j['audio'] as String,
        audioText: j['audio_text'] as String? ?? j['word'] as String,
        prompt: j['prompt'] as String? ?? '',
        hint: j['hint'] as String? ?? '',
        options: (j['options'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        correct: j['correct'] as int? ?? 0,
      );
}

class LearnLesson {
  final String id;
  final String title;
  final List<LearnStep> steps;
  const LearnLesson({required this.id, required this.title, required this.steps});
  factory LearnLesson.fromJson(Map<String, dynamic> j) => LearnLesson(
        id: j['id'] as String,
        title: j['title'] as String,
        steps: (j['steps'] as List<dynamic>)
            .map((e) => LearnStep.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class Curriculum {
  final Map<String, String> ui;
  final List<LearnLesson> lessons;
  final List<int> srsIntervals;
  final List<Map<String, dynamic>> leaderboard;
  final int stepsPerLesson;

  const Curriculum({
    required this.ui,
    required this.lessons,
    required this.srsIntervals,
    required this.leaderboard,
    required this.stepsPerLesson,
  });

  String t(String key) => ui[key] ?? key;

  static Future<Curriculum> load() async {
    final raw = await rootBundle.loadString('lib/models/curriculum.json');
    final j = json.decode(raw) as Map<String, dynamic>;
    return Curriculum(
      ui: (j['ui'] as Map<String, dynamic>).map((k, v) => MapEntry(k, v.toString())),
      lessons: (j['lessons'] as List<dynamic>)
          .map((e) => LearnLesson.fromJson(e as Map<String, dynamic>))
          .toList(),
      srsIntervals: (j['srsIntervals'] as List<dynamic>).map((e) => e as int).toList(),
      leaderboard: (j['leaderboard'] as List<dynamic>)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      stepsPerLesson: j['stepsPerLesson'] as int? ?? 30,
    );
  }
}
