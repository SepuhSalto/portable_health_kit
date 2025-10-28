import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Keep if Firebase is used elsewhere
import 'package:intl/date_symbol_data_local.dart'; // For date formatting
import 'package:alarm/alarm.dart'; // Primary alarm package
import 'package:alarm/utils/alarm_set.dart'; // Data structure from alarm package
import 'package:portable_health_kit/services/notification_service.dart'; // Our notification handler
import 'package:portable_health_kit/services/alarm_store.dart'; // Our Hive database service
import 'package:portable_health_kit/models/alarm_data.dart'; // Our Hive data model
import 'dart:async'; // For StreamSubscription
import 'firebase_options.dart'; // Firebase config (keep if needed) // Initial screen
import 'alarm_ring_screen.dart'; // Screen shown when alarm rings
import 'main_navigation_screen.dart'; // Main app navigation hub
import 'services/user_session_service.dart'; // For setting the default user ID// For formatting in _updateNextAlarmNotification
import 'package:firebase_auth/firebase_auth.dart';
import 'package:portable_health_kit/alarm_ring_screen.dart';
import 'package:portable_health_kit/main_navigation_screen.dart';
import 'package:portable_health_kit/services/user_session_service.dart';
import 'package:portable_health_kit/services/notification_service.dart';

// Global navigator key allows navigation from logic outside the widget tree (like the alarm listener)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Entry point of the application.
Future<void> main() async {
  // Ensure Flutter bindings are initialized before calling async code.
  WidgetsFlutterBinding.ensureInitialized();

  // --- Initialize Core Services ---

  // Initialize Firebase (if used for Firestore, Auth, etc.)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
     print("Main: Firebase Initialized");
     // --- ADD THIS BLOCK TO SIGN IN ---
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Not signed in yet, so sign in anonymously
      await FirebaseAuth.instance.signInAnonymously();
      print("Main: New sign-in successful.");
    } else {
      // Already signed in
      print("Main: Already signed in with User ID: ${user.uid}");
    }
    // --- END OF NEW BLOCK ---
  } catch (e) {
     print("Main: Firebase Initialization Error: $e");
     // Decide how to handle Firebase init failure if it's critical
  }


  // Initialize Hive for storing alarm data and repeat flags
  try {
    await AlarmStore.initialize();
    print("Main: Hive Initialized");
  } catch (e) {
     print("Main: Hive Initialization Error: $e");
     // Handle Hive init failure (alarms might not load/save)
  }


  // Initialize the 'alarm' package (essential for scheduling and sound)
  try {
    await Alarm.init();
    print("Main: Alarm Package Initialized");
  } catch (e) {
      print("Main: Alarm Package Initialization Error: $e");
      // Handle failure (alarms won't work)
  }


  // Initialize our Notification Service (creates channels, etc.)
  try {
    // Uses the global instance defined in notification_service.dart
    await notificationService.initialize();
    print("Main: Notification Service Initialized");
  } catch (e) {
      print("Main: Notification Service Initialization Error: $e");
      // Handle failure (notifications might not show)
  }


  // Initialize date formatting for Indonesian locale
  try {
    await initializeDateFormatting('id_ID', null);
    print("Main: Date Formatting Initialized for id_ID");
  } catch (e) {
       print("Main: Date Formatting Initialization Error: $e");
  }


  // --- Setup Alarm Listener ---
  // Start listening for alarms ringing in the background or foreground
  //_setupAlarmListener();

  // --- Run the App ---
  runApp(const MyApp());

  // --- Post-Startup Tasks ---
  // Perform tasks after the first frame is rendered to avoid delaying startup
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    print("Main: Running post-frame callbacks...");
    try {
      // Check for missed alarms and ensure active alarms are scheduled
      await _handleMissedAlarmsAndReschedule();
      // Update the ongoing notification showing the next alarm
      await _updateNextAlarmNotification();
      // Optional: Could add a prompt for battery optimization here if desired
    } catch (e) {
        print("Main: Error during post-frame callbacks: $e");
    }
    print("Main: Post-frame callbacks complete.");
  });
}

// Holds the subscription to the alarm ringing stream
StreamSubscription<AlarmSet>? ringSubscription;

