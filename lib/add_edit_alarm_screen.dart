import 'package:flutter/material.dart';
import 'models/alarm_models.dart';

class AddEditAlarmScreen extends StatefulWidget {
  final Alarm? alarmToEdit;

  const AddEditAlarmScreen({super.key, this.alarmToEdit});

  @override
  State<AddEditAlarmScreen> createState() => _AddEditAlarmScreenState();
}

class _AddEditAlarmScreenState extends State<AddEditAlarmScreen> {
  final _titleController = TextEditingController();
  TimeOfDay _selectedTime = TimeOfDay.now();
  List<bool> _repeatDays = List.filled(7, false);

  @override
  void initState() {
    super.initState();
    if (widget.alarmToEdit != null) {
      _titleController.text = widget.alarmToEdit!.title;
      _selectedTime = widget.alarmToEdit!.time;
      _repeatDays = widget.alarmToEdit!.repeatDays;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _saveAlarm() {
    // TODO: Implement save/update logic with Firestore
    print('Title: ${_titleController.text}');
    print('Time: ${_selectedTime.format(context)}');
    print('Repeat Days: $_repeatDays');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.alarmToEdit == null ? 'Tambah Alarm Baru' : 'Edit Alarm'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Judul Alarm', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'e.g., Minum Obat Pagi',
                prefixIcon: Icon(Icons.label_outline),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Waktu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.access_time),
                title: Text(_selectedTime.format(context), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                onTap: () => _selectTime(context),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Ulangi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _buildRepeatDaysSelector(),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _saveAlarm,
              child: const Text('Simpan Alarm'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRepeatDaysSelector() {
    const dayNames = ['S', 'S', 'R', 'K', 'J', 'S', 'M'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        return GestureDetector(
          onTap: () {
            setState(() {
              _repeatDays[index] = !_repeatDays[index];
            });
          },
          child: CircleAvatar(
            radius: 20,
            backgroundColor: _repeatDays[index] ? Theme.of(context).primaryColor : Colors.grey[300],
            child: Text(
              dayNames[index],
              style: TextStyle(
                color: _repeatDays[index] ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }),
    );
  }
}