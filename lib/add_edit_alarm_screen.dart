import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart'; // 1. Import new package

class AddEditAlarmScreen extends StatefulWidget {
  // 2. It now takes AlarmSettings from the new package
  final AlarmSettings? alarmToEdit;

  const AddEditAlarmScreen({super.key, this.alarmToEdit});

  @override
  State<AddEditAlarmScreen> createState() => _AddEditAlarmScreenState();
}

class _AddEditAlarmScreenState extends State<AddEditAlarmScreen> {
  final _titleController = TextEditingController();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isFixed = false;
  
  // 3. List of our provided sounds
  final List<String> _providedSounds = [
    'assets/sounds/alarm_classic.wav',
    'assets/sounds/alarm_simple.wav',
  ];
  String _selectedSound = '';

  @override
  void initState() {
    super.initState();
    if (widget.alarmToEdit != null) {
      _titleController.text = widget.alarmToEdit!.notificationSettings.title;
      _selectedTime = TimeOfDay.fromDateTime(widget.alarmToEdit!.dateTime);
      _selectedSound = widget.alarmToEdit!.assetAudioPath;
      // Check if it's one of our fixed alarms
      _isFixed = (widget.alarmToEdit!.id == 1 || widget.alarmToEdit!.id == 2);
    } else {
      // Default for new alarms
      _selectedSound = _providedSounds.first;
      _titleController.text = 'Alarm';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  // 4. Added the 24-hour format builder
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  // 5. Helper to get next DateTime from TimeOfDay
  DateTime _getNextDateTime(TimeOfDay time) {
    final now = DateTime.now();
    var dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    // If time is in the past, schedule it for tomorrow
    if (dt.isBefore(now)) {
      dt = dt.add(const Duration(days: 1));
    }
    return dt;
  }

  Future<void> _saveAlarm() async {
    final title = _titleController.text;
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul tidak boleh kosong.'), backgroundColor: Colors.red),
      );
      return;
    }

    // 6. Create the AlarmSettings object
    final alarmSettings = AlarmSettings(
      // If editing, use existing ID. If new, generate a random one.
      id: widget.alarmToEdit?.id ?? DateTime.now().millisecondsSinceEpoch % 100000,
      dateTime: _getNextDateTime(_selectedTime),
      assetAudioPath: _selectedSound,
      loopAudio: true,
      vibrate: true,
      volumeSettings: VolumeSettings.fade(
        volume: 0.8,
        fadeDuration: Duration(seconds: 5),
        volumeEnforced: true,
      ),  
      notificationSettings: NotificationSettings(
        title: title,
        body: 'Waktunya untuk: $title',
        stopButton: 'Stop',
        icon: 'notification_icon',
      ),
    );

    // 7. Save the alarm
    await Alarm.set(alarmSettings: alarmSettings);
    
    if (mounted) Navigator.of(context).pop();
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
              // Title is disabled ONLY for fixed alarms
              enabled: !_isFixed,
              decoration: InputDecoration(
                hintText: 'e.g., Minum Obat Pagi',
                prefixIcon: const Icon(Icons.label_outline),
                fillColor: _isFixed ? Colors.grey[200] : Colors.white,
                filled: true,
              ),
            ),
            const SizedBox(height: 24),
            const Text('Waktu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.access_time),
                title: Text(_selectedTime.format(context), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                trailing: _isFixed ? Icon(Icons.lock_outline, color: Colors.grey[600]) : null,
                onTap: () => _selectTime(context),
              ),
            ),
            const SizedBox(height: 24),
            
            // 8. Sound Selection
            const Text('Suara Alarm', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _buildSoundSelector(),
            
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

  // 9. Sound selector (Fixed alarms keep their custom sound)
  Widget _buildSoundSelector() {
    if (_isFixed) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.music_note_outlined),
          title: Text(_selectedSound.split('/').last.replaceAll('.wav', '')),
          enabled: false,
        ),
      );
    }
    
    return DropdownButtonFormField<String>(
      value: _selectedSound,
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.music_note_outlined),
        filled: true,
        fillColor: Colors.white,
      ),
      items: _providedSounds.map((String sound) {
        return DropdownMenuItem<String>(
          value: sound,
          child: Text(sound.split('/').last.replaceAll('.wav', '').replaceAll('_', ' ').toUpperCase()),
        );
      }).toList(),
      onChanged: (String? newValue) {
        if (newValue != null) {
          setState(() {
            _selectedSound = newValue;
          });
        }
      },
    );
  }
}