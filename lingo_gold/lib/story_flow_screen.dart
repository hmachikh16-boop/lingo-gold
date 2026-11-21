import 'dart:math';

import 'package:flutter/material.dart';

import 'data.dart';
import 'lesson_choice.dart';
import 'lesson_matching.dart';
import 'lesson_speaking.dart';
import 'lesson_writing.dart';
import 'services/sound_service.dart';
import 'services/speech_service.dart';
import 'theme.dart';
import 'widgets.dart';

enum _Challenge { listen, speak, write, choose, match }

/// تدفّق قصصي يحوّل الـ4 دروس إلى قصة واحدة متصلة:
/// غلاف → مشهد لكل درس مع تحدٍّ عشوائي واحد → خاتمة ونجوم.
class StoryFlowScreen extends StatefulWidget {
  final String storyId;
  final String storyTitle;
  final int level;
  final List<Lesson> lessons;
  final int savedStars;
  final VoidCallback onExit;
  final ValueChanged<int> onComplete;

  const StoryFlowScreen({
    super.key,
    required this.storyId,
    required this.storyTitle,
    required this.level,
    required this.lessons,
    this.savedStars = 0,
    required this.onExit,
    required this.onComplete,
  });

  @override
  State<StoryFlowScreen> createState() => _StoryFlowScreenState();
}

class _StoryFlowScreenState extends State<StoryFlowScreen> {
  // 0 = غلاف القصة، 1 = تحدّي الدرس، 2 = الخاتمة
  int _phase = 0;
  int _index = 0;
  int _hearts = 3;
  int _combo = 0;
  int _bestCombo = 0;
  int _correct = 0;
  bool _feedback = false;
  bool _lastCorrect = false;
  bool _completed = false;
  late _Challenge _challenge;

  final Random _random = Random(DateTime.now().millisecondsSinceEpoch);

  Lesson get _lesson => widget.lessons[_index];

  List<Lesson> get _others => widget.lessons
      .where((l) => !identical(l, _lesson))
      .toList();

  int get _stars {
    if (_hearts == 3 && _correct == widget.lessons.length) return 3;
    if (_hearts >= 2) return 2;
    return 1;
  }

  @override
  void initState() {
    super.initState();
    _pickChallenge();
  }

  void _pickChallenge() {
    _challenge = _Challenge.values[_random.nextInt(_Challenge.values.length)];
  }

  void _finish(bool correct) {
    if (_feedback) return;
    setState(() {
      _feedback = true;
      _lastCorrect = correct;
      if (correct) {
        _combo += 1;
        _correct += 1;
        if (_combo > _bestCombo) _bestCombo = _combo;
      } else {
        _combo = 0;
        if (_hearts > 0) _hearts -= 1;
      }
    });
    if (correct) {
      SoundService.instance.playCorrect();
    } else {
      SoundService.instance.playError();
    }
  }

  void _next() {
    if (!_feedback) return;
    if (_index + 1 < widget.lessons.length) {
      setState(() {
        _index += 1;
        _feedback = false;
        _pickChallenge();
      });
      return;
    }
    if (!_completed) {
      _completed = true;
      widget.onComplete(_stars);
    }
    setState(() => _phase = 2);
  }

