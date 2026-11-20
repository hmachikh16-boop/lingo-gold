import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show SystemChannels;
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;

import 'data.dart' as app;
import 'firebase_service.dart';
import 'models.dart' as fb;

/// Loads editable lesson content from the remote JSON bundle published by the
/// dashboard, and applies it to the app's in-memory lesson list (data.dart) so admin edits
/// (sentences/images/new lessons) can reach the app without rebuilding the APK
/// when the remote bundle URL is configured/hosted.
class LessonContentService {
  LessonContentService._();
  static final LessonContentService instance = LessonContentService._();

  /// روابط JSON منشورة (يُصدَّر من لوحة التحكم عبر GitHub). التطبيق يجربها
  /// بالترتيب عند كل فحص، ويستخدم أول رابط يستجيب. لا حاجة لإعادة البناء عند
  /// تحديث المحتوى؛ تُحدَّث الحزمة تلقائيًا من لوحة التحكم.
  ///
  /// كل شبكات CDN (Gist/jsDelivr/raw) تخزّن الحزمة 5 دقائق ويمكن أن تعلق
  /// بنسخة قديمة. لذلك نعرف آخر commit من Git refs (غير مخزّن، 444 بايت)
  /// ثم نجلب الحزمة من رابط الـ commit الثابت. جلب الحزمة يتم فقط عند تغيّر
  /// الـ commit، لذا الفحص كل ثانية خفيف جداً ويصل التحديث خلال ثانية تقريباً.
  static const String contentRepoRefsUrl =
      'https://github.com/hmachikh16-boop/lingo-gold-content/info/refs?service=git-upload-pack';
  static const String contentRepoRawBase =
      'https://raw.githubusercontent.com/hmachikh16-boop/lingo-gold-content';
  static const List<String> remoteBundleUrls = <String>[
    'https://gist.githubusercontent.com/hmachikh16-boop/2b5187c6e1696ac92701872452a04ea2/raw/lingo-lessons-bundle.json',
    'https://cdn.jsdelivr.net/gh/hmachikh16-boop/lingo-gold-content@main/lingo-lessons-bundle.json',
    'https://raw.githubusercontent.com/hmachikh16-boop/lingo-gold-content/main/lingo-lessons-bundle.json',
  ];
  static const String remoteBundleUrl = String.fromEnvironment(
    'LINGO_BUNDLE_URL',
    defaultValue: '',
  );

  final ValueNotifier<int> revision = ValueNotifier<int>(0);
  StreamSubscription<List<fb.Lesson>>? _sub;
  bool _started = false;
  bool _remoteReady = false;
  Timer? _remoteTimer;
  String? _lastContentSha;
  final Map<int, Map<String, dynamic>> stepOverridesByIndex = {};
  Map<String, dynamic>? curriculumConfig;

  /// عدد دروس التطبيق الأساسية قبل أي دروس تُضاف من لوحة التحكم.
  /// يُستخدم لتنظيف الدروس الديناميكية التي حُذفت من الحزمة البعيدة.
  final int _baseLessonCount = app.lessons.length;

  Map<String, dynamic>? getStepOverrides(int appIndex) {
    final m = stepOverridesByIndex[appIndex];
    if (m == null || m.isEmpty) return null;
    return m;
  }

  @visibleForTesting
  bool applyBundleForTest(Map<String, dynamic> bundle) =>
      _applyRemoteBundle(bundle);

  @visibleForTesting
  static String? parseContentRepoMainSha(String refsBody) =>
      RegExp(r'([0-9a-f]{40})\s+refs/heads/main').firstMatch(refsBody)?.group(1);

  void start() {
    if (_started) return;
    _started = true;
    // القانون الصارم: الدروس تُعدَّل فقط من لوحة التحكم، والمصدر الوحيد
    // الذي يقرأه التطبيق هو الحزمة المنشورة. لا يُسمح لـ Firestore (أو أي
    // مصدر آخر) بتغيير الدروس، حتى لا يحدث تضارب أو استبدال لتعديلات اللوحة.
    _startRemoteSync();
    // عند العودة للتطبيق، اجلب آخر حزمة فورًا (بدلاً من انتظار دورة الـ polling).
    SystemChannels.lifecycle.setMessageHandler((state) async {
      if (state == 'AppLifecycleState.resumed') {
        unawaited(fetchRemoteBundle());
      }
      return null;
    });
  }

  List<String> get _effectiveUrls {
    final override = remoteBundleUrl.trim();
    if (override.isNotEmpty) return <String>[override];
    return remoteBundleUrls;
  }

