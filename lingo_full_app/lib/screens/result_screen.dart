import 'package:flutter/material.dart';

import '../core.dart';
import '../models/curriculum.dart';
import 'milestone_screen.dart';

class ResultScreen extends StatelessWidget {
  final Curriculum curriculum;
  final int lessonIndex;
  const ResultScreen({super.key, required this.curriculum, required this.lessonIndex});

  @override
  Widget build(BuildContext context) {
    final r = Progress.instance.lastResult;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: kGreen,
        foregroundColor: Colors.white,
        title: Text(curriculum.t('quiz_result'), style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.emoji_events_rounded, size: 92, color: kGreen),
                const SizedBox(height: 16),
                Text('${r[0]} / ${curriculum.stepsPerLesson}', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: kInk)),
                const SizedBox(height: 6),
                Text(curriculum.t('correct'), style: const TextStyle(color: kMuted)),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [for (var i = 0; i < 3; i++) Icon(i < r[2] ? Icons.star_rounded : Icons.star_outline_rounded, size: 40, color: kGreen)],
                ),
                const SizedBox(height: 14),
                Text('+${r[1]} XP', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: kGreenDark)),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(backgroundColor: kGreen, minimumSize: const Size(0, 52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: Text(curriculum.t('continue'), style: const TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ),
                const SizedBox(height: 10),
                if ((lessonIndex + 1) % 4 == 0)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => openPage(context, MilestoneScreen(curriculum: curriculum)),
                      icon: const Icon(Icons.chat_rounded),
                      label: Text(curriculum.t('milestone')),
                      style: OutlinedButton.styleFrom(foregroundColor: kGreenDark, minimumSize: const Size(0, 52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
