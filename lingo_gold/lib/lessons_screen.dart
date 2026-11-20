import 'package:flutter/material.dart';

import 'data.dart';
import 'lesson_content_service.dart';
import 'theme.dart';

/// Shows every lesson in the app order, grouped by the lesson category.
/// Remote lessons appended from the admin bundle appear automatically because
/// this screen rebuilds whenever LessonContentService.revision changes.
class LessonsScreen extends StatelessWidget {
  final void Function(int lessonId) onStartLesson;

  const LessonsScreen({super.key, required this.onStartLesson});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: LessonContentService.instance.revision,
      builder: (context, _, __) {
        final sections = _buildSections();
        final localNumbers = <int, int>{};
        final counters = <String, int>{};
        for (var i = 0; i < lessons.length; i++) {
          final cat = lessons[i].category.trim().isEmpty
              ? 'دروس أخرى'
              : lessons[i].category.trim();
          final n = (counters[cat] ?? 0) + 1;
          counters[cat] = n;
          localNumbers[i] = n;
        }
        return SafeArea(
          bottom: false,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
            itemCount: sections.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'الدروس',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: kInk,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          final before =
                              LessonContentService.instance.revision.value;
                          final ok = await LessonContentService
                              .instance
                              .fetchRemoteBundle();
                          if (!context.mounted) return;
                          final after =
                              LessonContentService.instance.revision.value;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                !ok
                                    ? 'تعذر الاتصال بمصدر الدروس'
                                    : (after > before
                                        ? 'تم تحديث الدروس'
                                        : 'الدروس محدثة بالفعل'),
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: const Icon(Icons.sync_rounded, size: 18),
                        label: const Text('تحديث'),
                      ),
                    ],
                  ),
                );
              }
              final section = sections[index - 1];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${section.name} (${section.indices.length})',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: kInk,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...section.indices.map((idx) {
                    final lesson = lessons[idx];
                    final lessonNumber = localNumbers[idx] ?? idx + 1;
                    final globalLessonNumber = idx + 1;
                    final isNew = idx >= 140;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: kLine),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isNew ? kSoftBlue : kSoftGreen,
                          foregroundColor:
                              isNew ? kSecondary : kPrimaryDark,
                          child: Text(
                            '$lessonNumber',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                lesson.word,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: kInk,
                                ),
                              ),
                            ),
                            if (isNew)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: kSoftBlue,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'جديد',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: kSecondary),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Text(
                          lesson.translation,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: kMuted,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.play_arrow_rounded,
                          color: kPrimary,
                        ),
                        onTap: () => onStartLesson(globalLessonNumber),
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        );
      },
    );
  }

  List<_Section> _buildSections() {
    final byCategory = <String, List<int>>{};
    for (var i = 0; i < lessons.length; i++) {
      final name = lessons[i].category.trim().isEmpty
          ? 'دروس أخرى'
          : lessons[i].category.trim();
      byCategory.putIfAbsent(name, () => <int>[]).add(i);
    }
    // sort lessons inside each category by their explicit order field
    for (final entry in byCategory.entries) {
      entry.value.sort((a, b) {
        final oa = lessons[a].order > 0 ? lessons[a].order : a + 1;
        final ob = lessons[b].order > 0 ? lessons[b].order : b + 1;
        return oa.compareTo(ob);
      });
    }
    final result = byCategory.entries
        .map((e) => _Section(e.key, e.value))
        .toList();

    // sort categories by explicit group order
    result.sort((a, b) {
      final ga = groups.where((g) => g.name == a.name).firstOrNull;
      final gb = groups.where((g) => g.name == b.name).firstOrNull;
      final oa = ga?.order ?? 999;
      final ob = gb?.order ?? 999;
      if (oa != ob) return oa.compareTo(ob);
      if (ga != null && gb != null) return 0;
      if (ga != null) return -1;
      if (gb != null) return 1;
      return a.name.compareTo(b.name);
    });
    return result;
  }
}

class _Section {
  final String name;
  final List<int> indices;
  const _Section(this.name, this.indices);
}
