import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart';
import 'package:portable_health_kit/models/alarm_data.dart'; // Import Hive model
import 'package:portable_health_kit/services/alarm_store.dart'; // Import Hive store
import 'package:portable_health_kit/services/notification_service.dart'; // For sound list
// Note: No need to import main.dart for alarmCallback anymore

const List<String> availableSounds = [
  // Use file names only
  'alarm_classic.wav',
  'alarm_simple.wav',
  'waktunya_minum_obat.wav',
  'lakukan_senam_kaki.wav',
];

class AddEditAlarmScreen extends StatefulWidget {
  final int? alarmId; // Pass ID from AlarmData

  const AddEditAlarmScreen({super.key, this.alarmId});

  @override
  State<AddEditAlarmScreen> createState() => _AddEditAlarmScreenState();
}

class _AddEditAlarmScreenState extends State<AddEditAlarmScreen> {
  final _titleController = TextEditingController();
  TimeOfDay _selectedTime = TimeOfDay.now();
  // Initialize with the first available sound (normalize to full asset path)
  String _selectedSoundAssetPath = 'assets/sounds/${availableSounds.first}';
  bool _loopAudio = true;
  bool _vibrate = true;
  bool _repeatEveryday = false; // Default for new alarms

  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.alarmId != null;
    if (_isEditing) {
      _loadAlarmDetails(widget.alarmId!);
    } else {
      _titleController.text = 'Alarm';
      final now = DateTime.now().add(const Duration(minutes: 5));
      _selectedTime = TimeOfDay(hour: now.hour, minute: now.minute);
      // Ensure normalized default
      _selectedSoundAssetPath = _normalizeAssetPath(_selectedSoundAssetPath);
    }
  }

  String _normalizeAssetPath(String path) {
    var p = path.trim();
    p = p.replaceAll('assets/sounds/assets/', 'assets/sounds/');
    p = p.replaceAll('assets/assets/', 'assets/');
    p = p.replaceAll('assets/sounds/sounds/', 'assets/sounds/');
    if (!p.startsWith('assets/')) {
      p = 'assets/sounds/$p';
    }
    return p;
  }

  Future<void> _loadAlarmDetails(int id) async {
    setState(() { _isLoading = true; });
    final alarmData = AlarmStore.getAlarmById(id);

    if (alarmData != null && mounted) {
      setState(() {
        _titleController.text = alarmData.title;
        _selectedTime = TimeOfDay(hour: alarmData.hour, minute: alarmData.minute);
        _selectedSoundAssetPath = _normalizeAssetPath(alarmData.soundAssetPath);
        _loopAudio = alarmData.loopAudio;
        _vibrate = alarmData.vibrate;
        _repeatEveryday = alarmData.repeatEveryday;
        _isLoading = false;
      });
    } else if (mounted) {
      // Handle case where alarm data is missing
       setState(() { _isLoading = false; });
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('Error: Alarm data for ID $id not found.'), backgroundColor: Colors.red),
       );
       Navigator.of(context).pop(); // Go back if data is missing
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context) async {
    // ... (selectTime function is unchanged) ...
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
      setState(() { _selectedTime = picked; });
    }
  }

  DateTime _calculateNextTrigger(TimeOfDay time) {
    final now = DateTime.now();
    // Calculate today's time at the specified hour/minute
    DateTime next = DateTime(now.year, now.month, now.day, time.hour, time.minute);

    // *** FIX: Only add a day if the calculated time is strictly in the past ***
    if (next.isBefore(now)) {
      next = next.add(const Duration(days: 1));
    }
    // *** END FIX ***
    return next;
  }

  Future<void> _saveAlarm() async {
    if (_titleController.text.isEmpty) {
      // ... (show error SnackBar) ...
      return;
    }
    setState(() { _isLoading = true; });

    final alarmId = widget.alarmId ?? (DateTime.now().millisecondsSinceEpoch % 100000 + 1);
    final title = _titleController.text;
    final body = 'Waktunya untuk: $title';
    final triggerTime = _calculateNextTrigger(_selectedTime);
    final normalizedSound = _normalizeAssetPath(_selectedSoundAssetPath);

    print("Saving Alarm ID=$alarmId:");
    print("  Title: $title");
    print("  Sound Asset: $normalizedSound");
    print("  Time: ${_selectedTime.hour}:${_selectedTime.minute}");
    print("  Repeat: $_repeatEveryday");
    print("  Next Trigger: $triggerTime");

    final alarmSettings = AlarmSettings(
      id: alarmId,
      dateTime: triggerTime,
      loopAudio: _loopAudio,
      vibrate: _vibrate,
      assetAudioPath: normalizedSound,
      volumeSettings: const VolumeSettings.fixed(),
      notificationSettings: NotificationSettings(
        title: title,
        body: body,
        stopButton: 'Stop',
      ),
      allowAlarmOverlap: false,
    );

    // Schedule using the `alarm` package
    final success = await Alarm.set(alarmSettings: alarmSettings);

    if (success) {
      print("Alarm $alarmId scheduled successfully via Alarm.set()");
      // Save/update details (including repeat flag) in Hive
      await AlarmStore.upsert(
          alarmSettings,
          enabled: true, // Saving means it's enabled
          repeatEveryday: _repeatEveryday);
    } else {
        print("FAILED to schedule alarm $alarmId via Alarm.set()");
    }

    if (!mounted) return;
    setState(() { _isLoading = false; });

    if (success) {
      Navigator.of(context).pop(true); // Pop and indicate success
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menyimpan alarm. Pastikan izin diberikan.'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (show loading indicator if _isLoading and _isEditing) ...
    return Scaffold(
      appBar: AppBar( /* ... */ ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title TextField
            const Text('Judul Alarm', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(controller: _titleController, /* ... */ ),
            const SizedBox(height: 24),

            // Time Picker Card
            const Text('Waktu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Card(child: ListTile( /* ... */ onTap: () => _selectTime(context),)),
            const SizedBox(height: 24),

            // Sound Selector
            const Text('Suara Alarm', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _buildSoundSelector(), // Uses full asset path now
             const SizedBox(height: 12),

             // Repeat Switch
            SwitchListTile(
               contentPadding: EdgeInsets.zero,
               title: const Text('Ulangi Setiap Hari'),
               value: _repeatEveryday,
               onChanged: (value) => setState(() => _repeatEveryday = value),
               activeColor: Theme.of(context).primaryColor,
            ),
             const SizedBox(height: 12),


             // Optional: Add Loop and Vibrate switches if needed
             // SwitchListTile(...) for _loopAudio
             // SwitchListTile(...) for _vibrate

            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveAlarm,
              child: _isLoading ? const CircularProgressIndicator() : const Text('Simpan Alarm'),
            ),
          ],
        ),
      ),
    );
  }

  // Sound selector uses full asset path
  Widget _buildSoundSelector() {
    return DropdownButtonFormField<String>(
      value: _normalizeAssetPath(_selectedSoundAssetPath),
      decoration: const InputDecoration(prefixIcon: Icon(Icons.music_note_outlined), /* ... */),
      items: availableSounds.map((String fileName) {
        final String assetPath = 'assets/sounds/$fileName';
        return DropdownMenuItem<String>(
          value: assetPath,
          child: Text(fileName.split('.').first.replaceAll('_', ' ').toUpperCase()),
        );
      }).toList(),
      onChanged: (String? newValue) {
        if (newValue != null) {
          setState(() { _selectedSoundAssetPath = _normalizeAssetPath(newValue); });
        }
      },
    );
  }
}