/// Sets up the listener that reacts when an alarm starts ringing.
void _setupAlarmListener() {
  // Prevent setting up multiple listeners
  if (ringSubscription != null) {
      print("Main: Alarm Ring Listener already active.");
      return;
  }
  try {
    // Subscribe to the stream provided by the 'alarm' package
    ringSubscription = Alarm.ringing.listen(
      (alarmSet) { // This callback runs when an alarm starts
        print("Main: Alarm Ring Stream Received! Ringing IDs: ${alarmSet.alarms.map((a) => a.id).join(', ')} at ${DateTime.now()}");
        if (alarmSet.alarms.isEmpty) {
            print("Main: Ring stream received empty set, ignoring.");
            return; // Ignore if the set is empty
        }

        // Handle the first ringing alarm in the set
        // (Usually only one unless allowAlarmOverlap is true)
        final ringingAlarmSettings = alarmSet.alarms.first;

        // 1. Trigger the silent full-screen notification
        // This attempts to wake the device and prepare the UI transition
        notificationService.showFullScreenAlarmNotification(
            ringingAlarmSettings.id,
            ringingAlarmSettings.notificationSettings.title,
            ringingAlarmSettings.notificationSettings.body);

        // 2. Navigate to the dedicated ringing screen using the global key
        final context = navigatorKey.currentContext;
        if (context != null && ModalRoute.of(context)?.isCurrent != true) {
            // Check if context is available and we're not already on the top route somehow
          Navigator.push(
            context,
            MaterialPageRoute(
              // Pass the ringing alarm's settings to the screen
              builder: (_) => AlarmRingScreen(alarmSettings: ringingAlarmSettings),
              // Make it appear like an overlay
              fullscreenDialog: true,
            ),
          );
           print("Main: Successfully navigated to AlarmRingScreen for ID=${ringingAlarmSettings.id}");
        } else {
             print("Main: ERROR - Navigator context was null or not current, cannot navigate to AlarmRingScreen.");
             // Fallback: The full-screen notification might still appear.
        }
      },
      onError: (error) {
        // Handle errors in the stream (e.g., native side issues)
        print("Main: Error in Alarm Ring Stream: $error");
        // Reset subscription state and attempt to re-listen after a delay
        ringSubscription?.cancel(); // Cancel existing just in case
        ringSubscription = null;
        Future.delayed(const Duration(seconds: 10), _setupAlarmListener);
      },
      onDone: () {
        // Handle stream closure (less common unless Alarm.init() changes)
        print("Main: Alarm Ring Stream Closed.");
        ringSubscription = null; // Allow re-subscribing if needed
      },
      cancelOnError: false, // Keep listening even after an error
    );
    print("Main: Alarm Ring Stream Listener Attached.");
  } catch (e) {
     // Catch errors during the initial listen setup
     print("Main: Error attaching Alarm Ring Stream Listener: $e");
  }

  // --- Setup Listener for Schedule Changes ---
  // Listens for when `Alarm.set` or `Alarm.stop` is called.
  try {
    Alarm.scheduled.listen(
      (_) async {
         print("Main: Alarm schedule potentially changed, updating next alarm notification.");
         // Update the ongoing notification whenever an alarm is set or stopped
         await _updateNextAlarmNotification();
     },
      onError: (error) => print("Main: Error in Alarm Scheduled Stream: $error"),
      onDone: () => print("Main: Alarm Scheduled Stream Closed."),
      cancelOnError: false,
    );
    print("Main: Alarm Scheduled Stream Listener Attached.");
  } catch (e) {
      print("Main: Error attaching Alarm Scheduled Stream Listener: $e");
  }
}


