import 'package:hive/hive.dart';

part 'alarm_data.g.dart'; // Hive will generate this file

@HiveType(typeId: 0) // Unique ID for this model type
class AlarmData extends HiveObject {
  @HiveField(0)
  late int id; // Corresponds to AlarmSettings.id

  @HiveField(1)
  late int hour;

  @HiveField(2)
  late int minute;

  @HiveField(3)
  late String title;

  @HiveField(4)
  late String body;

  @HiveField(5)
  late String soundAssetPath; // Store full path e.g., 'assets/sounds/classic.wav'

  @HiveField(6)
  late bool loopAudio;

  @HiveField(7)
  late bool vibrate;

  @HiveField(8)
  late bool enabled; // Is the alarm active?

  @HiveField(9)
  late bool repeatEveryday; // Should it reschedule daily?

  // Add other fields if needed, like volume settings if you customize them
}