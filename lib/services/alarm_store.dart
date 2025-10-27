import 'package:hive_flutter/hive_flutter.dart';
import 'package:portable_health_kit/models/alarm_data.dart';
import 'package:alarm/alarm.dart'; // Import AlarmSettings

class AlarmStore {
  static const String _boxName = 'alarms_box';
  static Box<AlarmData>? _box;

  // REMOVED _normalizeAssetPath from here - Path correction should happen before saving

  /// Initializes Hive, registers the adapter, and opens the alarm box.
  static Future<void> initialize() async {
    // Ensure Hive is initialized for Flutter
    await Hive.initFlutter();
    // Register the generated adapter for the AlarmData model
    Hive.registerAdapter(AlarmDataAdapter());
    // Open the box where alarms will be stored
    _box = await Hive.openBox<AlarmData>(_boxName);
    print("AlarmStore: Hive box '$_boxName' opened.");

    // Optional: One-time migration for old paths (run once, then comment out)
    // await migrateSoundPaths();
  }

  /// Returns the opened Hive box, throwing an error if not initialized.
  static Box<AlarmData> getBox() {
    if (_box == null) {
      // Throw a clear error if initialization hasn't happened
      throw Exception("AlarmStore not initialized. Call initialize() first in main().");
    }
    return _box!;
  }

  /// Saves or updates an alarm in the Hive box.
  /// Takes an AlarmSettings object and custom flags.
  static Future<void> upsert(AlarmSettings s, {required bool enabled, required bool repeatEveryday}) async {
    final box = getBox();
    // Ensure the asset path is in the expected format before saving.
    // This assumes the path passed in `s.assetAudioPath` is already correct.
    final String correctAssetPath = s.assetAudioPath;

    // Create or update the AlarmData object for Hive storage
    final alarmData = AlarmData()
      ..id = s.id
      ..hour = s.dateTime.hour
      ..minute = s.dateTime.minute
      ..title = s.notificationSettings.title ?? 'Alarm' // Use default if null
      ..body = s.notificationSettings.body ?? '' // Use default if null
      ..soundAssetPath = correctAssetPath // Store the correct, full asset path
      ..loopAudio = s.loopAudio
      ..vibrate = s.vibrate
      ..enabled = enabled // Store the current enabled state
      ..repeatEveryday = repeatEveryday; // Store the repeat flag

    // Use the alarm ID as the key in the Hive box for easy retrieval/update
    await box.put(s.id, alarmData);
    // Log the action for debugging
    print("AlarmStore: Upserted alarm ID=${s.id} with sound path='${correctAssetPath}', enabled=$enabled, repeat=$repeatEveryday");
  }

  /// Updates only the 'enabled' status of an existing alarm in Hive.
  static Future<void> setEnabled(int id, bool enabled) async {
    final box = getBox();
    // Retrieve the existing alarm data using its ID
    final alarmData = box.get(id);
    if (alarmData != null) {
      // Update the enabled field and save the changes back to Hive
      alarmData.enabled = enabled;
      await alarmData.save(); // HiveObject allows saving changes directly
      print("AlarmStore: Set enabled=$enabled for alarm ID=$id");
    } else {
       // Log a warning if the alarm ID wasn't found
       print("AlarmStore: Warning - Could not find alarm ID=$id to set enabled status.");
    }
  }

  /// Deletes an alarm from the Hive box using its ID.
  static Future<void> remove(int id) async {
    final box = getBox();
    await box.delete(id);
    print("AlarmStore: Deleted alarm ID=$id");
  }

  /// Retrieves all stored alarms from the Hive box.
  static List<AlarmData> getAllAlarms() {
    final box = getBox();
    // Get all values from the box and convert to a list
    final alarms = box.values.toList();
    // Sort the alarms chronologically by their time of day
    alarms.sort((a, b) {
       final timeA = a.hour * 60 + a.minute;
       final timeB = b.hour * 60 + b.minute;
       return timeA.compareTo(timeB);
    });
    print("AlarmStore: Loaded ${alarms.length} alarms from Hive.");
    return alarms;
  }

  /// Retrieves a single alarm by its ID from the Hive box. Returns null if not found.
  static AlarmData? getAlarmById(int id) {
    final box = getBox();
    return box.get(id);
  }

  // --- Path Normalization and Migration (Keep for potential one-time fix) ---

  /// Normalizes a given path string to ensure it follows the 'assets/sounds/filename' format.
  /// Useful for correcting potentially inconsistent paths stored previously.
  static String _normalizeAssetPathForMigration(String path) {
    var p = path.trim();
    // Remove potential duplicate segments
    p = p.replaceAll('assets/sounds/assets/', 'assets/sounds/');
    p = p.replaceAll('assets/assets/', 'assets/');
    p = p.replaceAll('assets/sounds/sounds/', 'assets/sounds/');

    // Ensure the path starts correctly
    if (!p.startsWith('assets/sounds/')) {
        if (p.startsWith('assets/')) {
           // Path starts with 'assets/' but missing 'sounds/'
           p = p.replaceFirst('assets/', 'assets/sounds/');
        } else if (p.startsWith('sounds/')) {
             // Path starts with 'sounds/' but missing 'assets/'
             p = 'assets/$p';
        }
        else {
            // Assumed to be just the filename
            p = 'assets/sounds/$p';
        }
    }
    return p;
  }

  /// Iterates through all stored alarms and corrects their soundAssetPath using the normalization logic.
  /// This should be run only once after initialization if you suspect old paths are incorrect.
  static Future<int> migrateSoundPaths() async {
    final box = getBox();
    int updated = 0;
    // Get keys first to avoid issues while modifying during iteration
    List<int> keysToUpdate = box.keys.cast<int>().toList();

    for (final key in keysToUpdate) {
        final alarm = box.get(key);
        if (alarm != null) {
            final normalized = _normalizeAssetPathForMigration(alarm.soundAssetPath);
            // If the path changed after normalization, save the corrected path
            if (normalized != alarm.soundAssetPath) {
                print("AlarmStore: Migrating path for ID=${alarm.id}: '${alarm.soundAssetPath}' -> '$normalized'");
                alarm.soundAssetPath = normalized;
                await alarm.save(); // Save the change back to Hive
                updated++;
            }
        }
    }
    if (updated > 0) {
      print("AlarmStore: Migration complete. Updated $updated alarm sound paths.");
    } else {
      print("AlarmStore: No sound path migration needed.");
    }
    return updated;
  }
}