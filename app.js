/* ============================================================
   Lingo Gold — Rosetta Style
   ملف الجافاسكريبت المسؤول عن:
   1) قراءة ملف data.rsd عبر fetch
   2) بناء 4 بطاقات تلقائياً
   3) ربط الصور من مجلد media/images
   4) التحقق الفوري من الإجابة عند الكتابة (حدث input)
   ============================================================ */

'use strict';

/*
  ملاحظة مهمة:
  لا تعمل دالة fetch مع ملفات file:// مباشرة.
  يجب تشغيل المشروع عبر خادم محلي، مثلاً:
  - في VS Code: انقر Big على "Go Live" (Live Server)
  - أو من الطرفية: npx serve .
  ثم افتح الرابط الذي يظهر (مثل http://localhost:5500)
*/
const DATA_URL = 'data.rsd';

// ---- عناصر الواجهة التي سنتعامل معها ----
const grid = document.getElementById('cardsGrid');
const statusBar = document.getElementById('statusBar');
const footerDots = document.getElementById('footerDots');
const resetBtn = document.getElementById('resetBtn');
const languageLabel = document.getElementById('languageLabel');
const breadcrumb = document.getElementById('breadcrumb');

// ---- متغيرات حالة بسيطة ----
let questions = []; // الأسئلة القادمة من ملف البيانات

/* ------------------------------------------------------------
   تنظيف النص للمقارنة (حروف صغيرة + إزالة مسافات زائدة)
------------------------------------------------------------ */
function normalize(value) {
  return String(value).trim().toLowerCase();
}

/* ------------------------------------------------------------
   نطق النص باستخدام Web Speech API المدمج في المتصفح
------------------------------------------------------------ */
function speak(text) {
  if (!('speechSynthesis' in window)) return;
  window.speechSynthesis.cancel(); // إيقاف أي نطق سابق

  const utterance = new SpeechSynthesisUtterance(text);
  utterance.lang = 'en-US';
  utterance.rate = 0.85; // سرعة مناسبة للتعلّم
  window.speechSynthesis.speak(utterance);
}

/* ------------------------------------------------------------
   تحديث نقاط الإنجاز في الشريط السفلي
------------------------------------------------------------ */
function updateFooterDots() {
  if (!footerDots) return;

  const correctCount = document.querySelectorAll('.card.correct').length;
  const dots = footerDots.querySelectorAll('.dot');

  dots.forEach((dot, index) => {
    dot.classList.toggle('done', index < correctCount);
  });
}

/* ------------------------------------------------------------
   بناء بطاقة واحدة من بيانات السؤال
------------------------------------------------------------ */
function createCard(item, index) {
  // الحاوية الأساسية للبطاقة
  const card = document.createElement('div');
  card.className = 'card';
  card.dataset.index = index;

  // ---- منطقة النص ----
  const textArea = document.createElement('div');
  textArea.className = 'card-text-area';

  const before = document.createElement('span');
  before.textContent = item.before + ' ';

  // خانة الفراغ (الإجابة تُكتب هنا)
  const blank = document.createElement('input');
  blank.type = 'text';
  blank.className = 'blank';
  blank.placeholder = '...';
  blank.autocomplete = 'off';
  blank.maxLength = 14;
  blank.setAttribute('aria-label', 'اكتب الإجابة');

  const after = document.createElement('span');
  after.textContent = ' ' + item.after;

  // زر الصوت
  const audioBtn = document.createElement('button');
  audioBtn.type = 'button';
  audioBtn.className = 'audio-btn';
  audioBtn.textContent = '▶';
  audioBtn.title = 'استمع إلى الكلمة';
  audioBtn.addEventListener('click', () => speak(item.audio || item.answer));

  textArea.append(before, blank, after, audioBtn);

  // ---- منطقة الصورة ----
  const imageArea = document.createElement('div');
  imageArea.className = 'card-image-area';

  const img = document.createElement('img');
  img.src = item.image;
  img.alt = item.answer;

  const successMark = document.createElement('div');
  successMark.className = 'success-mark';
  successMark.textContent = '✓';

  imageArea.append(img, successMark);

  // تجميع البطاقة
  card.append(textArea, imageArea);

  /* --------------------------------------------------------
     التحقق الفوري من الإجابة باستخدام حدث input
     - إذا كانت صحيحة: إطار أخضر + علامة ✓
     - إذا كانت خاطئة: إطار أحمر + اهتزاز
     - إذا كانت فارغة: إزالة كل التأثيرات
  -------------------------------------------------------- */
  blank.addEventListener('input', () => {
    const value = blank.value.trim();

    // حالة فارغة → لا يوجد تقييم بعد
    if (value === '') {
      card.classList.remove('correct', 'wrong');
      updateFooterDots();
      return;
    }

    const isCorrect = normalize(value) === normalize(item.answer);

    if (isCorrect) {
      card.classList.remove('wrong');
      card.classList.add('correct');
    } else {
      // إعادة تشغيل حركة الاهتزاز في كل محاولة خاطئة
      card.classList.remove('wrong');
      void card.offsetWidth; // إجبار المتصفح على إعادة الرسم
      card.classList.add('wrong');
    }

    updateFooterDots();
  });

  return card;
}

/* ------------------------------------------------------------
   رسم كل البطاقات + نقاط الحالة
------------------------------------------------------------ */
function render(data) {
  questions = data.questions || [];

  // تحديث العناوين من ملف البيانات إن وُجدت
  if (data.language) languageLabel.textContent = data.language;
  if (data.title) breadcrumb.textContent = data.title;

  // تنظيف الحاويات
  grid.innerHTML = '';
  statusBar.innerHTML = '';
  footerDots.innerHTML = '';

  // نقاط الشريط العلوي (واحدة نشطة حالياً)
  questions.forEach((_, i) => {
    const dot = document.createElement('div');
    dot.className = 'dot' + (i === 0 ? ' active' : '');
    statusBar.appendChild(dot);
  });

  // نقاط الشريط السفلي
  questions.forEach(() => {
    const dot = document.createElement('div');
    dot.className = 'dot';
    footerDots.appendChild(dot);
  });

  // بناء البطاقات
  questions.forEach((item, index) => {
    grid.appendChild(createCard(item, index));
  });
}

/* ------------------------------------------------------------
   قراءة ملف البيانات عبر fetch
------------------------------------------------------------ */
async function loadData() {
  const response = await fetch(DATA_URL);

  if (!response.ok) {
    throw new Error('تعذّر قراءة الملف: ' + response.status);
  }

  // نحاول تحليل الملف كـ JSON (حتى لو كان امتداده rsd)
  return await response.json();
}

/* ------------------------------------------------------------
   زر Reset: إفراغ كل الخانات وإزالة التقييمات
------------------------------------------------------------ */
if (resetBtn) {
  resetBtn.addEventListener('click', () => {
    document.querySelectorAll('.blank').forEach((input) => {
      input.value = '';
    });
    document.querySelectorAll('.card').forEach((card) => {
      card.classList.remove('correct', 'wrong');
    });
    updateFooterDots();
  });
}

/* ------------------------------------------------------------
   نقطة الدخول
------------------------------------------------------------ */
async function init() {
  try {
    const data = await loadData();
    render(data);
  } catch (error) {
    grid.innerHTML = '';
    const box = document.createElement('div');
    box.className = 'error-message';
    box.textContent =
      'لم يتم تحميل البيانات. تأكد من تشغيل المشروع عبر خادم محلي (Live Server). ' +
      'التفاصيل: ' + error.message;
    grid.appendChild(box);
    console.error(error);
  }
}

// تشغيل التهيئة بعد تجهيز الصفحة
init();
