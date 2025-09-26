import 'package:flutter/material.dart';

class Alarm {
  final String id;
  String title;
  TimeOfDay time;
  bool isActive;
  List<bool> repeatDays; // Corresponds to Mon, Tue, Wed, Thu, Fri, Sat, Sun

  Alarm({
    required this.id,
    required this.title,
    required this.time,
    this.isActive = true,
    required this.repeatDays,
  });
}