  void _startRemoteSync() {
    // Fetch once now, then poll periodically.
    unawaited(fetchRemoteBundle());
    _remoteTimer?.cancel();
    _remoteTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      unawaited(fetchRemoteBundle());
    });
  }

  Future<bool> fetchRemoteBundle([String? overrideUrl]) async {
    // مسار Git refs أولاً (غير مخزّن) لجلب آخر commit ثم الحزمة الثابتة.
    if (overrideUrl == null || overrideUrl.trim().isEmpty) {
      if (await _fetchFromGitRefs()) return true;
    }
    final urls = (overrideUrl != null && overrideUrl.trim().isNotEmpty)
        ? <String>[overrideUrl.trim()]
        : _effectiveUrls;
    if (urls.isEmpty) return false;
    final cacheBust = DateTime.now().millisecondsSinceEpoch.toString();
    for (final url in urls) {
      try {
        final baseUri = Uri.parse(url);
        final uri = baseUri.replace(queryParameters: <String, String>{
          ...baseUri.queryParameters,
          '_cb': cacheBust,
        });
        final res = await http.get(uri, headers: {
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
          'Expires': '0',
          'Accept': 'application/json',
        }).timeout(const Duration(seconds: 5));
        if (res.statusCode < 200 || res.statusCode >= 300) continue;
        final body = res.body;
        if (body.isEmpty) continue;
        final decoded = jsonDecode(body);
        if (decoded is! Map<String, dynamic>) continue;
        // طبّق الحزمة في كل فحص، حتى لو كان نصها مطابقاً للمرة السابقة؛
        // بهذا نستعيد التعديلات لو كتبت مصادر أخرى بيانات قديمة في الذاكرة.
        final changed = _applyRemoteBundle(decoded);
        _remoteReady = true;
        if (changed) revision.value = revision.value + 1;
        return true; // نجح أحد الروابط
      } catch (_) {
        // جرّب الرابط التالي
      }
    }
    return false;
  }

  /// يقرأ آخر commit من Git refs (استجابة صغيرة غير مخزّنة)، ويجلب الحزمة من
  /// رابط الـ commit الثابت فقط عندما يتغيّر الـ commit. لا يعتمد على كاش CDN.
  Future<bool> _fetchFromGitRefs() async {
    try {
      final refs = await http.get(
        Uri.parse(contentRepoRefsUrl),
        headers: const {
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
          'Accept': 'application/x-git-upload-pack-advertisement',
        },
      ).timeout(const Duration(seconds: 5));
      if (refs.statusCode < 200 || refs.statusCode >= 300) return false;
      final sha = parseContentRepoMainSha(refs.body);
      if (sha == null) return false;
      if (sha == _lastContentSha && _remoteReady) return true;

      final cacheBust = DateTime.now().millisecondsSinceEpoch.toString();
      final uri = Uri.parse('$contentRepoRawBase/$sha/lingo-lessons-bundle.json')
          .replace(queryParameters: <String, String>{'_cb': cacheBust});
      final res = await http.get(uri, headers: {
        'Cache-Control': 'no-cache, no-store, must-revalidate',
        'Pragma': 'no-cache',
        'Accept': 'application/json',
      }).timeout(const Duration(seconds: 5));
      if (res.statusCode < 200 || res.statusCode >= 300) return false;
      if (res.body.isEmpty) return false;
      final decoded = jsonDecode(res.body);
      if (decoded is! Map<String, dynamic>) return false;
      final changed = _applyRemoteBundle(decoded);
      _lastContentSha = sha;
      _remoteReady = true;
      if (changed) revision.value = revision.value + 1;
      return true;
    } catch (_) {
      return false;
    }
  }

  void _apply(List<fb.Lesson> remote) {
    // الحزمة البعيدة نجحت بالفعل؛ لا نسمح لبيانات Firestore القديمة بالكتابة فوقها.
    if (_remoteReady || remote.isEmpty) return;
    var changed = false;
    for (final r in remote) {
      final idx = r.appIndex;
      if (idx < 0) continue;

      while (app.lessons.length <= idx) {
        final n = app.lessons.length;
        app.lessons.add(app.Lesson(
          word: r.word.isNotEmpty ? r.word : 'Lesson ${n + 1}',
          sentence: r.sentence,
          options: r.options.isNotEmpty ? r.options : const ['Option 1', 'Option 2', 'Option 3'],
          imageFile: r.imageFile,
          indexInPack: r.indexInPack,
          isPack: r.isPack,
          category: r.category,
          translation: r.translation,
          imageUrl: r.imageUrl,
          spoken: r.spoken,
        ));
        changed = true;
      }

      final prevOv = stepOverridesByIndex[idx];
      final nextOv = (r.stepOverrides.isNotEmpty) ? r.stepOverrides : null;
      final ovChanged = !_mapEqualsShallow(prevOv, nextOv);
      if (ovChanged) {
        if (nextOv == null) {
          stepOverridesByIndex.remove(idx);
        } else {
          stepOverridesByIndex[idx] = Map<String, dynamic>.from(nextOv);
        }
        changed = true;
      }

      final hasContent = r.word.isNotEmpty ||
          r.sentence.isNotEmpty ||
          r.imageFile.isNotEmpty ||
          r.imageUrl != null ||
          r.translation.isNotEmpty ||
          r.options.isNotEmpty;
      if (!hasContent) continue;
      final base = app.lessons[idx];
      final spoken = (r.spoken != null && r.spoken!.trim().isNotEmpty) ? r.spoken!.trim() : null;
      final imageUrl = (r.imageUrl != null && r.imageUrl!.trim().isNotEmpty) ? r.imageUrl!.trim() : null;
      final merged = app.Lesson(
        word: r.word.isNotEmpty ? r.word : base.word,
        sentence: r.sentence.isNotEmpty ? r.sentence : base.sentence,
        spoken: spoken ?? base.spoken,
        options: r.options.isNotEmpty ? r.options : base.options,
        imageFile: r.imageFile.isNotEmpty ? r.imageFile : base.imageFile,
        indexInPack: r.imageFile.isNotEmpty ? r.indexInPack : base.indexInPack,
        isPack: r.imageFile.isNotEmpty ? r.isPack : base.isPack,
        category: r.category.isNotEmpty ? r.category : base.category,
        translation: r.translation.isNotEmpty ? r.translation : base.translation,
        imageUrl: imageUrl ?? base.imageUrl,
      );
      if (!_lessonEquals(base, merged)) {
        app.lessons[idx] = merged;
        changed = true;
      }
    }
    if (changed) revision.value = revision.value + 1;
  }

  bool _applyRemoteBundle(Map<String, dynamic> bundle) {
    var changed = false;
    if (bundle['curriculum'] is Map) {
      final cfg = Map<String, dynamic>.from(bundle['curriculum'] as Map);
      final cur = curriculumConfig;
      if (cur == null || _mapEqualsShallow(cur, cfg) == false) {
        curriculumConfig = cfg;
        changed = true;
      }
    }

    // Support a few shapes:
    // { lessons: [...] } where each item may include appIndex/base fields/stepOverrides
    // { lessons: [...], newLessons: [...] }
    // { items: [...] }
    final rawLessons = (bundle['lessons'] is List)
        ? bundle['lessons'] as List
        : (bundle['items'] is List ? bundle['items'] as List : const []);
    final rawNew = (bundle['newLessons'] is List) ? bundle['newLessons'] as List : const [];

    final all = <Map<String, dynamic>>[];
    for (final it in rawLessons) {
      if (it is Map) all.add(Map<String, dynamic>.from(it));
    }
    // حماية إضافية من الدروس الجديدة المكررة التي قد تأتي من حزمة قديمة:
    // نحتفظ بنسخة واحدة لكل (كلمة + فئة)، وهي آخر نسخة وصلت.
    final dynamicSeen = <String, int>{};
    for (final it in rawNew) {
      if (it is! Map) continue;
      final m = Map<String, dynamic>.from(it);
      final key = '${_asString(m['word']).toLowerCase()}|'
          '${_asString(m['category']).toLowerCase()}';
      final existing = dynamicSeen[key];
      if (existing != null) {
        all[existing] = m;
      } else {
        dynamicSeen[key] = all.length;
        all.add(m);
      }
    }
    if (all.isEmpty) return false;

    // Apply in appIndex order when available, otherwise in sequence order.
    all.sort((a, b) {
      final ai = _asInt(a['appIndex'], 1 << 30);
      final bi = _asInt(b['appIndex'], 1 << 30);
      if (ai != bi) return ai.compareTo(bi);
      return _asInt(a['order'], 0).compareTo(_asInt(b['order'], 0));
    });

    final appliedDynamicIndices = <int>{};

    for (final m in all) {
      // Allow explicit disabling/removal hints? keep simple: skip inactive if provided as false for non-new existing? 
      final hasAppIndex = m.containsKey('appIndex') && m['appIndex'] != null;
      var idx = hasAppIndex ? _asInt(m['appIndex'], -1) : -1;
      if (idx < 0) {
        // If no appIndex, append as new lesson at end.
        idx = app.lessons.length;
      }

      // Ensure capacity for appended lessons (including gaps, though gaps shouldn't happen)
      while (app.lessons.length <= idx) {
        final n = app.lessons.length;
        app.lessons.add(app.Lesson(
          word: (m['word'] ?? m['title'] ?? 'Lesson ${n + 1}').toString(),
          sentence: (m['sentence'] ?? '').toString(),
          options: _asStringList(m['options']),
          imageFile: (m['imageFile'] ?? '').toString(),
          indexInPack: _asInt(m['indexInPack'], 0),
          isPack: m['isPack'] == true,
          category: (m['category'] ?? '').toString(),
          translation: (m['translation'] ?? '').toString(),
          imageUrl: _asNullableString(m['imageUrl']),
          spoken: _asNullableString(m['spoken']),
          zoom: _asDouble(m['zoom'], 1.0),
          title: _asString(m['title']),
          level: _asInt(m['level'], 0),
          id: _asString(m['id']),
          hintLevel: _asInt(m['hintLevel'], 0),
          storyId: _asString(m['storyId']),
          storyOrder: _asInt(m['storyOrder'], 0),
          storyTitle: _asString(m['storyTitle']),
        ));
        changed = true;
      }

      if (idx >= _baseLessonCount) {
        appliedDynamicIndices.add(idx);
      }

      // Apply step overrides for this index
      final rawOv = m['stepOverrides'];
      final nextOv = (rawOv is Map && rawOv.isNotEmpty)
          ? Map<String, dynamic>.from(rawOv)
          : null;
      final prevOv = stepOverridesByIndex[idx];
      final ovChanged = !_mapEqualsShallow(prevOv, nextOv);
      if (ovChanged) {
        if (nextOv == null) {
          stepOverridesByIndex.remove(idx);
        } else {
          stepOverridesByIndex[idx] = nextOv;
        }
        changed = true;
      }

      // Merge base lesson content (only if content present; allow appending new lessons even if minimal)
      final base = app.lessons[idx];
      final isNewlyAppended = idx >= 0 && idx == app.lessons.length - 1 && (m['__new'] == true);
      final hasContent = _asString(m['word']).isNotEmpty ||
          _asString(m['sentence']).isNotEmpty ||
          _asString(m['imageFile']).isNotEmpty ||
          _asNullableString(m['imageUrl']) != null ||
          _asString(m['translation']).isNotEmpty ||
          _asStringList(m['options']).isNotEmpty ||
          _asNullableString(m['spoken']) != null ||
          isNewlyAppended ||
          (idx >= 140); // treat extended indices as dynamic lessons
      if (!hasContent) continue;

      final merged = _mergeBase(
        base,
        m,
        allowEmptyAsOverride: idx >= app.lessons.length - 0,
        forcedOrder: idx + 1,
      );
      if (!_lessonEquals(base, merged)) {
        app.lessons[idx] = merged;
        changed = true;
      }
    }

    // احذف الدروس الديناميكية التي لم تعد موجودة في الحزمة (مثل درس جديد حُذف من اللوحة)
    if (app.lessons.length > _baseLessonCount) {
      for (var i = app.lessons.length - 1; i >= _baseLessonCount; i--) {
        if (!appliedDynamicIndices.contains(i)) {
          app.lessons.removeAt(i);
          stepOverridesByIndex.remove(i);
          changed = true;
        }
      }
    }
    final staleOverrideKeys = stepOverridesByIndex.keys
        .where((k) => k >= _baseLessonCount && !appliedDynamicIndices.contains(k))
        .toList();
    for (final k in staleOverrideKeys) {
      stepOverridesByIndex.remove(k);
      changed = true;
    }

    return changed;
  }

  app.Lesson _mergeBase(app.Lesson base, Map<String, dynamic> m,
      {bool allowEmptyAsOverride = false, int? forcedOrder}) {
    String pickStr(String key, String fbv) {
      if (!m.containsKey(key)) return fbv;
      final s = _asString(m[key]);
      if (s.isEmpty && !allowEmptyAsOverride) return fbv;
      return s.isEmpty ? fbv : s;
    }

    final hasImageKeys = m.containsKey('imageFile') || m.containsKey('imageUrl') || m.containsKey('isPack') || m.containsKey('indexInPack');
    final spokenProvided = m.containsKey('spoken');
    final spokenStr = _asNullableString(m['spoken']);
    final imageUrlProvided = m.containsKey('imageUrl');
    final imageUrlStr = _asNullableString(m['imageUrl']);
    final opts = m.containsKey('options') ? _asStringList(m['options']) : base.options;

    final imageFile = hasImageKeys ? _asString(m['imageFile']) : base.imageFile;
    final isPack = hasImageKeys ? (m['isPack'] == true) : base.isPack;
    final indexInPack = hasImageKeys ? _asInt(m['indexInPack'], 0) : base.indexInPack;

    return app.Lesson(
      word: pickStr('word', base.word),
      sentence: pickStr('sentence', base.sentence),
      spoken: spokenProvided ? (spokenStr ?? base.spoken) : base.spoken,
      options: (m.containsKey('options') && opts.isNotEmpty) ? opts : base.options,
      imageFile: (hasImageKeys && imageFile.isNotEmpty) ? imageFile : (hasImageKeys ? base.imageFile : base.imageFile),
      indexInPack: isPack || (hasImageKeys && imageFile.isNotEmpty) ? indexInPack : base.indexInPack,
      isPack: hasImageKeys ? isPack : base.isPack,
      category: pickStr('category', base.category),
      translation: pickStr('translation', base.translation),
      // لا نأخذ `order` من الحزمة: اللوحة تُنتجه ترقيمًا داخل كل فئة،
      // بينما التطبيق يعتمد ترقيمًا عالميًا 1..140 (appIndex + 1).
      order: forcedOrder ?? base.order,
      // قيمة صريحة فارغة/فارغة null تعني «إزالة الصورة المرفوعة»، لا الرجوع
      // للصورة القديمة. بدون ذلك يستحيل حذف صورة سبق نشرها.
      imageUrl: imageUrlProvided ? (imageUrlStr ?? '') : base.imageUrl,
      zoom: m.containsKey('zoom') ? _asDouble(m['zoom'], 1.0) : base.zoom,
      title: m.containsKey('title') ? _asString(m['title']) : base.title,
      level: m.containsKey('level') ? _asInt(m['level'], base.level) : base.level,
      id: m.containsKey('id') ? _asString(m['id']) : base.id,
      hintLevel: m.containsKey('hintLevel') ? _asInt(m['hintLevel'], base.hintLevel) : base.hintLevel,
      storyId: m.containsKey('storyId') ? _asString(m['storyId']) : base.storyId,
      storyOrder: m.containsKey('storyOrder') ? _asInt(m['storyOrder'], base.storyOrder) : base.storyOrder,
      storyTitle: m.containsKey('storyTitle') ? _asString(m['storyTitle']) : base.storyTitle,
    );
  }

  bool _lessonEquals(app.Lesson a, app.Lesson b) {
    return a.word == b.word &&
        a.sentence == b.sentence &&
        a.spoken == b.spoken &&
        a.translation == b.translation &&
        a.imageFile == b.imageFile &&
        a.imageUrl == b.imageUrl &&
        a.isPack == b.isPack &&
        a.indexInPack == b.indexInPack &&
        a.category == b.category &&
        a.title == b.title &&
        a.level == b.level &&
        a.id == b.id &&
        a.hintLevel == b.hintLevel &&
        a.storyId == b.storyId &&
        a.storyOrder == b.storyOrder &&
        a.storyTitle == b.storyTitle &&
        a.zoom == b.zoom &&
        _listEquals(a.options, b.options);
  }

  String _asString(dynamic v) => v == null ? '' : v.toString().trim();

  String? _asNullableString(dynamic v) {
    final s = _asString(v);
    return s.isEmpty ? null : s;
  }

  int _asInt(dynamic v, int fallback) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(_asString(v)) ?? fallback;
  }

  double _asDouble(dynamic v, double fallback) {
    if (v is num) return v.toDouble();
    return double.tryParse(_asString(v)) ?? fallback;
  }

  List<String> _asStringList(dynamic v) {
    if (v is List) return v.map((e) => e.toString()).toList();
    return const [];
  }

  bool _mapEqualsShallow(Map<String, dynamic>? a, Map<String, dynamic>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return a == null && b == null;
    if (a.length != b.length) return false;
    for (final k in a.keys) {
      if (!b.containsKey(k)) return false;
      if (a[k].toString() != b[k].toString()) return false;
    }
    return true;
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void dispose() {
    _sub?.cancel();
    _remoteTimer?.cancel();
  }
}
