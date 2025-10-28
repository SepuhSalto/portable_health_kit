import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart';
// Note: We no longer import audioplayers
import 'package:portable_health_kit/services/alarm_store.dart'; 
import 'package:portable_health_kit/services/notification_service.dart'; 
import 'package:portable_health_kit/main_navigation_screen.dart';

class AlarmRingScreen extends StatefulWidget {
  final AlarmSettings alarmSettings;

  // This flag prevents the ring screen from opening multiple times
  static bool isRinging = false;

  const AlarmRingScreen({super.key, required this.alarmSettings});

  @override
  State<AlarmRingScreen> createState() => _AlarmRingScreenState();
}

class _AlarmRingScreenState extends State<AlarmRingScreen> {
  bool _isStopping = false; 
  final NotificationService notificationService = NotificationService();
  
  // No AudioPlayer needed

  @override
  void initState() {
    super.initState();
    
    // This logic now runs only ONCE when the first ring screen is created
    if (!AlarmRingScreen.isRinging) {
      AlarmRingScreen.isRinging = true;
      print("AlarmRingScreen: isRinging set to true. Restarting native sound.");
      
      // This re-sets the alarm to *now*. It restarts the native sound 
      // that was stopped by Alarm.init() when the app was killed.
      final settings = widget.alarmSettings.copyWith(
        dateTime: DateTime.now().subtract(const Duration(seconds: 1)),
      );
      Alarm.set(alarmSettings: settings);
    }
  }

  @override
  void dispose() {
    // When the screen closes, reset the flag
    AlarmRingScreen.isRinging = false;
    print("AlarmRingScreen: isRinging set to false.");
    super.dispose();
  }

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
    
    // No manual audio to stop. Just stop the native alarm.
    await Alarm.stop(widget.alarmSettings.id);
    print("RingScreen: Alarm.stop(${widget.alarmSettings.id}) called.");
 
    await notificationService.cancelRingingNotification(widget.alarmSettings.id);

    final alarmData = AlarmStore.getAlarmById(widget.alarmSettings.id);
    final bool shouldRepeat = alarmData?.repeatEveryday ?? false;

    if (shouldRepeat) {
      final time = TimeOfDay(hour: widget.alarmSettings.dateTime.hour, minute: widget.alarmSettings.dateTime.minute);
      final nextTrigger = _calculateNextDay(time);
      final nextSettings = widget.alarmSettings.copyWith(dateTime: nextTrigger);
      await Alarm.set(alarmSettings: nextSettings);
      
       if (alarmData != null && !alarmData.enabled) {
          await AlarmStore.setEnabled(widget.alarmSettings.id, true);
       }
    } else {
        await AlarmStore.setEnabled(widget.alarmSettings.id, false);
    }

    if (mounted) {
      Navigator.of(context).pushReplacement( 
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    }
  }

  Future<void> _snooze() async {
    if (_isStopping) return;
    setState(() { _isStopping = true; }); 
     
    // No manual audio to stop. Just stop the native alarm.
    await Alarm.stop(widget.alarmSettings.id);
    await notificationService.cancelRingingNotification(widget.alarmSettings.id);

    final snoozeTime = DateTime.now().add(const Duration(minutes: 5));
    final snoozeSettings = widget.alarmSettings.copyWith(dateTime: snoozeTime);
    await Alarm.set(alarmSettings: snoozeSettings);

    if (mounted) {
        Navigator.of(context).pushReplacement( 
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    // This part is unchanged
    final timeOfDay = TimeOfDay.fromDateTime(widget.alarmSettings.dateTime);
    final time = '${timeOfDay.hour.toString().padLeft(2, '0')}:${timeOfDay.minute.toString().padLeft(2, '0')}';
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
              const Text('⏰', style: TextStyle(fontSize: 72)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _isStopping ? null : _snooze,
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