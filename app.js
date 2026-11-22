/* ============================================================
   Lingo Gold — Immersion Engine
   Photo-led, audio-first lessons. Gamification stays secondary.
   ============================================================ */
(function () {
  'use strict';

  var C = window.IMS_CURRICULUM;
  var STORE = 'lingo_gold_immersion_v1';
  var FALLBACK = "data:image/svg+xml;utf8," + encodeURIComponent(
    '<svg xmlns="http://www.w3.org/2000/svg" width="640" height="440"><rect width="640" height="440" fill="#eceff1"/><text x="50%" y="50%" dominant-baseline="middle" text-anchor="middle" fill="#9aa4ad" font-family="sans-serif" font-size="20">Image unavailable</text></svg>'
  );
  var SRS = [1, 2, 4, 8, 16, 32];
  var ACH = [
    { id: 'first', ic: '🌱', ar: 'أول درس', d: 'أكمل أول درس', t: function (s, n) { return n >= 1; } },
    { id: 'five', ic: '📖', ar: 'خمسة دروس', d: 'أتقن 5 دروس', t: function (s, n) { return n >= 5; } },
    { id: 'twelve', ic: '🌿', ar: 'A1 مكتمل', d: 'أتقن 12 درسًا', t: function (s, n) { return n >= 12; } },
    { id: 'twentyfour', ic: '🌳', ar: 'نصف الطريق', d: 'أتقن 24 درسًا', t: function (s, n) { return n >= 24; } },
    { id: 'all', ic: '🏔', ar: 'كل الدروس', d: 'أتقن 48 درسًا', t: function (s, n) { return n >= 48; } },
    { id: 'speaker', ic: '🎙', ar: 'صوت واثق', d: 'تحدث في 10 دروس', t: function (s) { return s.stats.speaking >= 10; } },
    { id: 'reviewer', ic: '🔁', ar: 'مراجع', d: 'أكمل 10 مراجعات', t: function (s) { return s.stats.reviews >= 10; } },
    { id: 'units', ic: '🧩', ar: 'اختبارات الوحدات', d: 'اجتز كل اختبارات الوحدات', t: function (s) { return C.levels.every(function (l) { return l.units.every(function (u) { return s.tests['U-' + u.id] && s.tests['U-' + u.id].pass; }); }); } },
    { id: 'levels', ic: '🎓', ar: 'المستويات', d: 'اجتز اختبارات المستويات', t: function (s) { return C.levels.every(function (l) { return s.tests['L-' + l.id] && s.tests['L-' + l.id].pass; }); } },
    { id: 'week', ic: '🗓', ar: '/spotdefined', d: 'تعلّم 7 أيام متتالية', t: function (s) { return s.streak.count >= 7; } }
  ];
  ACH[9].ar = 'أسبوع تعلّم';

  var DEF = {
    v: 1, xp: 0, lessons: {}, tests: {}, ach: [],
    streak: { count: 0, last: '' },
    stats: { speaking: 0, reviews: 0 }, theme: 'light'
  };

  var state, ui = {
    level: 0, unit: 0, view: 'dashboard',
    lesson: null, stage: 0, passed: false, heard: false,
    match: { photo: null, done: {} },
    test: null, qi: 0, ans: []
  };
  var $ = function (id) { return document.getElementById(id); };

  /* ---------- state ---------- */
  function load() {
    var s = JSON.parse(JSON.stringify(DEF));
    try {
      var raw = localStorage.getItem(STORE);
      if (raw) {
        var old = JSON.parse(raw);
        Object.keys(s).forEach(function (k) { if (old[k] !== undefined) s[k] = old[k]; });
        s.streak = Object.assign({}, DEF.streak, old.streak || {});
        s.stats = Object.assign({}, DEF.stats, old.stats || {});
      }
    } catch (e) { console.warn('Progress read failed', e); }
    return s;
  }
  function save() { try { localStorage.setItem(STORE, JSON.stringify(state)); } catch (e) { console.warn('Progress save failed', e); } }
  function mastered(id) { return !!(state.lessons[id] && state.lessons[id].done); }
  function due(id) { var r = state.lessons[id]; return !!(r && r.done && r.due && r.due <= Date.now()); }
  function rec(id) { return state.lessons[id] || (state.lessons[id] = { done: false, reps: 0, due: 0, at: 0 }); }
  function masteredCount() { return Object.keys(state.lessons).filter(function (k) { return mastered(k); }).length; }
  function touch() {
    var t = new Date().toISOString().slice(0, 10);
    var y = new Date(Date.now() - 86400000).toISOString().slice(0, 10);
    if (state.streak.last === t) return;
    state.streak.count = state.streak.last === y ? state.streak.count + 1 : 1;
    state.streak.last = t;
  }
  function toast(msg) {
    var el = $('toast'); el.textContent = msg; el.classList.add('show');
    clearTimeout(el._t); el._t = setTimeout(function () { el.classList.remove('show'); }, 2400);
  }
  function fb(msg, kind) { var e = $('feedback'); e.textContent = msg || ''; e.className = 'feedback' + (kind ? ' ' + kind : ''); }
  function gate(on) { ui.passed = !!on; $('nextBtn').disabled = !on; }
  function speak(text, btn) {
    if (!('speechSynthesis' in window)) { toast('هذا المتصفح لا يدعم النطق'); return; }
    try {
      speechSynthesis.cancel();
      var u = new SpeechSynthesisUtterance(String(text));
      u.lang = 'en-US'; u.rate = .88;
      if (btn) { btn.classList.add('playing'); setTimeout(function () { btn.classList.remove('playing'); }, 800); }
      u.onend = function () { if (btn) btn.classList.remove('playing'); };
      speechSynthesis.speak(u);
    } catch (e) { toast('تعذّر تشغيل الصوت'); }
  }
  function norm(s) { return String(s).toLowerCase().replace(/[.,!?؟،]/g, '').replace(/\s+/g, ' ').trim(); }
  function shuffle(a, seed) {
    var x = a.slice(), n = x.length; seed = seed || 1;
    while (n > 1) { seed = (seed * 9301 + 49297) % 233280; var i = Math.floor(seed / 233280 * n); n--; var t = x[n]; x[n] = x[i]; x[i] = t; }
    return x;
  }
  function img(src, cls) {
    var e = document.createElement('img');
    e.src = src || FALLBACK; if (cls) e.className = cls; e.alt = '';
    e.onerror = function () { e.onerror = null; e.src = FALLBACK; };
    return e;
  }

  /* ---------- progression ---------- */
  function levelOpen(li) { if (li === 0) return true; var t = state.tests['L-' + C.levels[li - 1].id]; return !!(t && t.pass); }
  function unitOpen(li, uiIdx) {
    if (!levelOpen(li)) return false;
    if (uiIdx === 0) return true;
    return C.levels[li].units[uiIdx - 1].lessons.every(function (l) { return mastered(l.id); });
  }
  function lessonOpen(l) {
    if (!unitOpen(l.levelIndex, l.unitIndex)) return false;
    if (l.lessonInUnit === 1) return true;
    var u = C.levels[l.levelIndex].units[l.unitIndex];
    return mastered(u.lessons[l.lessonInUnit - 2].id);
  }
  function unitTestOpen(u) { return u.lessons.every(function (l) { return mastered(l.id); }); }
  function levelTestOpen(lv) { return lv.units.every(function (u) { var t = state.tests['U-' + u.id]; return t && t.pass; }); }
  function nextLesson() { for (var i = 0; i < C.allLessons.length; i++) if (!mastered(C.allLessons[i].id)) return C.allLessons[i]; return null; }
  function achievements() {
    var n = masteredCount();
    ACH.forEach(function (a) {
      if (state.ach.indexOf(a.id) === -1 && a.t(state, n)) { state.ach.push(a.id); state.xp += 15; toast('✦ ' + a.ar); }
    });
  }
  function addXp(n) { state.xp += n; achievements(); save(); chrome(); }

  /* ---------- chrome ---------- */
  function chrome() {
    $('xpVal').textContent = state.xp;
    $('streakVal').textContent = state.streak.count;
    $('themeBtn').textContent = state.theme === 'dark' ? '☀' : '☾';
    document.documentElement.setAttribute('data-theme', state.theme);
    $('profileText').textContent = masteredCount() + ' / ' + C.allLessons.length + ' درسًا متقنًا';
    $('profileBar').style.width = (masteredCount() / C.allLessons.length * 100) + '%';
    $('achCount').textContent = state.ach.length + ' / ' + ACH.length;
    var d = C.allLessons.filter(function (l) { return due(l.id); }).length;
    $('reviewCount').textContent = d;
  }
  function sidebar() {
    var box = $('levelNav'); box.innerHTML = '';
    C.levels.forEach(function (lv, li) {
      var open = levelOpen(li);
      var item = document.createElement('div'); item.className = 'level-item' + (li === ui.level ? ' open' : '');
      var b = document.createElement('button');
      b.className = 'level-btn' + (li === ui.level ? ' active' : '');
      b.innerHTML = '<span class="level-dot" style="background:' + lv.color + '"></span><span>' + lv.name + '</span><small>' + (open ? lv.en : '🔒') + '</small>';
      b.onclick = function () {
        if (!open) { toast('اجتز اختبار المستوى السابق أولًا'); return; }
        ui.level = li; ui.unit = 0; sidebar(); dashboard();
      };
      item.appendChild(b);
      var ul = document.createElement('div'); ul.className = 'unit-list';
      lv.units.forEach(function (u, uidx) {
        var ub = document.createElement('button');
        ub.className = 'unit-btn' + (uidx === ui.unit && li === ui.level ? ' active' : '');
        var done = u.lessons.filter(function (l) { return mastered(l.id); }).length;
        ub.innerHTML = '<span>' + (unitOpen(li, uidx) ? '' : '🔒 ') + u.titleAr + '</span><span>' + done + '/4</span>';
        ub.onclick = function () {
          if (!unitOpen(li, uidx)) { toast('أكمل الوحدة السابقة أولًا'); return; }
          ui.level = li; ui.unit = uidx; sidebar(); dashboard();
        };
        ul.appendChild(ub);
      });
      item.appendChild(ul); box.appendChild(item);
    });
  }
  function view(name) {
    ui.view = name;
    ['dashboard', 'lesson', 'review', 'ach', 'test'].forEach(function (v) {
      var el = $(v + 'View'); if (el) el.classList.toggle('active', v === name);
    });
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }
  function go(name) {
    view(name);
    if (name === 'dashboard') { sidebar(); dashboard(); }
    if (name === 'review') reviews();
    if (name === 'ach') achView();
  }

  /* ---------- dashboard ---------- */
  function dashboard() {
    var lv = C.levels[ui.level], u = lv.units[ui.unit];
    $('crumbLevel').textContent = lv.name + ' · ' + u.titleEn;
    $('dashTitle').textContent = u.titleAr;
    $('dashSub').textContent = lv.desc;
    $('levelBadge').textContent = lv.en;
    var grid = $('lessonGrid'); grid.innerHTML = '';
    u.lessons.forEach(function (l) {
      var m = mastered(l.id), open = lessonOpen(l);
      var card = document.createElement('div');
      card.className = 'lesson-card' + (open ? ' open' : ' locked') + (m ? ' done' : '');
      card.innerHTML = '<span class="mark' + (m ? ' done' : '') + '">' + (m ? '✓' : (open ? '' : '🔒')) + '</span>' +
        '<img class="lesson-thumb" src="' + l.image + '" alt="">' +
        '<div class="lesson-body"><div class="lesson-num">LESSON ' + String(l.index + 1).padStart(2, '0') + '</div>' +
        '<h3>' + l.titleAr + '</h3><div class="eng">' + l.titleEn + '</div>' +
        '<div class="lesson-foot"><span>' + (l.category) + '</span><span>' + (m ? 'متقن' : '8 مراحل') + '</span></div></div>';
      var im = card.querySelector('img'); im.onerror = function () { im.onerror = null; im.src = FALLBACK; };
      card.onclick = function () { if (open) openLesson(l); else toast('أكمل الدرس السابق أولًا'); };
      grid.appendChild(card);
    });
    var strip = $('testStrip'); strip.innerHTML = '';
    [['U-' + u.id, unitTestOpen(u), 'اختبار الوحدة', u.titleAr, 'unit'],
     ['L-' + lv.id, levelTestOpen(lv) && levelOpen(ui.level), 'اختبار المستوى', lv.name, 'level']].forEach(function (t) {
      var r = state.tests[t[0]], tile = document.createElement('div');
      tile.className = 'test-tile' + (t[1] && !(r && r.pass) ? ' ready' : '');
      tile.innerHTML = '<div><h3>' + t[2] + '</h3><p>' + t[3] + '</p></div>' +
        '<button class="btn-soft">' + ((r && r.pass) ? '✓ ' + r.score + '%' : (t[1] ? 'ابدأ' : '🔒')) + '</button>';
      if (t[1] && !(r && r.pass)) tile.querySelector('button').onclick = function () { startTest(t[4]); };
      strip.appendChild(tile);
    });
    chrome();
  }

  /* ---------- lesson: 8 connected stages ---------- */
  function openLesson(l) {
    if (!lessonOpen(l)) return;
    ui.lesson = l; ui.stage = 0; ui.match = { photo: null, done: {} };
    view('lesson'); renderStage();
  }
  var STAGE_AR = ['ملاحظة', 'استماع', 'فهم', 'اختيار الصورة', 'ربط الجمل', 'تكوين الجمل', 'التحدث', 'مراجعة'];
  function renderStage() {
    var l = ui.lesson, s = ui.stage;
    ui.passed = false; $('nextBtn').disabled = true; fb('');
    var dots = $('stageDots'); dots.innerHTML = '';
    C.stages.forEach(function (_, i) {
      var d = document.createElement('span');
      d.className = 'stage-dot' + (i < s ? ' done' : '') + (i === s ? ' current' : '');
      dots.appendChild(d);
    });
    $('stageLabel').textContent = (s + 1) + ' / 8 · ' + STAGE_AR[s];
    $('lessonTitle').textContent = l.titleAr + ' · ' + l.titleEn;
    var host = $('stageArea'); host.innerHTML = '';
    $('stepHint').textContent = '';

    if (s === 0) stageObserve(host, l);
    else if (s === 1) stageListen(host, l);
    else if (s === 2) stageUnderstand(host, l);
    else if (s === 3) stageSelect(host, l);
    else if (s === 4) stageMatch(host, l);
    else if (s === 5) stageBuild(host, l);
    else if (s === 6) stageSpeak(host, l);
    else stageReview(host, l);
  }

  function hero(host, src, sentence, withSound) {
    var f = document.createElement('div'); f.className = 'stage-frame';
    f.appendChild(img(src, 'hero-photo'));
    var bar = document.createElement('div'); bar.className = 'hero-bar';
    var txt = document.createElement('div'); txt.className = 'hero-sentence eng'; txt.textContent = sentence;
    bar.appendChild(txt);
    if (withSound) {
      var b = document.createElement('button'); b.className = 'sound-btn'; b.textContent = '🔊'; b.title = 'استمع';
      bar.appendChild(b); f._sound = b;
    }
    f.appendChild(bar); host.appendChild(f); return f;
  }
  function instruction(host, text) {
    var d = document.createElement('div'); d.className = 'stage-body';
    var p = document.createElement('div'); p.className = 'stage-instruction'; p.textContent = text;
    d.appendChild(p); host.appendChild(d); return d;
  }
  function photos(host, items, answerIdx, onPick, cols) {
    var wrap = document.createElement('div'); wrap.className = cols ? 'match-columns' : 'photo-grid';
    var grid = document.createElement('div'); grid.className = 'photo-grid';
    items.forEach(function (src, i) {
      var b = document.createElement('button'); b.className = 'photo-tile'; b.appendChild(img(src));
      b.onclick = function () {
        if (b.dataset.lock) return;
        [].slice.call(grid.children).forEach(function (x) { x.dataset.lock = '1'; x.classList.remove('correct', 'wrong'); });
        var ok = onPick(i, src);
        b.classList.add(ok ? 'correct' : 'wrong');
        gate(ok);
        fb(ok ? 'أحسنت.' : 'تأمّل الصورة ثم حاولagain.', ok ? 'good' : 'bad');
      };
      grid.appendChild(b);
    });
    wrap.appendChild(grid); host.appendChild(wrap); return wrap;
  }
  function sentences(host, options, answerIdx, onPick) {
    var wrap = document.createElement('div'); wrap.className = 'sentence-list';
    options.forEach(function (txt, i) {
      var b = document.createElement('button'); b.className = 'sentence-choice'; b.textContent = txt;
      b.onclick = function () {
        if (b.dataset.lock) return;
        [].slice.call(wrap.children).forEach(function (x) { x.dataset.lock = '1'; x.classList.remove('correct', 'wrong'); });
        var ok = i === answerIdx;
        b.classList.add(ok ? 'correct' : 'wrong');
        if (onPick) onPick(txt);
        gate(ok); fb(ok ? 'فهمت المعنى من السياق.' : 'استمع مرة أخرى وحاول.', ok ? 'good' : 'bad');
      };
      wrap.appendChild(b);
    });
    host.appendChild(wrap); return wrap;
  }

  function stageObserve(host, l) {
    var f = hero(host, l.image, l.phrase, true);
    f._sound.onclick = function () { speak(l.phrase, f._sound); gate(true); fb('استمعت إلى الجملة. تابع.', 'good'); };
    var d = instruction(host, 'انظر إلى الصورة واستمع إلى الجملة الإنجليزية. لا تترجم — افهم من السياق.');
    var q = document.createElement('div'); q.className = 'stage-caption eng'; q.style.border = '0';
    q.textContent = l.question; d.appendChild(q);
    $('stepHint').textContent = 'اضغط زر الصوت لتفعيل المتابعة';
    speak(l.phrase, f._sound);
  }
  function stageListen(host, l) {
    var d = instruction(host, 'استمع جيدًا، ثم اختر الصورة التي تسمعها.');
    var b = document.createElement('button'); b.className = 'sound-btn'; b.style.margin = '0 auto 18px'; b.textContent = '🔊';
    d.appendChild(b); b.onclick = function () { speak(l.phrase, b); };
    photos(host, l.imageOptions.slice(0, 4), 0, function (i) { if (i === 0) speak(l.phrase); return i === 0; });
    speak(l.phrase);
  }
  function stageUnderstand(host, l) {
    var f = hero(host, l.image, '', false);
    f.querySelector('.hero-sentence').textContent = ' ';
    var d = instruction(host, 'أي جملة تصف هذه الصورة؟');
    sentences(host, l.phraseOptions, l.phraseAnswer, function (t) { speak(t); });
  }
  function stageSelect(host, l) {
    var f = hero(host, '', l.phrase, true);
    f._sound.onclick = function () { speak(l.phrase, f._sound); };
    f.querySelector('img').style.display = 'none';
    var d = instruction(host, l.question);
    photos(host, l.imageOptions.slice(0, 4), 0, function (i) { speak(l.phrase); return i === 0; });
    speak(l.phrase);
  }
  function stageMatch(host, l) {
    var d = instruction(host, 'اربط كل جملة بالصورة المناسبة: اختر صورة ثم الجملة.');
    var cols = document.createElement('div'); cols.className = 'match-columns';
    var left = document.createElement('div'); left.className = 'match-col';
    var right = document.createElement('div'); right.className = 'match-col';
    var pairs = shuffle(l.matchPairs, l.index + 5);
    var selected = null, doneCount = 0;
    pairs.forEach(function (p) {
      var im = img(p.image, 'match-photo');
      im.onclick = function () {
        if (im.dataset.done || doneCount === pairs.length) return;
        [].slice.call(left.children).forEach(function (x) { x.classList.remove('sel'); });
        im.classList.add('sel'); selected = { im: im, p: p };
      };
      left.appendChild(im);
    });
    shuffle(pairs.map(function (p) { return p.phrase; }), l.index + 9).forEach(function (txt) {
      var b = document.createElement('button'); b.className = 'sentence-choice'; b.textContent = txt;
      b.onclick = function () {
        if (b.dataset.done || !selected) { if (!selected) fb('اختر صورة أولًا.'); return; }
        var ok = selected.p.phrase === txt;
        selected.im.classList.add(ok ? 'ok' : 'wrong');
        b.classList.add(ok ? 'correct' : 'wrong');
        b.dataset.done = '1'; selected.im.dataset.done = '1';
        selected = null; doneCount++;
        if (doneCount === pairs.length) {
          gate(true); fb('تم ربط كل الجمل بنجاح.', 'good');
        } else fb(ok ? 'صحيح.' : 'حاول ربطًا آخر.', ok ? 'good' : 'bad');
      };
      right.appendChild(b);
    });
    cols.append(left, right); d.appendChild(cols);
  }
  function stageBuild(host, l) {
    hero(host, l.image, '', false).querySelector('.hero-sentence').textContent = ' ';
    var d = instruction(host, 'رتّب الكلمات لتكوين الجملة.');
    var line = document.createElement('div'); line.className = 'word-line eng';
    var bank = document.createElement('div'); bank.className = 'word-bank eng';
    var placed = [];
    shuffle(l.words.map(function (w, i) { return { w: w, i: i }; }), l.index + 3).forEach(function (t) {
      var b = document.createElement('button'); b.className = 'word'; b.textContent = t.w;
      b.onclick = function () { b.classList.add('used'); placed.push(t); draw(); };
      bank.appendChild(b);
    });
    function draw() {
      line.innerHTML = '';
      placed.forEach(function (t, j) {
        var c = document.createElement('button'); c.className = 'word placed'; c.textContent = t.w;
        c.onclick = function () {
          placed.splice(j, 1);
          var o = [].slice.call(bank.children).filter(function (x) { return x.textContent === t.w && x.classList.contains('used'); })[0];
          if (o) o.classList.remove('used'); draw();
        };
        line.appendChild(c);
      });
      var ok = placed.map(function (t) { return t.w; }).join(' ') === l.words.join(' ');
      gate(ok);
      if (ok) { fb('جملة صحيحة.', 'good'); speak(l.phrase); }
    }
    d.append(line, bank);
  }
  function stageSpeak(host, l) {
    hero(host, l.image, l.phrase, true)._sound.onclick = function () { speak(l.phrase); };
    var d = instruction(host, 'استمع ثم قل الجملة بصوت عالٍ.');
    var box = document.createElement('div'); box.className = 'speak-box';
    box.innerHTML = '<div class="target eng">' + l.phrase + '</div>' +
      '<button class="mic" id="micBtn">🎙 ابدأ التحدث</button>' +
      '<div class="meter"><span id="meterBar"></span></div>' +
      '<div class="mic-status" id="micStatus">اضغط وقل الجملة. إن لم يتوفر التعرف الصوتي، تدرب ثم أكّد.</div>' +
      '<button class="soft-btn" id="selfBtn">تدربت بصوت عالٍ (دون تقييم نطق)</button>';
    d.appendChild(box);
    $('micBtn').onclick = function () { listen(l); };
    $('selfBtn').onclick = function () {
      state.stats.speaking++; save(); gate(true);
      fb('تم تسجيل التدريب. لم يتم تقييم النطق تلقائيًا.', 'good');
    };
  }
  function listen(l) {
    var SR = window.SpeechRecognition || window.webkitSpeechRecognition;
    var btn = $('micBtn'), bar = $('meterBar'), st = $('micStatus');
    if (!SR) { st.textContent = 'التعرف الصوتي غير متاح هنا — استخدم زر التدريب الذاتي.'; fb('لا يمكن تقييم النطق في هذا المتصفح.', 'bad'); return; }
    try {
      var r = new SR(); r.lang = 'en-US'; r.interimResults = false;
      btn.classList.add('rec'); bar.style.width = '35%'; st.textContent = 'جارٍ الاستماع...';
      r.onresult = function (e) {
        btn.classList.remove('rec'); var said = e.results[0][0].transcript;
        bar.style.width = '100%'; st.textContent = 'سمعت: "' + said + '"';
        if (norm(said) === norm(l.phrase)) {
          state.stats.speaking++; save(); gate(true);
          fb('تم التعرف على الجملة بدقة: "' + said + '"', 'good');
        } else { gate(false); fb('حاول مرة أخرى بعد الاستماع للنموذج.', 'bad'); }
      };
      r.onerror = function (e) { btn.classList.remove('rec'); bar.style.width = '0%'; st.textContent = 'تعذّر الاستماع (' + (e.error || '') + ').'; fb('لم يتم تقييم النطق.', 'bad'); };
      r.onend = function () { btn.classList.remove('rec'); };
      r.start();
    } catch (e) { btn.classList.remove('rec'); st.textContent = 'تعذّر بدء الميكروفون.'; }
  }
  function stageReview(host, l) {
    var d = instruction(host, 'مراجعة سريعة قبل إتقان الدرس.');
    var pool = C.allLessons.slice(0, l.index).filter(function (x) { return mastered(x.id); });
    if (pool.length < 2) pool = C.allLessons.slice(Math.max(0, l.index - 6), l.index);
    var picks = pool.slice(-2); if (picks.length < 2) picks = [l, l];
    var done = 0, ok = 0;
    picks.forEach(function (p, k) {
      var card = document.createElement('div'); card.className = 'test-card';
      card.innerHTML = '<h3>' + (k + 1) + '. ' + p.titleAr + '</h3>';
      var grid = document.createElement('div'); grid.className = 'photo-grid';
      shuffle(p.imageOptions.slice(0, 4), p.index + k).forEach(function (src) {
        var b = document.createElement('button'); b.className = 'photo-tile'; b.appendChild(img(src));
        b.onclick = function () {
          if (b.dataset.lock) return;
          [].slice.call(grid.children).forEach(function (x) { x.dataset.lock = '1'; });
          done++; if (src === p.image) { ok++; b.classList.add('correct'); } else b.classList.add('wrong');
          if (done === picks.length) {
            if (ok === picks.length) { fb('مراجعة ممتازة — أكمل اختبار الإتقان.', 'good'); buildMaster(m, l); }
            else { gate(false); fb('راجع الصور ثم حاول.', 'bad'); }
          }
        };
        grid.appendChild(b);
      });
      card.appendChild(grid); d.appendChild(card);
    });
    // final mastery questions are appended after the review passes
    var m = document.createElement('div'); m.id = 'masterBox'; d.appendChild(m);
    $('stepHint').textContent = 'أجب عن المراجعة لفتح اختبار الإتقان';
  }
  function buildMaster(box, l) {
    var qs = [
      { label: 'اختر الصورة', prompt: l.phrase, options: shuffle(l.imageOptions.slice(0, 4), l.index + 31), answer: 0, type: 'image', correct: l.image },
      { label: 'اختر الجملة', prompt: l.question, options: shuffle(l.phraseOptions, l.index + 41), answer: 0, type: 'text', correct: l.phrase }
    ];
    var target = l.words.filter(function (w) { return norm(w).length > 2; })[0] || l.words[0];
    var others = C.allLessons.filter(function (x) { return x.index !== l.index; }).map(function (x) {
      return x.words.filter(function (w) { return norm(w).length > 2; })[0];
    }).filter(Boolean);
    var words = shuffle([target, others[(l.index * 3) % others.length], others[(l.index * 5 + 1) % others.length], others[(l.index * 7 + 2) % others.length]], l.index + 53);
    qs.push({ label: 'اختر الكلمة', prompt: l.phrase.replace(target, '____'), options: words, answer: words.indexOf(target), type: 'text', correct: target });
    var done = 0, ok = 0;
    var h = document.createElement('h3'); h.style.cssText = 'font-size:14px;margin:18px 0 10px'; h.textContent = 'إتقان الدرس — 3 أسئلة';
    box.appendChild(h);
    qs.forEach(function (q, qi) {
      var c = document.createElement('div'); c.className = 'test-card';
      c.innerHTML = '<h3>' + (qi + 1) + '. ' + q.label + '</h3><div class="eng" style="font-weight:700;margin-bottom:12px">' + q.prompt + '</div>';
      var wrap = document.createElement('div'); wrap.className = q.type === 'image' ? 'photo-grid' : 'sentence-list';
      q.options.forEach(function (opt, i) {
        var b = document.createElement('button');
        b.className = q.type === 'image' ? 'photo-tile' : 'sentence-choice';
        if (q.type === 'image') b.appendChild(img(opt)); else b.textContent = opt;
        b.onclick = function () {
          if (b.dataset.lock) return;
          [].slice.call(wrap.children).forEach(function (x) { x.dataset.lock = '1'; x.classList.remove('correct', 'wrong'); });
          done++;
          var right = q.type === 'image' ? opt === q.correct : i === q.answer;
          if (right) { ok++; b.classList.add('correct'); } else b.classList.add('wrong');
          if (done === qs.length) {
            if (ok === qs.length) { gate(true); fb('إتقان كامل.', 'good'); }
            else { gate(false); fb('أجب عن الثلاثة بشكل صحيح.', 'bad'); }
          }
        };
        wrap.appendChild(b);
      });
      c.appendChild(wrap); box.appendChild(c);
    });
    $('stepHint').textContent = 'أجب عن الأسئلة الثلاثة لإتقان الدرس';
  }
  function nextStage() {
    if (!ui.passed) return;
    if (ui.stage < 7) { ui.stage++; renderStage(); return; }
    var l = ui.lesson, r = rec(l.id);
    r.done = true; r.reps = 0; r.due = Date.now() + SRS[0] * 86400000; r.at = Date.now();
    touch(); addXp(12); save(); toast('تم إتقان الدرس');
    var nx = nextLesson();
    if (nx) { ui.level = nx.levelIndex; ui.unit = nx.unitIndex; }
    sidebar(); dashboard(); view('dashboard');
  }

  /* ---------- tests ---------- */
  function qFor(l, kind) {
    if (kind === 0) { var o = shuffle(l.imageOptions.slice(0, 4), l.index + 31); return { t: 'image', p: l.phrase, o: o, a: o.indexOf(l.image) }; }
    if (kind === 1) { var o = shuffle(l.phraseOptions, l.index + 41); return { t: 'text', p: l.question, o: o, a: o.indexOf(l.phrase) }; }
    var target = l.words.filter(function (w) { return norm(w).length > 2; })[0] || l.words[0];
    var others = C.allLessons.filter(function (x) { return x.index !== l.index; }).map(function (x) { return x.words.filter(function (w) { return norm(w).length > 2; })[0]; }).filter(Boolean);
    var o = shuffle([target, others[(l.index * 3) % others.length], others[(l.index * 5 + 1) % others.length]], l.index + 53);
    return { t: 'text', p: l.phrase.replace(target, '____'), o: o, a: o.indexOf(target) };
  }
  function startTest(type) {
    var lv = C.levels[ui.level];
    var src = type === 'unit' ? lv.units[ui.unit].lessons : C.allLessons.filter(function (l) { return l.levelIndex === ui.level; });
    var qs = shuffle(src, Date.now() % 997).slice(0, type === 'unit' ? 4 : 6).map(function (l, i) { return qFor(l, i % 3); });
    ui.test = { type: type, id: (type === 'unit' ? 'U-' + lv.units[ui.unit].id : 'L-' + lv.id), qs: qs, title: type === 'unit' ? 'اختبار الوحدة' : 'اختبار المستوى' };
    ui.qi = 0; ui.ans = []; view('test'); testQ();
  }
  function testQ() {
    var t = ui.test;
    if (ui.qi >= t.qs.length) { testDone(); return; }
    var q = t.qs[ui.qi];
    $('testTitle').textContent = t.title + ' — ' + (ui.qi + 1) + ' / ' + t.qs.length;
    var body = $('testBody'); body.innerHTML = '';
    var c = document.createElement('div'); c.className = 'test-card';
    c.innerHTML = '<h3>' + (q.t === 'image' ? 'اختر الصورة' : q.t === 'text' ? 'اختر الإجابة' : 'أكمل') + '</h3>' +
      '<div class="eng" style="font-size:18px;font-weight:700;margin-bottom:14px">' + q.p + '</div>';
    var w = document.createElement('div'); w.className = q.t === 'image' ? 'photo-grid' : 'sentence-list';
    q.o.forEach(function (opt, i) {
      var b = document.createElement('button'); b.className = q.t === 'image' ? 'photo-tile' : 'sentence-choice';
      if (q.t === 'image') b.appendChild(img(opt)); else b.textContent = opt;
      b.onclick = function () { ui.ans.push(i === q.a); ui.qi++; testQ(); };
      w.appendChild(b);
    });
    c.appendChild(w); body.appendChild(c);
  }
  function testDone() {
    var t = ui.test, good = ui.ans.filter(Boolean).length, pct = Math.round(good / t.qs.length * 100), pass = pct >= 75;
    var old = state.tests[t.id];
    if (pass && !(old && old.pass)) addXp(t.type === 'unit' ? 30 : 60);
    state.tests[t.id] = { pass: pass || (old && old.pass), score: Math.max(pct, old ? old.score : 0), at: Date.now() };
    touch(); save(); chrome();
    $('testTitle').textContent = t.title;
    $('testBody').innerHTML = '<div class="test-done"><div class="score">' + pct + '%</div>' +
      '<h3>' + (pass ? 'اجتزت الاختبار' : 'حاول مرة أخرى') + '</h3>' +
      '<p style="color:var(--muted);font-size:12px">' + good + ' من ' + t.qs.length + ' — تحتاج 75%</p>' +
      '<button class="continue" id="afterTest" style="margin-top:20px">العودة للمسار</button></div>';
    $('afterTest').onclick = function () { go('dashboard'); };
  }

  /* ---------- review / achievements ---------- */
  function reviews() {
    var dueL = C.allLessons.filter(function (l) { return due(l.id); });
    $('reviewSub').textContent = dueL.length + ' درسًا مستحقًا للمراجعة';
    var box = $('reviewList'); box.innerHTML = '';
    if (!dueL.length) { box.innerHTML = '<div class="review-row"><span>لا توجد مراجعات مستحقة الآن.</span></div>'; return; }
    dueL.slice(0, 20).forEach(function (l) {
      var row = document.createElement('div'); row.className = 'review-row';
      row.innerHTML = '<div><div class="eng">' + l.phrase + '</div><small>' + l.titleAr + '</small></div><button class="btn-soft">راجع</button>';
      row.querySelector('button').onclick = function () { reviewOne(l, row); };
      box.appendChild(row);
    });
  }
  function reviewOne(l, row) {
    var q = qFor(l, l.index % 2);
    row.innerHTML = '';
    var c = document.createElement('div'); c.className = 'test-card';
    c.innerHTML = '<h3>' + l.titleAr + '</h3><div class="eng" style="font-weight:700;margin-bottom:12px">' + q.p + '</div>';
    var w = document.createElement('div'); w.className = q.t === 'image' ? 'photo-grid' : 'sentence-list';
    q.o.forEach(function (opt, i) {
      var b = document.createElement('button'); b.className = q.t === 'image' ? 'photo-tile' : 'sentence-choice';
      if (q.t === 'image') b.appendChild(img(opt)); else b.textContent = opt;
      b.onclick = function () {
        var ok = i === q.a; b.classList.add(ok ? 'correct' : 'wrong');
        var r = rec(l.id);
        if (ok) { r.reps++; r.due = Date.now() + SRS[Math.min(r.reps - 1, SRS.length - 1)] * 86400000; state.stats.reviews++; addXp(4); toast('مراجعة ناجحة'); }
        else { r.reps = 0; r.due = Date.now() + 86400000; toast('ستعود المراجعة غدًا'); }
        save(); chrome(); reviews();
      };
      w.appendChild(b);
    });
    c.appendChild(w); row.appendChild(c);
  }
  function achView() {
    var g = $('achGrid'); g.innerHTML = '';
    ACH.forEach(function (a) {
      var got = state.ach.indexOf(a.id) !== -1;
      var d = document.createElement('div'); d.className = 'ach' + (got ? '' : ' locked');
      d.innerHTML = '<div class="ic">' + a.ic + '</div><h3>' + a.ar + '</h3><p>' + a.d + '</p>';
      g.appendChild(d);
    });
  }

  /* ---------- boot ---------- */
  function boot() {
    if (!C || !C.allLessons.length) {
      var e = $('errorBanner'); e.classList.add('show'); e.textContent = 'تعذّر تحميل المنهج.';
      $('loading').classList.add('hide'); return;
    }
    state = load();
    document.documentElement.setAttribute('data-theme', state.theme);
    $('themeBtn').onclick = function () { state.theme = state.theme === 'dark' ? 'light' : 'dark'; save(); chrome(); };
    $('nextBtn').onclick = nextStage;
    $('backBtn').onclick = function () { go('dashboard'); };
    $('navHome').onclick = function () { go('dashboard'); };
    $('navReview').onclick = function () { go('review'); };
    $('navAch').onclick = function () { go('ach'); };
    $('resetBtn').onclick = function () {
      if (!confirm('سيتم مسح كل التقدم. هل أنت متأكد؟')) return;
      localStorage.removeItem(STORE); state = load(); ui.level = 0; ui.unit = 0; go('dashboard'); toast('تمت إعادة الضبط');
    };
    chrome(); sidebar(); dashboard();
    setTimeout(function () { $('loading').classList.add('hide'); }, 300);
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', boot); else boot();
})();
