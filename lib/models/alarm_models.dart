import 'package:flutter/material.dart';

class Alarm {
  final String id;
  String title;
  TimeOfDay time;
  bool isActive;
  List<bool> repeatDays;
  final bool isFixed; // This new property marks the default alarms

  Alarm({
    required this.id,
    required this.title,
    required this.time,
    this.isActive = true,
    required this.repeatDays,
    this.isFixed = false, // Custom alarms are not fixed by default
  });
}