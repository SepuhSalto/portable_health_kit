import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart'; // 1. Import new package
import 'package:audioplayers/audioplayers.dart';
import 'package:portable_health_kit/add_edit_alarm_screen.dart';

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  // 2. The list is now of type AlarmSettings
  List<AlarmSettings> _alarms = [];

  @override
  void initState() {
    super.initState();
    _loadAlarms();
  }

  // 3. Load alarms from the package
  Future<void> _loadAlarms() async {
    final alarms = await Alarm.getAlarms();
    setState(() {
      _alarms = alarms;
      // Sort them by time
      _alarms.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    });
  }

  // 4. Play sound from assets
  Future<void> _playSound(String soundAsset) async {
    // We can only preview sounds that are in our assets
    if (soundAsset.startsWith('assets/')) {
      await _audioPlayer.play(AssetSource(soundAsset.replaceFirst('assets/', '')));
    } else {
      // Can't play 'default' or other system sounds
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Suara default tidak bisa diputar.'), backgroundColor: Colors.blue),
      );
    }
  }

  // 5. Delete alarm
  Future<void> _deleteAlarm(int id) async {
    await Alarm.stop(id);
    _loadAlarms(); // Refresh the list
  }
  
  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  // 6. Navigate to Edit screen
  Future<void> _editAlarm(AlarmSettings alarm) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddEditAlarmScreen(alarmToEdit: alarm)),
    );
    _loadAlarms(); // Refresh list after editing
  }

  // 7. Navigate to Add screen
  Future<void> _addAlarm() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddEditAlarmScreen()),
    );
    _loadAlarms(); // Refresh list after adding
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Alarm'),
        automaticallyImplyLeading: false,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: _alarms.length,
        itemBuilder: (context, index) {
          final alarm = _alarms[index];
          // 8. Check if it's one of our fixed alarms
          final bool isFixed = (alarm.id == 1 || alarm.id == 2);
          
          return Card(
            margin: const EdgeInsets.only(bottom: 12.0),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              title: Text(alarm.notificationSettings.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Pukul ${TimeOfDay.fromDateTime(alarm.dateTime).format(context)} • Setiap Hari'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // "Play" button
                  IconButton(
                    icon: Icon(Icons.volume_up_outlined, color: Theme.of(context).primaryColor),
                    onPressed: () => _playSound(alarm.assetAudioPath),
                  ),
                  
                  // 9. REMOVED the Switch. The list itself shows what's active.

                  // "Edit" button
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _editAlarm(alarm),
                  ),

                  // "Delete" button (hidden for fixed alarms)
                  if (!isFixed)
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: Colors.red[700]),
                      onPressed: () => _deleteAlarm(alarm.id),
                    ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addAlarm,
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}