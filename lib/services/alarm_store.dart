import 'package:hive_flutter/hive_flutter.dart';
import 'package:portable_health_kit/models/alarm_data.dart';
import 'package:alarm/alarm.dart'; // Import AlarmSettings

class AlarmStore {
  static const String _boxName = 'alarms_box';
  static Box<AlarmData>? _box;

  static String _normalizeAssetPath(String path) {
    var p = path.trim();
    p = p.replaceAll('assets/sounds/assets/', 'assets/sounds/');
    p = p.replaceAll('assets/assets/', 'assets/');
    p = p.replaceAll('assets/sounds/sounds/', 'assets/sounds/');
    if (!p.startsWith('assets/')) {
      p = 'assets/sounds/$p';
    }
    return p;
  }

  static Future<void> initialize() async {
    await Hive.initFlutter();
    Hive.registerAdapter(AlarmDataAdapter());
    _box = await Hive.openBox<AlarmData>(_boxName);
    print("AlarmStore: Hive box '$_boxName' opened.");
  }

  static Box<AlarmData> getBox() {
    if (_box == null) {
      throw Exception("AlarmStore not initialized. Call initialize() first.");
    }
    return _box!;
  }

  // Save or Update an alarm based on AlarmSettings and custom flags
  static Future<void> upsert(AlarmSettings s, {required bool enabled, required bool repeatEveryday}) async {
    final box = getBox();
    final alarmData = AlarmData()
      ..id = s.id
      ..hour = s.dateTime.hour
      ..minute = s.dateTime.minute
      ..title = s.notificationSettings.title ?? 'Alarm'
      ..body = s.notificationSettings.body ?? ''
      ..soundAssetPath = _normalizeAssetPath(s.assetAudioPath)
      ..loopAudio = s.loopAudio
      ..vibrate = s.vibrate
      ..enabled = enabled
      ..repeatEveryday = repeatEveryday;

    await box.put(s.id, alarmData);
    print("AlarmStore: Upserted alarm ID=${s.id}");
  }

  static Future<void> setEnabled(int id, bool enabled) async {
    final box = getBox();
    final alarmData = box.get(id);
    if (alarmData != null) {
      alarmData.enabled = enabled;
      await alarmData.save(); // Save changes to the existing object
      print("AlarmStore: Set enabled=$enabled for alarm ID=$id");
    } else {
       print("AlarmStore: Warning - Could not find alarm ID=$id to set enabled status.");
    }
  }

   static Future<void> remove(int id) async {
    final box = getBox();
    await box.delete(id);
    print("AlarmStore: Deleted alarm ID=$id");
  }

  static List<AlarmData> getAllAlarms() {
    final box = getBox();
    final alarms = box.values.toList();
    // Optionally sort here if needed, e.g., by time
    alarms.sort((a, b) {
       final timeA = a.hour * 60 + a.minute;
       final timeB = b.hour * 60 + b.minute;
       return timeA.compareTo(timeB);
    });
    print("AlarmStore: Loaded ${alarms.length} alarms.");
    return alarms;
  }

  static AlarmData? getAlarmById(int id) {
    final box = getBox();
    return box.get(id);
  }

  static Future<int> migrateSoundPaths() async {
    final box = getBox();
    int updated = 0;
    for (final alarm in box.values) {
      final normalized = _normalizeAssetPath(alarm.soundAssetPath);
      if (normalized != alarm.soundAssetPath) {
        alarm.soundAssetPath = normalized;
        await alarm.save();
        updated++;
      }
    }
    if (updated > 0) {
      print("AlarmStore: Migrated $updated alarm sound paths.");
    } else {
      print("AlarmStore: No sound path migration needed.");
    }
    return updated;
  }
}