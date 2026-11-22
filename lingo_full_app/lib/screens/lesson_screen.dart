import 'dart:async';

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../core.dart';
import '../models/curriculum.dart';
import 'result_screen.dart';

class LessonScreen extends StatefulWidget {
  final Curriculum curriculum;
  final int lessonIndex;
  const LessonScreen({super.key, required this.curriculum, required this.lessonIndex});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> with TickerProviderStateMixin {
  late final AnimationController _entry;
  late final AnimationController _shake;
  late final Animation<Offset> _slide;
  late final Animation<double> _scale;
  late final Animation<double> _shakeValue;
  final ScrollController _numbers = ScrollController();
  final TextEditingController _write = TextEditingController();
  SpeechToText? _stt;

  int _index = 0;
  int _correctCount = 0;
  int? _selected;
  bool _checked = false;
  bool _isCorrect = false;
  bool _listening = false;
  String? _rating;
  String? _heard;

  List<LearnStep> get _steps => widget.curriculum.lessons[widget.lessonIndex].steps;
  LearnStep get _step => _steps[_index];
  String _t(String key) => widget.curriculum.t(key);

  @override
  void initState() {
    super.initState();
    _entry = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 320));
    _slide = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entry, curve: Curves.easeOut));
    _scale = Tween<double>(begin: 0.9, end: 1.0)
        .animate(CurvedAnimation(parent: _entry, curve: Curves.easeOut));
    _shakeValue = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -8), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8, end: 0), weight: 1),
    ]).animate(_shake);
    _entry.forward();
  }

  @override
  void dispose() {
    _entry.dispose();
    _shake.dispose();
    _write.dispose();
    _numbers.dispose();
    super.dispose();
  }

  void _replayEntry() {
    _entry.reset();
    _entry.forward();
    Future<void>.delayed(const Duration(milliseconds: 60), () {
      if (_numbers.hasClients) {
        _numbers.animateTo(
          (_index * 38.0).clamp(0, _numbers.position.maxScrollExtent),
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _listen() async {
    if (_listening) return;
    setState(() => _listening = true);
    final stt = _stt ??= SpeechToText();
    var ok = false;
    try {
      ok = await stt.initialize();
    } catch (_) {}
    if (!ok || !stt.isAvailable) {
      setState(() {
        _listening = false;
        _heard = '🎤 غير مدعوم — استعمل زر الاستماع';
      });
      return;
    }
    final completer = Completer<String?>();
    await stt.listen(
      onResult: (r) {
        if (r.finalResult && !completer.isCompleted) completer.complete(r.recognizedWords);
      },
      localeId: 'en-US',
      cancelOnError: true,
    );
    final heard = await completer.future.timeout(
      const Duration(seconds: 6),
      onTimeout: () => null,
    );
    await stt.stop();
    if (!mounted) return;
    final text = (heard ?? '').trim();
    final want = _step.word.toLowerCase().replaceAll(RegExp(r'[^a-z ]'), '').trim();
    final got = text.toLowerCase();
    final rating = text.isEmpty
        ? _t('try_again')
        : (got.contains(want) || want.contains(got))
            ? _t('perfect')
            : (got.length > 2 ? _t('good') : _t('try_again'));
    setState(() {
      _listening = false;
      _heard = text.isEmpty ? '' : '“$text”';
      _rating = rating;
    });
  }

  void _answer(bool correct) {
    setState(() {
      _checked = true;
      _isCorrect = correct;
    });
    _shake.forward(from: 0);
    Progress.instance.answer(_step.word, correct);
    if (correct) {
      _correctCount++;
      Future<void>.delayed(const Duration(milliseconds: 600), _next);
    } else {
      Future<void>.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        setState(() {
          _checked = false;
          _selected = null;
          _rating = null;
          _heard = null;
        });
      });
    }
  }

  void _check() {
    final type = _step.type;
    if (type == 'learn' || type == 'review') {
      _answer(true);
      return;
    }
    if (type == 'writing') {
      final got = _write.text.trim().toLowerCase().replaceAll(RegExp(r'[^a-z ]'), '');
      final want = _step.word.toLowerCase().replaceAll(RegExp(r'[^a-z ]'), '');
      _answer(got == want);
      return;
    }
    if (type == 'speaking') {
      if (_rating == null) return;
      _answer(_rating != _t('try_again'));
      return;
    }
    if (_selected == null) return;
    _answer(_selected == _step.correct);
  }

  void _next() {
    if (_index < _steps.length - 1) {
      setState(() {
        _index++;
        _selected = null;
        _checked = false;
        _isCorrect = false;
        _rating = null;
        _heard = null;
        _write.clear();
      });
      _replayEntry();
    } else {
      Progress.instance.completeLesson(widget.lessonIndex, _correctCount);
      openPage(
        context,
        ResultScreen(curriculum: widget.curriculum, lessonIndex: widget.lessonIndex),
      );
    }
  }

  Widget _photo(String file, {double height = 210}) => ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: Image.asset(
            'assets/images/$file',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: kGreenSoft,
              alignment: Alignment.center,
              child: const Text('🐶', style: TextStyle(fontSize: 60)),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final step = _step;
    final isImageChoice = step.type == 'listening' || step.type == 'reading';
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: kGreen,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.curriculum.lessons[widget.lessonIndex].title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up_rounded),
            onPressed: () => Tts.instance.speak(step.audioText),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(8),
          child: LinearProgressIndicator(
            value: (_index + 1) / _steps.length,
            backgroundColor: kLine,
            color: kGreen,
            minHeight: 8,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: AnimatedBuilder(
                animation: _shake,
                builder: (context, _) => Transform.translate(
                  offset: Offset(_shakeValue.value, 0),
                  child: SlideTransition(
                    position: _slide,
                    child: ScaleTransition(
                      scale: _scale,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
                        children: [
                          Text(
                            '${step.step} / ${_steps.length}  •  ${step.type}',
                            style: const TextStyle(fontSize: 11, color: kMuted, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _checked ? (_isCorrect ? kGreen : kWrong) : kLine,
                                width: _checked ? 3 : 1,
                              ),
                              boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 10)],
                            ),
                            child: Column(
                              children: [
                                if (step.type != 'writing') _photo(step.image),
                                const SizedBox(height: 14),
                                Text(
                                  step.type == 'choose_prompt' ? step.prompt : step.word,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: kInk),
                                ),
                                if (step.type == 'choose_prompt') ...[
                                  const SizedBox(height: 6),
                                  Text(step.prompt, style: const TextStyle(fontSize: 13, color: kMuted)),
                                ],
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      onPressed: () => Tts.instance.speak(step.audioText),
                                      icon: const Icon(Icons.volume_up_rounded, color: kGreen, size: 30),
                                      tooltip: _t('check'),
                                    ),
                                    const SizedBox(width: 18),
                                    GestureDetector(
                                      onTap: step.type == 'speaking' ? _listen : () => Tts.instance.speak(step.audioText),
                                      child: Container(
                                        width: 56,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color: _listening ? kGreenDark : kGreen,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(_listening ? Icons.graphic_eq : Icons.mic_rounded, color: Colors.white, size: 28),
                                      ),
                                    ),
                                  ],
                                ),
                                if (_heard != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(_heard!, style: const TextStyle(fontSize: 12, color: kMuted)),
                                  ),
                                if (_rating != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      '⭐ $_rating',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: _rating == _t('perfect') ? kGreen : (_rating == _t('good') ? kGreenDark : kWrong),
                                      ),
                                    ),
                                  ),
                                if (step.type == 'writing') ...[
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _write,
                                    textAlign: TextAlign.center,
                                    decoration: InputDecoration(
                                      hintText: step.hint,
                                      filled: true,
                                      fillColor: kCard,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kLine)),
                                    ),
                                  ),
                                ],
                                if (_checked)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: Text(
                                      _isCorrect ? '✅ ${_t('correct')}' : '❌ ${_t('wrong')}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: _isCorrect ? kGreen : kWrong,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (isImageChoice)
                            GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 2,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              childAspectRatio: 1.4,
                              children: [
                                for (var i = 0; i < step.options.length; i++)
                                  _optionTile(i, image: step.options[i]),
                              ],
                            )
                          else if (step.options.isNotEmpty)
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: [
                                for (var i = 0; i < step.options.length; i++)
                                  _optionTile(i, text: step.options[i]),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 52,
              child: ListView.builder(
                controller: _numbers,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: _steps.length,
                itemBuilder: (context, i) {
                  final done = i < _index;
                  final now = i == _index;
                  return Container(
                    width: 34,
                    alignment: Alignment.center,
                    child: Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: done ? kGreen : (now ? Colors.white : const Color(0xFFDDDDDD)),
                        borderRadius: BorderRadius.circular(9),
                        border: now ? Border.all(color: kInk, width: 2) : null,
                      ),
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: done ? Colors.white : (now ? kInk : kMuted),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _canContinue ? _check : null,
                  style: FilledButton.styleFrom(backgroundColor: kGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: Text(
                    step.type == 'speaking' ? _t('check') : _t('continue'),
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _canContinue {
    final type = _step.type;
    if (type == 'learn' || type == 'review') return true;
    if (type == 'speaking') return _rating != null;
    if (type == 'writing') return _write.text.trim().isNotEmpty;
    return _selected != null;
  }

  Widget _optionTile(int i, {String? text, String? image}) {
    final selected = _selected == i;
    final showCorrect = _checked && i == _step.correct;
    final showWrong = _checked && selected && !_isCorrect;
    return GestureDetector(
      onTap: _checked ? null : () => setState(() => _selected = i),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: showCorrect ? kGreenSoft : (selected ? kGreenSoft : Colors.white),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: showCorrect ? kGreen : (showWrong ? kWrong : (selected ? kGreen : kLine)),
            width: showCorrect || showWrong || selected ? 3 : 2,
          ),
        ),
        child: image != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  height: 78,
                  child: Image.asset(
                    'assets/images/$image',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(child: Text('🐱', style: TextStyle(fontSize: 36))),
                  ),
                ),
              )
            : Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(text ?? '', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                ),
              ),
      ),
    );
  }
}
