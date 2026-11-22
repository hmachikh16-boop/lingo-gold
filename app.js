/* ============================================================
   Lingo Gold — Rosetta Style
   يقرأ الآن ملف data.rsd بالهيكل الجديد:
   units -> lessons -> exercises (أنواع: fill_blank / choose_image / choose_text)
   ============================================================ */

'use strict';

/*
  ملاحظة: استخدم خادماً محلياً (Live Server) لأن fetch لا يعمل مع file://
  مثال: http://localhost:8097
*/
const DATA_URL = 'data.rsd';

// عناصر الواجهة
const grid = document.getElementById('cardsGrid');
const statusBar = document.getElementById('statusBar');
const footerDots = document.getElementById('footerDots');
const resetBtn = document.getElementById('resetBtn');
const languageLabel = document.getElementById('languageLabel');
const breadcrumb = document.getElementById('breadcrumb');

let exercises = [];

/* تنظيف النص للمقارنة */
function normalize(value) {
  return String(value).trim().toLowerCase();
}

/* النطق باستخدام المتصفح */
function speak(text) {
  if (!('speechSynthesis' in window) || !text) return;
  window.speechSynthesis.cancel();
  const u = new SpeechSynthesisUtterance(String(text));
  u.lang = 'en-US';
  u.rate = 0.85;
  window.speechSynthesis.speak(u);
}

/* تحديث نقاط الإنجاز */
function updateFooterDots() {
  if (!footerDots) return;
  const correctCount = document.querySelectorAll('.card.correct').length;
  footerDots.querySelectorAll('.dot').forEach((dot, i) => {
    dot.classList.toggle('done', i < correctCount);
  });
}

/* تحويل الهيكل الجديد إلى قائمة تمرينات مسطّحة */
function collectExercises(data) {
  const list = [];
  (data.units || []).forEach((unit) => {
    (unit.lessons || []).forEach((lesson) => {
      (lesson.exercises || []).forEach((ex) => {
        list.push(Object.assign({}, ex, {
          unitId: unit.unitId,
          lessonId: lesson.lessonId
        }));
      });
    });
  });
  return list;
}

/* مساعدة: agricultural audio للتمرين */
function audioFor(ex) {
  if (ex.audio && !/\.mp3$/i.test(ex.audio)) return ex.audio;
  // لا يوجد ملف صوت فعلي → ننطق النص
  if (ex.question) return ex.question;
  if (ex.sentence) return ex.sentence.replace('___', ex.answer || '');
  return ex.answer || '';
}

