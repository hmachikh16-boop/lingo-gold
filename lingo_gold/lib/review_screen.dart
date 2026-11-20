import 'package:flutter/material.dart';

import 'data.dart';
import 'lesson_content_service.dart';
import 'lesson_matching.dart';
import 'progress_service.dart';
import 'services/sound_service.dart';
import 'theme.dart';

/// مراجعة سريعة للعناصر المستحقة باستخدام نفس واجهة المطابقة المألوفة.
class ReviewScreen extends StatefulWidget {
  final List<String> itemIds;
  final VoidCallback onExit;

  const ReviewScreen({
    super.key,
    required this.itemIds,
    required this.onExit,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  int _group = 0;

  List<Lesson> _groupItems() {
    if (widget.itemIds.isEmpty) return const [];
    final start = _group * 3;
    final ids = widget.itemIds.skip(start).take(3).toList();
    final items = LessonContentService.instance.lessonsForIds(ids);
    if (items.length < 2 && items.isNotEmpty) {
      items.addAll(LessonContentService.instance
          .siblingsForItemId(items.first.id, 2));
    }
    return items.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = _groupItems();
    final totalGroups = (widget.itemIds.length / 3).ceil();
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('مراجعة مستحقة'),
        backgroundColor: Colors.white,
        foregroundColor: kInk,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: widget.onExit,
            tooltip: 'إغلاق',
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
      body: items.length < 2
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'لا توجد عناصر كافية للمراجعة بعد.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, color: kMuted),
                ),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
                  child: Row(
                    children: [
                      Text(
                        'المجموعة ${_group + 1} / $totalGroups',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: kMuted,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${widget.itemIds.length} عنصر',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: kPrimaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: MatchingStep(
                    key: ValueKey('review-$_group'),
                    lesson: items.first,
                    distractors: items.sublist(1),
                    onComplete: (correct) {
                      ProgressService.instance.record(items.first.id, correct);
                      if (!correct) SoundService.instance.playError();
                      if (_group + 1 < totalGroups) {
                        setState(() => _group++);
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
