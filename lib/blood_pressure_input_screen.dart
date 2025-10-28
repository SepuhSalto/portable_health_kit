import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:portable_health_kit/services/firestore_service.dart';
import 'package:audioplayers/audioplayers.dart'; // Import audioplayers

class BloodPressureInputScreen extends StatefulWidget {
  final String patientId;
  final String patientName;
  // No gender needed for BP check based on image

  const BloodPressureInputScreen({
    super.key,
    required this.patientId,
    required this.patientName
  });

  @override
  State<BloodPressureInputScreen> createState() => _BloodPressureInputScreenState();
}

class _BloodPressureInputScreenState extends State<BloodPressureInputScreen> {
  final _firestoreService = FirestoreService();
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();
  bool _isLoading = false;
  // Audio player instance for this screen
  late AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    // Initialize the player
    _audioPlayer = AudioPlayer();
    // Optional: Configure player settings if needed
    // _audioPlayer.setReleaseMode(ReleaseMode.stop);
  }


  @override
  void dispose() {
    _systolicController.dispose();
    _diastolicController.dispose();
    // Release player resources when screen is disposed
    _audioPlayer.dispose();
    print("BloodPressureInputScreen: AudioPlayer disposed.");
    super.dispose();
  }

  // --- Category Check Logic (copied from history/home screen) ---
  String _getBloodPressureCategory(int systolic, int diastolic) {
    if (systolic <= 0 || diastolic <= 0) return 'N/A'; // Handle invalid input
    if (systolic >= 140 || diastolic >= 90) return 'Hipertensi Derajat 2';
    if (systolic >= 130 || diastolic >= 80) return 'Hipertensi Derajat 1';
    if (systolic >= 120) return 'Pra-hipertensi';
    if (systolic < 90 || diastolic < 60) return 'Hipotensi'; // Low BP
    return 'Normal';
  }
  // --- End Category Check ---

  /// Plays a sound from the assets/sounds folder.
  Future<void> _playSound(String soundAssetFileName) async {
    // Construct the path relative to assets/ for AssetSource
    final String relativePath = 'sounds/$soundAssetFileName';
    try {
      print("Attempting to play sound: $relativePath");
      await _audioPlayer.stop(); // Stop any previous sound
      await _audioPlayer.play(AssetSource(relativePath));
      print("Play command issued for $relativePath");
    } catch (e) {
      print("Error playing sound $relativePath: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memutar suara: $e'), backgroundColor: Colors.orange),
        );
      }
    }
  }


  Future<void> _saveData() async {
    // --- Validation ---
    if (_systolicController.text.isEmpty || _diastolicController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mohon isi nilai sistolik dan diastolik.'), backgroundColor: Colors.red));
      return;
    }
    final int? systolicValue = int.tryParse(_systolicController.text);
    final int? diastolicValue = int.tryParse(_diastolicController.text);

    // Ensure values are positive integers
    if (systolicValue == null || diastolicValue == null || systolicValue <= 0 || diastolicValue <= 0) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mohon masukkan angka tekanan darah yang valid (lebih dari 0).'), backgroundColor: Colors.red));
       return;
    }
    // --- End Validation ---


    setState(() { _isLoading = true; }); // Show loading indicator

    // Prepare data map for Firestore
    final readingData = {
      'SystolicValue': systolicValue,
      'DiastolicValue': diastolicValue,
      'BloodSugarValue': null, // Set other fields to null
      'UricAcidValue': null,
      'CholesterolValue': null,
      'WaistCircumferenceValue': null,
      'Timestamp': Timestamp.now(), // Record the time of saving
    };

    String? soundToPlay; // Variable to determine which sound to play

    try {
      // 1. Save data to Firestore
      await _firestoreService.addHealthReadingToPatient(widget.patientId, readingData);
      print("Blood Pressure data saved successfully.");

      // 2. Check if the reading is normal or abnormal
      final category = _getBloodPressureCategory(systolicValue, diastolicValue);
      print("Saved BP: $systolicValue/$diastolicValue, Category: $category");

      // 3. Determine which sound file to play
      if (category != 'Normal' && category != 'N/A') {
          // *** REPLACE 'abnormal_tensi.mp3' with your actual filename ***
          soundToPlay = 'abnormal_tensi.wav';
      } else if (category == 'Normal') {
           // *** REPLACE 'normal_reading.mp3' with your actual filename ***
           soundToPlay = 'normal_reading.wav';
      }
      // --- End Sound Determination ---

      // 4. Show success message to the user promptly
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data tekanan darah berhasil disimpan!'), backgroundColor: Colors.green));

      // 5. Play the determined sound (if any)
      if (soundToPlay != null) {
          await _playSound(soundToPlay);
          // *** ADD DELAY: Wait a bit for the sound to play before closing screen ***
          await Future.delayed(const Duration(seconds: 2)); // Adjust duration if needed
      } else {
          // If no sound, still wait briefly before closing
          await Future.delayed(const Duration(milliseconds: 500));
      }
      // --- End Play Sound ---

      // 6. Close the input screen
      if (mounted) {
           Navigator.of(context).pop();
       }
      // --- End Pop Screen ---

    } catch (e) {
      // Handle errors during saving or sound playback
      print("Error saving BP or playing sound: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan data: $e'), backgroundColor: Colors.red));
      }
    } finally {
      // Ensure loading indicator is hidden, even if errors occur
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Input Tekanan Darah: ${widget.patientName}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Systolic Input ---
            const Text('Sistolik (mmHg)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
                controller: _systolicController,
                keyboardType: TextInputType.number, // Use number keyboard
                decoration: const InputDecoration(
                    hintText: 'e.g., 120',
                    prefixIcon: Icon(Icons.arrow_upward)
                ),
                // Simple validator for positive integer
                validator: (v) => (v == null || v.isEmpty || int.tryParse(v) == null || int.parse(v) <= 0) ? 'Masukkan angka > 0' : null,
            ),
            const SizedBox(height: 20),

            // --- Diastolic Input ---
            const Text('Diastolik (mmHg)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
                controller: _diastolicController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    hintText: 'e.g., 80',
                    prefixIcon: Icon(Icons.arrow_downward)
                ),
                validator: (v) => (v == null || v.isEmpty || int.tryParse(v) == null || int.parse(v) <= 0) ? 'Masukkan angka > 0' : null,
            ),
            const SizedBox(height: 40),

            // --- Save Button ---
            ElevatedButton(
              // Disable button while loading state is true
              onPressed: _isLoading ? null : _saveData,
              child: _isLoading
                  // Show loading indicator inside button when loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  // Show button text when not loading
                  : const Text('Simpan Data'),
            )
          ],
        ),
      ),
    );
  }
}