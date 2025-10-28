import 'package:flutter/material.dart';
import 'home_screen.dart'; // The new dashboard screen
import 'health_check_screen.dart'; // The menu to input data
import 'history_screen.dart'; // The history screen
import 'alarm_screen.dart'; // The new alarm screen
import 'materi_screen.dart'; // The materi screen
import 'dart:async'; // For StreamSubscription
import 'package:alarm/utils/alarm_set.dart';
import 'package:alarm/alarm.dart'; // For the alarm package
import 'package:portable_health_kit/alarm_ring_screen.dart'; // To navigate
import 'package:portable_health_kit/services/notification_service.dart'; // To show notification
import 'package:portable_health_kit/services/alarm_store.dart';
import 'package:portable_health_kit/models/alarm_data.dart'; // Import the AlarmData model
import 'package:flutter/material.dart'; // Needed for TimeOfDay
import 'package:intl/intl.dart'; // Needed for DateFormat

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  // We need to make this stateful to pass the callback
  late final List<Widget> _widgetOptions;
  StreamSubscription<AlarmSet>? _alarmSubscription;

  @override
  void initState() {
    super.initState();
    // Initialize the list here, passing the _onItemTapped function to HomeScreen
    _widgetOptions = <Widget>[
      // MODIFICATION: Pass the navigation callback to HomeScreen
      HomeScreen(onNavigateToInput: _onItemTapped),
      HealthCheckScreen(),
      HistoryScreen(),
      AlarmScreen(),
      MateriScreen(),
    ];

    _setupAlarmListener();
    _updateNextAlarmNotification();
    Alarm.scheduled.listen((_) {
      print("MainNavigation: Schedule changed, updating notification.");
      _updateNextAlarmNotification();
    });
  }

  void _setupAlarmListener() {
    _alarmSubscription = Alarm.ringing.listen((alarmSet) {
      if (alarmSet.alarms.isEmpty) return;
      
      // --- ADD THIS CHECK ---
      // If the ring screen is already opening/open, don't open another one.
      if (AlarmRingScreen.isRinging) {
        print("MainNavigation: Ring event received, but screen is already ringing. Ignoring.");
        return;
      }
      // --- END OF CHECK ---

      print("MainNavigationScreen: Alarm Ring Stream Received!");
      
      final alarm = alarmSet.alarms.first;
      
      // Show the notification (for background)
      notificationService.showFullScreenAlarmNotification(
          alarm.id,
          alarm.notificationSettings.title,
          alarm.notificationSettings.body);
      
      // Push the ring screen (for foreground)
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AlarmRingScreen(alarmSettings: alarm),
            fullscreenDialog: true,
          ),
        );
      }
    });
  }

  // --- ADD THIS DISPOSE METHOD ---
  @override
  void dispose() {
    _alarmSubscription?.cancel();
    super.dispose();
  }
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  Future<void> _updateNextAlarmNotification() async {
    print("MainNavigation: Updating next alarm notification...");
    final alarms = AlarmStore.getAllAlarms();
    final now = DateTime.now();
    AlarmData? nextAlarmData;
    DateTime? earliestNextTime;

    for (final alarmData in alarms) {
      if (alarmData.enabled) { 
        final alarmTime = TimeOfDay(hour: alarmData.hour, minute: alarmData.minute);
        DateTime triggerTime = _calculateNextDay(alarmTime);

        if (triggerTime.isAfter(now)) {
          if (earliestNextTime == null || triggerTime.isBefore(earliestNextTime)) {
            earliestNextTime = triggerTime;
            nextAlarmData = alarmData;
          }
        }
      }
    }

    if (nextAlarmData != null && earliestNextTime != null) {
      await notificationService.showNextAlarmOngoingNotification(earliestNextTime, nextAlarmData.title);
    } else {
      await notificationService.cancelNextAlarmOngoingNotification();
    }
    print("MainNavigation: Update next alarm notification complete.");
  }

  // --- ADD THIS HELPER FUNCTION ---
  DateTime _calculateNextDay(TimeOfDay time) {
    final now = DateTime.now();
    DateTime next = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    if (next.isBefore(now)) {
      next = next.add(const Duration(days: 1));
    }
    return next;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        // Use the stateful widget list
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box_outlined),
            label: 'Input Data',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            label: 'Riwayat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.alarm_outlined),
            label: 'Alarm',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.lightbulb_outline),
            label: 'Materi',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
      ),
    );
  }
}