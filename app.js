/* ============================================================
   Lingo Gold — Immersion Engine
   Nine linked exercises inside a full-screen photo lesson.
   ============================================================ */
(function () {
  'use strict';
  var C = window.IMS_CURRICULUM;
  var KEY = 'lingo_gold_immersion_v1';
  var FALLBACK = "data:image/svg+xml;utf8," + encodeURIComponent(
    '<svg xmlns="http://www.w3.org/2000/svg" width="600" height="400"><rect width="600" height="400" fill="#eef0ef"/><text x="50%" y="50%" dominant-baseline="middle" text-anchor="middle" fill="#9aa5ad" font-family="sans-serif" font-size="18">Image</text></svg>'
  );
  var SRS = [1, 2, 4, 8, 16, 32];
  var NAMES = ['الملاحظة', 'الاستماع', 'ربط الصوت بالصورة', 'اختيار الصورة', 'فهم السياق', 'التعرف على الجملة', 'تكوين الجملة', 'النطق', 'المراجعة'];
  var $ = function (i) { return document.getElementById(i); };

  var state, ui = { level: 0, unit: 0, lesson: null, stage: 0, ok: false, match: null };
  var timer;

  function load() {
    var d = { v: 2, xp: 0, lessons: {}, tests: {}, streak: { count: 0, last: '' }, stats: { speaking: 0, reviews: 0 } };
    try {
      var raw = localStorage.getItem(KEY);
      if (raw) { var o = JSON.parse(raw); Object.keys(d).forEach(function (k) { if (o[k] !== undefined) d[k] = o[k]; }); }
    } catch (e) { console.warn('read failed', e); }
    return d;
  }
  function save() { try { localStorage.setItem(KEY, JSON.stringify(state)); } catch (e) { console.warn('save failed', e); } }
  function rec(id) { return state.lessons[id] || (state.lessons[id] = { done: false, reps: 0, due: 0, at: 0 }); }
  function done(id) { return !!(state.lessons[id] && state.lessons[id].done); }
  function due(id) { var r = state.lessons[id]; return !!(r && r.done && r.due && r.due <= Date.now()); }
  function doneCount() { return Object.keys(state.lessons).filter(done).length; }
  function touch() {
    var t = new Date().toISOString().slice(0, 10), y = new Date(Date.now() - 86400000).toISOString().slice(0, 10);
    if (state.streak.last !== t) { state.streak.count = state.streak.last === y ? state.streak.count + 1 : 1; state.streak.last = t; }
  }
  function toast(m) { var e = $('toast'); e.textContent = m; e.classList.add('show'); clearTimeout(timer); timer = setTimeout(function () { e.classList.remove('show'); }, 2200); }
  function note(m, k) { var e = $('lNote'); e.textContent = m || ''; e.className = 'note' + (k ? ' ' + k : ''); }
  function gate(v) { ui.ok = !!v; $('goBtn').disabled = !v; }
  function img(src) {
    var e = document.createElement('img'); e.src = src || FALLBACK; e.alt = '';
    e.onerror = function () { e.onerror = null; e.src = FALLBACK; }; return e;
  }
  function norm(s) { return String(s).toLowerCase().replace(/[.,!?]/g, '').replace(/\s+/g, ' ').trim(); }
  function shuffled(a, seed) {
    var x = a.slice(), n = x.length; seed = seed || 1;
    while (n > 1) { seed = (seed * 9301 + 49297) % 233280; var i = Math.floor(seed / 233280 * n); n--; var t = x[n]; x[n] = x[i]; x[i] = t; }
    return x;
  }
  function say(text, btn) {
    if (!('speechSynthesis' in window)) { toast('هذا المتصفح لا يدعم الصوت'); return; }
    try {
      speechSynthesis.cancel();
      var u = new SpeechSynthesisUtterance(String(text));
      u.lang = 'en-US'; u.rate = .9;
      if (btn) { btn.classList.add('playing'); u.onend = function () { btn.classList.remove('playing'); }; }
      speechSynthesis.speak(u);
    } catch (e) { toast('تعذّر تشغيل الصوت'); }
  }

  /* ---------- progression ---------- */
  function levelOpen(i) { if (i === 0) return true; var t = state.tests['L-' + C.levels[i - 1].id]; return !!(t && t.pass); }
  function unitOpen(li, uidx) {
    if (!levelOpen(li)) return false;
    if (uidx === 0) return true;
    return C.levels[li].units[uidx - 1].lessons.every(function (l) { return done(l.id); });
  }
  function lessonOpen(l) {
    if (!unitOpen(l.levelIndex, l.unitIndex)) return false;
    if (l.lessonInUnit === 1) return true;
    var u = C.levels[l.levelIndex].units[l.unitIndex];
    return done(u.lessons[l.lessonInUnit - 2].id);
  }
  function unitTest(u) { return u.lessons.every(function (l) { return done(l.id); }); }
  function levelTest(lv) { return lv.units.every(function (u) { var t = state.tests['U-' + u.id]; return t && t.pass; }); }
  function nextLesson() { for (var i = 0; i < C.allLessons.length; i++) if (!done(C.allLessons[i].id)) return C.allLessons[i]; return null; }

  /* ---------- home ---------- */
  function renderHome() {
    var lv = C.levels[ui.level], u = lv.units[ui.unit];
    $('homeProgress').textContent = doneCount() + ' / ' + C.allLessons.length;
    var sl = $('sideLevels'); sl.innerHTML = '';
    C.levels.forEach(function (l, i) {
      var b = document.createElement('button');
      b.className = 'lv' + (i === ui.level ? ' on' : '');
      b.innerHTML = '<span>' + (levelOpen(i) ? '' : '🔒 ') + l.name + '</span><small>' + l.ar + '</small>';
      b.onclick = function () {
        if (!levelOpen(i)) { toast('اجتز اختبار المستوى السابق أولًا'); return; }
        ui.level = i; ui.unit = 0; renderHome();
      };
      sl.appendChild(b);
      if (i === ui.level) l.units.forEach(function (un, j) {
        var ub = document.createElement('button');
        ub.className = 'u-item' + (j === ui.unit ? ' on' : '');
        var c = un.lessons.filter(function (x) { return done(x.id); }).length;
        ub.innerHTML = '<span>' + (unitOpen(i, j) ? '' : '🔒 ') + un.titleAr + '</span><span>' + c + '/4</span>';
        ub.onclick = function () {
          if (!unitOpen(i, j)) { toast('أكمل الوحدة السابقة أولًا'); return; }
          ui.level = i; ui.unit = j; renderHome();
        };
        sl.appendChild(ub);
      });
    });
    $('homeTitle').textContent = u.titleAr;
    $('homeLead').textContent = lv.name + ' · ' + u.title + ' — تعلّم بالصورة والسياق';
    var g = $('pathGrid'); g.innerHTML = '';
    u.lessons.forEach(function (l) {
      var ok = lessonOpen(l), finished = done(l.id);
      var t = document.createElement('div');
      t.className = 'tile' + (ok ? ' open' : ' lock') + (finished ? ' done' : '');
      t.innerHTML = '<span class="flag' + (finished ? ' ok' : '') + '">' + (finished ? '✓' : (ok ? '' : '🔒')) + '</span>' +
        '<img src="' + l.image + '" alt=""><div class="t"><small>' + l.level + ' · LESSON ' + String(l.index + 1).padStart(2, '0') + '</small>' +
        '<h3>' + l.titleAr + '</h3><div class="en">' + l.titleEn + '</div></div>';
      var im = t.querySelector('img'); im.onerror = function () { im.onerror = null; im.src = FALLBACK; };
      t.onclick = function () { if (ok) open(l); else toast('أكمل الدرس السابق أولًا'); };
      g.appendChild(t);
    });
    var row = $('testRow'); row.innerHTML = '';
    [['U-' + u.id, unitTest(u), 'اختبار الوحدة', u.titleAr, 'unit'],
     ['L-' + lv.id, levelTest(lv) && levelOpen(ui.level), 'اختبار المستوى', lv.name, 'level']].forEach(function (a) {
      var r = state.tests[a[0]], b = document.createElement('button');
      b.className = 'mini' + (a[1] && !(r && r.pass) ? ' go' : '');
      b.innerHTML = (r && r.pass ? '✓ ' + r.score + '%' : (a[1] ? a[2] + ' ابدأ' : '🔒 ' + a[2]));
      if (a[1] && !(r && r.pass)) b.onclick = function () { startTest(a[4]); };
      row.appendChild(b);
    });
    var dueN = C.allLessons.filter(function (l) { return due(l.id); }).length;
    $('reviewBtn').textContent = dueN ? 'مراجعة (' + dueN + ')' : 'مراجعة';
  }

  /* ---------- lesson shell ---------- */
  function open(l) {
    if (!lessonOpen(l)) return;
    ui.lesson = l; ui.stage = 0;
    $('home').style.display = 'none';
    $('lesson').classList.add('on');
    render();
  }
  function closeLesson() {
    $('lesson').classList.remove('on');
    $('home').style.display = 'grid';
    renderHome();
  }
  function render() {
    var s = ui.stage, l = ui.lesson;
    gate(false); note('');
    var seg = $('segBar'); seg.innerHTML = '';
    for (var i = 0; i < 9; i++) {
      var d = document.createElement('span');
      d.className = 'seg' + (i < s ? ' done' : '') + (i === s ? ' cur' : '');
      seg.appendChild(d);
    }
    $('lCount').textContent = (s + 1) + '/9';
    $('lPrompt').textContent = NAMES[s];
    var host = $('lStage'); host.innerHTML = '';
    if (s === 0) observe(host, l);
    else if (s === 1) listenPicture(host, l);
    else if (s === 2) wordPicture(host, l);
    else if (s === 3) selectPicture(host, l);
    else if (s === 4) context(host, l);
    else if (s === 5) recognize(host, l);
    else if (s === 6) build(host, l);
    else if (s === 7) speak(host, l);
    else review(host, l);
  }

  function scene(host, src, sentence, withSound) {
    var f = document.createElement('div'); f.className = 'scene';
    if (!src) { f.style.display = 'none'; }
    else f.appendChild(img(src));
    host.appendChild(f);
    if (sentence !== null) {
      var r = document.createElement('div'); r.className = 'sentence-row';
      var t = document.createElement('div'); t.className = 'sentence'; t.textContent = sentence || '';
      r.appendChild(t);
      if (withSound) {
        var b = document.createElement('button'); b.className = 'sound'; b.textContent = '🔊';
        b.onclick = function () { say(sentence, b); }; r.appendChild(b); f._sound = b;
      }
      host.appendChild(r);
    }
    return f;
  }
  function prompt(host, text) { var d = document.createElement('div'); d.className = 'prompt'; d.textContent = text; host.appendChild(d); }
  function photoChoices(host, list, correctIdx, onResult) {
    var g = document.createElement('div'); g.className = 'choices';
    list.forEach(function (src, i) {
      var b = document.createElement('button'); b.className = 'opt'; b.appendChild(img(src));
      b.onclick = function () {
        if (b.dataset.lock) return;
        var ok = i === correctIdx;
        [].slice.call(g.children).forEach(function (x) { x.classList.remove('correct', 'wrong'); });
        b.classList.add(ok ? 'correct' : 'wrong');
        if (!ok) b.dataset.lock = '1';
        if (onResult) onResult(ok, i);
        gate(ok); note(ok ? 'أحسنت.' : 'حاول مرة أخرى.', ok ? 'ok' : 'bad');
      };
      g.appendChild(b);
    });
    host.appendChild(g); return g;
  }
  function textChoices(host, list, correctIdx, onResult) {
    var g = document.createElement('div'); g.className = 'choices';
    g.style.gridTemplateColumns = '1fr';
    list.forEach(function (txt, i) {
      var b = document.createElement('button'); b.className = 'opt-text en'; b.textContent = txt;
      b.onclick = function () {
        if (b.dataset.lock) return;
        var ok = i === correctIdx;
        [].slice.call(g.children).forEach(function (x) { x.classList.remove('correct', 'wrong'); });
        b.classList.add(ok ? 'correct' : 'wrong');
        if (!ok) b.dataset.lock = '1';
        if (onResult) onResult(ok, txt);
        gate(ok); note(ok ? 'صحيح.' : 'حاول مرة أخرى.', ok ? 'ok' : 'bad');
      };
      g.appendChild(b);
    });
    host.appendChild(g); return g;
  }

  /* ---------- nine stages ---------- */
  function observe(host, l) {
    var f = scene(host, l.image, l.phrase, true);
    prompt(host, l.question + ' — انظر واستمع.');
    f._sound.onclick = function () { say(l.phrase, f._sound); gate(true); note('استمعت إلى الجملة.', 'ok'); };
    say(l.phrase, f._sound);
  }
  function listenPicture(host, l) {
    prompt(host, 'استمع، ثم اختر الصورة التي تسمعها.');
    var r = document.createElement('div'); r.className = 'sentence-row';
    var b = document.createElement('button'); b.className = 'sound'; b.textContent = '🔊'; b.onclick = function () { say(l.phrase, b); };
    r.appendChild(b); host.appendChild(r);
    photoChoices(host, l.imageOptions.slice(0, 4), 0, function (ok) { if (ok) say(l.phrase); });
    say(l.phrase);
  }
  function wordPicture(host, l) {
    prompt(host, 'استمع إلى الكلمة واربطها بالصورة.');
    var r = document.createElement('div'); r.className = 'sentence-row';
    var b = document.createElement('button'); b.className = 'sound'; b.textContent = '🔊'; b.onclick = function () { say(l.focus, b); };
    r.appendChild(b); host.appendChild(r);
    photoChoices(host, l.imageOptions.slice(0, 4), 0, function (ok) { if (ok) say(l.focus); });
    say(l.focus);
  }
  function selectPicture(host, l) {
    scene(host, '', l.phrase, true);
    prompt(host, 'اختر الصورة التي تطابق الجملة.');
    photoChoices(host, l.imageOptions.slice(0, 4), 0, function (ok) { if (ok) say(l.phrase); });
    say(l.phrase);
  }
  function context(host, l) {
    scene(host, l.image, null, false);
    prompt(host, 'أكمل الجملة من السياق.');
    var line = document.createElement('div'); line.className = 'sentence en'; line.style.fontSize = '20px';
    line.innerHTML = l.blank.split('____')[0] + '<span style="color:var(--gold)">____</span>' + (l.blank.split('____')[1] || '');
    host.appendChild(line);
    textChoices(host, l.wordOptions, 0, function (ok, w) { if (ok) { say(l.phrase); note('ممتاز — ' + w, 'ok'); } });
  }
  function recognize(host, l) {
    scene(host, l.image, null, false);
    prompt(host, 'أي جملة تصف الصورة؟');
    textChoices(host, l.phraseOptions, 0, function (ok, t) { if (ok) say(t); });
  }
  function build(host, l) {
    scene(host, l.image, null, false);
    prompt(host, 'رتّب الكلمات لتكوين الجملة.');
    var line = document.createElement('div'); line.className = 'wordline en';
    var bank = document.createElement('div'); bank.className = 'words en';
    var placed = [];
    shuffled(l.words.map(function (w, i) { return { w: w, i: i }; }), l.index + 3).forEach(function (t) {
      var c = document.createElement('button'); c.className = 'chip'; c.textContent = t.w;
      c.onclick = function () { c.classList.add('used'); placed.push(t); draw(); };
      bank.appendChild(c);
    });
    function draw() {
      line.innerHTML = '';
      placed.forEach(function (t, j) {
        var c = document.createElement('button'); c.className = 'chip placed'; c.textContent = t.w;
        c.onclick = function () {
          placed.splice(j, 1);
          var o = [].slice.call(bank.children).filter(function (x) { return x.textContent === t.w && x.classList.contains('used'); })[0];
          if (o) o.classList.remove('used'); draw();
        };
        line.appendChild(c);
      });
      var ok = placed.map(function (t) { return t.w; }).join(' ') === l.words.join(' ');
      gate(ok);
      if (ok) { note('جملة صحيحة.', 'ok'); say(l.phrase); }
    }
    host.append(line, bank);
  }
  function speak(host, l) {
    scene(host, l.image, l.phrase, true)._sound.onclick = function () { say(l.phrase); };
    prompt(host, 'استمع ثم قل الجملة بصوت عالٍ.');
    var b = document.createElement('button'); b.className = 'mic'; b.textContent = '🎙 ابدأ التحدث';
    var m = document.createElement('div'); m.className = 'meter'; m.innerHTML = '<span></span>';
    var s = document.createElement('div'); s.className = 'prompt'; s.textContent = 'إن لم يتوفر التعرف الصوتي، تدرب ثم أكّد أدناه.';
    var self = document.createElement('button'); self.className = 'mini'; self.textContent = 'تدربت بصوت عالٍ (دون تقييم)';
    host.append(b, m, s, self);
    b.onclick = function () { speechCheck(l, b, m.firstChild, s); };
    self.onclick = function () { state.stats.speaking++; save(); gate(true); note('تم التدريب — لم يُقيَّم النطق آليًا.', 'ok'); };
  }
  function speechCheck(l, btn, bar, st) {
    var SR = window.SpeechRecognition || window.webkitSpeechRecognition;
    if (!SR) { st.textContent = 'التعرف الصوتي غير متاح في هذا المتصفح.'; note('لا يمكن تقييم النطق هنا.', 'bad'); return; }
    try {
      var r = new SR(); r.lang = 'en-US'; r.interimResults = false;
      btn.classList.add('rec'); bar.style.width = '35%'; st.textContent = 'جارٍ الاستماع...';
      r.onresult = function (e) {
        btn.classList.remove('rec'); var said = e.results[0][0].transcript;
        bar.style.width = '100%'; st.textContent = 'سمعت: "' + said + '"';
        if (norm(said) === norm(l.phrase)) {
          state.stats.speaking++; save(); gate(true);
          note('تم التعرف على الجملة بدقة.', 'ok');
        } else { gate(false); note('حاول مرة أخرى.', 'bad'); }
      };
      r.onerror = function (e) { btn.classList.remove('rec'); bar.style.width = '0%'; st.textContent = 'خطأ في الميكروفون: ' + (e.error || ''); note('لم يتم تقييم النطق.', 'bad'); };
      r.onend = function () { btn.classList.remove('rec'); };
      r.start();
    } catch (e) { btn.classList.remove('rec'); st.textContent = 'تعذّر بدء الميكروفون.'; }
  }
  function review(host, l) {
    prompt(host, 'راجع ما تعلّمته قبل إتقان الدرس.');
    var g = document.createElement('div'); g.className = 'choices';
    var answered = 0, ok = 0;
    l.review.forEach(function (p, k) {
      var c = document.createElement('div'); c.style.cssText = 'grid-column:1/-1;margin-bottom:10px';
      var h = document.createElement('div'); h.className = 'prompt'; h.textContent = (k + 1) + '. ' + p.title;
      var row = document.createElement('div'); row.className = 'choices';
      var opts = shuffled([p.image].concat(l.imageOptions.slice(1, 4)), p.title.length + k);
      opts.forEach(function (src) {
        var b = document.createElement('button'); b.className = 'opt'; b.appendChild(img(src));
        b.onclick = function () {
          if (b.dataset.lock) return;
          [].slice.call(row.children).forEach(function (x) { x.dataset.lock = '1'; });
          answered++;
          if (src === p.image) { ok++; b.classList.add('correct'); } else b.classList.add('wrong');
          if (answered === l.review.length) {
            if (ok === l.review.length) { note('مراجعة ممتازة — أكمل الإتقان.', 'ok'); master(host, l); }
            else { gate(false); note('راجع الصور ثم حاول.', 'bad'); }
          }
        };
        row.appendChild(b);
      });
      c.append(h, row); g.appendChild(c);
    });
    host.appendChild(g);
  }
  function master(host, l) {
    var box = document.createElement('div');
    box.style.cssText = 'grid-column:1/-1;border-top:1px solid var(--line);margin-top:12px;padding-top:12px';
    var h = document.createElement('div'); h.className = 'prompt'; h.textContent = 'إتقان الدرس — 3 أسئلة';
    box.appendChild(h);
    var qs = [
      { p: l.phrase, list: shuffled(l.imageOptions.slice(0, 4), l.index + 31), type: 'img', right: l.image },
      { p: l.question, list: shuffled(l.phraseOptions, l.index + 41), type: 'txt', right: l.phrase },
      { p: l.blank, list: shuffled(l.wordOptions, l.index + 53), type: 'txt', right: l.focus }
    ];
    var done = 0, ok = 0;
    qs.forEach(function (q, qi) {
      var c = document.createElement('div'); c.style.marginBottom = '10px';
      var p = document.createElement('div'); p.className = 'prompt en'; p.style.textAlign = 'center'; p.textContent = (qi + 1) + '. ' + q.p;
      var row = document.createElement('div'); row.className = q.type === 'img' ? 'choices' : 'choices';
      if (q.type !== 'img') row.style.gridTemplateColumns = '1fr';
      q.list.forEach(function (opt) {
        var b = document.createElement('button');
        b.className = q.type === 'img' ? 'opt' : 'opt-text en';
        if (q.type === 'img') b.appendChild(img(opt)); else b.textContent = opt;
        b.onclick = function () {
          if (b.dataset.lock) return;
          [].slice.call(row.children).forEach(function (x) { x.dataset.lock = '1'; x.classList.remove('correct', 'wrong'); });
          done++;
          var right = opt === q.right;
          if (right) { ok++; b.classList.add('correct'); } else b.classList.add('wrong');
          if (done === qs.length) {
            if (ok === qs.length) { gate(true); note('إتقان كامل.', 'ok'); }
            else { gate(false); note('أجب عن الثلاثة بشكل صحيح.', 'bad'); }
          }
        };
        row.appendChild(b);
      });
      c.append(p, row); box.appendChild(c);
    });
    host.querySelector('.choices').appendChild(box);
  }
  function advance() {
    if (!ui.ok) return;
    if (ui.stage < 8) { ui.stage++; render(); return; }
    var l = ui.lesson, r = rec(l.id);
    r.done = true; r.reps = 0; r.due = Date.now() + SRS[0] * 86400000; r.at = Date.now();
    touch(); state.xp += 10; save(); toast('تم إتقان الدرس');
    var nx = nextLesson();
    if (nx) { ui.level = nx.levelIndex; ui.unit = nx.unitIndex; }
    closeLesson();
  }

  /* ---------- tests ---------- */
  function q(l, k) {
    if (k === 0) return { p: l.phrase, list: shuffled(l.imageOptions.slice(0, 4), l.index + 7), right: l.image, img: true };
    if (k === 1) return { p: l.question, list: shuffled(l.phraseOptions, l.index + 11), right: l.phrase, img: false };
    return { p: l.blank, list: shuffled(l.wordOptions, l.index + 17), right: l.focus, img: false };
  }
  var testState = null;
  function startTest(type) {
    var lv = C.levels[ui.level];
    var src = type === 'unit' ? lv.units[ui.unit].lessons : C.allLessons.filter(function (l) { return l.levelIndex === ui.level; });
    testState = { type: type, id: (type === 'unit' ? 'U-' + lv.units[ui.unit].id : 'L-' + lv.id),
      qs: shuffled(src, Date.now() % 997).slice(0, type === 'unit' ? 4 : 6).map(function (l, i) { return q(l, i % 3); }), i: 0, res: [] };
    testShow();
  }
  function testShow() {
    var t = testState;
    if (t.i >= t.qs.length) { testEnd(); return; }
    var qq = t.qs[t.i], box = $('testArea');
    box.innerHTML = '<div class="prompt">' + (t.type === 'unit' ? 'اختبار الوحدة' : 'اختبار المستوى') + ' — ' + (t.i + 1) + '/' + t.qs.length + '</div>' +
      '<div class="prompt en" style="font-size:18px;color:var(--ink)">' + qq.p + '</div>' +
      '<div class="choices" id="testChoices" style="grid-column:1/-1"></div>';
    var row = $('testChoices');
    if (!qq.img) row.style.gridTemplateColumns = '1fr';
    qq.list.forEach(function (opt) {
      var b = document.createElement('button'); b.className = qq.img ? 'opt' : 'opt-text en';
      if (qq.img) b.appendChild(img(opt)); else b.textContent = opt;
      b.onclick = function () { t.res.push(opt === qq.right); t.i++; testShow(); };
      row.appendChild(b);
    });
    $('testModal').classList.add('on');
  }
  function testEnd() {
    var t = testState, good = t.res.filter(Boolean).length, pct = Math.round(good / t.qs.length * 100), pass = pct >= 75;
    var old = state.tests[t.id];
    if (pass && !(old && old.pass)) state.xp += t.type === 'unit' ? 25 : 50;
    state.tests[t.id] = { pass: pass || (old && old.pass), score: Math.max(pct, old ? old.score : 0) };
    touch(); save();
    $('testArea').innerHTML = '<div class="prompt" style="font-size:22px;color:var(--ink)">' + pct + '%</div>' +
      '<div class="prompt">' + (pass ? 'اجتزت الاختبار' : 'حاول مرة أخرى') + '</div>' +
      '<button class="go" id="testClose" style="margin:auto">حسنًا</button>';
    $('testClose').onclick = function () { $('testModal').classList.remove('on'); renderHome(); };
  }

  /* ---------- review ---------- */
  function openReview() {
    var list = C.allLessons.filter(function (l) { return due(l.id); });
    $('reviewArea').innerHTML = list.length ? '' : '<div class="prompt">لا توجد مراجعات مستحقة الآن.</div>';
    list.slice(0, 12).forEach(function (l) {
      var r = document.createElement('div'); r.className = 'review-row';
      r.innerHTML = '<div><div class="en">' + l.phrase + '</div><small>' + l.titleAr + '</small></div><button class="mini go">راجع</button>';
      r.querySelector('button').onclick = function () { doReview(l, r); };
      $('reviewArea').appendChild(r);
    });
    $('reviewModal').classList.add('on');
  }
  function doReview(l, row) {
    var qq = q(l, l.index % 2);
    row.innerHTML = '<div class="prompt en">' + qq.p + '</div><div class="choices" id="rv"></div>';
    var box = row.querySelector('#rv');
    if (!qq.img) box.style.gridTemplateColumns = '1fr';
    qq.list.forEach(function (opt) {
      var b = document.createElement('button'); b.className = qq.img ? 'opt' : 'opt-text en';
      if (qq.img) b.appendChild(img(opt)); else b.textContent = opt;
      b.onclick = function () {
        if (opt === qq.right) { var r = rec(l.id); r.reps++; r.due = Date.now() + SRS[Math.min(r.reps - 1, SRS.length - 1)] * 86400000;
          state.stats.reviews++; state.xp += 3; save(); toast('مراجعة ناجحة'); }
        else { var r2 = rec(l.id); r2.reps = 0; r2.due = Date.now() + 86400000; toast('ستعود غدًا'); }
        $('reviewModal').classList.remove('on'); renderHome();
      };
      box.appendChild(b);
    });
  }

  /* ---------- boot ---------- */
  function boot() {
    if (!C || !C.allLessons.length) { $('loading').classList.add('hide'); return; }
    state = load();
    $('goBtn').onclick = advance;
    $('exitBtn').onclick = closeLesson;
    $('reviewBtn').onclick = openReview;
    $('testCloseX').onclick = function () { $('testModal').classList.remove('on'); };
    $('reviewCloseX').onclick = function () { $('reviewModal').classList.remove('on'); };
    renderHome();
    setTimeout(function () { $('loading').classList.add('hide'); }, 250);
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', boot); else boot();
})();
