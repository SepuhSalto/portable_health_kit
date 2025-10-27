import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:disable_battery_optimization/disable_battery_optimization.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:portable_health_kit/add_edit_alarm_screen.dart';
import 'package:portable_health_kit/services/alarm_store.dart';
import 'package:portable_health_kit/models/alarm_data.dart';
// No need to import notification_service here unless needed for 'availableSounds'
import 'package:intl/intl.dart';


class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});
  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  // Audio player instance for manual sound preview
  final AudioPlayer _audioPlayer = AudioPlayer();
  // List to hold alarm data loaded from Hive
  List<AlarmData> _alarms = [];
  // State flags for loading and permission checks
  bool _isLoading = true;
  bool _permissionsChecked = false;


  @override
  void initState() {
    super.initState();
    // Schedule permission check and alarm loading after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
         _checkPermissionsAndLoad();
    });

    // --- Add AudioPlayer Listeners for Debugging ---
    _audioPlayer.onPlayerStateChanged.listen((state) {
       print("AlarmScreen: AudioPlayer state changed: $state");
       // e.g., PlayerState.playing, PlayerState.paused, PlayerState.completed
    });
    _audioPlayer.onPlayerComplete.listen((_) {
        print("AlarmScreen: AudioPlayer playback completed");
    });
    print("AlarmScreen: AudioPlayer listeners attached in initState.");
    // --- End AudioPlayer Listeners ---
  }

  @override
  void dispose() {
    // IMPORTANT: Release audio player resources when screen is removed
    _audioPlayer.dispose();
    print("AlarmScreen: AudioPlayer disposed.");
    super.dispose();
  }

  // --- Permission and Loading Logic ---

  /// Checks permissions (if not already checked) and then loads alarms.
  Future<void> _checkPermissionsAndLoad() async {
    if (!mounted) return; // Exit if widget is no longer in the tree
    setState(() { _isLoading = true; }); // Show loading indicator

    // Only check/request permissions on the first load or if explicitly triggered
    if (!_permissionsChecked) {
        print("AlarmScreen: Checking permissions...");
        await _checkAllPermissions(); // Perform permission requests/checks
        if (!mounted) return; // Check again after async gap
        setState(() { _permissionsChecked = true; }); // Mark as checked
    }
     print("AlarmScreen: Loading alarms...");
     await _loadAlarms(); // Load alarm data from Hive

     if (mounted) setState(() { _isLoading = false; }); // Hide loading indicator
  }

  /// Checks and requests Notification, Exact Alarm, and Battery Optimization permissions.
  Future<void> _checkAllPermissions() async {
    bool permissionsFullyGranted = true;

    // --- Notification Permission (Android 13+) ---
    print("AlarmScreen: Checking Notification permission...");
    PermissionStatus notificationStatus = await Permission.notification.status;
    if (notificationStatus.isDenied || notificationStatus.isPermanentlyDenied) { // Check both denied states
      print("AlarmScreen: Requesting Notification permission...");
      notificationStatus = await Permission.notification.request();
      print("AlarmScreen: Notification permission status after request: $notificationStatus");
    }
     if (!notificationStatus.isGranted) permissionsFullyGranted = false;


    // --- Exact Alarm Permission (Android 12+, Required Android 14+) ---
    print("AlarmScreen: Checking Exact Alarm permission...");
    PermissionStatus alarmStatus = await Permission.scheduleExactAlarm.status;
    if (alarmStatus.isDenied || alarmStatus.isPermanentlyDenied) {
       print("AlarmScreen: Requesting Exact Alarm permission...");
       alarmStatus = await Permission.scheduleExactAlarm.request();
       print("AlarmScreen: Exact Alarm permission status after request: $alarmStatus");
    }
     if (!alarmStatus.isGranted) permissionsFullyGranted = false;


    // --- Battery Optimization ---
    print("AlarmScreen: Checking Battery Optimization status...");
    bool? isBatteryOptDisabled;
    try {
        // Check if optimization is already disabled for this app
        isBatteryOptDisabled = await DisableBatteryOptimization.isBatteryOptimizationDisabled;
        print("AlarmScreen: Is Battery Optimization Disabled: $isBatteryOptDisabled");
        // If not disabled, request the user to disable it via system settings
        if (isBatteryOptDisabled == false) {
           print("AlarmScreen: Requesting user to disable Battery Optimization via settings...");
           // This opens the system settings; does not guarantee user action
           await DisableBatteryOptimization.showDisableBatteryOptimizationSettings();
        }
    } catch (e) {
        print("AlarmScreen: Error checking or requesting battery optimization: $e");
        // Optionally inform the user about potential issues
         if (mounted) ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Tidak dapat memeriksa pengaturan baterai.'), backgroundColor: Colors.orange),
         );
    }


    // --- User Feedback ---
    if (!mounted) return; // Check mount status before showing UI

    if (notificationStatus.isPermanentlyDenied || alarmStatus.isPermanentlyDenied) {
       print("AlarmScreen: A critical permission was permanently denied.");
       _showPermissionDeniedDialog(); // Show dialog guiding user to settings
    } else if (!permissionsFullyGranted) {
         print("AlarmScreen: Some permissions were denied, but not permanently.");
         // Show a less intrusive message
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Izin Notifikasi & Alarm dibutuhkan agar alarm berfungsi optimal.'),
                  backgroundColor: Colors.orange)
          );
    } else {
        print("AlarmScreen: All checkable permissions appear granted or requested.");
        // We still can't be 100% sure about battery optimization without re-checking later.
    }
  }

  /// Shows a dialog guiding the user to manually enable permanently denied permissions.
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
                   openAppSettings(); // From permission_handler package
                   Navigator.of(context).pop();
                 }),
             ],
           ),
        );
  }

  // --- Alarm Data Handling ---

  /// Loads all alarm data from the Hive store.
  Future<void> _loadAlarms() async {
     print("AlarmScreen: Loading alarms from Hive...");
     try {
       // Retrieve the list of AlarmData objects from the store
       final loadedAlarms = AlarmStore.getAllAlarms(); // Assumes getAllAlarms is synchronous or handled async internally
       if (mounted) {
         // Update the state with the loaded alarms
         setState(() { _alarms = loadedAlarms; });
         print("AlarmScreen: Alarms loaded. Count: ${_alarms.length}");
       }
     } catch (e) {
         // Handle errors during loading (e.g., Hive not initialized)
         print("AlarmScreen: ERROR loading alarms from Hive: $e");
         if (mounted) {
            setState(() { _alarms = []; }); // Reset to empty list
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Gagal memuat daftar alarm: $e'), backgroundColor: Colors.red),
            );
         }
     }
  }

  // --- UI Actions ---

  /// Plays the sound associated with the alarm using audioplayers for preview.
  Future<void> _playSound(String soundAssetPath) async {
     // Validate the path starts correctly
     if (soundAssetPath.startsWith('assets/sounds/')) {
        // Create the relative path needed by AssetSource
        final String relativePath = soundAssetPath.replaceFirst('assets/', '');
        try {
           print("AlarmScreen: Attempting to play sound via AssetSource: $relativePath");
           // Stop any currently playing audio before starting new playback
           await _audioPlayer.stop();
           // Play the audio from assets
           await _audioPlayer.play(AssetSource(relativePath));
           print("AlarmScreen: Play command issued for $relativePath");
        } catch (e) {
             // Log and show error if playback fails
             print("AlarmScreen: ERROR playing sound '$relativePath': $e");
             if(mounted) {
               ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(content: Text('Gagal memutar suara: $e'), backgroundColor: Colors.red),
               );
             }
        }
     } else {
        // Handle invalid paths
        print("AlarmScreen: Invalid asset path provided to _playSound: $soundAssetPath");
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Path suara tidak valid.'), backgroundColor: Colors.orange),
          );
        }
     }
  }


  /// Toggles the enabled state: schedules via Alarm.set or stops via Alarm.stop, and updates Hive.
  Future<void> _toggleAlarm(AlarmData alarmData, bool enable) async {
     print("AlarmScreen: Toggling alarm ID=${alarmData.id} to enabled=$enable");
     if (!mounted) return;
     setState(() { _isLoading = true; }); // Show loading indicator

     bool operationSuccess = false; // Track if operation succeeds

     if (enable) {
         // --- Enabling the Alarm ---
         final time = TimeOfDay(hour: alarmData.hour, minute: alarmData.minute);
         // Calculate the exact DateTime for the next trigger
         final nextTrigger = _calculateNextTrigger(time);
         // Ensure the sound path is valid before scheduling
         final soundPath = alarmData.soundAssetPath;
         if (!soundPath.startsWith('assets/sounds/')) {
             print("AlarmScreen: ERROR - Invalid sound path in Hive data for ID=${alarmData.id}: $soundPath");
              if(mounted) ScaffoldMessenger.of(context).showSnackBar(
                   const SnackBar(content: Text('Gagal mengaktifkan: Path suara tidak valid.'), backgroundColor: Colors.red),
              );
              if(mounted) setState(() { _isLoading = false; });
              return; // Abort if path is bad
         }

         // Create the AlarmSettings object for the `alarm` package
         final settings = AlarmSettings(
           id: alarmData.id,
           dateTime: nextTrigger,
           loopAudio: alarmData.loopAudio,
           vibrate: alarmData.vibrate,
           assetAudioPath: soundPath, // Use the path directly from Hive
           volumeSettings: const VolumeSettings.fixed(), // Default volume
           notificationSettings: NotificationSettings(
             title: alarmData.title,
             body: alarmData.body,
             stopButton: 'Stop', // Label on notification
           ),
           allowAlarmOverlap: false, // Prevent overlaps
         );

         print("AlarmScreen: Enabling alarm ID=${alarmData.id} with sound path='${settings.assetAudioPath}' for $nextTrigger");
         // Schedule the alarm using the `alarm` package
         operationSuccess = await Alarm.set(alarmSettings: settings);

         if (operationSuccess) {
            await AlarmStore.setEnabled(alarmData.id, true); // Update enabled status in Hive
            print("AlarmScreen: Enabled and scheduled alarm ID=${alarmData.id}");
         } else {
             print("AlarmScreen: FAILED to schedule alarm ID=${alarmData.id} via Alarm.set(). Check permissions.");
              if(mounted) ScaffoldMessenger.of(context).showSnackBar(
                   const SnackBar(content: Text('Gagal mengaktifkan alarm. Periksa izin sistem.'), backgroundColor: Colors.red),
              );
         }
     } else {
         // --- Disabling the Alarm ---
         // Stop the alarm using the `alarm` package
         operationSuccess = await Alarm.stop(alarmData.id);
         // Update the enabled status in Hive regardless of stop success (might already be stopped)
         await AlarmStore.setEnabled(alarmData.id, false);
         print("AlarmScreen: Disabled alarm ID=${alarmData.id}. Stop success: $operationSuccess");
         // Consider operation successful if stop command was sent, even if it wasn't running
         operationSuccess = true;
     }

     // Refresh the UI list from Hive after the operation
     if(mounted) {
        await _loadAlarms();
        setState(() { _isLoading = false; }); // Hide loading indicator
     }
  }

  /// Deletes an alarm completely from scheduling and storage.
  Future<void> _deleteAlarm(int id) async {
    print("AlarmScreen: Attempting to delete alarm ID=$id");
    if (!mounted) return;
    setState(() { _isLoading = true; }); // Show loading during deletion

    // 1. Stop/unschedule the alarm via the `alarm` package
    await Alarm.stop(id);
    // 2. Remove the alarm data from the Hive store
    await AlarmStore.remove(id);

    // 3. Refresh the UI list
    if (mounted) {
       await _loadAlarms();
       setState(() { _isLoading = false; }); // Hide loading
        // Show confirmation message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alarm berhasil dihapus.'), backgroundColor: Colors.green),
        );
    }
  }

  /// Navigates to the Add/Edit screen to modify an existing alarm.
  Future<void> _editAlarm(int alarmId) async {
    // Navigate and await result (true if saved)
    final result = await Navigator.push<bool>( // Specify return type
      context,
      MaterialPageRoute(builder: (context) => AddEditAlarmScreen(alarmId: alarmId)),
    );
    // Reload list only if the edit screen returned true (indicating a save)
    if (result == true && mounted) {
      print("AlarmScreen: Reloading alarms after successful edit.");
      _loadAlarms();
    } else {
       print("AlarmScreen: Edit screen closed without saving (result: $result).");
    }
  }

  /// Navigates to the Add/Edit screen to create a new alarm.
  Future<void> _addAlarm() async {
    // Navigate and await result (true if saved)
    final result = await Navigator.push<bool>( // Specify return type
      context,
      MaterialPageRoute(builder: (context) => const AddEditAlarmScreen()), // Pass null ID
    );
     // Reload list only if the add screen returned true (indicating a save)
    if (result == true && mounted) {
       print("AlarmScreen: Reloading alarms after successful add.");
       _loadAlarms();
    } else {
        print("AlarmScreen: Add screen closed without saving (result: $result).");
    }
  }

  // --- Helper Functions ---

  /// Calculates the next trigger DateTime based on the TimeOfDay.
  DateTime _calculateNextTrigger(TimeOfDay time) {
    final now = DateTime.now();
    DateTime next = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    if (next.isBefore(now)) {
      next = next.add(const Duration(days: 1));
    }
    return next;
  }

  // --- Build Method ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Alarm'),
        automaticallyImplyLeading: false,
        actions: [
             // Button to explicitly re-check permissions
             IconButton(
               icon: const Icon(Icons.shield_outlined),
               tooltip: 'Periksa Ulang Izin Sistem',
               onPressed: _checkAllPermissions, // Re-run the permission check flow
             ),
             // Button to manually reload the alarm list
             IconButton(
               icon: const Icon(Icons.refresh),
               tooltip: 'Muat Ulang Daftar Alarm',
               onPressed: _loadAlarms, // Just reload alarms without permission check
             )
        ]
      ),
      // Body content depends on loading state and alarm list content
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // Show loading indicator
          : _alarms.isEmpty
             ? Center( // Show message if list is empty
                 child: Padding(
                   padding: const EdgeInsets.all(20.0),
                   child: Text(
                     // Provide slightly different messages based on whether permissions were checked
                     !_permissionsChecked
                        ? 'Memeriksa izin...\nPastikan izin notifikasi dan alarm diberikan.'
                        : 'Belum ada alarm yang ditambahkan.\nTekan tombol + untuk membuat alarm baru.',
                     textAlign: TextAlign.center,
                     style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                 )
               )
             : ListView.builder( // Display the list if not loading and not empty
                 padding: const EdgeInsets.fromLTRB(16, 16, 16, 80), // Padding for list
                 itemCount: _alarms.length, // Number of alarms
                 itemBuilder: (context, index) {
                   // Get alarm data for the current list item
                   final alarm = _alarms[index];
                   final time = TimeOfDay(hour: alarm.hour, minute: alarm.minute);
                   // Calculate next trigger time for display purposes
                   final nextTrigger = _calculateNextTrigger(time);

                   // Build a Card for each alarm
                   return Card(
                     margin: const EdgeInsets.only(bottom: 12.0),
                     elevation: alarm.enabled ? 3 : 1, // More elevation for active alarms
                     color: alarm.enabled ? Colors.white : Colors.grey[200], // Grey out disabled alarms
                     child: ListTile(
                       contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                       // --- Toggle Switch ---
                       leading: Switch(
                            value: alarm.enabled, // Reflects stored enabled state
                            onChanged: (value) => _toggleAlarm(alarm, value), // Toggle action
                            activeColor: Theme.of(context).primaryColor, // Use theme color
                       ),
                       // --- Alarm Title & Time Info ---
                       title: Text(
                         alarm.title,
                         style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            // Style differently based on enabled state
                            color: alarm.enabled ? Colors.black87 : Colors.grey[600],
                            decoration: alarm.enabled ? TextDecoration.none : TextDecoration.lineThrough,
                          )
                       ),
                       subtitle: Text(
                         // Display time, repeat status, and next trigger time
                         'Pukul ${time.format(context)} ${alarm.repeatEveryday ? "• Setiap Hari" : ""}\nBerikutnya: ${DateFormat('EEE, d MMM HH:mm', 'id_ID').format(nextTrigger)}',
                         style: TextStyle(color: alarm.enabled ? Colors.grey[700] : Colors.grey[500])
                       ),
                       isThreeLine: true, // Allow space for the two lines of subtitle
                       // --- Action Buttons ---
                       trailing: Row(
                         mainAxisSize: MainAxisSize.min, // Keep buttons compact
                         children: [
                           // Play Sound Button
                           IconButton(
                             tooltip: 'Putar Suara Alarm',
                             icon: Icon(
                                 Icons.volume_up_outlined,
                                 color: alarm.enabled ? Theme.of(context).primaryColor : Colors.grey,
                                 size: 24, // Slightly larger icon
                            ),
                             onPressed: () => _playSound(alarm.soundAssetPath), // Pass the full path
                           ),
                           // Edit Button
                           IconButton(
                             tooltip: 'Edit Alarm',
                             icon: Icon(
                                 Icons.edit_outlined,
                                 color: alarm.enabled ? Colors.blueGrey[700] : Colors.grey,
                                 size: 24,
                            ),
                             onPressed: () => _editAlarm(alarm.id), // Pass alarm ID
                           ),
                           // Delete Button
                           IconButton(
                             tooltip: 'Hapus Alarm',
                             icon: Icon(
                                 Icons.delete_outline,
                                 color: Colors.red[700],
                                 size: 24,
                            ),
                             onPressed: () => _deleteAlarm(alarm.id), // Pass alarm ID
                           ),
                         ],
                       ),
                       // Optional: Allow tapping the whole ListTile to edit
                       // onTap: () => _editAlarm(alarm.id),
                     ),
                   );
                 },
               ),
      // --- Floating Action Button ---
      floatingActionButton: FloatingActionButton(
        onPressed: _addAlarm, // Action to add a new alarm
        backgroundColor: Theme.of(context).primaryColor, // Use theme color
        foregroundColor: Colors.white, // White icon
        tooltip: 'Tambah Alarm Baru',
        child: const Icon(Icons.add_alarm), // More specific icon
      ),
    );
  }
}