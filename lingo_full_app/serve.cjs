const http = require('http');
const fs = require('fs');
const path = require('path');
const root = path.join(__dirname, 'build', 'web');
const mime = {'.html':'text/html','.js':'application/javascript','.json':'application/json','.png':'image/png','.jpg':'image/jpeg','.ttf':'font/ttf','.wasm':'application/wasm','.svg':'image/svg+xml','.css':'text/css','.ico':'image/x-icon'};
http.createServer((req,res)=>{
  let p=decodeURIComponent(req.url.split('?')[0]); if(p==='/')p='/index.html';
  const f=path.join(root,p);
  fs.readFile(f,(e,d)=>{ if(e){res.writeHead(404);res.end('404');return;} res.writeHead(200,{'Content-Type':mime[path.extname(f)]||'application/octet-stream'});res.end(d);});
}).listen(8098,()=>console.log('full app: http://localhost:8098'));
