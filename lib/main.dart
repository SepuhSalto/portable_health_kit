import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:alarm/alarm.dart';
import 'package:alarm/utils/alarm_set.dart'; // Import AlarmSet
import 'package:portable_health_kit/services/notification_service.dart'; // Import our service
import 'package:portable_health_kit/services/alarm_store.dart'; // Import Hive store
import 'package:portable_health_kit/models/alarm_data.dart'; // Import Hive model
import 'dart:async'; // For StreamSubscription
import 'firebase_options.dart';
import 'splash_screen.dart';
import 'alarm_ring_screen.dart'; // Import the new ringing screen
import 'package:intl/intl.dart';

// Global navigator key to navigate from background
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (if still needed)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Hive
  await AlarmStore.initialize();
  print("Main: Hive Initialized");

  // Initialize Alarm package
  await Alarm.init();
  print("Main: Alarm Package Initialized");

  // Initialize Notification Service
  await notificationService.initialize(); // Use global instance
  print("Main: Notification Service Initialized");

  // Initialize date formatting
  await initializeDateFormatting('id_ID', null);

  // Set up the listener for when alarms start ringing
  _setupAlarmListener();

  // Run the app
  runApp(const MyApp());

  // Perform startup tasks after the first frame
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    print("Main: Running post-frame callbacks...");
    await _handleMissedAlarmsAndReschedule();
    await _updateNextAlarmNotification();
    // Maybe request battery optimization ignore here or in UI
    print("Main: Post-frame callbacks complete.");
  });
}

StreamSubscription<AlarmSet>? ringSubscription;

void _setupAlarmListener() {
  if (ringSubscription != null) return; // Avoid multiple listeners
  try {
    ringSubscription = Alarm.ringing.listen(
      (alarmSet) {
        print("Main: Alarm Ring Stream Received! IDs: ${alarmSet.alarms.map((a) => a.id).join(', ')}");
        if (alarmSet.alarms.isEmpty) return;

        // Typically only one alarm rings at a time with `allowAlarmOverlap: false` (default)
        // If overlap is allowed, we might just handle the first one.
        final ringingAlarmSettings = alarmSet.alarms.first;

        // Trigger the full-screen notification
        notificationService.showFullScreenAlarmNotification(
            ringingAlarmSettings.id,
            ringingAlarmSettings.notificationSettings.title,
            ringingAlarmSettings.notificationSettings.body);

        // Navigate to the ringing screen using the global key
        final context = navigatorKey.currentContext;
        if (context != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AlarmRingScreen(alarmSettings: ringingAlarmSettings),
              fullscreenDialog: true, // Make it feel more like an overlay
            ),
          );
           print("Main: Navigated to AlarmRingScreen for ID=${ringingAlarmSettings.id}");
        } else {
             print("Main: ERROR - Navigator context was null, cannot navigate to AlarmRingScreen.");
        }
      },
      onError: (error) {
        print("Main: Error in Alarm Ring Stream: $error");
        // Optionally try to restart the listener
        ringSubscription = null;
        Future.delayed(const Duration(seconds: 5), _setupAlarmListener);
      },
      onDone: () {
        print("Main: Alarm Ring Stream Closed.");
        ringSubscription = null; // Allow restarting if needed
      },
      cancelOnError: false,
    );
    print("Main: Alarm Ring Stream Listener Attached.");
  } catch (e) {
     print("Main: Error attaching Alarm Ring Stream Listener: $e");
  }

  // Also listen to schedule changes to update the ongoing notification
   Alarm.scheduled.listen((_) async {
       print("Main: Alarm schedule changed, updating next alarm notification.");
       await _updateNextAlarmNotification();
   });
    print("Main: Alarm Scheduled Stream Listener Attached.");
}


