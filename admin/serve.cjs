const http = require('http');
const https = require('https');
const fs = require('fs');
const path = require('path');
const { spawnSync, spawn } = require('child_process');

// مصادر النشر العام التي يقرأها التطبيق عبر الإنترنت
const GIST_ID = '2b5187c6e1696ac92701872452a04ea2';
const GIST_FILENAME = 'lingo-lessons-bundle.json';
const CONTENT_REPO_DIR = 'C:\\Users\\hmach\\AppData\\Local\\Temp\\opencode\\lingo-gold-content';
const CONTENT_REPO_FILE = path.join(CONTENT_REPO_DIR, 'lingo-lessons-bundle.json');
const CONTENT_IMAGES_DIR = path.join(CONTENT_REPO_DIR, 'images');
const CONTENT_RAW_BASE = 'https://raw.githubusercontent.com/hmachikh16-boop/lingo-gold-content/main/';
// jsDelivr هو المصدر الأساسي للتطبيق: يستجيب فوراً لتحديثات Git (عكس raw الذي
// يتجاهل معاملات كسر الكاش ويحتفظ بالنسخة القديمة 300 ثانية).
const CONTENT_CDN_BASE = 'https://cdn.jsdelivr.net/gh/hmachikh16-boop/lingo-gold-content@main/';
const PORT = 8080;
const ROOT = __dirname;
const APP_ASSETS = path.resolve(__dirname, '..', 'lingo_gold', 'assets');
// ملف حزمة التحديثات الذي يقرأه التطبيق عبر خادم التحميل (8765)
const LESSON_BUNDLE_FILE = path.resolve(__dirname, '..', 'lingo-lessons-bundle.json');
const MIME = {
  '.html':'text/html; charset=utf-8',
  '.js':'application/javascript',
  '.json':'application/json',
  '.webmanifest':'application/manifest+json; charset=utf-8',
  '.css':'text/css',
  '.png':'image/png',
  '.jpg':'image/jpeg',
  '.jpeg':'image/jpeg',
  '.webp':'image/webp',
  '.svg':'image/svg+xml',
  '.ico':'image/x-icon',
  '.mp3':'audio/mpeg',
  '.wav':'audio/wav',
  '.ogg':'audio/ogg',
};
function sendJson(res, status, obj) {
  res.statusCode = status;
  res.setHeader('Content-Type', 'application/json; charset=utf-8');
  res.setHeader('Cache-Control', 'no-store');
  res.end(JSON.stringify(obj));
}

// تنفيذ أوامر git/gh في الخلفية حتى لا ينتظر المتصفح اكتمال الشبكة
function runAsync(cmd, args, options) {
  return new Promise(resolve => {
    const child = spawn(cmd, args, Object.assign({ windowsHide: true }, options || {}));
    let out = '', err = '';
    if (child.stdout) child.stdout.on('data', d => { out += d.toString(); });
    if (child.stderr) child.stderr.on('data', d => { err += d.toString(); });
    child.on('error', e => resolve({ status: -1, stdout: out, stderr: String(e) }));
    child.on('close', code => resolve({ status: code, stdout: out, stderr: err }));
  });
}

// إبطال كاش jsDelivr فوراً بعد الدفع حتى تصل التعديلات للتطبيق خلال ثوانٍ
function purgeCdn(relPath) {
  const url = 'https://purge.jsdelivr.net/gh/hmachikh16-boop/lingo-gold-content@main/' + relPath;
  return new Promise(resolve => {
    const req = https.get(url, res => {
      let out = '';
      res.on('data', d => { out += d.toString(); });
      res.on('end', () => resolve({ ok: res.statusCode === 200, status: res.statusCode, body: out }));
    });
    req.on('error', e => resolve({ ok: false, error: String(e) }));
    req.setTimeout(15000, () => { req.destroy(new Error('purge timeout')); });
  });
}

// طابور نشر واحد لضمان عدم تداخل عمليات git عند تعديلات سريعة متتالية
let publishQueue = Promise.resolve();
function queuePublish(task) {
  publishQueue = publishQueue.then(task).catch(e => ({
    ok: false, error: e && e.message ? e.message : String(e)
  }));
  return publishQueue;
}

