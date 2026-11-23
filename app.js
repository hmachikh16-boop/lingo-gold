/* ============================================================
   Lingo Gold — Visual Immersion Engine
   Activities are driven by linked scenes, not isolated quiz pages.
   ============================================================ */
(function () {
  'use strict';
  var C = window.IMS_CURRICULUM;
  var KEY = 'lingo_gold_immersion_v1';
  var FALLBACK = "data:image/svg+xml;utf8," + encodeURIComponent(
    '<svg xmlns="http://www.w3.org/2000/svg" width="600" height="400"><rect width="600" height="400" fill="#eef0ef"/><text x="50%" y="50%" dominant-baseline="middle" text-anchor="middle" fill="#9aa5ad" font-family="sans-serif" font-size="18">Image</text></svg>'
  );
  var SRS = [1,2,4,8,16,32];
  var KINDS = ['OBSERVE','LISTEN','SOUND → PICTURE','CHOOSE PICTURE','IN CONTEXT','RECOGNIZE','BUILD','SPEAK','REVIEW'];
  var $ = function (i) { return document.getElementById(i); };
  var state, ui = { li:0, ui_:0, lesson:null, act:0, round:0, rounds:1, ok:false, quiz:null }, toastT;

  function load(){
    var d={v:3,xp:0,lessons:{},tests:{},streak:{count:0,last:''},stats:{speaking:0,reviews:0}};
    try{var raw=localStorage.getItem(KEY);if(raw){var o=JSON.parse(raw);Object.keys(d).forEach(function(k){if(o[k]!==undefined)d[k]=o[k];});}}catch(e){console.warn('read',e);}return d;
  }
  function save(){try{localStorage.setItem(KEY,JSON.stringify(state));}catch(e){console.warn('save',e);}}
  function rec(id){return state.lessons[id]||(state.lessons[id]={done:false,reps:0,due:0,at:0});}
  function done(id){return !!(state.lessons[id]&&state.lessons[id].done);}
  function due(id){var r=state.lessons[id];return !!(r&&r.done&&r.due&&r.due<=Date.now());}
  function doneCount(){return Object.keys(state.lessons).filter(done).length;}
  function touch(){var t=new Date().toISOString().slice(0,10),y=new Date(Date.now()-86400000).toISOString().slice(0,10);if(state.streak.last!==t){state.streak.count=state.streak.last===y?state.streak.count+1:1;state.streak.last=t;}}
  function toast(m){var e=$('toast');e.textContent=m;e.classList.add('show');clearTimeout(toastT);toastT=setTimeout(function(){e.classList.remove('show');},2100);}
  function mark(v){var e=$('mark');e.textContent=v?'✓':'✕';e.className='mark '+(v?'ok':'bad');}
  function gate(v){ui.ok=!!v;$('next').disabled=!v;}
  function shuffle(a,s){var x=a.slice(),n=x.length;s=s||1;while(n>1){s=(s*9301+49297)%233280;var i=Math.floor(s/233280*n);n--;var t=x[n];x[n]=x[i];x[i]=t;}return x;}
  function im(src){var e=document.createElement('img');e.src=src||FALLBACK;e.alt='';e.onerror=function(){e.onerror=null;e.src=FALLBACK;};return e;}
  function norm(s){return String(s).toLowerCase().replace(/[.,!?]/g,'').replace(/\s+/g,' ').trim();}
  function say(text,btn){if(!('speechSynthesis' in window)){toast('Audio not supported');return;}try{speechSynthesis.cancel();var u=new SpeechSynthesisUtterance(String(text));u.lang='en-US';u.rate=.9;if(btn){btn.classList.add('playing');u.onend=function(){btn.classList.remove('playing');};}speechSynthesis.speak(u);}catch(e){toast('Audio error');}}

  /* progression */
  function levelOpen(i){if(i===0)return true;var t=state.tests['L-'+C.levels[i-1]];return !!(t&&t.pass);}
  function unitOpen(li,uiIdx){if(!levelOpen(li))return false;if(uiIdx===0)return true;var idx=(li*12)+(uiIdx-1)*4;for(var k=0;k<4;k++)if(!done(C.allLessons[idx+k].id))return false;return true;}
  function lessonOpen(l){if(!unitOpen(l.levelIndex,l.unitIndex))return false;if(l.lessonInUnit===1)return true;return done(C.allLessons[l.index-1].id);}
  function unitTestOpen(u){var base=u*4;for(var k=0;k<4;k++)if(!done(C.allLessons[base+k].id))return false;return true;}
  function levelTestOpen(lv){for(var u=0;u<3;u++){var t=state.tests['U-'+lv+'-'+u];if(!(t&&t.pass))return false;}return true;}
  function nextLesson(){for(var i=0;i<C.allLessons.length;i++)if(!done(C.allLessons[i].id))return C.allLessons[i];return null;}

  /* home */
  function home(){
    $('progress').textContent=doneCount()+' / '+C.count;
    var lv=C.levels[ui.li], side=$('side');side.innerHTML='';
    C.levels.forEach(function(l,i){
      var b=document.createElement('button');b.className='lv'+(i===ui.li?' on':'');
      b.innerHTML='<span>'+(levelOpen(i)?'':'🔒 ')+l+'</span><span>'+doneCountForLevel(i)+'/12</span>';
      b.onclick=function(){if(!levelOpen(i)){toast('Complete the previous level test');return;}ui.li=i;ui.ui_=0;home();};
      side.appendChild(b);
      if(i===ui.li)['Unit 1','Unit 2','Unit 3'].forEach(function(u,j){
        var ub=document.createElement('button');ub.className='un'+(j===ui.ui_?' on':'');
        ub.innerHTML='<span>'+(unitOpen(i,j)?'':'🔒 ')+u+'</span><span>4</span>';
        ub.onclick=function(){if(!unitOpen(i,j)){toast('Complete the previous unit');return;}ui.li=i;ui.ui_=j;home();};
        side.appendChild(ub);
      });
    });
    var base=ui.li*12+ui.ui_*4;
    $('title').textContent=lv+' · Unit '+(ui.ui_+1);
    var grid=$('path');grid.innerHTML='';
    for(var k=0;k<4;k++){
      let l=C.allLessons[base+k], open=lessonOpen(l), fin=done(l.id);
      let t=document.createElement('div');t.className='tile'+(open?' open':' lock')+(fin?' done':'');
      t.innerHTML='<span class="st'+(fin?' ok':'')+'">'+(fin?'✓':(open?'':'🔒'))+'</span><img src="'+l.main.image+'" alt="">'+
        '<div class="info"><small>'+l.level+' · LESSON '+String(l.index+1).padStart(2,'0')+'</small><h3>'+l.title+'</h3><div class="en">'+l.titleSub+'</div></div>';
      var im=t.querySelector('img');im.onerror=function(){im.onerror=null;im.src=FALLBACK;};
      t.onclick=function(){if(open)openLesson(l);else toast('Finish the previous lesson first');};
      grid.appendChild(t);
    }
    var tools=$('tools');tools.innerHTML='';
    var a=document.createElement('button');a.className='btn-s'+(unitTestOpen(ui.ui_)?' go':'');a.textContent='Unit test';
    if(unitTestOpen(ui.ui_))a.onclick=function(){startTest('unit');};tools.appendChild(a);
    var b=document.createElement('button');b.className='btn-s'+(levelTestOpen(lv)?' go':'');b.textContent='Level test';
    if(levelTestOpen(lv))b.onclick=function(){startTest('level');};tools.appendChild(b);
    var dues=C.allLessons.filter(function(l){return due(l.id);}).length;
    var r=document.createElement('button');r.className='btn-s'+(dues?' go':'');r.textContent='Review'+(dues?' ('+dues+')':'');
    r.onclick=openReview;tools.appendChild(r);
  }
  function doneCountForLevel(i){var n=0;for(var k=i*12;k<i*12+12;k++)if(done(C.allLessons[k].id))n++;return n;}

  /* lesson */
  function openLesson(l){if(!lessonOpen(l))return;ui.lesson=l;ui.act=0;ui.round=0;$('home').style.display='none';$('stage').classList.add('on');render();}
  function exitLesson(){$('stage').classList.remove('on');$('home').style.display='block';home();}
  function bar(){var b=$('pieces');b.innerHTML='';for(var i=0;i<9;i++){var s=document.createElement('span');s.className='piece'+(i<ui.act?' done':'')+(i===ui.act?' now':'');b.appendChild(s);}$('count').textContent=(ui.act+1)+'/9';$('kind').textContent=KINDS[ui.act];}
  function render(){
    bar();gate(false);mark(0);
    var h=$('wrap');h.innerHTML='';
    if(ui.act===0)observe(h);
    else if(ui.act===1)bySound(h,false);
    else if(ui.act===2)bySound(h,true);
    else if(ui.act===3)byText(h);
    else if(ui.act===4)contextual(h);
    else if(ui.act===5)recognize(h);
    else if(ui.act===6)build(h);
    else if(ui.act===7)speaking(h);
    else reviewing(h);
  }
  function hero(h,scene,withSentence){
    var f=document.createElement('div');f.className='hero';f.appendChild(im(scene.image));h.appendChild(f);
    if(withSentence){var c=document.createElement('div');c.className='caption';var s=document.createElement('div');s.className='sent en';s.textContent=scene.phrase;c.appendChild(s);var b=document.createElement('button');b.className='listen';b.textContent='🔊';c.appendChild(b);h.appendChild(c);return b;}
    return null;
  }
  function imageRow(h,images,right,onRight){
    var row=document.createElement('div');row.className='row4';
    images.forEach(function(src){
      var b=document.createElement('button');b.className='pick';b.appendChild(im(src));
      b.onclick=function(){var ok=src===right;if(ok){b.classList.add('correct');onRight();}else b.classList.add('wrong');mark(ok);};
      row.appendChild(b);
    });
    h.appendChild(row);
  }
  function textLine(h,options,right,onRight){
    var line=document.createElement('div');line.className='line';
    options.forEach(function(txt){var b=document.createElement('button');b.className='word-opt en';b.textContent=txt;
      b.onclick=function(){var ok=txt===right;if(ok){b.classList.add('correct');onRight();}else b.classList.add('wrong');mark(ok);};line.appendChild(b);});
    h.appendChild(line);
  }
  function nextRound(){if(ui.round<ui.rounds-1){ui.round++;render();}else gate(true);}

  function observe(h){var l=ui.lesson,b=hero(h,l.main,true);b.onclick=function(){say(l.main.phrase,b);gate(true);mark(1);};say(l.main.phrase,b);}
  function bySound(h,word){
    ui.rounds=2;var l=ui.lesson,scene=l.scenes[ui.round%4],imgs=shuffle(l.images,l.index+ui.round*7);
    var c=document.createElement('div');c.className='caption';var b=document.createElement('button');b.className='listen';b.textContent='🔊';c.appendChild(b);h.appendChild(c);
    var target=word?scene.key:scene.phrase;b.onclick=function(){say(target,b);};say(target,b);
    imageRow(h,imgs,scene.image,nextRound);
  }
  function byText(h){ui.rounds=2;var l=ui.lesson,scene=l.scenes[(ui.round+1)%4],imgs=shuffle(l.images,l.index+ui.round*11);
    var cap=document.createElement('div');cap.className='caption';var s=document.createElement('div');s.className='sent en';s.textContent=scene.phrase;cap.appendChild(s);h.appendChild(cap);
    imageRow(h,imgs,scene.image,nextRound);}
  function contextual(h){ui.rounds=2;var l=ui.lesson,scene=l.scenes[(ui.round+2)%4];
    hero(h,scene,false);
    var cap=document.createElement('div');cap.className='caption';var s=document.createElement('div');s.className='sent en';
    s.innerHTML=scene.phrase.replace(new RegExp('\\b'+scene.key+'\\b','i'),'<span style="color:var(--gold)">____</span>');cap.appendChild(s);h.appendChild(cap);
    var opts=[scene.key];l.scenes.forEach(function(x){if(x.key!==scene.key&&opts.indexOf(x.key)===-1)opts.push(x.key);});
    while(opts.length<4)opts.push(l.scenes[(opts.length+ui.round)%4].key+'s');
    textLine(h,shuffle(opts,l.index+ui.round),scene.key,nextRound);}
  function recognize(h){ui.rounds=2;var l=ui.lesson,scene=l.scenes[(ui.round+3)%4];hero(h,scene,false);
    textLine(h,shuffle(l.phrases,l.index+ui.round*5),scene.phrase,nextRound);}
  function build(h){ui.rounds=2;var l=ui.lesson,scene=l.scenes[ui.round%4];hero(h,scene,false);
    var slots=document.createElement('div');slots.className='slots en';var pool=document.createElement('div');pool.className='pool en';var placed=[];
    shuffle(scene.words.map(function(w,i){return {w:w,i:i};}),l.index+ui.round).forEach(function(t){var c=document.createElement('button');c.className='chip';c.textContent=t.w;c.onclick=function(){c.classList.add('used');placed.push(t);draw();};pool.appendChild(c);});
    function draw(){slots.innerHTML='';placed.forEach(function(t,j){var c=document.createElement('button');c.className='chip placed';c.textContent=t.w;c.onclick=function(){placed.splice(j,1);var o=[].slice.call(pool.children).filter(function(x){return x.textContent===t.w&&x.classList.contains('used');})[0];if(o)o.classList.remove('used');draw();};slots.appendChild(c);});
      if(placed.map(function(t){return t.w;}).join(' ')===scene.words.join(' ')){mark(1);say(scene.phrase);nextRound();}}
    h.append(slots,pool);}
  function speaking(h){var l=ui.lesson,b=hero(h,l.main,true);b.onclick=function(){say(l.main.phrase,b);};
    var mic=document.createElement('button');mic.className='mic';mic.textContent='🎙 SPEAK';
    var meter=document.createElement('div');meter.className='levelbar';meter.innerHTML='<span></span>';
    var st=document.createElement('div');st.className='status';st.textContent='Press and say the sentence';
    var self=document.createElement('button');self.className='self';self.textContent='Practiced aloud (no pronunciation score)';
    h.append(mic,meter,st,self);
    mic.onclick=function(){speechCheck(l.main.phrase,mic,meter.firstChild,st);};
    self.onclick=function(){state.stats.speaking++;save();gate(true);mark(1);st.textContent='Practice recorded — pronunciation not scored';};}
  function speechCheck(target,btn,bar,st){var SR=window.SpeechRecognition||window.webkitSpeechRecognition;
    if(!SR){st.textContent='Speech recognition unavailable in this browser';return;}
    try{var r=new SR();r.lang='en-US';r.interimResults=false;btn.classList.add('rec');bar.style.width='35%';st.textContent='Listening...';
      r.onresult=function(e){btn.classList.remove('rec');var said=e.results[0][0].transcript;bar.style.width='100%';st.textContent='Heard: '+said;
        if(norm(said)===norm(target)){state.stats.speaking++;save();gate(true);mark(1);}else{mark(0);}};
      r.onerror=function(e){btn.classList.remove('rec');bar.style.width='0%';st.textContent='Recognition error: '+(e.error||'');mark(0);};
      r.onend=function(){btn.classList.remove('rec');};r.start();}catch(e){btn.classList.remove('rec');st.textContent='Microphone could not start';}}

  function reviewing(h){ui.rounds=4;var l=ui.lesson,prev=C.allLessons[l.index-1]||l;
    if(ui.round<2){var ps=prev.scenes[ui.round%4],imgs=shuffle(prev.images,prev.index+ui.round);
      var cap=document.createElement('div');cap.className='caption';var s=document.createElement('div');s.className='sent en';s.textContent=ps.phrase;cap.appendChild(s);h.appendChild(cap);
      imageRow(h,imgs,ps.image,nextRound);
    }else if(ui.round===2){var sc=l.main,imgs2=shuffle(l.images,l.index+41);
      var c2=document.createElement('div');c2.className='caption';var t2=document.createElement('div');t2.className='sent en';t2.textContent=sc.phrase;c2.appendChild(t2);h.appendChild(c2);
      imageRow(h,imgs2,sc.image,nextRound);
    }else{var sc3=l.scenes[1];hero(h,sc3,false);
      var cap3=document.createElement('div');cap3.className='caption';var x=document.createElement('div');x.className='sent en';x.innerHTML=sc3.phrase.replace(new RegExp('\\b'+sc3.key+'\\b','i'),'____');cap3.appendChild(x);h.appendChild(cap3);
      textLine(h,shuffle(l.scenes.map(function(s){return s.key;}),l.index+53),sc3.key,nextRound);}
  }
  function advance(){if(!ui.ok)return;if(ui.act<8){ui.act++;ui.round=0;render();return;}
    var l=ui.lesson,r=rec(l.id);r.done=true;r.reps=0;r.due=Date.now()+SRS[0]*86400000;r.at=Date.now();touch();state.xp+=10;save();toast('Lesson mastered');
    var nx=nextLesson();if(nx){ui.li=nx.levelIndex;ui.ui_=nx.unitIndex;}exitLesson();}

  /* tests */
  function startTest(type){var lv=ui.li,base=type==='unit'?lv*12+ui.ui_*4:lv*12;var src=[];for(var k=base;k<base+(type==='unit'?4:12);k++)src.push(C.allLessons[k]);
    ui.quiz={type:type,id:(type==='unit'?'U-'+lv+'-'+ui.ui_:'L-'+lv),qs:shuffle(src,Date.now()%997).slice(0,type==='unit'?4:6),i:0,res:[]};question();}
  function question(){var q=ui.quiz;if(q.i>=q.qs.length){testEnd();return;}
    var l=q.qs[q.i],kind=q.i%3,body=$('testWrap');body.innerHTML='';
    var cap=document.createElement('div');cap.className='caption';cap.style.justifyContent='center';var s=document.createElement('div');s.className='sent en';
    var right,opts,imgs=false;
    if(kind===0){s.textContent=l.main.phrase;right=l.main.image;opts=shuffle(l.images,l.index+3);imgs=true;}
    else if(kind===1){s.textContent=l.titleSub;right=l.main.phrase;opts=shuffle(l.phrases,l.index+7);}
    else{s.innerHTML=l.main.phrase.replace(new RegExp('\\b'+l.main.key+'\\b','i'),'____');right=l.main.key;opts=shuffle(l.scenes.map(function(x){return x.key;}),l.index+11);}
    cap.appendChild(s);body.appendChild(cap);
    if(imgs)imageRow(body,opts,right,function(){q.res.push(true);q.i++;question();});
    else{textLine(body,opts,right,function(){q.res.push(true);q.i++;question();});
      [].slice.call(body.querySelectorAll('.word-opt')).forEach(function(b){if(b.textContent!==right){var old=b.onclick;b.onclick=function(){mark(0);q.res.push(false);q.i++;question();};}});}
    $('testModal').classList.add('on');}
  function testEnd(){var q=ui.quiz,pct=Math.round(q.res.filter(Boolean).length/q.qs.length*100),pass=pct>=75;var old=state.tests[q.id];
    if(pass&&!(old&&old.pass))state.xp+=q.type==='unit'?25:50;state.tests[q.id]={pass:pass||(old&&old.pass),score:Math.max(pct,old?old.score:0)};touch();save();
    $('testWrap').innerHTML='<div class="caption" style="justify-content:center"><div class="sent" style="font-size:34px">'+pct+'%</div></div><div class="caption" style="justify-content:center"><div class="sent">'+(pass?'PASSED':'TRY AGAIN')+'</div></div><button class="next" style="margin:16px auto" id="tclose">OK</button>';
    $('tclose').onclick=function(){$('testModal').classList.remove('on');home();};}
  function openReview(){var list=C.allLessons.filter(function(l){return due(l.id);}),box=$('reviewWrap');box.innerHTML='';
    if(!list.length)box.innerHTML='<div class="caption" style="justify-content:center"><div class="sent">Nothing due now</div></div>';
    list.slice(0,10).forEach(function(l){var row=document.createElement('div');row.className='line';row.style.marginBottom='10px';var b=document.createElement('button');b.className='word-opt en';b.textContent=l.main.phrase;b.onclick=function(){
      var opts=shuffle(l.images,l.index+19);row.innerHTML='';imageRow(row,opts,l.main.image,function(){var r=rec(l.id);r.reps++;r.due=Date.now()+SRS[Math.min(r.reps-1,SRS.length-1)]*86400000;state.stats.reviews++;state.xp+=3;save();toast('Reviewed');$('reviewModal').classList.remove('on');home();});};row.appendChild(b);box.appendChild(row);});
    $('reviewModal').classList.add('on');}

  function boot(){if(!C){$('loading').classList.add('hide');return;}state=load();
    $('next').onclick=advance;$('exit').onclick=exitLesson;
    $('texit').onclick=function(){$('testModal').classList.remove('on');};$('rexit').onclick=function(){$('reviewModal').classList.remove('on');};
    home();setTimeout(function(){$('loading').classList.add('hide');},220);}
  if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',boot);else boot();
})();
