import 'package:shared_preferences/shared_preferences.dart';

/// سجل بسيط لعدد الدروس المكتملة لكل يوم، يستخدمه التقرير الأسبوعي.
class DailyActivityService {
  DailyActivityService._();

  static final DailyActivityService instance = DailyActivityService._();

  static const _key = 'lingo_daily_activity_v1';

  final Map<String, int> _counts = {};

  String _keyOf(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? const <String>[];
    for (final entry in raw) {
      final parts = entry.split(':');
      if (parts.length == 2) {
        _counts[parts[0]] = int.tryParse(parts[1]) ?? 0;
      }
    }
  }

  int countFor(DateTime day) => _counts[_keyOf(day)] ?? 0;

  /// آخر 7 أيام، من الأقدم إلى الأحدث.
  List<int> last7() {
    final now = DateTime.now();
    return List.generate(
      7,
      (i) => countFor(now.subtract(Duration(days: 6 - i))),
    );
  }

  void recordLesson() {
    final key = _keyOf(DateTime.now());
    _counts[key] = (_counts[key] ?? 0) + 1;
    _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      _counts.entries.map((e) => '${e.key}:${e.value}').toList(),
    );
  }
}