function saveLessonBundle(req, res) {
  let body = '';
  req.setEncoding('utf8');
  req.on('data', chunk => {
    body += chunk;
    if (body.length > 20 * 1024 * 1024) {
      req.destroy();
    }
  });
  req.on('end', () => {
    try {
      const parsed = JSON.parse(body);
      if (!parsed || typeof parsed !== 'object' || !Array.isArray(parsed.lessons)) {
        return sendJson(res, 400, { ok: false, error: 'Invalid bundle: lessons array missing' });
      }
      // نسخة احتياطية سريعة قبل الاستبدال (إن وُجد الملف القديم)
      try {
        if (fs.existsSync(LESSON_BUNDLE_FILE)) {
          fs.copyFileSync(LESSON_BUNDLE_FILE, LESSON_BUNDLE_FILE + '.bak');
        }
      } catch (_) {}
      fs.writeFileSync(LESSON_BUNDLE_FILE, JSON.stringify(parsed, null, 2), 'utf8');

      // لقطة محلية فورية + نشر في الخلفية حتى لا ينتظر المتصفح الشبكة
      try { fs.copyFileSync(LESSON_BUNDLE_FILE, CONTENT_REPO_FILE); } catch (_) {}

      queuePublish(async () => {
        const add = await runAsync('git', ['-C', CONTENT_REPO_DIR, 'add', 'lingo-lessons-bundle.json']);
        const commit = await runAsync('git', [
          '-C', CONTENT_REPO_DIR, '-c', 'user.name=Lingo Gold Admin',
          '-c', 'user.email=admin@lingogold.com', 'commit', '-m', 'Auto publish lesson bundle'
        ]);
        const push = await runAsync('git', ['-C', CONTENT_REPO_DIR, 'push', 'origin', 'HEAD:main']);
        const repoOk = push.status === 0;
        if (repoOk) await purgeCdn('lingo-lessons-bundle.json');

        const gist = await runAsync('gh', ['gist', 'edit', GIST_ID, '--filename', GIST_FILENAME, LESSON_BUNDLE_FILE]);
        return {
          repo: {
            ok: repoOk,
            url: CONTENT_CDN_BASE + 'lingo-lessons-bundle.json',
            error: repoOk ? undefined : (push.stderr || push.stdout || commit.stderr || add.stderr || 'git push failed').trim()
          },
          gist: {
            ok: gist.status === 0,
            url: 'https://gist.github.com/hmachikh16-boop/' + GIST_ID,
            error: gist.status === 0 ? undefined : (gist.stderr || gist.stdout || 'gh gist edit failed').trim()
          }
        };
      });

      sendJson(res, 200, {
        ok: true,
        path: LESSON_BUNDLE_FILE,
        lessons: parsed.lessons.length,
        newLessons: Array.isArray(parsed.newLessons) ? parsed.newLessons.length : 0,
        savedAt: new Date().toISOString(),
        repo: { ok: null, queued: true, url: CONTENT_CDN_BASE + 'lingo-lessons-bundle.json' },
        gist: { ok: null, queued: true }
      });
    } catch (e) {
      sendJson(res, 400, { ok: false, error: e && e.message ? e.message : String(e) });
    }
  });
}