/// Checks stored alarms against currently scheduled ones.
/// Reschedules active alarms if they were missed or not scheduled correctly.
Future<void> _handleMissedAlarmsAndReschedule() async {
  print("Main: Handling missed alarms and rescheduling...");
  final now = DateTime.now();
  int rescheduledCount = 0;
  List<AlarmData> storedAlms = []; // Renamed variable

  try {
    storedAlms = AlarmStore.getAllAlarms(); // Load alarms from Hive
  } catch (e) {
     print("Main: ERROR loading alarms during reschedule check: $e");
     return; // Cannot proceed without alarm data
  }


  for (final alarmData in storedAlms) {
    // Skip alarms that are marked as disabled in our Hive store
    if (!alarmData.enabled) {
        print("  - Skipping disabled alarm ID=${alarmData.id}");
        continue;
    }

    // Calculate the next theoretical trigger time based on stored hour/minute
    final TimeOfDay alarmTime = TimeOfDay(hour: alarmData.hour, minute: alarmData.minute);
    DateTime nextScheduleTime = _calculateNextDay(alarmTime);

    // Get the currently scheduled alarm (if any) from the `alarm` package
    AlarmSettings? currentSetting;
    try {
        currentSetting = await Alarm.getAlarm(alarmData.id);
    } catch (e) {
        print("  - ERROR getting current setting for alarm ID=${alarmData.id}: $e");
        // Proceed assuming rescheduling might be needed
    }


    // Determine if rescheduling is needed:
    // 1. If it's not currently scheduled (`currentSetting == null`).
    // 2. If the scheduled time is different from our calculated next time.
    // 3. If the scheduled time is in the past (it was missed).
    bool needsReschedule = currentSetting == null ||
                           currentSetting.dateTime.millisecondsSinceEpoch != nextScheduleTime.millisecondsSinceEpoch ||
                           currentSetting.dateTime.isBefore(now);

    if (needsReschedule)
    {
      print("  - Rescheduling required for ID=${alarmData.id}. Current: ${currentSetting?.dateTime}, Calculated Next: $nextScheduleTime");

      // Create the AlarmSettings object using data from Hive (AlarmData)
      // Ensure the sound path is the full asset path
      final settingsToSchedule = AlarmSettings(
        id: alarmData.id,
        dateTime: nextScheduleTime,
        loopAudio: alarmData.loopAudio,
        vibrate: alarmData.vibrate,
        assetAudioPath: alarmData.soundAssetPath, // Use the path stored in Hive
        volumeSettings: const VolumeSettings.fixed(), // Using default volume
        notificationSettings: NotificationSettings(
          title: alarmData.title,
          body: alarmData.body,
          stopButton: 'Stop',
        ),
        allowAlarmOverlap: false, // Prevent multiple alarms ringing at once
      );
       print("    - Rescheduling with details: ID=${settingsToSchedule.id}, Time=${settingsToSchedule.dateTime}, Sound='${settingsToSchedule.assetAudioPath}'");

      // Attempt to set/reschedule the alarm
      bool success = false;
      try {
          success = await Alarm.set(alarmSettings: settingsToSchedule);
      } catch (e) {
           print("  - EXCEPTION during Alarm.set for ID=${alarmData.id}: $e");
      }

      if (success) {
          print("  - Successfully rescheduled ID=${alarmData.id} for $nextScheduleTime");
          rescheduledCount++;
      } else {
          print("  - FAILED to reschedule ID=${alarmData.id}. Check permissions and logs.");
      }
    } else {
         // Log if the alarm is already scheduled correctly
         print("  - Alarm ID=${alarmData.id} is already correctly scheduled for ${currentSetting.dateTime}.");
    }
  }
   print("Main: Finished rescheduling check. Attempted to reschedule $rescheduledCount alarms.");
}

/// Finds the next upcoming enabled alarm and updates the ongoing status bar notification.
Future<void> _updateNextAlarmNotification() async {
   print("Main: Updating next alarm notification...");
   List<AlarmData> alarms = [];
   try {
       alarms = AlarmStore.getAllAlarms();
   } catch(e) {
        print("Main: ERROR loading alarms for next alarm notification: $e");
        await notificationService.cancelNextAlarmOngoingNotification(); // Clear if error
        return;
   }

   final now = DateTime.now();
   AlarmData? nextAlarmData;
   DateTime? earliestNextTime;

   // Iterate through stored alarms to find the soonest upcoming enabled one
   for (final alarmData in alarms) {
       if (alarmData.enabled) { // Only consider enabled alarms
           final alarmTime = TimeOfDay(hour: alarmData.hour, minute: alarmData.minute);
           // Calculate the next trigger time for this alarm
           DateTime triggerTime = _calculateNextDay(alarmTime);

           // Check if this trigger time is in the future
           if (triggerTime.isAfter(now)) {
               // If it's the first future alarm found, or earlier than the current earliest, update
               if (earliestNextTime == null || triggerTime.isBefore(earliestNextTime)) {
                   earliestNextTime = triggerTime;
                   nextAlarmData = alarmData;
               }
           }
       }
   }

   // Show or cancel the ongoing notification based on whether an upcoming alarm was found
   if (nextAlarmData != null && earliestNextTime != null) {
       await notificationService.showNextAlarmOngoingNotification(earliestNextTime, nextAlarmData.title);
   } else {
       await notificationService.cancelNextAlarmOngoingNotification();
   }
    print("Main: Update next alarm notification complete.");
}


