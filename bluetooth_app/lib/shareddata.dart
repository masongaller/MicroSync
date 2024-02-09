import 'dart:math';

import 'package:flutter/material.dart';

class SharedData extends ChangeNotifier {
  List<Point> _points = [];

  List<Point> get points => _points;

  // simulate a data source
  void simulateDataStream() async {
    for (var i = 0; i < 100; i++) {
      await Future.delayed(const Duration(seconds: 2));
      _points.add(Point(_points.length, Random().nextDouble() * 100));
      notifyListeners(); // This will alert the widgets that are listening to this model.
    }
  }

  void addPoint() {
    simulateDataStream();
  }
}
