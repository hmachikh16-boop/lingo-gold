# Lingo Gold — Rosetta-style Flutter App

تطبيق تعليم لغة كامل بمنهج Rosetta، بصورك وصوتك، مع كل التحركات والتكرار المتباعد.

## التشغيل

```bash
flutter pub get
flutter run
```

## الهيكل

```
lib/
  main.dart                     App +.bottom navigation
  core.dart                     Palette, Progress, SRS, TTS
  models/
    curriculum.json             كل الدروس والكلمات والخيارات (لا كلمات داخل الكود)
    curriculum.dart             تحميل الـ JSON
  screens/
    lesson_screen.dart          شاشة الدرس + كل التحركات وأنواع الأسئلة السبعة
    result_screen.dart          نتيجة الدرس
    milestone_screen.dart       محادثة بعد 4 دروس
    app_screens.dart            Dashboard / Review / Settings / Leaderboard / Weekly
assets/
  images/                       الصور
  audio/                        ملفات الصوت (اختياري — التطبيق يستخدم TTS إن نقصت)
test/
  app_test.dart                 اختبارات المنهج والتقدم والتنقل
```

## المحتوى

- 4 دروس × 30 خطوة = **120 خطوة**.
- كل خطوة في `curriculum.json` فيها: `id, type, word, image, audio, audio_text, options, correct`.
- الأنواع: `choose_image`, `choose_prompt`, `listening`, `speaking`, `reading`, `writing`, `numbers`.
- التكرار المتباعد: **1 → 2 → 4 → 8 → 16 يوماً**.
- بعد كل 4 دروس: شاشة **Milestone**.

## كيف تبدّل صورة أو صوت أو كلمة في 3 خطوات

1. ضع الملف في `assets/images/` أو `assets/audio/`.
2. افتح `lib/models/curriculum.json` وبدّل الاسم أو الكلمة داخل الخطوة المطلوبة.
3. شغّل `flutter run` مرة أخرى.

مثال تبديل كلمة:

```json
{
  "id": "L1_S1",
  "type": "choose_image",
  "word": "Hello.",
  "image": "img_hello.jpg",
  "audio": "audio_hello.mp3",
  "audio_text": "Hello.",
  "options": ["Hello.", "Goodbye."],
  "correct": 0
}
```

> إن لم يوجد ملف الصوت، التطبيق ينطق `audio_text` تلقائياً عبر `flutter_tts`.

## الاختبارات

```bash
flutter test
```