function uploadImage(req, res) {
  let body = '';
  req.setEncoding('utf8');
  req.on('data', chunk => {
    body += chunk;
    if (body.length > 12 * 1024 * 1024) req.destroy();
  });
  req.on('end', () => {
    try {
      const parsed = JSON.parse(body);
      const dataUrl = String((parsed && parsed.dataUrl) || '');
      const m = dataUrl.match(/^data:image\/(png|jpe?g|gif|webp|bmp|svg\+xml);base64,([A-Za-z0-9+/=\r\n]+)$/i);
      if (!m) {
        return sendJson(res, 400, { ok: false, error: 'صورة غير صالحة (اختر PNG أو JPG أو WebP)' });
      }
      const mime = m[1].toLowerCase();
      const ext = mime === 'jpeg' ? 'jpg' : (mime === 'svg+xml' ? 'svg' : mime);
      const bytes = Buffer.from(m[2].replace(/\s/g, ''), 'base64');
      if (!bytes.length) return sendJson(res, 400, { ok: false, error: 'الصورة فارغة' });

      const rawPrefix = String((parsed && parsed.name) || 'lesson-image');
      const safePrefix = rawPrefix.replace(/[^a-zA-Z0-9_-]+/g, '_').replace(/^_+|_+$/g, '').slice(0, 40) || 'image';
      const fileName = safePrefix + '_' + Date.now() + '_' + Math.random().toString(36).slice(2, 7) + '.' + ext;
      fs.mkdirSync(CONTENT_IMAGES_DIR, { recursive: true });
      const target = path.join(CONTENT_IMAGES_DIR, fileName);
      fs.writeFileSync(target, bytes);

      const git = (args) => spawnSync('git', ['-C', CONTENT_REPO_DIR].concat(args), {
        encoding: 'utf8', windowsHide: true, timeout: 30000
      });
      git(['add', 'images/' + fileName]);
      git(['-c', 'user.name=Lingo Gold Admin', '-c', 'user.email=admin@lingogold.com',
           'commit', '-m', 'Upload lesson image ' + fileName]);
      const gp = git(['push', 'origin', 'HEAD:main']);
      if (gp.status !== 0) {
        return sendJson(res, 500, { ok: false, error: (gp.stderr || gp.stdout || 'git push failed').trim() });
      }
      purgeCdn('images/' + encodeURIComponent(fileName));
      return sendJson(res, 200, {
        ok: true,
        // raw أولاً: اسم الملف جديد وفريد، فلا يوجد كاش قديم، ويظهر فوراً.
        // jsDelivr قد يعلق على نسخة قديمة حتى مع purge.
        url: CONTENT_RAW_BASE + 'images/' + encodeURIComponent(fileName),
        path: target
      });
    } catch (e) {
      return sendJson(res, 400, { ok: false, error: e && e.message ? e.message : String(e) });
    }
  });
}

http.createServer((req,res)=>{
  try {
    let urlPath = decodeURIComponent((req.url || '/').split('?')[0]);

    // حفظ مباشر لحزمة الدروس التي يقرأها التطبيق (بدون تنزيل/نسخ يدوي)
    if (req.method === 'POST' && (urlPath === '/api/save-lesson-bundle' || urlPath === '/save-lesson-bundle')) {
      return saveLessonBundle(req, res);
    }

    // رفع صورة الدرس/الواجهة مباشرة إلى مستودع المحتوى (بدون Firebase Storage)
    if (req.method === 'POST' && (urlPath === '/api/upload-image' || urlPath === '/upload-image')) {
      return uploadImage(req, res);
    }

    // الحزمة المنشورة حالياً: تُستخدم في اللوحة لدمج stepOverrides القديمة
    // بدل فقدانها عند كل نشر جديد (كانت تختفي إذا لم توجد مسودة محلية).
    if (req.method === 'GET' && (urlPath === '/api/published-bundle' || urlPath === '/published-bundle')) {
      fs.readFile(LESSON_BUNDLE_FILE, 'utf8', (err, data) => {
        if (err) return sendJson(res, 404, { ok: false, error: 'bundle not found' });
        res.statusCode = 200;
        res.setHeader('Content-Type', 'application/json; charset=utf-8');
        res.setHeader('Cache-Control', 'no-store');
        res.end(data);
      });
      return;
    }

    if (urlPath === '/') urlPath = '/index.html';

    let file;
    if (urlPath.startsWith('/app-assets/')) {
      const rel = urlPath.slice('/app-assets/'.length);
      file = path.resolve(APP_ASSETS, rel);
      if (!file.startsWith(APP_ASSETS)) { res.statusCode=403; res.end('Forbidden'); return; }
    } else {
      file = path.resolve(ROOT, '.' + urlPath);
      if (!file.startsWith(ROOT)) { res.statusCode=403; res.end('Forbidden'); return; }
    }

    fs.readFile(file, (err,data)=>{
      if (err) { res.statusCode=404; res.end('Not found'); return; }
      const ext = path.extname(file).toLowerCase();
      res.setHeader('Content-Type', MIME[ext] || 'application/octet-stream');
      if (urlPath === '/sw.js') {
        res.setHeader('Cache-Control', 'no-cache');
        res.setHeader('Service-Worker-Allowed', '/');
      } else if (urlPath === '/manifest.webmanifest') {
        res.setHeader('Cache-Control', 'no-cache');
      }
      res.end(data);
    });
  } catch (e) {
    res.statusCode=500; res.end('Server error');
  }
}).listen(PORT, ()=>console.log('Admin panel: http://localhost:'+PORT));
