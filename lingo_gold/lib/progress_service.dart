import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ItemProgress {
  int attempts;
  int correct;
  int streak;
  int lastCorrectMs;
  int nextDueMs;

  ItemProgress({
    this.attempts = 0,
    this.correct = 0,
    this.streak = 0,
    this.lastCorrectMs = 0,
    this.nextDueMs = 0,
  });

  Map<String, dynamic> toJson() => {
        'a': attempts,
        'c': correct,
        's': streak,
        'l': lastCorrectMs,
        'd': nextDueMs,
      };

  factory ItemProgress.fromJson(Map<String, dynamic> m) => ItemProgress(
        attempts: (m['a'] is num) ? (m['a'] as num).toInt() : 0,
        correct: (m['c'] is num) ? (m['c'] as num).toInt() : 0,
        streak: (m['s'] is num) ? (m['s'] as num).toInt() : 0,
        lastCorrectMs: (m['l'] is num) ? (m['l'] as num).toInt() : 0,
        nextDueMs: (m['d'] is num) ? (m['d'] as num).toInt() : 0,
      );
}

/// تقدّم المتعلم محليًا على الجهاز. ليس محتوى درس، لذلك لا تُعدّله لوحة التحكم.
class ProgressService {
  ProgressService._();
  static final ProgressService instance = ProgressService._();

  static const _key = 'lingo_progress_v1';
  SharedPreferences? _prefs;
  final Map<String, ItemProgress> _cache = {};

  Future<void> init() async {
    if (_prefs != null) return;
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_key);
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      decoded.forEach((k, v) {
        if (v is Map<String, dynamic>) _cache[k] = ItemProgress.fromJson(v);
      });
    } catch (_) {}
  }

  ItemProgress get(String id) =>
      _cache.putIfAbsent(id, () => ItemProgress());

  int streak(String id) => get(id).streak;

  void record(String id, bool correct) {
    if (id.trim().isEmpty) return;
    final p = get(id);
    final now = DateTime.now().millisecondsSinceEpoch;
    p.attempts++;
    if (correct) {
      p.correct++;
      p.streak++;
      p.lastCorrectMs = now;
      final steps = const [1, 3, 7, 14];
      final idx = (p.streak - 1).clamp(0, steps.length - 1);
      p.nextDueMs = now + Duration(days: steps[idx]).inMilliseconds;
    } else {
      p.streak = 0;
      p.nextDueMs = now + const Duration(minutes: 10).inMilliseconds;
    }
    _save();
  }

  bool shouldRevealTranslation(String id, int revealAfter) {
    if (revealAfter <= 0) return true;
    return streak(id) >= revealAfter;
  }

  int effectiveHint(String id, int base) {
    final p = get(id);
    if (p.streak >= 2 && base > 0) return base - 1;
    return base < 0 ? 0 : base;
  }

  int dueCount(Iterable<String> ids) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return ids.where((id) {
      final d = get(id).nextDueMs;
      return d > 0 && d <= now;
    }).length;
  }

  void _save() {
    final mapped = _cache.map((k, v) =>
        MapEntry<String, dynamic>(k, v.toJson()));
    _prefs?.setString(_key, jsonEncode(mapped));
  }
}
