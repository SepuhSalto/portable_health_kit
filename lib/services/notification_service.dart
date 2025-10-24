import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter/material.dart'; // For Color
import 'package:intl/intl.dart'; // For DateFormat

// List of sound filenames expected in assets/sounds/
// Ensure these EXACTLY match your files (case, underscores).
const List<String> availableSounds = [
  'alarm_classic.wav',
  'alarm_simple.wav',
  'waktunya_minum_obat.wav', // Example: Use lowercase and underscores if needed for resources
  'lakukan_senam_kaki.wav',   // Example: Use lowercase and underscores if needed for resources
];


class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  // Unique IDs for our notification channels
  static const String silentChannelId = 'alarm_fullscreen_silent_channel_v1'; // Added v1 for potential updates
  static const String nextAlarmChannelId = 'next_alarm_channel_v1';

  // --- Initialization ---
  /// Initializes the notification plugin and creates necessary channels.
  /// Should be called once when the app starts.
  Future<void> initialize() async {
    // Prevent redundant initialization
    if (_initialized) return;
    print("NotificationService: Initializing...");

    // Initialize timezone data for potential future scheduling needs (though not used directly here)
    tz.initializeTimeZones();

    // Platform-specific initialization settings
    const AndroidInitializationSettings androidInit =
        // Ensure you have ic_launcher.png (or similar) in android/app/src/main/res/mipmap folders
        AndroidInitializationSettings('@mipmap/ic_launcher');
    // Basic iOS settings (iOS features less relevant for this specific Android-focused alarm setup)
    const DarwinInitializationSettings iosInit = DarwinInitializationSettings();
    const InitializationSettings initSettings = InitializationSettings(
      android: androidInit, iOS: iosInit
    );

    try {
      // Initialize the plugin. Add callbacks if needed later for notification taps.
      await _notificationsPlugin.initialize(initSettings,
          // Example callback for notification taps:
          // onDidReceiveNotificationResponse: (NotificationResponse response) {
          //   print("Notification tapped with payload: ${response.payload}");
          //   // Handle payload routing here if needed
          // },
          );

      // --- Create Notification Channels ---

      // 1. Silent channel for the full-screen intent trigger
      const AndroidNotificationChannel silentChannel = AndroidNotificationChannel(
        silentChannelId,
        'Alarms Trigger (Silent)', // User visible name in App Settings
        description: 'Internal channel to trigger alarm screen (no sound)',
        importance: Importance.max, // Max importance needed for full-screen
        playSound: false, // CRITICAL: This channel MUST be silent
        enableVibration: false,
        showBadge: true, // Show badge if desired
      );
      await _createChannel(silentChannel);
      print("NotificationService: Created silent full-screen channel: $silentChannelId");

      // 2. Channel for the ongoing 'Next Alarm' status notification
       const AndroidNotificationChannel nextChannel = AndroidNotificationChannel(
        nextAlarmChannelId,
        'Next Alarm Status', // User visible name
        description: 'Shows the upcoming alarm in the status bar',
        importance: Importance.low, // Low importance - won't pop up or make noise
        playSound: false,
        enableVibration: false,
        showBadge: false, // Usually don't want a badge for this
      );
      await _createChannel(nextChannel);
      print("NotificationService: Created next alarm channel: $nextAlarmChannelId");

      // --- TODO (Optional): Create channels for audible preview/test sounds if needed ---
      // You could create separate channels here if you wanted a "Test Notification" button
      // that *does* make sound, distinct from the silent full-screen trigger. Example:
      // const AndroidNotificationChannel testChannel = AndroidNotificationChannel(
      //   'test_sound_channel', 'Test Notifications', importance: Importance.max, playSound: true
      // );
      // await _createChannel(testChannel);

      _initialized = true;
      print("NotificationService: Initialization COMPLETE");
    } catch (e) {
      print("NotificationService: ERROR during initialization: $e");
    }
  }

  /// Helper to create or update an Android notification channel.
  Future<void> _createChannel(AndroidNotificationChannel channel) async {
    try {
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    } catch (e) {
       print("NotificationService: ERROR creating channel ${channel.id}: $e");
    }
  }

  // --- Showing Notifications ---

  /// Shows a high-priority, silent notification designed to trigger a full-screen intent.
  /// This should be called when the alarm starts ringing via Alarm.ringStream.
  Future<void> showFullScreenAlarmNotification(int id, String? title, String? body) async {
     if (!_initialized) {
       print("NotificationService Error: Not initialized before showing notification.");
       return;
     }
     print("NotificationService: Showing full-screen trigger for ID=$id");

     final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
       silentChannelId, // Use the dedicated silent channel
       'Alarms Trigger (Silent)', // Match channel name
       channelDescription: 'Internal channel to trigger alarm screen', // Match channel description
       importance: Importance.max,
       priority: Priority.max,
       category: AndroidNotificationCategory.alarm, // Crucial category for alarms
       fullScreenIntent: true, // Request to show full screen UI
       autoCancel: false, // Must be cancelled manually when alarm stops
       ongoing: true, // Makes it persistent, harder to dismiss
       playSound: false, // Ensure no sound plays from this notification itself
       enableVibration: false,
       // icon: 'ic_stat_alarm', // Optional: Small icon for status bar (needs drawable resource)
       // color: Colors.red, // Optional: Accent color for notification
       // visibility: NotificationVisibility.public, // Control lock screen visibility if needed
     );
     final NotificationDetails details = NotificationDetails(android: androidDetails);

     try {
       await _notificationsPlugin.show(
         id, // Use the unique alarm ID
         title ?? 'Alarm',
         body ?? 'Alarm sedang berbunyi...',
         details,
         payload: 'alarm_ringing_$id' // Payload identifies the ringing alarm
       );
       print("NotificationService: Full-screen notification shown for ID=$id");
     } catch (e) {
        print("NotificationService: ERROR showing full-screen notification for ID=$id: $e");
     }
  }

  /// Shows or updates the persistent, low-priority notification indicating the next alarm.
  Future<void> showNextAlarmOngoingNotification(DateTime nextAlarmTime, String label) async {
     if (!_initialized) return; // Fail silently if not ready

     final formattedTime = DateFormat('EEE, d MMM HH:mm', 'id_ID').format(nextAlarmTime);
     final body = '$label • $formattedTime';
     const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
       nextAlarmChannelId, // Use the dedicated 'next alarm' channel
       'Next Alarm Status',
       channelDescription: 'Shows the upcoming alarm in the status bar',
       importance: Importance.low,
       priority: Priority.low,
       autoCancel: false, // Must not auto-cancel
       ongoing: true, // Makes it persistent
       onlyAlertOnce: true, // Don't make noise/vibrate on updates
       playSound: false,
       enableVibration: false,
       // icon: 'ic_stat_next_alarm', // Optional: Small icon for status bar
     );
     const NotificationDetails details = NotificationDetails(android: androidDetails);
     try {
       // Use a fixed, unique ID for this specific notification type
       const int nextAlarmNotificationId = 999999;
       await _notificationsPlugin.show(
         nextAlarmNotificationId,
         'Alarm Berikutnya', // Consistent title
         body,
         details,
         payload: 'show_next_alarm' // Payload to potentially open alarm list on tap
       );
        print("NotificationService: Updated next alarm notification: $body");
     } catch (e) {
         print("NotificationService: ERROR showing/updating next alarm notification: $e");
     }
  }

  // --- Cancelling Notifications ---

  /// Cancels the ongoing 'Next Alarm' notification.
  Future<void> cancelNextAlarmOngoingNotification() async {
     if (!_initialized) return;
     try {
       const int nextAlarmNotificationId = 999999; // Use the fixed ID
       await _notificationsPlugin.cancel(nextAlarmNotificationId);
       print("NotificationService: Cancelled next alarm notification.");
     } catch (e) {
         print("NotificationService: ERROR cancelling next alarm notification: $e");
     }
  }

  /// Cancels a specific ringing alarm's full-screen notification.
  /// Should be called when the alarm is stopped (e.g., in AlarmRingScreen).
  Future<void> cancelRingingNotification(int id) async {
      if (!_initialized) return;
      try {
        await _notificationsPlugin.cancel(id); // Use the alarm's ID
        print("NotificationService: Cancelled ringing notification for ID=$id");
      } catch (e) {
          print("NotificationService: ERROR cancelling ringing notification ID=$id: $e");
      }
  }

  // --- Permissions ---
   /// Requests Android notification permission (Android 13+).
   /// Call this from your UI when needed.
   Future<bool> requestPermissions() async {
     print("NotificationService: Requesting notification permission...");
     bool? result = await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
     print("NotificationService: Notification permission result: $result");
     return result ?? false;
     // Note: Exact Alarm and Battery permissions need permission_handler
     // and disable_battery_optimization respectively, called from the UI.
   }
}

// Optional: Create a global instance for easy access,
// or use a proper dependency injection method like Provider, GetIt, etc.
final NotificationService notificationService = NotificationService();