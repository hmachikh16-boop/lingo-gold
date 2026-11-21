import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'data.dart';
import 'lesson_content_service.dart';
import 'services/sound_service.dart';
import 'services/speech_service.dart';
import 'theme.dart';
import 'widgets.dart';

/// جلسة غمر صارمة على طريقة Rosetta Stone:
/// صورة كاملة + إنجليزية فقط + 4 مراحل (استماع، تحديد، نطق، كتابة)
/// بدون ترجمة، بدون نصوص عربية، وبدون زر متابعة.
class ImmersionFlowScreen extends StatefulWidget {
  final int startId;
  final int endId;
  final VoidCallback onExit;
  final ValueChanged<int> onLessonComplete;

  const ImmersionFlowScreen({
    super.key,
    required this.startId,
    required this.endId,
    required this.onExit,
    required this.onLessonComplete,
  });

  @override
  State<ImmersionFlowScreen> createState() => _ImmersionFlowScreenState();
}

class _ImmersionFlowScreenState extends State<ImmersionFlowScreen> {
  int _lessonId = 1;
  int _phase = 0; // 0 listen, 1 identify, 2 speak, 3 write
  bool _busy = false;
  bool _wrong = false;
  int? _selected;
  List<Lesson> _choices = const [];
  int _correctIndex = -1;
  bool _listening = false;
  int _score = 0;
  bool _speechDone = false;
  int _speakAttempts = 0;
  int _mistakes = 0;
  Timer? _speechTimer;
  String _typed = '';

  Lesson get _lesson {
    final idx = (_lessonId - 1).clamp(0, lessons.length - 1);
    return lessons[idx];
  }

  String get _target => _lesson.word.trim();

  @override
  void initState() {
    super.initState();
    _lessonId = widget.startId.clamp(1, widget.endId);
    _prepareLesson();
  }

  @override
  void dispose() {
    _speechTimer?.cancel();
    super.dispose();
  }

  void _prepareLesson() {
    final l = _lesson;
    final sibs = LessonContentService.instance.siblingsForItemId(
      l.id.isNotEmpty ? l.id : 'L$_lessonId',
      3,
    );
    _choices = [l, ...sibs].take(4).toList();
    final r = Random(l.word.hashCode + _lessonId * 17);
    _choices.shuffle(r);
    _correctIndex = _choices.indexWhere((c) => c.word == l.word);
    setState(() {
      _phase = 0;
      _busy = false;
      _wrong = false;
      _selected = null;
      _listening = false;
      _score = 0;
      _speechDone = false;
      _speakAttempts = 0;
      _typed = '';
    });
    _playAndAdvance();
  }