/* إنشاء بطاقة واحدة حسب نوع التمرين */
function createCard(ex, index) {
  const card = document.createElement('div');
  card.className = 'card';
  card.dataset.index = index;
  card.dataset.type = ex.type;

  const textArea = document.createElement('div');
  textArea.className = 'card-text-area';

  // زر الصوت المشترك
  const audioBtn = document.createElement('button');
  audioBtn.type = 'button';
  audioBtn.className = 'audio-btn';
  audioBtn.textContent = '▶';
  audioBtn.title = 'استمع';
  audioBtn.addEventListener('click', () => speak(audioFor(ex)));

  let blank = null;
  let optionNodes = [];

  if (ex.type === 'fill_blank') {
    // تقسيم الجملة عند الفراغ
    const parts = String(ex.sentence).split('___');
    const before = document.createElement('span');
    before.textContent = parts[0] || '';
    blank = document.createElement('input');
    blank.type = 'text';
    blank.className = 'blank';
    blank.placeholder = '...';
    blank.autocomplete = 'off';
    blank.maxLength = 14;
    blank.setAttribute('aria-label', 'اكتب الإجابة');
    const after = document.createElement('span');
    after.textContent = parts[1] || '';
    textArea.append(before, blank, after, audioBtn);

    blank.addEventListener('input', () => {
      const value = blank.value.trim();
      if (value === '') {
        card.classList.remove('correct', 'wrong');
        updateFooterDots();
        return;
      }
      if (normalize(value) === normalize(ex.answer)) {
        card.classList.remove('wrong');
        card.classList.add('correct');
      } else {
        card.classList.remove('wrong');
        void card.offsetWidth; // إعادة تشغيل الاهتزاز
        card.classList.add('wrong');
      }
      updateFooterDots();
    });
  } else if (ex.type === 'choose_image') {
    const q = document.createElement('div');
    q.className = 'question-text';
    q.textContent = ex.question || 'Choose the matching image';
    textArea.append(q, audioBtn);
  } else {
    // choose_text
    const q = document.createElement('div');
    q.className = 'question-text';
    q.textContent = 'Choose the correct sentence';
    textArea.append(q, audioBtn);
  }

  card.appendChild(textArea);

  /* ===== منطقة المحتوى ===== */
  const body = document.createElement('div');
  body.className = 'card-body';

  if (ex.type === 'fill_blank') {
    const imageArea = document.createElement('div');
    imageArea.className = 'card-image-area';
    const img = document.createElement('img');
    img.src = ex.image;
    img.alt = ex.answer;
    const mark = document.createElement('div');
    mark.className = 'success-mark';
    mark.textContent = '✓';
    imageArea.append(img, mark);
    body.appendChild(imageArea);
  } else if (ex.type === 'choose_image') {
    const opts = document.createElement('div');
    opts.className = 'options-grid image-options';
    (ex.options || []).forEach((src) => {
      const btn = document.createElement('button');
      btn.type = 'button';
      btn.className = 'option image-option';
      const img = document.createElement('img');
      img.src = src;
      img.alt = '';
      btn.appendChild(img);
      btn.addEventListener('click', () => {
        optionNodes.forEach((o) => o.classList.remove('selected', 'correct', 'wrong'));
        btn.classList.add('selected');
        const ok = src === ex.answer;
        btn.classList.add(ok ? 'correct' : 'wrong');
        card.classList.remove('correct', 'wrong');
        card.classList.add(ok ? 'correct' : 'wrong');
        updateFooterDots();
      });
      optionNodes.push(btn);
      opts.appendChild(btn);
    });
    body.appendChild(opts);
  } else {
    // choose_text: صورة + خيارات نصية
    const imageArea = document.createElement('div');
    imageArea.className = 'card-image-area small';
    const img = document.createElement('img');
    img.src = ex.image;
    img.alt = '';
    imageArea.appendChild(img);
    body.appendChild(imageArea);

    const opts = document.createElement('div');
    opts.className = 'options-grid text-options';
    (ex.options || []).forEach((text) => {
      const btn = document.createElement('button');
      btn.type = 'button';
      btn.className = 'option text-option';
      btn.textContent = text;
      btn.addEventListener('click', () => {
        optionNodes.forEach((o) => o.classList.remove('selected', 'correct', 'wrong'));
        btn.classList.add('selected');
        const ok = text === ex.answer;
        btn.classList.add(ok ? 'correct' : 'wrong');
        card.classList.remove('correct', 'wrong');
        card.classList.add(ok ? 'correct' : 'wrong');
        updateFooterDots();
      });
      optionNodes.push(btn);
      opts.appendChild(btn);
    });
    body.appendChild(opts);
  }

  card.appendChild(body);
  return card;
}

/* رسم كل التمرينات */
function render(data) {
  exercises = collectExercises(data);
  const firstUnit = (data.units || [])[0];
  if (firstUnit) {
    if (languageLabel) languageLabel.textContent = 'English (American)';
    if (breadcrumb) {
      breadcrumb.textContent = firstUnit.title + ' > ' +
        ((firstUnit.lessons || [])[0] ? firstUnit.lessons[0].title : '');
    }
  }

  grid.innerHTML = '';
  statusBar.innerHTML = '';
  footerDots.innerHTML = '';

  exercises.forEach((_, i) => {
    const dot = document.createElement('div');
    dot.className = 'dot' + (i === 0 ? ' active' : '');
    statusBar.appendChild(dot);

    const fdot = document.createElement('div');
    fdot.className = 'dot';
    footerDots.appendChild(fdot);
  });

  exercises.forEach((ex, i) => grid.appendChild(createCard(ex, i)));
}

/* قراءة البيانات */
async function loadData() {
  const res = await fetch(DATA_URL);
  if (!res.ok) throw new Error('تعذّر قراءة الملف: ' + res.status);
  return await res.json();
}

/* زر Reset */
if (resetBtn) {
  resetBtn.addEventListener('click', () => {
    document.querySelectorAll('.blank').forEach((i) => { i.value = ''; });
    document.querySelectorAll('.option').forEach((o) => o.classList.remove('selected', 'correct', 'wrong'));
    document.querySelectorAll('.card').forEach((c) => c.classList.remove('correct', 'wrong'));
    updateFooterDots();
  });
}

/* نقطة الدخول */
async function init() {
  try {
    const data = await loadData();
    render(data);
  } catch (error) {
    grid.innerHTML = '';
    const box = document.createElement('div');
    box.className = 'error-message';
    box.textContent = 'لم يتم تحميل البيانات. شغّل المشروع عبر خادم محلي (Live Server). ' + error.message;
    grid.appendChild(box);
    console.error(error);
  }
}

init();
