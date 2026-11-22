import 'dart:math';

import 'package:flutter/material.dart';

/// Original elements created for this replica, matching the *categories and
/// counts* seen in the SWF structure table. None of these come from the
/// protected file.

const int motionCount = 683;
const int shapeCount = 256;
const int soundCount = 8;

const List<String> featuredPhotos = <String>[
  'num_01.jpg',
  'num_02.jpg',
  'num_03.jpg',
  'L153_the_dog.jpg',
  'L152_the_cat.jpg',
  'L165_a_blue_pen.jpg',
  'L220_a_red_car.jpg',
  'L223_bicycle.jpg',
  'L169_a_brown_egg.jpg',
  'market_morning.jpg',
];

Duration motionDuration(int index) =>
    Duration(milliseconds: 120 + (index.abs() * 37) % 401);

double motionScale(int index) => 0.96 + ((index.abs() * 17) % 11) / 100;

double shapeRadius(int index) => 8 + (index.abs() % 9) * 2.0;

Color shapeTint(int index) {
  final t = (index.abs() % 10) / 10;
  return Color.lerp(const Color(0xFFE9F7EF), Colors.white, t) ?? Colors.white;
}

Curve shapeCurve(int index) {
  const curves = <Curve>[
    Curves.linear, Curves.easeIn, Curves.easeOut, Curves.easeInOut,
    Curves.easeInCubic, Curves.easeOutCubic, Curves.easeInOutCubic,
    Curves.easeInBack, Curves.easeOutBack, Curves.elasticOut,
  ];
  return curves[index.abs() % curves.length];
}