  Future<void> _playAndAdvance() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await TtsService.instance.speak(_lesson.spokenText).timeout(
            const Duration(seconds: 7),
            onTimeout: () {},
          );
    } catch (_) {}
    if (!mounted || _phase != 0) return;
    setState(() {
      _busy = false;
      _phase = 1;
    });
  }

  void _pick(int index) {
    if (_busy || _selected != null) return;
    setState(() {
      _selected = index;
      _wrong = index != _correctIndex;
    });
    if (!_wrong) {
      SoundService.instance.playCorrect();
      Timer(const Duration(milliseconds: 420), _toSpeak);
    } else {
      SoundService.instance.playError();
      _mistakes += 1;
      Timer(const Duration(milliseconds: 650), () {
        if (mounted) setState(() => _selected = null);
      });
    }
  }

  void _toSpeak() {
    if (!mounted) return;
    setState(() {
      _phase = 2;
      _score = 0;
      _speechDone = false;
      _listening = true;
    });
    _speechTimer?.cancel();
    _speechTimer = Timer(const Duration(seconds: 16), () {
      if (mounted && !_speechDone) {
        setState(() {
          _listening = false;
          _speechDone = true;
        });
        Timer(const Duration(milliseconds: 700), _toWrite);
      }
    });
    unawaited(_startListening());
  }

  Future<void> _startListening() async {
    await SpeechService.listenEnglish((heard) {
      if (!mounted || _speechDone) return;
      final s = _scoreFor(heard, _lesson.spokenText);
      setState(() {
        _score = s;
        _listening = false;
        _speechDone = true;
      });
      _speechTimer?.cancel();
      if (s >= 70) {
        SoundService.instance.playCorrect();
        Timer(const Duration(milliseconds: 650), _toWrite);
      } else {
        SoundService.instance.playError();
        _mistakes += 1;
        _speakAttempts += 1;
        if (_speakAttempts >= 2) {
          Timer(const Duration(milliseconds: 700), _toWrite);
        } else {
          Timer(const Duration(milliseconds: 900), _retrySpeak);
        }
      }
    });
  }

  void _retrySpeak() {
    if (!mounted) return;
    setState(() {
      _listening = true;
      _speechDone = false;
      _score = 0;
    });
    _speechTimer?.cancel();
    _speechTimer = Timer(const Duration(seconds: 16), () {
      if (mounted && !_speechDone) {
        setState(() {
          _listening = false;
          _speechDone = true;
        });
        Timer(const Duration(milliseconds: 600), _toWrite);
      }
    });
    unawaited(_startListening());
  }

  void _toWrite() {
    if (!mounted) return;
    setState(() {
      _phase = 3;
      _typed = '';
    });
  }

  int _scoreFor(String heard, String target) {
    String clean(String s) => s
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty && !const {'a', 'an', 'the'}.contains(w))
        .toList()
        .join(' ');
    final h = clean(heard).split(' ').where((x) => x.isNotEmpty).toList();
    final t = clean(target).split(' ').where((x) => x.isNotEmpty).toList();
    if (t.isEmpty) return 100;
    final hit = t.where((w) => h.contains(w)).length;
    return (hit * 100 / t.length).round();
  }

  void _key(String k) {
    final letters = _target.replaceAll(' ', '');
    if (_typed.replaceAll(' ', '').length >= letters.length) return;
    setState(() => _typed += k);
    final typedLetters = _typed.replaceAll(' ', '');
    if (typedLetters.toLowerCase() == letters.toLowerCase()) {
      SoundService.instance.playCorrect();
      Timer(const Duration(milliseconds: 420), _finishLesson);
    }
  }

  void _backspace() {
    if (_typed.isEmpty) return;
    setState(() => _typed = _typed.substring(0, _typed.length - 1));
  }

  void _finishLesson() {
    if (!mounted) return;
    widget.onLessonComplete(_lessonId);
    if (_lessonId >= widget.endId) {
      setState(() => _phase = 4);
      return;
    }
    setState(() => _lessonId += 1);
    _prepareLesson();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: _phase == 1 || _phase == 3
                  ? Container(color: Colors.white)
                  : LessonImage(lesson: _lesson, fit: BoxFit.cover),
            ),
            if (_phase == 0 || _phase == 2)
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x66000000), Color(0x00000000)],
                    ),
                  ),
                ),
              ),
            Column(
              children: [
                _buildTopBar(),
                Expanded(child: _buildPhase()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onExit,
            child: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
          ),
          const Spacer(),
          Row(
            children: List.generate(4, (i) {
              final on = i <= _phase;
              return Container(
                width: 22,
                height: 5,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: on ? kGold : Colors.white.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const Spacer(),
          const SizedBox(width: 26),
        ],
      ),
    );
  }

  Widget _buildPhase() {
    switch (_phase) {
      case 0:
        return _listenPhase();
      case 1:
        return _identifyPhase();
      case 2:
        return _speakPhase();
      case 3:
        return _writePhase();
      default:
        return _buildComplete();
    }
  }

  Widget _listenPhase() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          top: MediaQuery.of(context).size.height * 0.28,
          child: _pulseRing(190, 0.07),
        ),
        Positioned(
          top: MediaQuery.of(context).size.height * 0.30,
          child: _pulseRing(150, 0.12),
        ),
        GestureDetector(
          onTap: _busy ? null : _playAndAdvance,
          child: Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.96),
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(color: Color(0x33000000), blurRadius: 26, spreadRadius: 2),
              ],
            ),
            child: const Icon(Icons.volume_up_rounded, size: 46, color: kPrimary),
          ),
        ),
        Positioned(
          bottom: 78,
          left: 24,
          right: 24,
          child: Text(
            _lesson.spokenText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              shadows: [Shadow(color: Color(0x99000000), blurRadius: 8)],
            ),
          ),
        ),
      ],
    );
  }

  Widget _pulseRing(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: opacity),
          width: 1.5,
        ),
      ),
    );
  }

  Widget _identifyPhase() {
    return Column(
      children: [
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _playAndAdvance,
          child: const Icon(Icons.volume_up_rounded, size: 30, color: kPrimary),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
            itemCount: _choices.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.35,
            ),
            itemBuilder: (context, i) {
              final sel = _selected == i;
              final border = sel ? (_wrong ? kDanger : kPrimary) : kLine;
              return GestureDetector(
                onTap: () => _pick(i),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: border, width: sel ? 4 : 2),
                    boxShadow: [
                      BoxShadow(
                        color: sel
                            ? Colors.black.withValues(alpha: 0.18)
                            : Colors.black.withValues(alpha: 0.08),
                        blurRadius: sel ? 18 : 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        LessonImage(lesson: _choices[i], fit: BoxFit.cover),
                        if (sel && !_wrong)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: kPrimary,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                size: 15,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _speakPhase() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: _speechDone ? _retrySpeak : null,
          child: Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: _listening ? kPrimary : Colors.white,
              shape: BoxShape.circle,
              boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 20)],
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: Icon(
              Icons.mic_rounded,
              size: 52,
              color: _listening ? Colors.white : kPrimary,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Waveform(active: _listening, color: Colors.white, height: 46),
        const SizedBox(height: 10),
        if (_speechDone && _score > 0)
          Text(
            '$_score',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: _score >= 70 ? kGold : Colors.white,
            ),
          ),
      ],
    );
  }

  Widget _writePhase() {
    final letters = _target.replaceAll(' ', '');
    final typed = _typed.replaceAll(' ', '');
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            height: 150,
            width: double.infinity,
            child: LessonImage(lesson: _lesson, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 18),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            children: List.generate(letters.length, (i) {
              final filled = i < typed.length;
              return Container(
                width: 34,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: filled ? kSoftGreen : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: filled ? kPrimary : kLine, width: 1.6),
                ),
                child: Text(
                  filled ? typed[i].toUpperCase() : '',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: kPrimaryDark,
                  ),
                ),
              );
            }),
          ),
        ),
        const Spacer(),
        _keyboard(),
      ],
    );
  }

  Widget _buildComplete() {
    final start = (_lessonId - 3).clamp(1, lessons.length);
    final strip = <Lesson>[];
    for (var id = start; id <= _lessonId && id <= lessons.length; id++) {
      strip.add(lessons[id - 1]);
    }
    final stars = (3 - _mistakes).clamp(1, 3);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [kGold, Color(0xFFE09E00)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: kGold.withValues(alpha: 0.34),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: const Icon(Icons.check_rounded, size: 46, color: Colors.white),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'COMPLETE',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
              color: kPrimaryDark,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              3,
              (i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Icon(
                  Icons.star_rounded,
                  size: 34,
                  color: i < stars ? kGold : const Color(0xFFD9DCE1),
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 88,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: strip.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) => ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 88,
                  height: 88,
                  child: LessonImage(lesson: strip[i], fit: BoxFit.cover),
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          FilledButton(
            onPressed: widget.onExit,
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: const Text(
              'CONTINUE',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _keyboard() {
    const rows = [
      ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
      ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'],
      ['Z', 'X', 'C', 'V', 'B', 'N', 'M'],
    ];
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 18),
        child: Column(
          children: [
            for (final row in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final k in row)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: SizedBox(
                          width: 32,
                          height: 40,
                          child: OutlinedButton(
                            onPressed: () => _key(k),
                            style: OutlinedButton.styleFrom(
                              minimumSize: Size.zero,
                              padding: EdgeInsets.zero,
                              foregroundColor: kInk,
                              side: const BorderSide(color: kLine),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(k, style: const TextStyle(fontSize: 14)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _backspace,
                  icon: const Icon(Icons.backspace_outlined, color: kMuted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
