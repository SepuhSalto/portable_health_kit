import 'package:flutter/material.dart';
import 'models/alarm_models.dart';
import 'add_edit_alarm_screen.dart';

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  // Mock data for demonstration. Later, this will come from Firestore.
  final List<Alarm> _alarms = [
    Alarm(id: '1', title: 'Minum Obat Hipertensi', time: const TimeOfDay(hour: 9, minute: 0), repeatDays: List.filled(7, true)),
    Alarm(id: '2', title: 'Senam Kaki Diabetes', time: const TimeOfDay(hour: 17, minute: 0), repeatDays: [true, false, true, false, true, false, false], isActive: false),
    Alarm(id: '3', title: 'Cek Gula Darah', time: const TimeOfDay(hour: 20, minute: 0), repeatDays: [true, true, true, true, true, true, true]),
  ];

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Alarm'),
        automaticallyImplyLeading: false,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
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
                  Switch(
                    value: alarm.isActive,
                    onChanged: (bool value) {
                      setState(() {
                        alarm.isActive = value;
                        // TODO: Save updated alarm state to Firestore
                      });
                    },
                    activeColor: Theme.of(context).primaryColor,
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => AddEditAlarmScreen(alarmToEdit: alarm)));
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AddEditAlarmScreen()));
        },
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}