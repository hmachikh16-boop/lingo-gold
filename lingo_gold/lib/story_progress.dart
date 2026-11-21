import 'package:shared_preferences/shared_preferences.dart';

/// يحفظ أفضل نتيجة نجوم لكل قصة بشكل محلي وبسيط.
class StoryProgressService {
  StoryProgressService._();

  static final StoryProgressService instance = StoryProgressService._();

  static const _key = 'lingo_story_stars_v1';

  final Map<String, int> _stars = {};

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? const <String>[];
    for (final entry in raw) {
      final parts = entry.split(':');
      if (parts.length == 2) {
        _stars[parts[0]] = int.tryParse(parts[1]) ?? 0;
      }
    }
  }

  int starsFor(String storyId) => _stars[storyId] ?? 0;

  int get totalStars => _stars.values.fold(0, (sum, n) => sum + n);

  Future<void> saveStars(String storyId, int stars) async {
    final previous = _stars[storyId] ?? 0;
    if (stars <= previous) return;
    _stars[storyId] = stars;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      _stars.entries.map((e) => '${e.key}:${e.value}').toList(),
    );
  }
}
