import 'package:flutter/material.dart';

import 'data.dart';
import 'lesson_content_service.dart';
import 'lesson_fill_arrange.dart';
import 'progress_service.dart';
import 'theme.dart';
import 'widgets.dart';

/// مركز تدريب مساعد لا يغيّر تدفق الدروس الخماسي.
class TrainingScreen extends StatefulWidget {
  final int currentLessonId;
  final ValueChanged<int> onOpenLesson;
  final ValueChanged<String> onOpenStory;
  final VoidCallback onReview;

  const TrainingScreen({
    super.key,
    required this.currentLessonId,
    required this.onOpenLesson,
    required this.onOpenStory,
    required this.onReview,
  });

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  bool _showBuilder = false;

  Lesson get _target {
    final idx = (widget.currentLessonId - 1).clamp(0, lessons.length - 1);
    return lessons[idx];
  }

  String get _targetId =>
      _target.id.isNotEmpty ? _target.id : 'L${widget.currentLessonId}';

  Lesson get _builderLesson {
    final l = _target;
    final w = l.word.trim();
    var sentence = l.sentence.trim();
    if (w.isNotEmpty && sentence.toLowerCase().contains(w.toLowerCase())) {
      sentence = sentence.replaceFirst(
        RegExp(RegExp.escape(w), caseSensitive: false),
        '___',
      );
    } else {
      sentence = '___ ${sentence.isEmpty ? w : sentence}'.trim();
    }
    return l.copyWith(sentence: sentence);
  }

  List<Lesson> get _builderDistractors {
    final idx = (widget.currentLessonId - 1).clamp(0, lessons.length - 1);
    final ov = LessonContentService.instance.getStepOverrides(idx);
    final intro = ov?['intro'];
    final ids = <String>[];
    if (intro is Map && intro['items'] is List) {
      for (final it in intro['items'] as List) {
        if (it is Map) {
          final id = (it['id'] ?? '').toString();
          if (id.isNotEmpty && id != _targetId) ids.add(id);
        }
      }
    }
    final out = LessonContentService.instance.lessonsForIds(ids);
    if (out.length >= 2) return out.take(2).toList();
    for (var d = 1; out.length < 2 && d < lessons.length; d++) {
      for (final j in [idx - d, idx + d]) {
        if (j < 0 || j >= lessons.length || j == idx) continue;
        if (out.any((x) => x.word.toLowerCase() == lessons[j].word.toLowerCase())) continue;
        out.add(lessons[j]);
        if (out.length >= 2) break;
      }
    }
    return out.take(2).toList();
  }

  Widget _card({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    String? badge,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: kLine),
      ),
      child: ListTile(
        leading: CircleIcon(icon: icon, background: kCard, foreground: color),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w800, color: kInk),
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: kSoftGreen,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: kPrimaryDark,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(subtitle, style: const TextStyle(color: kMuted, fontSize: 12)),
        trailing: const Icon(Icons.chevron_left_rounded, color: kMuted),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showBuilder) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('بناء الجملة'),
          backgroundColor: Colors.white,
          foregroundColor: kInk,
          elevation: 0,
          leading: IconButton(
            onPressed: () => setState(() => _showBuilder = false),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        ),
        body: FillBlankStep(
          lesson: _builderLesson,
          distractors: _builderDistractors,
          onComplete: (correct) {
            ProgressService.instance.record(_targetId, correct);
            setState(() => _showBuilder = false);
          },
        ),
      );
    }

    final due = ProgressService.instance.dueIds().length;
    final weak = ProgressService.instance.weakIds();
    final storyGroups = <String, List<Lesson>>{};
    for (final l in lessons) {
      if (l.storyId.trim().isEmpty) continue;
      storyGroups.putIfAbsent(l.storyId, () => <Lesson>[]).add(l);
    }
    final stories = storyGroups.values
        .where((g) => g.length > 1)
        .take(8)
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          children: [
            const Text(
              'مركز التدريب',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: kInk),
            ),
            const SizedBox(height: 4),
            const Text(
              'تدريبات مساعدة لا تغيّر ترتيب الدروس',
              style: TextStyle(fontSize: 12, color: kMuted),
            ),
            const SizedBox(height: 18),
            _card(
              icon: Icons.replay_rounded,
              color: kPrimary,
              title: 'التحدي اليومي',
              subtitle: due > 0 ? '$due عنصر جاهز للمراجعة' : 'لا توجد مراجعة مستحقة الآن',
              badge: due > 0 ? '$due' : null,
              onTap: widget.onReview,
            ),
            _card(
              icon: Icons.edit_note_rounded,
              color: kSecondary,
              title: 'بناء الجملة',
              subtitle: _target.title.isNotEmpty
                  ? 'الدرس الحالي: ${_target.title}'
                  : 'اختر الكلمة الناقصة في الجملة',
              onTap: () => setState(() => _showBuilder = true),
            ),
            _card(
              icon: Icons.report_problem_outlined,
              color: kDanger,
              title: 'تقرير الضعف',
              subtitle: weak.isEmpty ? 'لا توجد نقاط ضعف مسجلة' : '${weak.length} عناصر تحتاج مراجعة',
              badge: weak.isEmpty ? null : '${weak.length}',
              onTap: () => _showWeakReport(weak),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(4, 14, 4, 8),
              child: Text(
                'مكتبة القصص',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: kInk),
              ),
            ),
            if (stories.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('لا توجد قصص بعد.', style: TextStyle(color: kMuted)),
              )
            else
              SizedBox(
                height: 132,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: stories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    final g = stories[i];
                    final first = g.first;
                    return GestureDetector(
                      onTap: () => widget.onOpenStory(first.storyId),
                      child: Container(
                        width: 168,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: kLine),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: SizedBox(
                                height: 58,
                                width: double.infinity,
                                child: LessonImage(lesson: first),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              first.storyTitle.isNotEmpty ? first.storyTitle : 'قصة',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w900, color: kInk),
                            ),
                            Text(
                              '${g.length} دروس',
                              style: const TextStyle(fontSize: 10, color: kMuted),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showWeakReport(List<String> ids) {
    final rows = ids.map((id) {
      final l = LessonContentService.instance.lessonForItemId(id);
      final p = ProgressService.instance.get(id);
      final acc = (ProgressService.instance.accuracy(id) * 100).round();
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Text(
                l == null ? id : (l.title.isNotEmpty ? l.title : l.word),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
            Text('$acc% • ${p.attempts} محاولات',
                style: const TextStyle(fontSize: 11, color: kMuted)),
          ],
        ),
      );
    }).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'نقاط الضعف',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: kInk),
            ),
            const SizedBox(height: 10),
            if (rows.isEmpty)
              const Text('لا توجد نقاط ضعف مسجلة.', style: TextStyle(color: kMuted))
            else
              ...rows,
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onReview();
              },
              child: const Text('مراجعة الآن'),
            ),
          ],
        ),
      ),
    );
  }
}
