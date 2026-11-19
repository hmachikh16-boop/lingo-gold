const http = require('http');
const fs = require('fs');
const path = require('path');

const apkFile = path.resolve('lingo_gold/build/app/outputs/flutter-apk/app-release.apk');
const bundleFile = path.resolve('lingo-lessons-bundle.json');
const qrFile = path.resolve('lingo_gold_apk_qr_v44.png');
const port = 8765;

function sendFile(res, file, contentType, downloadName) {
  if (!fs.existsSync(file)) { res.writeHead(404, { 'Cache-Control': 'no-store' }); res.end('Not found'); return; }
  const stat = fs.statSync(file);
  const headers = {
    'Content-Type': contentType,
    'Content-Length': stat.size,
    'Cache-Control': 'no-store',
    'Access-Control-Allow-Origin': '*'
  };
  if (downloadName) headers['Content-Disposition'] = 'attachment; filename="' + downloadName + '"';
  res.writeHead(200, headers);
  fs.createReadStream(file).pipe(res);
}

const server = http.createServer((req, res) => {
  const url = decodeURIComponent((req.url || '/').split('?')[0]);
  if (url === '/' || url === '/app-release.apk') {
    return sendFile(res, apkFile, 'application/vnd.android.package-archive', 'app-release.apk');
  }
  if (url === '/lingo-lessons-bundle.json' || url === '/bundle' || url === '/updates.json') {
    return sendFile(res, bundleFile, 'application/json; charset=utf-8');
  }
  if (url === '/qr.png' || url === '/qr' || url === '/qrcode.png') {
    return sendFile(res, qrFile, 'image/png');
  }
  res.writeHead(404, { 'Cache-Control': 'no-store' }); res.end('Not found');
});
server.on('error', (e) => console.error('APK_SERVER_ERR', e && e.message ? e.message : e));
server.listen(port, '0.0.0.0', () => {
  console.log('APK_SERVER_READY http://192.168.1.11:' + port + '/app-release.apk');
  console.log('BUNDLE_READY     http://192.168.1.11:' + port + '/lingo-lessons-bundle.json');
});
