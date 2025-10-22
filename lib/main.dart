import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:alarm/alarm.dart'; // 1. Import the new package
import 'package:shared_preferences/shared_preferences.dart'; // 2. Import SharedPreferences
import 'firebase_options.dart';
import 'splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 3. Initialize the alarm service
  await Alarm.init();

  // 4. Initialize date formatting
  await initializeDateFormatting('id_ID', null);

  // 5. NEW: Pre-populate fixed alarms on first launch
  await _setupFixedAlarms();

  runApp(const MyApp());
}

// 6. NEW: Function to add fixed alarms only once
Future<void> _setupFixedAlarms() async {
  final prefs = await SharedPreferences.getInstance();
  final bool alarmsSet = prefs.getBool('fixed_alarms_set') ?? false;

  if (!alarmsSet) {
    // We use unique IDs 1 and 2 for our fixed alarms
    final fixedAlarm1 = AlarmSettings(
      id: 1, // Fixed ID 1
      dateTime: const TimeOfDay(hour: 9, minute: 0).toDateTime(),
      assetAudioPath: 'assets/sounds/Waktunya Minum Obat.wav',
      loopAudio: true,
      vibrate: true,
      volumeSettings: VolumeSettings.fade(
        volume: 0.8,
        fadeDuration: Duration(seconds: 5),
        volumeEnforced: true,
      ),
      notificationSettings: const NotificationSettings(
        title: 'Minum Obat',
        body: 'Sudah waktunya minum obat.',
        stopButton: null,
      ),
    );
    final fixedAlarm2 = AlarmSettings(
      id: 2, // Fixed ID 2
      dateTime: const TimeOfDay(hour: 17, minute: 0).toDateTime(),
      assetAudioPath: 'assets/sounds/Lakukan Senam Kaki.wav',
      loopAudio: true,
      vibrate: true,
      volumeSettings: VolumeSettings.fade(
        volume: 0.8,
        fadeDuration: Duration(seconds: 5),
        volumeEnforced: true,
      ),
      notificationSettings: const NotificationSettings(
        title: 'Senam Kaki',
        body: 'Sudah waktunya melakukan senam kaki.',
        stopButton: null,
      ),
    );

    await Alarm.set(alarmSettings: fixedAlarm1);
    await Alarm.set(alarmSettings: fixedAlarm2);

    await prefs.setBool('fixed_alarms_set', true);
  }
}

// Helper extension to convert TimeOfDay to next DateTime
extension TimeOfDayExtension on TimeOfDay {
  DateTime toDateTime() {
    final now = DateTime.now();
    var dt = DateTime(now.year, now.month, now.day, hour, minute);
    if (dt.isBefore(now)) {
      dt = dt.add(const Duration(days: 1));
    }
    return dt;
  }
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Portable Health Kit',
      theme: ThemeData(
        primaryColor: const Color(0xFF46A24A),
        scaffoldBackgroundColor: const Color(0xFFF0F4F0),
        fontFamily: 'Poppins',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF46A24A),
          primary: const Color(0xFF46A24A),
          secondary: const Color(0xFF66BB6A),
          background: const Color(0xFFF0F4F0),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF46A24A),
          foregroundColor: Colors.white,
          elevation: 2,
          titleTextStyle: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.05),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF46A24A),
            foregroundColor: Colors.white,
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
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}