/// Helper function to calculate the next DateTime for a given TimeOfDay.
/// If the time has already passed today, it returns the time for tomorrow.
DateTime _calculateNextDay(TimeOfDay time) {
  final now = DateTime.now();
  DateTime next = DateTime(now.year, now.month, now.day, time.hour, time.minute);
  if (next.isBefore(now)) {
    next = next.add(const Duration(days: 1));
  }
  return next;
}


/// The root widget of the application.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Define theme colors (consider moving to a separate theme file)
  static const Color primaryGreen = Color(0xFF46A24A);
  static const Color secondaryGreen = Color(0xFF66BB6A);
  static const Color lightBackground = Color(0xFFF0F4F0);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Portable Health Kit Bali-Sehat',
      navigatorKey: navigatorKey, // Crucial for navigating from the alarm listener
      theme: ThemeData(
        primaryColor: primaryGreen,
        scaffoldBackgroundColor: lightBackground,
        fontFamily: 'Poppins',
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryGreen,
          primary: primaryGreen,
          secondary: secondaryGreen,
          background: lightBackground,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          elevation: 2,
          titleTextStyle: TextStyle( fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white, ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.05),
          shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(16), ),
          color: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder( borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none, ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryGreen,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(12), ),
            textStyle: const TextStyle( fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Poppins', ),
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
           selectedItemColor: primaryGreen,
           unselectedItemColor: Colors.grey[600],
           backgroundColor: Colors.white,
           type: BottomNavigationBarType.fixed,
           showUnselectedLabels: true,
        ),
         dialogTheme: DialogThemeData( // Theme for dialogs like permission denied
           backgroundColor: Colors.white,
           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
         ),
        useMaterial3: true, // Enable Material 3 features
      ),
      debugShowCheckedModeBanner: false, // Hide debug banner
      home: const SplashScreen(), // Start with the splash screen
    );
  }
}

// Ensure SplashScreen and UserSessionService are defined/imported correctly
// (Assuming SplashScreen handles initial setup and navigation to MainNavigationScreen)
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  StreamSubscription<AlarmSet>? _alarmSubscription;

  @override
  void initState() {
    super.initState();
    // Listen for an alarm that might be ringing *right now*
    _alarmSubscription = Alarm.ringing.listen(_handleAlarmRing);
    // Simulate login and navigate after a delay
    _logInHealthWorkerAndNavigate();
  }

  void _handleAlarmRing(AlarmSet alarmSet) {
    if (alarmSet.alarms.isEmpty) {
      print("SplashScreen: Received empty alarm set, ignoring.");
      return;
    }

    // --- ADD THIS CHECK ---
    if (AlarmRingScreen.isRinging) {
      print("SplashScreen: Ring event received, but screen is already ringing. Ignoring.");
      return;
    }
    // --- END OF CHECK ---

    _alarmSubscription?.cancel();
    if (mounted) {
      print("SplashScreen: Alarm is ringing. Navigating to AlarmRingScreen.");
      Navigator.of(context).pushReplacement( 
        MaterialPageRoute(
          builder: (_) => AlarmRingScreen(alarmSettings: alarmSet.alarms.first),
        ),
      );
    }
  }

  Future<void> _logInHealthWorkerAndNavigate() async {
    UserSessionService().setCurrentUserId("clinic_bali_sehat_kiosk_01");
    print("SplashScreen: Kiosk User ID set.");

    // Wait for splash screen duration
    await Future.delayed(const Duration(seconds: 3));

    // This code will only run if _handleAlarmRing did *not* fire
    if (mounted && _alarmSubscription != null) { 
       _alarmSubscription?.cancel(); // Stop listening
       print("SplashScreen: No alarm. Navigating to MainNavigationScreen.");
       Navigator.of(context).pushReplacement(
         MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
       );
    }
  }

  @override
  void dispose() {
    _alarmSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;
    return Scaffold(
      backgroundColor: Colors.white, // Use theme color
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.jpg', // Assumes your logo is named 'logo.png'
              width: 300, // You can adjust this size
              height: 300,
            ),
            const SizedBox(height: 20),
            Text( // App name
              'Portable Health Kit',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: primaryColor),
            ),
             const SizedBox(height: 30), // Increased spacing
             CircularProgressIndicator(color: primaryColor), // Loading indicator
             const SizedBox(height: 10),
             Text('Memuat...', style: TextStyle(color: Colors.grey[600])), // Loading text
          ],
        ),
      ),
    );
  }
}

