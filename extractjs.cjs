const fs=require('fs');
const html=fs.readFileSync('public/pictures-admin.html','utf8');
const m=html.match(/<script>([\s\S]*?)<\/script>/);
fs.writeFileSync('C:/Users/hmach/AppData/Local/Temp/opencode/pa.js', m[1]);
