const http = require('http');
const fs = require('fs');
const path = require('path');

const root = path.join(__dirname, 'build', 'web');
const mime = {
  '.html': 'text/html', '.js': 'application/javascript', '.json': 'application/json',
  '.png': 'image/png', '.jpg': 'image/jpeg', '.jpeg': 'image/jpeg', '.ttf': 'font/ttf',
  '.wasm': 'application/wasm', '.svg': 'image/svg+xml', '.css': 'text/css', '.ico': 'image/x-icon',
};

http.createServer((req, res) => {
  let p = decodeURIComponent(req.url.split('?')[0]);
  if (p === '/') p = '/index.html';
  const file = path.join(root, p);
  fs.readFile(file, (err, data) => {
    if (err) { res.writeHead(404); res.end('404'); return; }
    res.writeHead(200, { 'Content-Type': mime[path.extname(file)] || 'application/octet-stream' });
    res.end(data);
  });
}).listen(8099, () => console.log('Lingo Gold replica: http://localhost:8099'));
