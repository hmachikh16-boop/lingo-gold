import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data.dart';
import 'theme.dart';
import 'user_profile.dart';
import 'widgets.dart';

/// تظهر مرة واحدة عند أول تشغيل لتحديد مستوى المنهج.
class LevelSelectScreen extends StatefulWidget {
  final VoidCallback onDone;
  const LevelSelectScreen({super.key, required this.onDone});

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  static const _key = 'lingo_selected_level_v1';
  int _selected = 1;

  final _levels = const [
    {'n': 1, 'title': 'التأسيس البصري', 'desc': 'أتعرف على الأشياء والصور والكلمات الأولى', 'icon': Icons.emoji_objects_outlined},
    {'n': 2, 'title': 'الناس والأفعال', 'desc': 'أتعرف على الأسرة والتحيات والأفعال اليومية', 'icon': Icons.people_outline},
    {'n': 3, 'title': 'الطعام والحيوانات', 'desc': 'أميّز الطعام والحيوانات والأشياء المكتشفة', 'icon': Icons.restaurant_menu_outlined},
    {'n': 4, 'title': 'المنزل والمدرسة', 'desc': 'أبني مفردات المكان والوظائف والأرقام', 'icon': Icons.school_outlined},
    {'n': 5, 'title': 'الدمج والتطبيق', 'desc': 'أستخدم الجمل في مواقف جديدة وأراجع ما تعلمته', 'icon': Icons.auto_awesome_outlined},
  ];

  int _countFor(int level) => lessons.where((l) => l.level == level).length;

  Future<void> _confirm() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, _selected);
    final first = lessons.indexWhere((l) => l.level == _selected) + 1;
    await UserProfile.instance.saveCourseProgress(
      lessonId: first < 1 ? 1 : first,
      completed: UserProfile.instance.lessonsCompleted.value,
      newStars: UserProfile.instance.stars.value,
      xp: UserProfile.instance.totalXP.value,
    );
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
          children: [
            const CircleIcon(
              icon: Icons.flag_rounded,
              background: kSoftGreen,
              foreground: kPrimary,
            ),
            const SizedBox(height: 16),
            const Text(
              'اختر مستواك',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: kInk),
            ),
            const SizedBox(height: 6),
            const Text(
              'سنبدأ من أول درس في المستوى الذي تختاره. يمكنك تغييره لاحقًا من ملفي.',
              style: TextStyle(fontSize: 13, color: kMuted, height: 1.6),
            ),
            const SizedBox(height: 20),
            ..._levels.map((lv) {
              final n = lv['n'] as int;
              final selected = n == _selected;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: () => setState(() => _selected = n),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: selected ? kSoftGreen : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected ? kPrimary : kLine,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: selected ? kPrimary : kCard,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              '$n',
                              style: TextStyle(
                                color: selected ? Colors.white : kInk,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lv['title'] as String,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: kInk,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                lv['desc'] as String,
                                style: const TextStyle(fontSize: 11.5, color: kMuted),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_countFor(n)} درس',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: kPrimaryDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                          color: selected ? kPrimary : kLine,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: _confirm,
              style: FilledButton.styleFrom(
                backgroundColor: kPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('ابدأ من هذا المستوى', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
  }
}
