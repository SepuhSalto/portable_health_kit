import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart';
import 'package:portable_health_kit/services/alarm_store.dart';

// Define availableSounds list directly here or import if defined elsewhere (e.g., notification_service)
// Ensure these filenames EXACTLY match your files in assets/sounds/
const List<String> availableSounds = [
  'alarm_classic.wav', // Make sure this file exists in assets/sounds/
  'alarm_simple.wav',
  'waktunya_minum_obat.wav',
  'lakukan_senam_kaki.wav',
];


class AddEditAlarmScreen extends StatefulWidget {
  final int? alarmId; // Pass ID from AlarmData if editing

  const AddEditAlarmScreen({super.key, this.alarmId});

  @override
  State<AddEditAlarmScreen> createState() => _AddEditAlarmScreenState();
}

class _AddEditAlarmScreenState extends State<AddEditAlarmScreen> {
  // State variables for the form fields
  final _titleController = TextEditingController();
  TimeOfDay _selectedTime = TimeOfDay.now();
  // Store the full asset path, initialized to the first sound
  String _selectedSoundAssetPath = 'assets/sounds/${availableSounds.first}';
  bool _loopAudio = true;
  bool _vibrate = true;
  bool _repeatEveryday = false; // Default for new alarms

  bool _isLoading = false; // To show loading indicator on save/load
  bool _isEditing = false; // To determine if loading existing data

  @override
  void initState() {
    super.initState();
    _isEditing = widget.alarmId != null; // Check if an ID was passed
    if (_isEditing) {
      // If editing, load the existing alarm's details
      _loadAlarmDetails(widget.alarmId!);
    } else {
      // If creating a new alarm, set default values
      _titleController.text = 'Alarm';
      // Set default time slightly in the future
      final now = DateTime.now().add(const Duration(minutes: 5));
      _selectedTime = TimeOfDay(hour: now.hour, minute: now.minute);
      // Ensure default sound path is the full asset path
      _selectedSoundAssetPath = 'assets/sounds/${availableSounds.first}';
    }
  }

