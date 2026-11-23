/* ============================================================
   Lingo Gold — Immersion Syllabus
   Each lesson = 4 linked scenes. Vocabulary returns in new contexts.
   All image names verified against the 120 local files.
   ============================================================ */
(function (w) {
  'use strict';
  var IMG = function (n) { return 'assets/img/img_' + n + '.jpg'; };

  /* [image, sentence, key word] */
  var DATA = {
    A1: [
      [
        ['People', 'Ashkhas', [
          ['man','This is a man.','man'],['woman','This is a woman.','woman'],['boy','This is a boy.','boy'],['girl','This is a girl.','girl']]],
        ['Greetings', 'Tahiyya', [
          ['hello','Hello.','Hello'],['goodbye','Goodbye.','Goodbye'],['hello_context','Hello! How are you?','Hello'],['family','This is my family.','family']]],
        ['Numbers', 'Arqam', [
          ['one_apple','I have one apple.','one'],['two_apples','I have two apples.','two'],['three_apples','I have three apples.','three'],['four_apples','I have four apples.','four']]],
        ['Colors', 'Alwan', [
          ['color_red','The apple is red.','red'],['color_blue','The sky is blue.','blue'],['color_green','The leaf is green.','green'],['color_yellow','The sun is yellow.','yellow']]]
      ],
      [
        ['Family', 'Usra', [
          ['mother','This is my mother.','mother'],['father','This is my father.','father'],['sister','This is my sister.','sister'],['brother','This is my brother.','brother']]],
        ['Home', 'Bayt', [
          ['house','This is my house.','house'],['door','This is the door.','door'],['window','This is the window.','window'],['bed','This is the bed.','bed']]],
        ['School things', 'Ashya al-madrasa', [
          ['book','This is a book.','book'],['pen','This is a pen.','pen'],['pencil','This is a pencil.','pencil'],['desk','This is a desk.','desk']]],
        ['Animals', 'Hayawanat', [
          ['dog','This is a dog.','dog'],['cat','This is a cat.','cat'],['bird','This is a bird.','bird'],['fish','This is a fish.','fish']]]
      ],
      [
        ['Actions 1', 'Af al 1', [
          ['reading','He is reading.','reading'],['writing','She is writing.','writing'],['running','He is running.','running'],['jumping','She is jumping.','jumping']]],
        ['Actions 2', 'Af al 2', [
          ['sitting','He is sitting.','sitting'],['sleeping','She is sleeping.','sleeping'],['eating','He is eating.','eating'],['drinking','She is drinking.','drinking']]],
        ['Food', 'Taam', [
          ['apple','This is an apple.','apple'],['banana','This is a banana.','banana'],['bread','This is bread.','bread'],['milk','This is milk.','milk']]],
        ['Places', 'Amaakin', [
          ['park','This is the park.','park'],['school','This is the school.','school'],['market','This is the market.','market'],['library','This is the library.','library']]]
      ]
    ],
    A2: [
      [
        ['Family at home', 'Usra fil bayt', [
          ['family_home','My family is at home.','family'],['mother','My mother is reading.','mother'],['father','My father is sitting.','father'],['baby','The baby is sleeping.','baby']]],
        ['Rooms', 'Ghuraf', [
          ['house','This is my house.','house'],['door','The door is open.','door'],['window','The window is big.','window'],['chair','The chair is near the table.','chair']]],
        ['Clothes', 'Malabis', [
          ['shirt','He is wearing a shirt.','shirt'],['pants','He is wearing pants.','pants'],['shoes','She is wearing shoes.','shoes'],['hat','She is wearing a hat.','hat']]],
        ['Objects', 'Ashya', [
          ['table','The book is on the table.','table'],['bed','The cat is on the bed.','bed'],['clock','The clock is on the wall.','clock'],['book','The book is open.','book']]]
      ],
      [
        ['Morning', 'Sabah', [
          ['morning','It is morning.','morning'],['reading','I read in the morning.','read'],['drinking','I drink water in the morning.','drink'],['eating','I eat bread in the morning.','eat']]],
        ['Movement', 'Haraka', [
          ['running','They are running.','running'],['jumping','They are jumping.','jumping'],['swimming','They are swimming.','swimming'],['soccer','They are playing soccer.','soccer']]],
        ['People at work', 'Nas fi al amal', [
          ['teacher','She is a teacher.','teacher'],['student','He is a student.','student'],['doctor','She is a doctor.','doctor'],['nurse','He is a nurse.','nurse']]],
        ['Evening', 'Masa', [
          ['evening','It is evening.','evening'],['night','It is night.','night'],['sitting','We are sitting.','sitting'],['sleeping','We are sleeping.','sleeping']]]
      ],
      [
        ['At the market', 'Fil suq', [
          ['market','We are at the market.','market'],['vendor','The vendor is here.','vendor'],['money','I have money.','money'],['oranges','I like oranges.','oranges']]],
        ['Food', 'Taam', [
          ['bread','I would like some bread.','bread'],['milk','There is a glass of milk.','milk'],['tomatoes','I like tomatoes.','tomatoes'],['vegetables','We need vegetables.','vegetables']]],
        ['In town', 'Fil madina', [
          ['street','This is the street.','street'],['building','This is a tall building.','building'],['hospital','The hospital is here.','hospital'],['library','The library is quiet.','library']]],
        ['Outside', 'Fi al kharij', [
          ['park','The children are in the park.','children'],['tree','There is a tree.','tree'],['flower','There is a flower.','flower'],['river','There is a river.','river']]]
      ]
    ],
    B1: [
      [
        ['Daily routine', 'Routin yawmi', [
          ['morning','I get up early in the morning.','morning'],['clock','The clock says seven.','clock'],['bus','I go to work by bus.','bus'],['evening','I rest in the evening.','evening']]],
        ['Jobs', 'Mihan', [
          ['nurse','She has worked as a nurse for years.','nurse'],['teacher','He teaches at a school.','teaches'],['chef','The chef prepares food.','chef'],['farmer','The farmer works outside.','farmer']]],
        ['Transport', 'Muwasalat', [
          ['car','I drive a car.','car'],['bicycle','He rides a bicycle.','bicycle'],['bus','We take the bus.','bus'],['train','The train leaves at six.','train']]],
        ['School days', 'Ayyam al madrasa', [
          ['school','I went to school yesterday.','school'],['classroom','The classroom was full.','classroom'],['student','The student asked a question.','student'],['book','I read the book.','book']]]
      ],
      [
        ['At the station', 'Fil mahatta', [
          ['train_station','We arrived at the train station.','station'],['train','The train was late.','train'],['map','I looked at the map.','map'],['clock','We waited for an hour.','hour']]],
        ['Flying', 'Tayaran', [
          ['airplane','We travelled by plane.','plane'],['airport','The airport was busy.','airport'],['hotel','We stayed at a hotel.','hotel'],['map','We used a map.','map']]],
        ['Places to stay', 'Amaakin al iqama', [
          ['hotel','The hotel was small.','hotel'],['house','We visited a house.','house'],['building','The building is old.','building'],['street','The street was quiet.','street']]],
        ['Getting around', 'Tanaqul', [
          ['boat','We travelled by boat.','boat'],['car','We drove a car.','car'],['bicycle','We rode bicycles.','bicycles'],['bus','We took the bus.','bus']]]
      ],
      [
        ['Weather', 'Taqs', [
          ['sunny','It is sunny today.','sunny'],['rainy','It was raining all day.','raining'],['snowy','It is snowy in winter.','snowy'],['windy','It is windy outside.','windy']]],
        ['Landscape', 'Manzar', [
          ['mountain','We climbed the mountain.','mountain'],['river','The river flows through the village.','river'],['tree','An old tree stands nearby.','tree'],['flower','The flower is beautiful.','flower']]],
        ['Sky', 'Sama', [
          ['sun','The sun is bright.','sun'],['moon','The moon is white.','moon'],['cloud','There is a cloud.','cloud'],['night','The night is quiet.','night']]],
        ['Past weather', 'Taqs madi', [
          ['rainy','It rained yesterday.','rained'],['windy','The wind blew hard.','wind'],['sunny','The sun came out.','sun'],['snowy','Snow fell last night.','snow']]]
      ]
    ],
    B2: [
      [
        ['Achievements', 'Injazat', [
          ['milestone','Congratulations on your achievement!','achievement'],['painting','I have finished the painting.','finished'],['music','I have written the music.','written'],['book','I have read the book.','read']]],
        ['Before we arrived', 'Qabla an nasil', [
          ['chef','The chef had prepared dinner.','prepared'],['bread','I had eaten the bread.','eaten'],['family_home','They had left home.','left'],['market','We had visited the market.','visited']]],
        ['Opinions', 'Araa', [
          ['music','I think the music is beautiful.','beautiful'],['painting','I believe the painting is old.','old'],['book','This book is useful.','useful'],['soccer','Soccer is exciting.','exciting']]],
        ['The library', 'Al maktaba', [
          ['library','The library provides free books.','provides'],['book','You can borrow a book.','borrow'],['classroom','Students study in the classroom.','study'],['teacher','The teacher helps students.','helps']]]
      ],
      [
        ['Help', 'Musaada', [
          ['police','The officer helped the tourist.','helped'],['hospital','The hospital helped many people.','helped'],['doctor','The doctor advised me to rest.','advised'],['nurse','The nurse took care of him.','care']]],
        ['Advice', 'Nasiha', [
          ['doctor','If you are ill, see a doctor.','ill'],['bed','You should stay in bed.','stay'],['sleeping','You need more sleep.','sleep'],['milk','Drink a glass of milk.','drink']]],
        ['Conditions', 'Shurut', [
          ['cloud','If it gets cloudy, we will go in.','cloudy'],['rainy','If it rains, we will stay home.','rains'],['windy','If it is windy, close the window.','windy'],['sunny','If it is sunny, we will go out.','sunny']]],
        ['Neighborhood', 'Al hara', [
          ['street','They opened a new street.','opened'],['building','The building was built last year.','built'],['market','The market was crowded.','crowded'],['park','The park was cleaned.','cleaned']]]
      ],
      [
        ['Sports', 'Riyada', [
          ['swimming','They enjoy swimming.','swimming'],['soccer','He plays soccer well.','plays'],['basketball','She likes basketball.','likes'],['music','We listen to music.','listen']]],
        ['Nature', 'Tabia', [
          ['tree','An old tree stands beside the road.','stands'],['flower','Flowers grow in spring.','grow'],['mountain','The mountain is covered with snow.','covered'],['river','The river is very wide.','wide']]],
        ['Plans', 'Khatat', [
          ['boat','We might travel by boat.','might'],['airplane','We may fly to London.','may'],['hotel','We could stay at a hotel.','could'],['map','We should take a map.','should']]],
        ['Review', 'Murajaa', [
          ['library','I have already visited the library.','visited'],['mountain','We had climbed the mountain.','climbed'],['music','I have never heard such music.','heard'],['milestone','This is my greatest achievement.','achievement']]]
      ]
    ]
  };

  var all = [], index = 0;
  Object.keys(DATA).forEach(function (lid, li) {
    DATA[lid].forEach(function (unit, ui) {
      unit.forEach(function (lesson, lesi) {
        var scenes = lesson[2].map(function (s) {
          return { image: IMG(s[0]), phrase: s[1], key: s[2], words: s[1].replace(/([.!?])$/, ' $1').trim().split(/\s+/) };
        });
        var l = {
          id: lid + '-U' + (ui + 1) + '-L' + (lesi + 1),
          index: index++, level: lid, levelIndex: li, unitIndex: ui, lessonInUnit: lesi + 1,
          title: lesson[0], titleSub: lesson[1],
          unitTitle: ['First Words','People & Things','Colors & Actions'][ui] || lesson[0],
          scenes: scenes,
          main: scenes[0],
          images: scenes.map(function (s) { return s.image; }),
          phrases: scenes.map(function (s) { return s.phrase; })
        };
        all.push(l);
      });
    });
  });

  w.IMS_CURRICULUM = { version: 6, allLessons: all, levels: ['A1','A2','B1','B2'], count: all.length };
})(window);
