import 'package:flutter/material.dart';

import '../core.dart';
import '../models/curriculum.dart';

class MilestoneScreen extends StatefulWidget {
  final Curriculum curriculum;
  const MilestoneScreen({super.key, required this.curriculum});

  @override
  State<MilestoneScreen> createState() => _MilestoneScreenState();
}

class _MilestoneScreenState extends State<MilestoneScreen> {
  final _controller = TextEditingController();
  final _lines = <String>[];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _lines.add(text);
      _controller.clear();
    });
    Tts.instance.speak('Great! Let us continue.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: kGreen,
        foregroundColor: Colors.white,
        title: Text(widget.curriculum.t('milestone'), style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: kGreenSoft, borderRadius: BorderRadius.circular(14)),
                    child: const Text('Hello! Tell me about your family and your house.', style: TextStyle(fontSize: 15, color: kInk, height: 1.4)),
                  ),
                  const SizedBox(height: 12),
                  for (final line in _lines)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: kGreen, borderRadius: BorderRadius.circular(12)),
                        child: Text(line, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Type your answer…',
                        filled: true,
                        fillColor: kCard,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: kLine)),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: kGreen,
                    child: IconButton(icon: const Icon(Icons.send_rounded, color: Colors.white), onPressed: _send),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