  void _speak(Lesson l) => TtsService.instance.speak(l.spokenText);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _phase == 0
            ? _buildCover()
            : _phase == 2
                ? _buildEnding()
                : _buildChallengePhase(),
      ),
    );
  }

  Widget _buildCover() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _circleIcon(Icons.auto_stories_rounded, kPrimary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.storyTitle,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: kInk,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'المستوى ${widget.level} • ${widget.lessons.length} مشاهد • تحدٍّ مختلف في كل مشهد',
            style: const TextStyle(fontSize: 12, color: kMuted),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 108,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.lessons.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final l = widget.lessons[i];
                return ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 108,
                    height: 108,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        LessonImage(lesson: l, fit: BoxFit.cover),
                        Positioned(
                          bottom: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.92),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: kInk,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kSoftGreen,
              borderRadius: BorderRadius.circular(kRadius),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'أفضل نتيجة',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: kInk,
                    ),
                  ),
                ),
                StarRow(filled: widget.savedStars, size: 20),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => setState(() => _phase = 1),
            child: const Text('ابدأ القصة'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: widget.onExit,
            child: const Text('رجوع للخريطة'),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengePhase() {
    final l = _lesson;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.storyTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: kInk,
                      ),
                    ),
                    Text(
                      'المشهد ${_index + 1} من ${widget.lessons.length}',
                      style: const TextStyle(fontSize: 11, color: kMuted),
                    ),
                  ],
                ),
              ),
              if (_combo > 1)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: kSoftOrange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'كومبو ×$_combo',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFB45309),
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              Row(
                children: List.generate(
                  3,
                  (i) => Icon(
                    i < _hearts ? Icons.favorite_rounded : Icons.favorite_border,
                    size: 18,
                    color: i < _hearts ? kDanger : kLine,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 132,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  LessonImage(lesson: l, fit: BoxFit.cover),
                  Positioned(
                    left: 10,
                    bottom: 10,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: () => _speak(l),
                        icon: const Icon(Icons.volume_up_rounded, color: kPrimary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _feedback
              ? SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: _buildFeedback(l),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildChallengeWidget(),
                ),
        ),
      ],
    );
  }

  Widget _buildChallengeWidget() {
    final l = _lesson;
    final others = _others;
    switch (_challenge) {
      case _Challenge.listen:
        return ListeningStep(
          lesson: l,
          distractors: others.take(3).toList(),
          onComplete: _finish,
          showTranslation: false,
        );
      case _Challenge.speak:
        return SpeakingStep(
          lesson: l,
          onComplete: (correct, _) => _finish(correct),
          showTranslation: false,
        );
      case _Challenge.write:
        return WritingStep(
          lesson: l,
          targetWord: l.word,
          onComplete: _finish,
        );
      case _Challenge.choose:
        return ChooseStep(
          lesson: l,
          distractors: others.take(3).toList(),
          onComplete: _finish,
        );
      case _Challenge.match:
        return MatchingStep(
          lesson: l,
          distractors: others.take(2).toList(),
          onComplete: _finish,
        );
    }
  }

  Widget _buildFeedback(Lesson l) {
    final last = _index + 1 >= widget.lessons.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _lastCorrect ? kSoftGreen : kSoftRed,
            borderRadius: BorderRadius.circular(kRadius),
          ),
          child: Column(
            children: [
              Icon(
                _lastCorrect ? Icons.check_circle_rounded : Icons.info_rounded,
                size: 34,
                color: _lastCorrect ? kPrimary : kDanger,
              ),
              const SizedBox(height: 6),
              Text(
                _lastCorrect ? 'أحسنت! إجابة صحيحة' : 'لا بأس، خسرت قلبًا',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: _lastCorrect ? kPrimaryDark : kDanger,
                ),
              ),
              if (_combo > 1)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'كومبو ×$_combo — استمر!',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: kPrimary,
                    ),
                  ),
                ),
              if (l.translation.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  l.translation,
                  style: const TextStyle(fontSize: 14, color: kInk),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: _next,
          child: Text(last ? 'أنهِ القصة' : 'المشهد التالي'),
        ),
      ],
    );
  }

  Widget _buildEnding() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.emoji_events_rounded,
            size: 56,
            color: kGold,
          ),
          const SizedBox(height: 10),
          const Text(
            'أكملت القصة!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: kInk,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.storyTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: kMuted),
          ),
          const SizedBox(height: 18),
          Center(child: StarRow(filled: _stars, size: 34)),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _stat('$_correct/${widget.lessons.length}', 'إجابات صحيحة'),
              const SizedBox(width: 24),
              _stat('×$_bestCombo', 'أفضل كومبو'),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.lessons.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final l = widget.lessons[i];
                return GestureDetector(
                  onTap: () => _speak(l),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 92,
                      height: 92,
                      child: LessonImage(lesson: l, fit: BoxFit.cover),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'اضغط على أي صورة لسماع جملتها مرة أخرى',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: kMuted),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: widget.onExit,
            child: const Text('العودة للخريطة'),
          ),
        ],
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: kPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: kMuted)),
      ],
    );
  }

  Widget _circleIcon(IconData icon, Color color) {
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: color),
    );
  }
}
