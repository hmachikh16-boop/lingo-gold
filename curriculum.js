/* ============================================================
   Lingo Gold — Immersion Curriculum
   Context-first syllabus built from the 120 local photographs.
   Every picture is tied to its correct English word / sentence.
   Distractors come from the same semantic family (never random).
   New language is recycled in later, richer contexts.
   ============================================================ */
(function (global) {
  'use strict';

  var IMG = function (name) { return 'assets/img/img_' + name + '.jpg'; };

  /* Semantic families — used to keep distractors meaningful */
  var CAT = {
    hello: 'greeting', goodbye: 'greeting', hello_context: 'greeting', milestone: 'greeting',
    man: 'people', woman: 'people', boy: 'people', girl: 'people', baby: 'people',
    family: 'people', family_home: 'people', mother: 'people', father: 'people', sister: 'people', brother: 'people',
    one_dog: 'numbers', two_dogs: 'numbers', two_pens: 'numbers', three_cats: 'numbers',
    three_bicycles: 'numbers', one_car: 'numbers', one_egg: 'numbers', one_apple: 'numbers',
    two_apples: 'numbers', three_apples: 'numbers', four_apples: 'numbers', five_newspapers: 'numbers',
    six_apples: 'numbers', four_boys: 'numbers', six_girls: 'numbers', five_boys: 'numbers',
    color_red: 'colors', color_blue: 'colors', color_green: 'colors', color_yellow: 'colors',
    dog: 'animals', cat: 'animals', bird: 'animals', fish: 'animals',
    house: 'home', door: 'home', window: 'home', chair: 'home', table: 'home', bed: 'home',
    reading: 'actions', writing: 'actions', running: 'actions', jumping: 'actions',
    sitting: 'actions', sleeping: 'actions', eating: 'actions', drinking: 'actions',
    shirt: 'clothes', pants: 'clothes', shoes: 'clothes', hat: 'clothes', dress: 'clothes',
    book: 'school', pen: 'school', pencil: 'school', desk: 'school', teacher: 'school', student: 'school', classroom: 'school',
    apple: 'food', banana: 'food', bread: 'food', milk: 'food', oranges: 'food',
    tomatoes: 'food', vegetables: 'food', vendor: 'food', money: 'food',
    car: 'transport', bus: 'transport', bicycle: 'transport', train: 'transport',
    airplane: 'transport', boat: 'transport', train_station: 'transport', airport: 'transport', hotel: 'transport',
    market: 'places', park: 'places', library: 'places', hospital: 'places', school: 'places', street: 'places', building: 'places',
    sun: 'nature', moon: 'nature', cloud: 'nature', tree: 'nature', flower: 'nature', mountain: 'nature', river: 'nature',
    sunny: 'weather', rainy: 'weather', snowy: 'weather', windy: 'weather',
    morning: 'time', evening: 'time', night: 'time', clock: 'time',
    doctor: 'professions', nurse: 'professions', chef: 'professions', farmer: 'professions', police: 'professions',
    soccer: 'sports', basketball: 'sports', swimming: 'sports', music: 'sports', painting: 'sports',
    head: 'body', hand: 'body', eye: 'body', foot: 'body',
    map: 'travel'
  };

  /* [image, sentence, context question, Arabic title, English title] */
  var SEEDS = {
    A1: [
      [
        ['hello', 'Hello.', 'How do people greet each other?', 'مرحبًا', 'Greetings'],
        ['goodbye', 'Goodbye.', 'What do people say when they leave?', 'وداعًا', 'Saying Goodbye'],
        ['man', 'The man is reading.', 'Who is reading?', 'الرجل يقرأ', 'The Man'],
        ['woman', 'The woman is smiling.', 'Who is smiling?', 'المرأة تبتسم', 'The Woman']
      ],
      [
        ['boy', 'This is a boy.', 'Who is this?', 'هذا ولد', 'A Boy'],
        ['girl', 'This is a girl.', 'Who is this?', 'هذه بنت', 'A Girl'],
        ['one_apple', 'I have one apple.', 'How many apples?', 'تفاحة واحدة', 'One Apple'],
        ['two_pens', 'I can see two pens.', 'What can you see?', 'قلمان', 'Two Pens']
      ],
      [
        ['color_red', 'The color is red.', 'What color is it?', 'اللون أحمر', 'Red'],
        ['color_blue', 'The color is blue.', 'What color is it?', 'اللون أزرق', 'Blue'],
        ['dog', 'The dog is running.', 'Which animal is running?', 'الكلب يركض', 'A Running Dog'],
        ['cat', 'The cat is sleeping.', 'Which animal is sleeping?', 'القطة نائمة', 'A Sleeping Cat']
      ]
    ],
    A2: [
      [
        ['mother', 'This is my mother.', 'Who is this?', 'هذه أمي', 'My Mother'],
        ['father', 'My father is reading.', 'What is he doing?', 'أبي يقرأ', 'My Father'],
        ['house', 'This is my house.', 'What is this?', 'هذا بيتي', 'My House'],
        ['family_home', 'My family is at home.', 'Where is the family?', 'العائلة في البيت', 'At Home']
      ],
      [
        ['writing', 'She is writing a letter.', 'What is she doing?', 'هي تكتب رسالة', 'Writing'],
        ['jumping', 'The girl is jumping.', 'What is the girl doing?', 'البنت تقفز', 'Jumping'],
        ['drinking', 'He is drinking water.', 'What is he drinking?', 'هو يشرب ماء', 'Drinking'],
        ['eating', 'They are eating lunch.', 'What are they doing?', 'هم يتناولون الغداء', 'Eating']
      ],
      [
        ['bread', 'I would like some bread.', 'What would you like?', 'أريد بعض الخبز', 'Bread'],
        ['milk', 'There is a glass of milk.', 'What is on the table?', 'كوب من الحليب', 'Milk'],
        ['market', 'We are at the market.', 'Where are they?', 'نحن في السوق', 'The Market'],
        ['park', 'The children are playing in the park.', 'Where are the children?', 'الأطفال في الحديقة', 'The Park']
      ]
    ],
    B1: [
      [
        ['morning', 'I usually get up early in the morning.', 'What do you usually do in the morning?', 'صباحي المعتاد', 'Morning Routine'],
        ['nurse', 'She has worked as a nurse for five years.', 'What does she do?', 'ممرضة', 'A Nurse'],
        ['teacher', 'He is a teacher at the local school.', 'Who is he?', 'معلم', 'A Teacher'],
        ['bus', 'We take the bus to work every day.', 'How do they go to work?', 'بالحافلة', 'Taking the Bus']
      ],
      [
        ['train', 'The train leaves at six o\'clock.', 'When does the train leave?', 'القطار يغادر السادسة', 'The Train'],
        ['airplane', 'We travelled to London by plane.', 'How did they travel?', 'سافرنا بالطائرة', 'By Plane'],
        ['airport', 'The airport was very busy yesterday.', 'How was the airport?', 'المطار كان مزدحمًا', 'The Airport'],
        ['hotel', 'We stayed at a small hotel near the beach.', 'Where did they stay?', 'فندق صغير', 'The Hotel']
      ],
      [
        ['rainy', 'It has been raining all morning.', 'What has the weather been like?', 'مطر طول الصباح', 'Rainy Weather'],
        ['river', 'The river flows through the village.', 'What flows through the village?', 'النهر', 'The River'],
        ['mountain', 'We climbed the mountain last summer.', 'What did they climb?', 'تسلقنا الجبل', 'The Mountain'],
        ['sunny', 'The weather is sunny and warm today.', 'How is the weather today?', 'جو مشمس', 'Sunny Weather']
      ]
    ],
    B2: [
      [
        ['painting', 'I have already finished the painting.', 'What has she finished?', 'أنهيت اللوحة', 'A Finished Painting'],
        ['chef', 'The chef had prepared dinner before we arrived.', 'Who prepared dinner?', 'الطاهي حضّر العشاء', 'The Chef'],
        ['milestone', 'Congratulations on your great achievement!', 'What do you say to someone who succeeded?', 'تهانينا على الإنجاز', 'Achievement'],
        ['library', 'The library provides free books for everyone.', 'What does the library provide?', 'المكتبة توفر الكتب', 'The Library']
      ],
      [
        ['hospital', 'The doctor suggested that I rest at home.', 'What did the doctor suggest?', 'نصيحة الطبيب', 'Doctor Advice'],
        ['cloud', 'If it gets cloudy, we will go inside.', 'What will they do if it gets cloudy?', 'إذا غيمت السماء', 'Cloudy Skies'],
        ['police', 'The police officer helped the lost tourist.', 'Who helped the tourist?', 'ساعد الشرطي السائح', 'Helpful Officer'],
        ['street', 'The new street was opened last month.', 'What was opened last month?', 'شارع جديد', 'A New Street']
      ],
      [
        ['swimming', 'They enjoy swimming in the sea.', 'What do they enjoy?', 'يحبون السباحة', 'Swimming'],
        ['music', 'The music was playing loudly in the room.', 'How was the music playing?', 'الموسيقى كانت عالية', 'Loud Music'],
        ['tree', 'The old tree stands beside the road.', 'What stands beside the road?', 'شجرة قديمة', 'An Old Tree'],
        ['boat', 'We might travel by boat tomorrow.', 'How might they travel?', 'قد نسافر بالقارب', 'By Boat']
      ]
    ]
  };

  var LEVELS = [
    { id: 'A1', name: 'A1 · مبتدئ', en: 'Beginner', desc: 'ألفاظ يومية وجمل قصيرة مرتبطة بالصورة', color: '#2f9e6f' },
    { id: 'A2', name: 'A2 · أساسي', en: 'Elementary', desc: 'الأسرة، الأفعال، والأماكن في سياق حي', color: '#2b7fc4' },
    { id: 'B1', name: 'B1 · متوسط', en: 'Intermediate', desc: 'الروتين والسفر والطقس بتراكيب أغنى', color: '#8e5bd0' },
    { id: 'B2', name: 'B2 · فوق المتوسط', en: 'Upper Intermediate', desc: 'خبرات وآراء وتعبيرات متقدمة', color: '#d9772f' }
  ];

  var UNIT_NAMES = {
    A1: ['أول الكلمات', 'الأشخاص والأشياء', 'الألوان والحيوانات'],
    A2: ['العائلة والبيت', 'الأفعال اليومية', 'الطعام والأماكن'],
    B1: ['الروتين والعمل', 'السفر والمواصلات', 'الطبيعة والطقس'],
    B2: ['الخبرات والإنجازات', 'المجتمع والخدمات', 'الثقافة والترفيه']
  };
  var UNIT_NAMES_EN = {
    A1: ['First Words', 'People & Things', 'Colors & Animals'],
    A2: ['Family & Home', 'Everyday Actions', 'Food & Places'],
    B1: ['Routines & Work', 'Travel & Transport', 'Nature & Weather'],
    B2: ['Experiences', 'Community & Services', 'Culture & Leisure']
  };

  var seedsFlat = [];
  Object.keys(SEEDS).forEach(function (lid) {
    SEEDS[lid].forEach(function (u) { u.forEach(function (s) { seedsFlat.push(s); }); });
  });

  function familyOf(name) { return CAT[name] || 'other'; }
  function pickFamily(name, count, exclude) {
    var fam = familyOf(name);
    var pool = Object.keys(CAT).filter(function (k) {
      return CAT[k] === fam && k !== name && exclude.indexOf(k) === -1;
    });
    if (pool.length < count) {
      Object.keys(CAT).forEach(function (k) {
        if (k !== name && exclude.indexOf(k) === -1 && pool.indexOf(k) === -1) pool.push(k);
      });
    }
    return pool.slice(0, count);
  }

  var counter = 0;
  var levels = LEVELS.map(function (level, li) {
    var units = SEEDS[level.id].map(function (unitSeeds, ui) {
      var lessons = unitSeeds.map(function (seed, si) {
        var idx = counter++;
        var name = seed[0];
        var fam = familyOf(name);
        var imageNames = [name].concat(pickFamily(name, 3, [name]));
        var sameFamilyPhrases = seedsFlat.filter(function (s) {
          return s[1] !== seed[1] && familyOf(s[0]) === fam;
        }).map(function (s) { return s[1]; });
        sameFamilyPhrases = sameFamilyPhrases.filter(function (x, i) { return sameFamilyPhrases.indexOf(x) === i; });
        if (sameFamilyPhrases.length < 2) {
          seedsFlat.forEach(function (s) {
            if (s[1] !== seed[1] && sameFamilyPhrases.indexOf(s[1]) === -1) sameFamilyPhrases.push(s[1]);
          });
        }
        return {
          id: level.id + '-U' + (ui + 1) + '-L' + (si + 1),
          index: idx, levelIndex: li, unitIndex: ui, lessonInUnit: si + 1,
          titleAr: seed[3], titleEn: seed[4],
          image: IMG(name), imageName: name, category: fam,
          phrase: seed[1], question: seed[2], speak: seed[1],
          words: seed[1].replace(/([.!?])$/, ' $1').trim().split(/\s+/),
          imageOptions: imageNames.map(IMG),
          imageAnswer: 0,
          phraseOptions: [seed[1], sameFamilyPhrases[0], sameFamilyPhrases[1]],
          phraseAnswer: 0
        };
      });
      return {
        id: level.id + '-U' + (ui + 1), unitInLevel: ui + 1,
        titleAr: UNIT_NAMES[level.id][ui], titleEn: UNIT_NAMES_EN[level.id][ui],
        lessons: lessons
      };
    });
    return {
      id: level.id, levelIndex: li, name: level.name, en: level.en,
      desc: level.desc, color: level.color, units: units
    };
  });

  var allLessons = levels.reduce(function (a, lv) {
    return a.concat(lv.units.reduce(function (b, u) { return b.concat(u.lessons); }, []));
  }, []);

  // Build matching sets: current lesson plus two earlier lessons from the same level.
  allLessons.forEach(function (l, i) {
    var earlier = allLessons.slice(0, i).filter(function (x) { return x.levelIndex === l.levelIndex; });
    if (earlier.length < 2) earlier = allLessons.slice(0, i);
    var picks = earlier.slice(-2);
    while (picks.length < 2) picks.push(allLessons[(i + picks.length + 3) % allLessons.length]);
    l.matchPairs = [l].concat(picks).map(function (x) {
      return { image: x.image, phrase: x.phrase, title: x.titleAr };
    });
  });

  global.IMS_CURRICULUM = {
    version: 4,
    levels: levels,
    allLessons: allLessons,
    stages: ['observe', 'listen', 'understand', 'select', 'match', 'build', 'speak', 'review']
  };
})(window);
