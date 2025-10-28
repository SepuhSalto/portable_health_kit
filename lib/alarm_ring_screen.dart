import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart';
import 'package:portable_health_kit/services/alarm_store.dart'; // Import Hive store // Import Hive model
import 'package:portable_health_kit/services/notification_service.dart'; // To cancel notification
import 'package:portable_health_kit/main_navigation_screen.dart';

class AlarmRingScreen extends StatefulWidget {
  final AlarmSettings alarmSettings;

  const AlarmRingScreen({super.key, required this.alarmSettings});

  @override
  State<AlarmRingScreen> createState() => _AlarmRingScreenState();
}

class _AlarmRingScreenState extends State<AlarmRingScreen> {
  bool _isStopping = false; // Prevent double taps
  final NotificationService notificationService = NotificationService();

  // Helper to calculate next day's trigger time
  DateTime _calculateNextDay(TimeOfDay time) {
    final now = DateTime.now();
    DateTime next = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    if (next.isBefore(now) || next.difference(now).inMinutes < 1) {
      next = next.add(const Duration(days: 1));
    }
    return next;
  }

  Future<void> _stopAndReschedule() async {
    if (_isStopping) return;
    setState(() { _isStopping = true; });
    print("RingScreen: Stop button pressed for ID=${widget.alarmSettings.id}");

    final id = widget.alarmSettings.id;

    // 1. Stop the current alarm sound/vibration
    await Alarm.stop(id);
    print("RingScreen: Alarm.stop($id) called.");

     // 2. Cancel the full-screen notification
    await notificationService.cancelRingingNotification(id);

    // 3. Load repeat flag from Hive
    final alarmData = AlarmStore.getAlarmById(id);
    final bool shouldRepeat = alarmData?.repeatEveryday ?? false;
    print("RingScreen: Repeat flag from Hive: $shouldRepeat");

    if (shouldRepeat) {
      // 4. Calculate next trigger time
      final time = TimeOfDay(hour: widget.alarmSettings.dateTime.hour, minute: widget.alarmSettings.dateTime.minute);
      final nextTrigger = _calculateNextDay(time);

      // 5. Create new settings for rescheduling
      final nextSettings = widget.alarmSettings.copyWith(dateTime: nextTrigger);

      // 6. Reschedule using Alarm.set()
      final success = await Alarm.set(alarmSettings: nextSettings);
      print("RingScreen: Rescheduled ID=$id for $nextTrigger. Success: $success");

       // 7. Ensure enabled flag is set in Hive (might have been missed if app was killed)
       if (alarmData != null && !alarmData.enabled) {
          await AlarmStore.setEnabled(id, true);
       }

    } else {
        // If not repeating, just ensure it's marked as disabled in Hive
        print("RingScreen: Alarm ID=$id is not set to repeat. Marking as disabled.");
        await AlarmStore.setEnabled(id, false);
    }

    // 8. Close the ringing screen
    if (mounted) {
      Navigator.of(context).pushReplacement( // Use pushReplacement
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
  }
  }

  // Optional: Snooze functionality
  Future<void> _snooze() async {
    if (_isStopping) return;
    setState(() { _isStopping = true; }); // Prevent double taps
     print("RingScreen: Snooze button pressed for ID=${widget.alarmSettings.id}");

    final id = widget.alarmSettings.id;
    final snoozeDuration = const Duration(minutes: 5); // Example: 5 minutes snooze
    final snoozeTime = DateTime.now().add(snoozeDuration);

     // 1. Stop the current alarm sound/vibration
    await Alarm.stop(id);
     print("RingScreen: Alarm.stop($id) called for snooze.");

     // 2. Cancel the full-screen notification
    await notificationService.cancelRingingNotification(id);


    // 3. Create snooze settings (use original settings but new time)
    final snoozeSettings = widget.alarmSettings.copyWith(dateTime: snoozeTime);

    // 4. Schedule the snooze alarm
    final success = await Alarm.set(alarmSettings: snoozeSettings);
     print("RingScreen: Snooze scheduled for ID=$id at $snoozeTime. Success: $success");

    // 5. Close the ringing screen
    if (mounted) {
        Navigator.of(context).pop();
    }
  }


  @override
  Widget build(BuildContext context) {
    final time = TimeOfDay.fromDateTime(widget.alarmSettings.dateTime).format(context);
    final title = widget.alarmSettings.notificationSettings.title ?? 'Alarm';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                children: [
                  Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(time, style: const TextStyle(fontSize: 52, fontWeight: FontWeight.w700)),
                   const SizedBox(height: 8),
                   Text(widget.alarmSettings.notificationSettings.body ?? 'Alarm sedang berbunyi...', textAlign: TextAlign.center),

                ],
              ),
              const Text('⏰', style: TextStyle(fontSize: 72)), // Alarm clock emoji
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _isStopping ? null : _snooze, // Add Snooze action
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.amber[700]),
                    child: const Text('Tunda (5 Mnt)'),
                  ),
                  ElevatedButton(
                    onPressed: _isStopping ? null : _stopAndReschedule,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
                    child: const Text('Stop'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}