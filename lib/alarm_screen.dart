import 'package:flutter/material.dart';
import 'package:portable_health_kit/models/alarm_models.dart';
import 'package:portable_health_kit/add_edit_alarm_screen.dart';
import 'package:audioplayers/audioplayers.dart'; // 1. Import the new package

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  // 2. Create an instance of the audio player
  final AudioPlayer _audioPlayer = AudioPlayer();

  final List<Alarm> _alarms = [
    Alarm(id: 'fixed_1', title: 'Minum Obat', time: const TimeOfDay(hour: 9, minute: 0), repeatDays: List.filled(7, true), isFixed: true),
    Alarm(id: 'fixed_2', title: 'Senam Kaki', time: const TimeOfDay(hour: 17, minute: 0), repeatDays: [true, false, true, false, true, false, false], isFixed: true),
    Alarm(id: 'custom_1', title: 'Cek Gula Darah', time: const TimeOfDay(hour: 20, minute: 0), repeatDays: List.filled(7, true)),
  ];

  // 3. Create a function to play a sound from your assets
  Future<void> _playSound(String soundAsset) async {
    await _audioPlayer.play(AssetSource(soundAsset));
  }

  String _getRepeatDaysString(List<bool> days) {
    if (days.every((day) => day)) return 'Setiap Hari';
    if (days.every((day) => !day)) return 'Tidak Diulang';
    const dayNames = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    final selectedDays = <String>[];
    for (int i = 0; i < days.length; i++) {
      if (days[i]) {
        selectedDays.add(dayNames[i]);
      }
    }
    return selectedDays.join(', ');
  }

  void _deleteAlarm(String id) {
    setState(() {
      _alarms.removeWhere((alarm) => alarm.id == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Alarm berhasil dihapus.'), backgroundColor: Colors.green),
    );
  }
  
  Future<void> _editAlarm(Alarm alarm) async {
    final Alarm? updatedAlarm = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddEditAlarmScreen(alarmToEdit: alarm)),
    );

    if (updatedAlarm != null && mounted) {
      setState(() {
        final index = _alarms.indexWhere((a) => a.id == updatedAlarm.id);
        if (index != -1) {
          _alarms[index] = updatedAlarm;
        }
      });
    }
  }

  Future<void> _addAlarm() async {
    final Alarm? newAlarm = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddEditAlarmScreen()),
    );

    if (newAlarm != null && mounted) {
      setState(() {
        _alarms.add(newAlarm);
      });
    }
  }


  @override
  void dispose() {
    _audioPlayer.dispose(); // Clean up the audio player when the screen is closed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Alarm'),
        automaticallyImplyLeading: false,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80), // Added bottom padding
        itemCount: _alarms.length,
        itemBuilder: (context, index) {
          final alarm = _alarms[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12.0),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              title: Text(alarm.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Pukul ${alarm.time.format(context)} • ${_getRepeatDaysString(alarm.repeatDays)}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (alarm.isFixed)
                    IconButton(
                      icon: Icon(Icons.volume_up_outlined, color: Theme.of(context).primaryColor),
                      onPressed: () {
                        if (alarm.title == 'Minum Obat') {
                          _playSound('sounds/Waktunya Minum Obat.wav');
                        } else if (alarm.title == 'Senam Kaki') {
                          _playSound('sounds/Lakukan Senam Kaki.wav');
                        }
                      },
                    ),
                  Switch(
                    value: alarm.isActive,
                    onChanged: (bool value) {
                      setState(() {
                        alarm.isActive = value;
                      });
                    },
                    activeColor: Theme.of(context).primaryColor,
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    // Use the new _editAlarm function
                    onPressed: () => _editAlarm(alarm),
                  ),
                  if (!alarm.isFixed)
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
        // Use the new _addAlarm function
        onPressed: _addAlarm,
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}