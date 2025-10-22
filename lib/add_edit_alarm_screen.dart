import 'package:flutter/material.dart';
import 'package:portable_health_kit/models/alarm_models.dart';

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
  bool _isFixed = false; // To check if we are editing a fixed alarm

  @override
  void initState() {
    super.initState();
    if (widget.alarmToEdit != null) {
      _titleController.text = widget.alarmToEdit!.title;
      _selectedTime = widget.alarmToEdit!.time;
      _repeatDays = widget.alarmToEdit!.repeatDays;
      _isFixed = widget.alarmToEdit!.isFixed;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context) async {
    // Disable time picking if the alarm is fixed
    if (_isFixed) return; 

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
    final title = _titleController.text;
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul tidak boleh kosong.'), backgroundColor: Colors.red),
      );
      return;
    }

    if (widget.alarmToEdit != null) {
      // Editing existing alarm
      widget.alarmToEdit!.title = title;
      widget.alarmToEdit!.time = _selectedTime;
      widget.alarmToEdit!.repeatDays = _repeatDays;
      Navigator.of(context).pop(widget.alarmToEdit);
    } else {
      // Creating new alarm
      final newAlarm = Alarm(
        // Use a simple unique ID for local alarms
        id: 'custom_${DateTime.now().millisecondsSinceEpoch}', 
        title: title,
        time: _selectedTime,
        repeatDays: _repeatDays,
        isActive: true, // New alarms are active by default
      );
      Navigator.of(context).pop(newAlarm);
    }
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
              enabled: !_isFixed,
              decoration: InputDecoration(
                hintText: 'e.g., Minum Obat Pagi',
                prefixIcon: const Icon(Icons.label_outline),
                fillColor: _isFixed ? Colors.grey[200] : Colors.white,
                filled: true, // Make sure the fill color is applied
              ),
            ),
            const SizedBox(height: 24),
            const Text('Waktu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.access_time),
                title: Text(_selectedTime.format(context), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                trailing: _isFixed ? Icon(Icons.lock, color: Colors.grey[600]) : null,
                onTap: () => _selectTime(context),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Ulangi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _buildRepeatDaysSelector(),
            const SizedBox(height: 40),
            ElevatedButton(
              // Disable save button for fixed alarms
              onPressed: _isFixed ? null : _saveAlarm,
              child: Text(_isFixed ? 'Alarm Tetap (Tidak Bisa Disimpan)' : 'Simpan Alarm'),
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
            // Disable day picking if the alarm is fixed
            if (_isFixed) return; 
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