  /// Loads alarm details from Hive store based on the provided ID.
  Future<void> _loadAlarmDetails(int id) async {
    // Show loading indicator while fetching data
    if (mounted) setState(() { _isLoading = true; });

    // Get alarm data from Hive
    final alarmData = AlarmStore.getAlarmById(id);

    if (alarmData != null && mounted) {
      // Construct the expected full path from the stored data
      String loadedPath = alarmData.soundAssetPath;
      // Basic check/correction: ensure it starts with 'assets/sounds/'
      if (!loadedPath.startsWith('assets/sounds/')) {
          loadedPath = 'assets/sounds/$loadedPath'; // Prepend if missing
      }

      // Update the state with loaded data
      setState(() {
        _titleController.text = alarmData.title;
        _selectedTime = TimeOfDay(hour: alarmData.hour, minute: alarmData.minute);
        // Validate the loaded path against available sounds, default if not found
        if (availableSounds.any((name) => loadedPath == 'assets/sounds/$name')) {
             _selectedSoundAssetPath = loadedPath;
        } else {
             _selectedSoundAssetPath = 'assets/sounds/${availableSounds.first}'; // Default
             print("AddEditAlarmScreen Warning: Loaded invalid sound path '${alarmData.soundAssetPath}', defaulting to ${_selectedSoundAssetPath}");
        }
        _loopAudio = alarmData.loopAudio;
        _vibrate = alarmData.vibrate;
        _repeatEveryday = alarmData.repeatEveryday;
        _isLoading = false; // Hide loading indicator
      });
    } else if (mounted) {
      // Handle case where alarm data for the ID is missing in Hive
       setState(() { _isLoading = false; });
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('Error: Data alarm untuk ID $id tidak ditemukan.'), backgroundColor: Colors.red),
       );
       Navigator.of(context).pop(); // Go back if data can't be loaded
    }
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed
    _titleController.dispose();
    super.dispose();
  }

  /// Shows the time picker dialog to select the alarm time.
  Future<void> _selectTime(BuildContext context) async {
     final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      // Use a builder to force 24-hour format regardless of device settings
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    // If a time was picked, update the state
    if (picked != null && picked != _selectedTime) {
      setState(() { _selectedTime = picked; });
    }
  }

  /// Calculates the next trigger DateTime based on the selected TimeOfDay.
  DateTime _calculateNextTrigger(TimeOfDay time) {
    final now = DateTime.now();
    // Calculate the time for today
    DateTime next = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    // If that time is already in the past today, schedule it for tomorrow
    if (next.isBefore(now)) {
      next = next.add(const Duration(days: 1));
    }
    return next;
  }

  /// Saves the alarm settings to Hive and schedules it using the Alarm package.
  Future<void> _saveAlarm() async {
    // Basic validation
    if (_titleController.text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Judul alarm tidak boleh kosong.'), backgroundColor: Colors.red),
      );
      return;
    }
    // Show loading indicator during save operation
    setState(() { _isLoading = true; });

    // Determine the alarm ID (use existing or generate new)
    final alarmId = widget.alarmId ?? (DateTime.now().millisecondsSinceEpoch % 100000 + 1);
    final title = _titleController.text;
    final body = 'Waktunya untuk: $title';
    // Calculate the exact time for the next trigger
    final triggerTime = _calculateNextTrigger(_selectedTime);
    // Use the currently selected full sound asset path
    final soundPath = _selectedSoundAssetPath;

    // Log details for debugging
    print("AddEditAlarmScreen: Saving Alarm ID=$alarmId:");
    print("  Title: $title");
    print("  Sound Asset Path: $soundPath");
    print("  Time: ${_selectedTime.hour}:${_selectedTime.minute}");
    print("  Repeat: $_repeatEveryday");
    print("  Next Trigger: $triggerTime");

    // Create the AlarmSettings object required by the `alarm` package
    final alarmSettings = AlarmSettings(
      id: alarmId,
      dateTime: triggerTime,
      loopAudio: _loopAudio,
      vibrate: _vibrate,
      assetAudioPath: soundPath, // Pass the full asset path
      volumeSettings: const VolumeSettings.fixed(), // Use default/fixed volume for now
      notificationSettings: NotificationSettings(
        title: title,
        body: body,
        stopButton: 'Stop', // Text for the stop button on the notification
      ),
      allowAlarmOverlap: false, // Prevent multiple instances ringing simultaneously
    );

    // Attempt to schedule the alarm using the `alarm` package
    final success = await Alarm.set(alarmSettings: alarmSettings);

    if (success) {
      print("AddEditAlarmScreen: Alarm $alarmId scheduled successfully via Alarm.set()");
      // Save/update the details (including repeat flag) in Hive store
      await AlarmStore.upsert(
          alarmSettings,
          enabled: true, // When saving, assume it's enabled
          repeatEveryday: _repeatEveryday); // Save the repeat setting
    } else {
        print("AddEditAlarmScreen: FAILED to schedule alarm $alarmId via Alarm.set()");
    }

    // Check if the widget is still mounted before updating state or navigating
    if (!mounted) return;
    setState(() { _isLoading = false; }); // Hide loading indicator

    if (success) {
      Navigator.of(context).pop(true); // Pop screen and return true to indicate success
    } else {
      // Show error message if scheduling failed
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menyimpan alarm. Pastikan izin sistem diberikan.'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show a loading screen if loading details for an existing alarm
     if (_isLoading && _isEditing) {
       return Scaffold(
         appBar: AppBar(title: const Text('Memuat Alarm...')),
         body: const Center(child: CircularProgressIndicator()),
       );
     }
    // Main UI for adding/editing
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Alarm' : 'Tambah Alarm Baru'),
        leading: IconButton( // Add a back button
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        // Add padding around the form content
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, // Make elements fill width
          children: [
            // --- Title Field ---
            const Text('Judul Alarm', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                 hintText: 'e.g., Minum Obat Pagi',
                 prefixIcon: Icon(Icons.label_outline),
                 // fillColor and filled already set by theme
              ),
            ),
            const SizedBox(height: 24),

            // --- Time Picker ---
            const Text('Waktu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Card(
              // Use theme card color
              child: ListTile(
                leading: const Icon(Icons.access_time),
                title: Text(
                  '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
                ),
                trailing: const Icon(Icons.arrow_drop_down), // Indicate tappable
                onTap: () => _selectTime(context), // Open time picker on tap
              ),
            ),
            const SizedBox(height: 24),

            // --- Sound Selector ---
            const Text('Suara Alarm', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _buildSoundSelector(), // The dropdown widget
            const SizedBox(height: 12),

             // --- Repeat Switch ---
            SwitchListTile(
               contentPadding: EdgeInsets.zero, // Remove default padding
               title: const Text('Ulangi Setiap Hari'),
               value: _repeatEveryday,
               onChanged: (value) => setState(() => _repeatEveryday = value),
               activeColor: Theme.of(context).primaryColor, // Use theme color
            ),
             const SizedBox(height: 12),

             // --- Optional: Loop Audio Switch ---
             SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Putar Suara Berulang'),
                value: _loopAudio,
                onChanged: (value) => setState(() => _loopAudio = value),
                activeColor: Theme.of(context).primaryColor,
             ),
             // --- Optional: Vibrate Switch ---
              SwitchListTile(
                 contentPadding: EdgeInsets.zero,
                 title: const Text('Getar'),
                 value: _vibrate,
                 onChanged: (value) => setState(() => _vibrate = value),
                 activeColor: Theme.of(context).primaryColor,
              ),

            const SizedBox(height: 40), // Spacing before button
            // --- Save Button ---
            ElevatedButton(
              onPressed: _isLoading ? null : _saveAlarm, // Disable button while loading
              // Show loading indicator inside button if saving
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2,))
                  : const Text('Simpan Alarm'),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the dropdown widget for selecting the alarm sound.
  Widget _buildSoundSelector() {
    return DropdownButtonFormField<String>(
      // The current value must be the full asset path
      value: _selectedSoundAssetPath,
      // Use theme input decoration
      decoration: const InputDecoration(
          prefixIcon: Icon(Icons.music_note_outlined),
          // labelText: 'Suara', // Optional label
      ),
      // Generate items for the dropdown
      items: availableSounds.map((String soundFileName) {
        // Construct the full asset path to be used as the item's value
        final String assetPath = 'assets/sounds/$soundFileName';
        return DropdownMenuItem<String>(
          value: assetPath, // The value associated with this item
          // The text displayed to the user
          child: Text(soundFileName.split('.').first.replaceAll('_', ' ').toUpperCase()),
        );
      }).toList(),
      // Update state when a new sound is selected
      onChanged: (String? newValue) {
        if (newValue != null) {
          // Store the selected full asset path
          setState(() { _selectedSoundAssetPath = newValue; });
        }
      },
    );
  }
}