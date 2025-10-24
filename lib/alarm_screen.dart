import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart';
// import 'package:shared_preferences/shared_preferences.dart'; // Keep for other prefs maybe (but not used here)
import 'package:permission_handler/permission_handler.dart';
import 'package:disable_battery_optimization/disable_battery_optimization.dart';
import 'package:audioplayers/audioplayers.dart'; // Import audioplayers
import 'package:portable_health_kit/add_edit_alarm_screen.dart';
import 'package:portable_health_kit/services/alarm_store.dart';
import 'package:portable_health_kit/models/alarm_data.dart';
import 'package:portable_health_kit/services/notification_service.dart'; // For sound list
import 'package:intl/intl.dart';

// Data class to hold alarm info loaded from SharedPreferences
// No need for separate AlarmInfo class, use AlarmData directly

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});
  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<AlarmData> _alarms = [];
  bool _isLoading = true;
  bool _permissionsChecked = false;


  @override
  void initState() {
    super.initState();
    // Use WidgetsBinding to schedule tasks after the first frame build
    WidgetsBinding.instance.addPostFrameCallback((_) {
         _checkPermissionsAndLoad();
    });
  }

  @override
  void dispose() {
    // Release the audio player resources when the screen is disposed
    _audioPlayer.dispose();
    print("AlarmScreen: AudioPlayer disposed.");
    super.dispose();
  }


  // --- Permission and Loading Logic ---

  Future<void> _checkPermissionsAndLoad() async {
    // Ensure the widget is still mounted before proceeding
    if (!mounted) return;
    setState(() { _isLoading = true; });

    // Check permissions only once per screen lifecycle unless explicitly triggered
    if (!_permissionsChecked) {
        print("AlarmScreen: Checking permissions...");
        await _checkAllPermissions();
        // Check mounted status again after async gap
        if (!mounted) return;
        setState(() { _permissionsChecked = true; });
    }
     print("AlarmScreen: Loading alarms...");
     await _loadAlarms();

     if (mounted) setState(() { _isLoading = false; });
  }

  Future<void> _checkAllPermissions() async {
    bool permissionsFullyGranted = true; // Assume true initially

    // Request Notification Permission (Android 13+)
    print("AlarmScreen: Checking Notification permission...");
    PermissionStatus notificationStatus = await Permission.notification.status;
    if (!notificationStatus.isGranted) {
      print("AlarmScreen: Requesting Notification permission...");
      notificationStatus = await Permission.notification.request();
      print("AlarmScreen: Notification permission status after request: $notificationStatus");
      if (!notificationStatus.isGranted) permissionsFullyGranted = false;
    }

    // Request Exact Alarm Permission (Android 12+, Required Android 14+)
    print("AlarmScreen: Checking Exact Alarm permission...");
    PermissionStatus alarmStatus = await Permission.scheduleExactAlarm.status;
    // On Android < 12, this permission doesn't exist and status might be 'granted' or 'denied' misleadingly.
    // Check if the permission is applicable first is safer if targeting older Android,
    // but for simplicity, we request if not granted.
    if (!alarmStatus.isGranted) {
       print("AlarmScreen: Requesting Exact Alarm permission...");
       alarmStatus = await Permission.scheduleExactAlarm.request();
       print("AlarmScreen: Exact Alarm permission status after request: $alarmStatus");
       if (!alarmStatus.isGranted) permissionsFullyGranted = false;
    }

    // Check Battery Optimization Status
    print("AlarmScreen: Checking Battery Optimization status...");
    bool? isBatteryOptDisabled;
    try {
        isBatteryOptDisabled = await DisableBatteryOptimization.isBatteryOptimizationDisabled;
        print("AlarmScreen: Is Battery Optimization Disabled: $isBatteryOptDisabled");
        if (isBatteryOptDisabled == false) {
           print("AlarmScreen: Requesting user to disable Battery Optimization via settings...");
           // This opens the system settings page; we can't await user action here.
           await DisableBatteryOptimization.showDisableBatteryOptimizationSettings();
           // We can't confirm success here, just that we opened settings.
        }
    } catch (e) {
        print("AlarmScreen: Error checking or requesting battery optimization: $e");
        // Handle error, maybe show a message if this feature is critical
    }


    // --- User Feedback based on Permissions ---
    if (!mounted) return; // Check mounted status before showing UI elements

    if (notificationStatus.isPermanentlyDenied || alarmStatus.isPermanentlyDenied) {
       print("AlarmScreen: A critical permission was permanently denied.");
       _showPermissionDeniedDialog();
    } else if (!permissionsFullyGranted) {
         print("AlarmScreen: Some permissions were denied, but not permanently.");
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Izin Notifikasi & Alarm dibutuhkan agar alarm berfungsi optimal.'),
                  backgroundColor: Colors.orange)
          );
    } else {
        print("AlarmScreen: All checkable permissions appear granted or requested.");
        // Note: We can't programmatically confirm battery optimization was disabled.
    }
  }

  void _showPermissionDeniedDialog() {
      if (!mounted) return;
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
             title: const Text('Izin Dibutuhkan'),
             content: const Text('Izin notifikasi atau alarm ditolak permanen. Harap aktifkan secara manual di pengaturan aplikasi.'),
             actions: [
               TextButton(child: const Text('Batal'), onPressed: () => Navigator.of(context).pop()),
               TextButton(
                 child: const Text('Buka Pengaturan'),
                 onPressed: () {
                   openAppSettings(); // From permission_handler
                   Navigator.of(context).pop();
                 }),
             ],
           ),
        );
  }

  // --- Alarm Data Handling ---

  Future<void> _loadAlarms() async {
     print("AlarmScreen: Loading alarms from Hive...");
     // Ensure Hive box is ready (can happen if app restarts quickly)
     // A more robust solution might involve checking AlarmStore readiness.
     try {
       final loadedAlarms = AlarmStore.getAllAlarms();
       if (mounted) {
         setState(() { _alarms = loadedAlarms; });
         print("AlarmScreen: Alarms loaded. Count: ${_alarms.length}");
       }
     } catch (e) {
         print("AlarmScreen: ERROR loading alarms from Hive: $e");
         if (mounted) {
            setState(() { _alarms = []; }); // Reset to empty list on error
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Gagal memuat alarm: $e'), backgroundColor: Colors.red),
            );
         }
     }
  }

  // --- UI Actions ---

  /// Plays the sound associated with the alarm using audioplayers.
  Future<void> _playSound(String soundAssetPath) async {
     final normalized = _normalizeAssetPath(soundAssetPath);
     if (normalized.startsWith('assets/')) {
        final String relativePath = normalized.replaceFirst('assets/', '');
        try {
           print("AlarmScreen: Attempting to play sound via AssetSource: $relativePath");
           await _audioPlayer.stop();
           await _audioPlayer.play(AssetSource(relativePath));
           print("AlarmScreen: Play command issued for $relativePath");
        } catch (e) {
           print("AlarmScreen: ERROR playing sound '$relativePath': $e");
           if(mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: Text('Gagal memutar suara: $e'), backgroundColor: Colors.red),
             );
           }
        }
     } else {
        print("AlarmScreen: Invalid sound path after normalization: $normalized");
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Format suara tidak valid atau tidak ditemukan.'), backgroundColor: Colors.orange),
          );
        }
     }
  }


  /// Toggles the enabled state of an alarm. Schedules via Alarm.set or stops via Alarm.stop.
  Future<void> _toggleAlarm(AlarmData alarmData, bool enable) async {
     print("AlarmScreen: Toggling alarm ID=${alarmData.id} to enabled=$enable");
     setState(() { _isLoading = true; });

     if (enable) {
         final time = TimeOfDay(hour: alarmData.hour, minute: alarmData.minute);
         final nextTrigger = _calculateNextTrigger(time);
         final soundPath = _normalizeAssetPath(alarmData.soundAssetPath);

         final settings = AlarmSettings(
           id: alarmData.id,
           dateTime: nextTrigger,
           loopAudio: alarmData.loopAudio,
           vibrate: alarmData.vibrate,
           assetAudioPath: soundPath,
           volumeSettings: const VolumeSettings.fixed(),
           notificationSettings: NotificationSettings(
             title: alarmData.title,
             body: alarmData.body,
             stopButton: 'Stop',
           ),
           allowAlarmOverlap: false,
         );

         final success = await Alarm.set(alarmSettings: settings);
         if (success) {
            await AlarmStore.setEnabled(alarmData.id, true);
            print("AlarmScreen: Enabled and scheduled alarm ID=${alarmData.id} for $nextTrigger");
         } else {
             print("AlarmScreen: FAILED to schedule alarm ID=${alarmData.id} on enable toggle.");
              if(mounted) ScaffoldMessenger.of(context).showSnackBar(
                   const SnackBar(content: Text('Gagal mengaktifkan alarm. Periksa izin.'), backgroundColor: Colors.red),
              );
         }
     } else {
         final success = await Alarm.stop(alarmData.id);
         await AlarmStore.setEnabled(alarmData.id, false);
         print("AlarmScreen: Disabled alarm ID=${alarmData.id}. Stop success: $success");
     }

     // Ensure UI updates even if component is disposed during async calls
     if(mounted) {
        await _loadAlarms(); // Refresh UI list from Hive
        setState(() { _isLoading = false; }); // Hide loading indicator
     }
  }

  /// Deletes an alarm completely.
  Future<void> _deleteAlarm(int id) async {
    print("AlarmScreen: Attempting to delete alarm ID=$id");
    setState(() { _isLoading = true; });
    await Alarm.stop(id); // Ensure it's stopped/unscheduled first
    await AlarmStore.remove(id); // Remove from Hive
    if(mounted) {
       await _loadAlarms(); // Refresh UI
       setState(() { _isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alarm dihapus.'), backgroundColor: Colors.green),
        );
    }
  }

  /// Navigates to the Add/Edit screen for editing an existing alarm.
  Future<void> _editAlarm(int alarmId) async {
    // Navigate and wait for a potential result (true if saved)
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddEditAlarmScreen(alarmId: alarmId)),
    );
    // Reload if the edit screen indicated a save occurred
    if (result == true && mounted) {
      print("AlarmScreen: Reloading alarms after edit.");
      _loadAlarms();
    }
  }

  /// Navigates to the Add/Edit screen to create a new alarm.
  Future<void> _addAlarm() async {
    // Navigate and wait for a potential result (true if saved)
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddEditAlarmScreen()), // Pass null ID
    );
    // Reload if the add screen indicated a save occurred
    if (result == true && mounted) {
       print("AlarmScreen: Reloading alarms after add.");
       _loadAlarms();
    }
  }

  // --- Helper Functions ---

  /// Calculates the next trigger DateTime based on the TimeOfDay.
  DateTime _calculateNextTrigger(TimeOfDay time) {
    final now = DateTime.now();
    DateTime next = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    // If the calculated time is today but already passed, schedule for tomorrow
    if (next.isBefore(now)) {
      next = next.add(const Duration(days: 1));
    }
    return next;
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

  // --- Build Method ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Alarm'),
        automaticallyImplyLeading: false, // No back button needed on main tabs
        actions: [
             IconButton(
               icon: const Icon(Icons.shield_outlined), // Icon for permissions
               tooltip: 'Periksa Izin Sistem',
               onPressed: _checkAllPermissions, // Allow explicit re-check
             ),
             IconButton(
               icon: const Icon(Icons.refresh),
               tooltip: 'Muat Ulang Daftar Alarm',
               onPressed: _checkPermissionsAndLoad, // Reloads alarms too
             )
        ]
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // Show loading indicator
          : _alarms.isEmpty
             ? Center( // Show message if no alarms or permissions not checked yet
                 child: Padding(
                   padding: const EdgeInsets.all(20.0),
                   child: Text(
                     !_permissionsChecked ? 'Memeriksa izin...' : 'Belum ada alarm yang ditambahkan.\nTekan tombol + untuk membuat alarm baru.',
                     textAlign: TextAlign.center,
                     style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                 )
               )
             : ListView.builder( // Display the list of alarms
                 padding: const EdgeInsets.fromLTRB(16, 16, 16, 80), // Padding around the list
                 itemCount: _alarms.length,
                 itemBuilder: (context, index) {
                   final alarm = _alarms[index];
                   final time = TimeOfDay(hour: alarm.hour, minute: alarm.minute);
                   final nextTrigger = _calculateNextTrigger(time); // For display

                   return Card(
                     margin: const EdgeInsets.only(bottom: 12.0),
                     elevation: alarm.enabled ? 2 : 0.5, // Subtle visual difference for enabled state
                     color: alarm.enabled ? Colors.white : Colors.grey[200], // Grey out disabled alarms
                     child: ListTile(
                       contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                       // Toggle switch on the left
                       leading: Switch(
                            value: alarm.enabled,
                            onChanged: (value) => _toggleAlarm(alarm, value),
                            activeColor: Theme.of(context).primaryColor,
                       ),
                       // Alarm title and time
                       title: Text(
                         alarm.title,
                         style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: alarm.enabled ? Colors.black : Colors.grey[600],
                            decoration: alarm.enabled ? TextDecoration.none : TextDecoration.lineThrough,
                          )
                       ),
                       subtitle: Text(
                         'Pukul ${time.format(context)} ${alarm.repeatEveryday ? "• Setiap Hari" : ""}\nBerikutnya: ${DateFormat('EEE, d MMM HH:mm', 'id_ID').format(nextTrigger)}',
                         style: TextStyle(color: alarm.enabled ? Colors.grey[700] : Colors.grey[500])
                       ),
                       isThreeLine: true, // Allow more space for subtitle
                       // Action buttons on the right
                       trailing: Row(
                         mainAxisSize: MainAxisSize.min,
                         children: [
                           IconButton(
                             tooltip: 'Putar Suara',
                             icon: Icon(Icons.volume_up_outlined, color: alarm.enabled ? Theme.of(context).primaryColor : Colors.grey),
                             onPressed: () => _playSound(alarm.soundAssetPath), // Use full path
                           ),
                           IconButton(
                             tooltip: 'Edit Alarm',
                             icon: Icon(Icons.edit_outlined, color: alarm.enabled ? Colors.black54 : Colors.grey),
                             onPressed: () => _editAlarm(alarm.id),
                           ),
                           IconButton(
                             tooltip: 'Hapus Alarm',
                             icon: Icon(Icons.delete_outline, color: Colors.red[700]),
                             onPressed: () => _deleteAlarm(alarm.id),
                           ),
                         ],
                       ),
                       // Optional: Tap list tile itself to edit
                       // onTap: () => _editAlarm(alarm.id),
                     ),
                   );
                 },
               ),
      // Floating Action Button to add new alarms
      floatingActionButton: FloatingActionButton(
        onPressed: _addAlarm,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white, // Ensure icon is white
        tooltip: 'Tambah Alarm Baru',
        child: const Icon(Icons.add),
      ),
    );
  }
}