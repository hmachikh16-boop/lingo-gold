import 'package:flutter/material.dart';

import 'data.dart' as app_data;
import 'theme.dart';
import 'widgets.dart';

/// خريطة القصص: تعرض قصص المنهج كعُقد بصرية بصورها الحقيقية.
/// تعتمد على بيانات storyId / storyOrder / storyTitle الموجودة في الحزمة،
/// ولا تحتاج أي تغيير في محتوى الدروس.
class StoriesScreen extends StatefulWidget {
  final int completedLessons;
  final ValueChanged<int> onOpenLesson;

  const StoriesScreen({
    super.key,
    required this.completedLessons,
    required this.onOpenLesson,
  });

  @override
  State<StoriesScreen> createState() => _StoriesScreenState();
}

class _StoriesScreenState extends State<StoriesScreen> {
  int _level = 0; // 0 = كل المستويات

  static const Map<int, String> _levelTitles = {
    1: 'التأسيس البصري',
    2: 'الطعام والوجبات',
    3: 'الحيوانات والطبيعة',
    4: 'الناس والأماكن',
    5: 'الدمج والتطبيق',
  };

  int _doneIn(List<app_data.Lesson> group) => group
      .where((l) => l.order > 0 && l.order <= widget.completedLessons)
      .length;

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<app_data.Lesson>>{};
    for (final l in app_data.lessons) {
      final key = l.storyId.trim();
      if (key.isEmpty) continue;
      groups.putIfAbsent(key, () => <app_data.Lesson>[]).add(l);
    }
    final allStories = groups.values
        .where((g) => g.length >= 4)
        .toList()
      ..sort((a, b) => a.first.order.compareTo(b.first.order));

    final stories = _level == 0
        ? allStories
        : allStories.where((g) => g.first.level == _level).toList();

    final doneStories =
        allStories.where((g) => _doneIn(g) == g.length).length;
    final overall = allStories.isEmpty
        ? 0.0
        : (doneStories / allStories.length).clamp(0.0, 1.0);

    final byLevel = <int, List<List<app_data.Lesson>>>{};
    for (final g in stories) {
      byLevel.putIfAbsent(g.first.level, () => <List<app_data.Lesson>>[]).add(g);
    }
    final levels = byLevel.keys.toList()..sort();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          children: [
            const Text(
              'خريطة القصص',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: kInk,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$doneStories من ${allStories.length} قصة مكتملة',
              style: const TextStyle(fontSize: 12, color: kMuted),
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: overall,
                minHeight: 8,
                backgroundColor: kSoftGreen,
                valueColor: const AlwaysStoppedAnimation<Color>(kPrimary),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _chip(0, 'الكل'),
                  for (final n in _levelTitles.keys) _chip(n, 'المستوى $n'),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (stories.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'لا توجد قصص في هذا المستوى بعد.',
                    style: TextStyle(color: kMuted),
                  ),
                ),
              )
            else
              for (final level in levels) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(2, 6, 2, 10),
                  child: Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: kGold,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$level',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _levelTitles[level] ?? 'المستوى $level',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: kInk,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.82,
                  ),
                  itemCount: byLevel[level]!.length,
                  itemBuilder: (context, i) =>
                      _storyCard(byLevel[level]![i]),
                ),
                const SizedBox(height: 18),
              ],
          ],
        ),
      ),
    );
  }

  Widget _chip(int value, String label) {
    final selected = _level == value;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: GestureDetector(
        onTap: () => setState(() => _level = value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? kPrimary : kCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? kPrimary : kLine),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : kMuted,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _storyCard(List<app_data.Lesson> group) {
    final first = group.first;
    final done = _doneIn(group);
    final complete = done == group.length;
    final next = group.firstWhere(
      (l) => l.order > widget.completedLessons,
      orElse: () => first,
    );

    return GestureDetector(
      onTap: () => widget.onOpenLesson(next.order),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(kRadius),
          border: Border.all(
            color: complete ? kPrimary : kLine,
            width: complete ? 2 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(kRadius),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    LessonImage(lesson: first, fit: BoxFit.cover),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: complete
                              ? kGold
                              : Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          complete ? 'مكتملة' : '$done/${group.length}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: complete ? Colors.white : kInk,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      first.storyTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: kInk,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 7),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: group.isEmpty
                            ? 0
                            : (done / group.length).clamp(0.0, 1.0),
                        minHeight: 5,
                        backgroundColor: kCard,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(kPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
