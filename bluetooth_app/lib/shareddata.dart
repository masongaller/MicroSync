import 'dart:math';

import 'package:flutter/material.dart';

class SharedData extends ChangeNotifier {
  List<Point> _points = [];

  List<Point> get points => _points;

  void addPoint() {
    _points.add(Point(_points.length, Random().nextDouble() * 10));
    notifyListeners();  // This will alert the widgets that are listening to this model.
  }
}