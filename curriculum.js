/* ============================================================
   Lingo Gold — Immersion Curriculum
   120 local photographs → semantic families → 48 graded lessons.
   Every scene has one correct sentence; grammar grows A1 → B2.
   ============================================================ */
(function (global) {
  'use strict';

  var P = function (n) { return 'assets/img/img_' + n + '.jpg'; };

  var FAMILY = {
    hello: 'greeting', goodbye: 'greeting', hello_context: 'greeting', milestone: 'greeting',
    man: 'people', woman: 'people', boy: 'people', girl: 'people', baby: 'people',
    family: 'people', family_home: 'people', mother: 'people', father: 'people', sister: 'people', brother: 'people',
    one_dog: 'numbers', two_dogs: 'numbers', two_pens: 'numbers', three_cats: 'numbers', three_bicycles: 'numbers',
    one_car: 'numbers', one_egg: 'numbers', one_apple: 'numbers', two_apples: 'numbers', three_apples: 'numbers',
    four_apples: 'numbers', five_newspapers: 'numbers', six_apples: 'numbers', four_boys: 'numbers',
    six_girls: 'numbers', five_boys: 'numbers',
    color_red: 'colors', color_blue: 'colors', color_green: 'colors', color_yellow: 'colors',
    dog: 'animals', cat: 'animals', bird: 'animals', fish: 'animals',
    house: 'home', door: 'home', window: 'home', chair: 'home', table: 'home', bed: 'home',
    reading: 'actions', writing: 'actions', running: 'actions', jumping: 'actions', sitting: 'actions',
    sleeping: 'actions', eating: 'actions', drinking: 'actions',
    shirt: 'clothes', pants: 'clothes', shoes: 'clothes', hat: 'clothes', dress: 'clothes',
    book: 'school', pen: 'school', pencil: 'school', desk: 'school', teacher: 'school', student: 'school', classroom: 'school',
    apple: 'food', banana: 'food', bread: 'food', milk: 'food', oranges: 'food', tomatoes: 'food',
    vegetables: 'food', vendor: 'food', money: 'food',
    car: 'transport', bus: 'transport', bicycle: 'transport', train: 'transport', airplane: 'transport',
    boat: 'transport', train_station: 'transport', airport: 'transport', hotel: 'transport',
    market: 'places', park: 'places', library: 'places', hospital: 'places', school: 'places', street: 'places', building: 'places',
    sun: 'nature', moon: 'nature', cloud: 'nature', tree: 'nature', flower: 'nature', mountain: 'nature', river: 'nature',
    sunny: 'weather', rainy: 'weather', snowy: 'weather', windy: 'weather',
    morning: 'time', evening: 'time', night: 'time', clock: 'time',
    doctor: 'professions', nurse: 'professions', chef: 'professions', farmer: 'professions', police: 'professions',
    soccer: 'sports', basketball: 'sports', swimming: 'sports', music: 'sports', painting: 'sports',
    head: 'body', hand: 'body', eye: 'body', foot: 'body', map: 'travel'
  };

  /* image, sentence, focus word, context question, AR title, EN title */
  var SEEDS = {
    A1: [
      [
        ['hello', 'Hello.', 'Hello', 'How do people greet?', 'مرحبًا', 'Greetings'],
        ['goodbye', 'Goodbye.', 'Goodbye', 'What do people say when leaving?', 'وداعًا', 'Farewell'],
        ['man', 'This is a man.', 'man', 'Who is this?', 'هذا رجل', 'A Man'],
        ['woman', 'This is a woman.', 'woman', 'Who is this?', 'هذه امرأة', 'A Woman']
      ],
      [
        ['boy', 'This is a boy.', 'boy', 'Who is this?', 'هذا ولد', 'A Boy'],
        ['girl', 'This is a girl.', 'girl', 'Who is this?', 'هذه بنت', 'A Girl'],
        ['one_apple', 'I have one apple.', 'apple', 'How many apples?', 'تفاحة واحدة', 'One Apple'],
        ['two_pens', 'I have two pens.', 'pens', 'What do I have?', 'قلمان', 'Two Pens']
      ],
      [
        ['color_red', 'The apple is red.', 'red', 'What color is the apple?', 'أحمر', 'Red'],
        ['color_blue', 'The sky is blue.', 'blue', 'What color is the sky?', 'أزرق', 'Blue'],
        ['dog', 'This is a dog.', 'dog', 'Which animal is this?', 'كلب', 'A Dog'],
        ['cat', 'This is a cat.', 'cat', 'Which animal is this?', 'قطة', 'A Cat']
      ]
    ],
    A2: [
      [
        ['mother', 'This is my mother.', 'mother', 'Who is this?', 'أمي', 'My Mother'],
        ['father', 'My father is reading.', 'reading', 'What is he doing?', 'أبي يقرأ', 'My Father'],
        ['house', 'This is my house.', 'house', 'What is this?', 'بيتي', 'My House'],
        ['family_home', 'My family is at home.', 'family', 'Where is the family?', 'العائلة', 'At Home']
      ],
      [
        ['reading', 'She is reading a book.', 'reading', 'What is she doing?', 'تقرأ', 'Reading'],
        ['writing', 'He is writing a letter.', 'writing', 'What is he doing?', 'يكتب', 'Writing'],
        ['running', 'The man is running.', 'running', 'What is the man doing?', 'يركض', 'Running'],
        ['drinking', 'She is drinking water.', 'drinking', 'What is she drinking?', 'تشرب', 'Drinking']
      ],
      [
        ['bread', 'I would like some bread.', 'bread', 'What would you like?', 'خبز', 'Bread'],
        ['milk', 'There is a glass of milk.', 'milk', 'What is on the table?', 'حليب', 'Milk'],
        ['market', 'We are at the market.', 'market', 'Where are they?', 'السوق', 'The Market'],
        ['park', 'The children are in the park.', 'children', 'Where are the children?', 'الحديقة', 'The Park']
      ]
    ],
    B1: [
      [
        ['morning', 'I get up early in the morning.', 'morning', 'When do you get up?', 'الصباح', 'Morning'],
        ['nurse', 'She works as a nurse.', 'nurse', 'What does she do?', 'ممرضة', 'A Nurse'],
        ['teacher', 'He teaches at a school.', 'teaches', 'What does he do?', 'معلم', 'A Teacher'],
        ['bus', 'I go to work by bus.', 'bus', 'How do you go to work?', 'الحافلة', 'By Bus']
      ],
      [
        ['train', 'The train leaves at six.', 'train', 'What leaves at six?', 'القطار', 'The Train'],
        ['airplane', 'We travelled by plane.', 'travelled', 'How did you travel?', 'الطائرة', 'By Plane'],
        ['airport', 'The airport was busy.', 'airport', 'What was busy?', 'المطار', 'The Airport'],
        ['hotel', 'We stayed at a hotel.', 'hotel', 'Where did you stay?', 'الفندق', 'The Hotel']
      ],
      [
        ['rainy', 'It was raining all day.', 'raining', 'What was the weather like?', 'ممطر', 'Rainy'],
        ['river', 'The river is very long.', 'river', 'What is very long?', 'النهر', 'The River'],
        ['mountain', 'We climbed the mountain.', 'mountain', 'What did you climb?', 'الجبل', 'The Mountain'],
        ['sunny', 'It is sunny today.', 'sunny', 'How is the weather?', 'مشمس', 'Sunny']
      ]
    ],
    B2: [
      [
        ['painting', 'I have finished the painting.', 'finished', 'What have you finished?', 'اللوحة', 'Finished'],
        ['chef', 'The chef prepared dinner.', 'prepared', 'Who prepared dinner?', 'الطاهي', 'The Chef'],
        ['milestone', 'Congratulations on your achievement!', 'achievement', 'What do you celebrate?', 'الإنجاز', 'Achievement'],
        ['library', 'The library has many books.', 'library', 'What has many books?', 'المكتبة', 'The Library']
      ],
      [
        ['hospital', 'The doctor advised me to rest.', 'advised', 'What did the doctor do?', 'نصيحة', 'Advice'],
        ['cloud', 'If it rains, we will stay in.', 'rains', 'What happens if it rains?', 'غيوم', 'Clouds'],
        ['police', 'The officer helped the tourist.', 'helped', 'Who helped the tourist?', 'الشرطي', 'Help'],
        ['street', 'They opened a new street.', 'opened', 'What did they open?', 'الشارع', 'A New Street']
      ],
      [
        ['swimming', 'They enjoy swimming.', 'swimming', 'What do they enjoy?', 'السباحة', 'Swimming'],
        ['music', 'The music was too loud.', 'loud', 'How was the music?', 'الموسيقى', 'Music'],
        ['tree', 'An old tree stands nearby.', 'tree', 'What stands nearby?', 'الشجرة', 'A Tree'],
        ['boat', 'We might travel by boat.', 'boat', 'How might you travel?', 'القارب', 'By Boat']
      ]
    ]
  };

  var LEVELS = [
    { id: 'A1', name: 'A1 — Beginner', ar: 'مبتدئ', desc: 'أول الكلمات والجمل القصيرة' },
    { id: 'A2', name: 'A2 — Elementary', ar: 'أساسي', desc: 'الأسرة والأفعال والأماكن' },
    { id: 'B1', name: 'B1 — Intermediate', ar: 'متوسط', desc: 'الروتين والسفر والطقس' },
    { id: 'B2', name: 'B2 — Upper Intermediate', ar: 'فوق المتوسط', desc: 'خبرات وتعبيرات أعمق' }
  ];
  var UNITS = {
    A1: ['First Words', 'People & Things', 'Colors & Animals'],
    A2: ['Family & Home', 'Everyday Actions', 'Food & Places'],
    B1: ['Routines & Work', 'Travel & Transport', 'Nature & Weather'],
    B2: ['Experiences', 'Community', 'Culture & Leisure']
  };
  var UNITS_AR = {
    A1: ['أول الكلمات', 'الأشخاص والأشياء', 'الألوان والحيوانات'],
    A2: ['العائلة والبيت', 'الأفعال اليومية', 'الطعام والأماكن'],
    B1: ['الروتين والعمل', 'السفر والمواصلات', 'الطبيعة والطقس'],
    B2: ['الخبرات', 'المجتمع', 'الثقافة والترفيه']
  };

  var flatSeeds = [];
  Object.keys(SEEDS).forEach(function (l) { SEEDS[l].forEach(function (u) { u.forEach(function (s) { flatSeeds.push(s); }); }); });

  function sameFamily(name, count, exclude) {
    var fam = FAMILY[name];
    var pool = Object.keys(FAMILY).filter(function (k) { return FAMILY[k] === fam && k !== name && exclude.indexOf(k) === -1; });
    while (pool.length < count) {
      Object.keys(FAMILY).forEach(function (k) {
        if (k !== name && exclude.indexOf(k) === -1 && pool.indexOf(k) === -1) pool.push(k);
      });
    }
    return pool.slice(0, count);
  }
  function otherWords(seed, count) {
    var w = seed[2];
    var pool = flatSeeds.filter(function (s) { return s[2].toLowerCase() !== w.toLowerCase(); })
      .map(function (s) { return s[2]; });
    pool = pool.filter(function (x, i) { return pool.indexOf(x) === i; });
    return pool.slice(0, count);
  }

  var n = 0;
  var levels = LEVELS.map(function (lv, li) {
    var units = SEEDS[lv.id].map(function (unitSeeds, ui) {
      var lessons = unitSeeds.map(function (s, si) {
        var idx = n++, name = s[0], focus = s[2];
        var words = s[1].replace(/([.!?])$/, ' $1').trim().split(/\s+/);
        var blank = s[1].replace(new RegExp('\\b' + focus + '\\b', 'i'), '____');
        var imgNames = [name].concat(sameFamily(name, 3, [name]));
        var phrs = flatSeeds.filter(function (x) { return x[1] !== s[1] && FAMILY[x[0]] === FAMILY[name]; })
          .map(function (x) { return x[1]; });
        phrs = phrs.filter(function (x, i) { return phrs.indexOf(x) === i; });
        if (phrs.length < 2) phrs = flatSeeds.map(function (x) { return x[1]; }).filter(function (x) { return x !== s[1]; });
        var wds = [focus].concat(otherWords(s, 3));
        return {
          id: lv.id + '-U' + (ui + 1) + '-L' + (si + 1),
          index: idx, levelIndex: li, unitIndex: ui, lessonInUnit: si + 1,
          titleAr: s[4], titleEn: s[5], level: lv.id,
          image: P(name), imageName: name, category: FAMILY[name],
          phrase: s[1], question: s[3], speak: s[1],
          words: words, focus: focus, blank: blank,
          imageOptions: imgNames.map(P), imageAnswer: 0,
          phraseOptions: [s[1], phrs[0], phrs[1]], phraseAnswer: 0,
          wordOptions: wds, wordAnswer: 0,
          unitTitle: UNITS[lv.id][ui], unitTitleAr: UNITS_AR[lv.id][ui]
        };
      });
      return { id: lv.id + '-U' + (ui + 1), title: UNITS[lv.id][ui], titleAr: UNITS_AR[lv.id][ui], lessons: lessons };
    });
    return { id: lv.id, name: lv.name, ar: lv.ar, desc: lv.desc, units: units };
  });

  var all = levels.reduce(function (a, l) { return a.concat(l.units.reduce(function (b, u) { return b.concat(u.lessons); }, [])); }, []);
  all.forEach(function (l, i) {
    var prev = all.slice(0, i).filter(function (x) { return x.levelIndex === l.levelIndex; }).slice(-2);
    if (prev.length < 2) prev = all.slice(0, i).slice(-2);
    while (prev.length < 2) prev.push(all[(i + prev.length + 5) % all.length]);
    l.review = prev.map(function (x) { return { image: x.image, phrase: x.phrase, title: x.titleAr }; });
    l.match = [l].concat(prev).map(function (x) { return { image: x.image, phrase: x.phrase }; });
  });

  global.IMS_CURRICULUM = { version: 5, levels: levels, allLessons: all, stages: 9 };
})(window);