// Function to handle missed alarms and ensure active ones are scheduled
Future<void> _handleMissedAlarmsAndReschedule() async {
  print("Main: Handling missed alarms and rescheduling...");
  final now = DateTime.now();
  final List<AlarmData> storedAlarms = AlarmStore.getAllAlarms();
  int rescheduledCount = 0;

  for (final alarmData in storedAlarms) {
    if (!alarmData.enabled) {
        print("  - Skipping disabled alarm ID=${alarmData.id}");
        continue;
    }

    final TimeOfDay alarmTime = TimeOfDay(hour: alarmData.hour, minute: alarmData.minute);
    DateTime nextScheduleTime = _calculateNextDay(alarmTime);

    // *** FIX IS HERE ***
    // Use 'await' to get the AlarmSettings? from the Future
    final AlarmSettings? currentSetting = await Alarm.getAlarm(alarmData.id);
    // *** END FIX ***

    // Now check if currentSetting is null before accessing dateTime
    if (currentSetting == null ||
        currentSetting.dateTime.millisecondsSinceEpoch != nextScheduleTime.millisecondsSinceEpoch ||
        currentSetting.dateTime.isBefore(now))
    {
      print("  - Rescheduling required for ID=${alarmData.id}. Current: ${currentSetting?.dateTime}, Next: $nextScheduleTime");

      // Create AlarmSettings using data from Hive (AlarmData)
      final settingsToSchedule = AlarmSettings(
        id: alarmData.id,
        dateTime: nextScheduleTime,
        loopAudio: alarmData.loopAudio,
        vibrate: alarmData.vibrate,
        assetAudioPath: alarmData.soundAssetPath, // Use the full path stored in Hive
        volumeSettings: const VolumeSettings.fixed(),
        notificationSettings: NotificationSettings(
          title: alarmData.title,
          body: alarmData.body,
          stopButton: 'Stop',
        ),
        allowAlarmOverlap: false,
      );

      final success = await Alarm.set(alarmSettings: settingsToSchedule); // Use settingsToSchedule
      if (success) {
          print("  - Successfully rescheduled ID=${alarmData.id} for $nextScheduleTime");
          rescheduledCount++;
      } else {
          print("  - FAILED to reschedule ID=${alarmData.id}");
      }
    } else {
         // Use currentSetting.dateTime safely here because we know it's not null
         print("  - Alarm ID=${alarmData.id} is already correctly scheduled for ${currentSetting.dateTime}.");
    }
  }
   print("Main: Finished rescheduling check. Rescheduled $rescheduledCount alarms.");
}

// Function to update the ongoing notification
Future<void> _updateNextAlarmNotification() async {
   print("Main: Updating next alarm notification...");
   final List<AlarmData> alarms = AlarmStore.getAllAlarms();
   final now = DateTime.now();

   // Find the next enabled alarm that is scheduled in the future
   AlarmData? nextAlarm;
   DateTime? earliestTime;

   for (final alarmData in alarms) {
       if (alarmData.enabled) {
           final alarmTime = TimeOfDay(hour: alarmData.hour, minute: alarmData.minute);
           DateTime triggerTime = _calculateNextDay(alarmTime);

           // Ensure the calculated time is indeed in the future relative to now
           if (triggerTime.isAfter(now)) {
               if (earliestTime == null || triggerTime.isBefore(earliestTime)) {
                   earliestTime = triggerTime;
                   nextAlarm = alarmData;
               }
           }
       }
   }

   if (nextAlarm != null && earliestTime != null) {
       await notificationService.showNextAlarmOngoingNotification(earliestTime, nextAlarm.title);
   } else {
       await notificationService.cancelNextAlarmOngoingNotification();
   }
}


// Helper function (can be moved to a utility file)
DateTime _calculateNextDay(TimeOfDay time) {
  final now = DateTime.now();
  // Calculate today's time at the specified hour/minute
  DateTime next = DateTime(now.year, now.month, now.day, time.hour, time.minute);

  // *** FIX: Only add a day if the calculated time is strictly in the past ***
  if (next.isBefore(now)) {
    next = next.add(const Duration(days: 1));
  }
  // *** END FIX ***
  return next;
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});
  static const Color primaryGreen = Color(0xFF46A24A);
    // Define a secondary green color (adjust if needed)
  static const Color secondaryGreen = Color(0xFF66BB6A);
    // Define a light background color
  static const Color lightBackground = Color(0xFFF0F4F0);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Portable Health Kit',
      navigatorKey: navigatorKey, // Assign the global key
      theme: ThemeData( 
        primaryColor: primaryGreen, // Set primary color
        scaffoldBackgroundColor: lightBackground, // Light background
        fontFamily: 'Poppins', // Keep your font
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryGreen, // Base color for scheme generation
          primary: primaryGreen, // Explicitly set primary
          secondary: secondaryGreen, // Explicitly set secondary/accent
          background: lightBackground, // Background color
          brightness: Brightness.light, // Use light theme overall
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryGreen, // Green AppBar
          foregroundColor: Colors.white, // White text/icons on AppBar
          elevation: 2,
          titleTextStyle: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white, // Ensure AppBar title is white
          ),
          iconTheme: IconThemeData(color: Colors.white), // Ensure AppBar icons are white
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.05),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Colors.white, // White cards
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white, // White text fields
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryGreen, // Green buttons
            foregroundColor: Colors.white, // White text on buttons
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
        ),
        // Theme for the Bottom Navigation Bar
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
           selectedItemColor: primaryGreen, // Highlight selected icon green
           unselectedItemColor: Colors.grey[600], // Grey for unselected
           backgroundColor: Colors.white, // White background for navbar
           type: BottomNavigationBarType.fixed, // Ensure type is fixed
           showUnselectedLabels: true, // Show labels always
        ),
        useMaterial3: true,
      ),
      // *** END THEME UPDATE ***
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}