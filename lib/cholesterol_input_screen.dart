import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:portable_health_kit/services/firestore_service.dart';
import 'package:audioplayers/audioplayers.dart'; // Import audioplayers

class CholesterolInputScreen extends StatefulWidget {
  final String patientId;
  final String patientName;
  // No gender needed for total cholesterol check based on image

  const CholesterolInputScreen({
    super.key,
    required this.patientId,
    required this.patientName
  });

  @override
  State<CholesterolInputScreen> createState() => _CholesterolInputScreenState();
}

class _CholesterolInputScreenState extends State<CholesterolInputScreen> {
  final _firestoreService = FirestoreService();
  final _cholesterolController = TextEditingController();
  bool _isLoading = false;
  // Audio player instance for this screen
  late AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    // Initialize the player
    _audioPlayer = AudioPlayer();
  }

  @override
  void dispose() {
    _cholesterolController.dispose();
    // Release player resources
    _audioPlayer.dispose();
    print("CholesterolInputScreen: AudioPlayer disposed.");
    super.dispose();
  }

  // --- Category Check Logic ---
   String _getCholesterolCategory(int value) {
       if (value <= 0) return 'N/A';
       // Range based on image_bb3438.jpg (Total Cholesterol)
       if (value >= 200) return 'Tinggi';
       return 'Normal'; // (< 200)
     }
  // --- End Category Check ---

  /// Plays a sound from the assets/sounds folder.
  Future<void> _playSound(String soundAssetFileName) async {
    final String relativePath = 'sounds/$soundAssetFileName';
    try {
      print("Attempting to play sound: $relativePath");
      await _audioPlayer.stop();
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
    if (_cholesterolController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mohon isi nilai kolesterol.'), backgroundColor: Colors.red));
      return;
    }
    final int? cholesterolValue = int.tryParse(_cholesterolController.text);
    // Check if parsing failed or value is negative
    if (cholesterolValue == null || cholesterolValue < 0) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mohon masukkan angka kolesterol yang valid (>= 0).'), backgroundColor: Colors.red));
      return;
    }
    // --- End Validation ---

    setState(() { _isLoading = true; }); // Show loading

    // Prepare data map
    final readingData = {
      'SystolicValue': null,
      'DiastolicValue': null,
      'BloodSugarValue': null,
      'UricAcidValue': null,
      'CholesterolValue': cholesterolValue, // The value being saved
      'WaistCircumferenceValue': null,
      'Timestamp': Timestamp.now(),
    };

    String? soundToPlay; // Sound to play after saving

    try {
      // 1. Save data
      await _firestoreService.addHealthReadingToPatient(widget.patientId, readingData);
      print("Cholesterol data saved successfully.");

      // 2. Check category
      final category = _getCholesterolCategory(cholesterolValue);
      print("Saved Cholesterol: $cholesterolValue, Category: $category");

      // 3. Determine sound
      if (category != 'Normal' && category != 'N/A') {
          // *** REPLACE 'abnormal_kolesterol.mp3' with your actual filename ***
          soundToPlay = 'abnormal_kolesterol.wav';
      } else if (category == 'Normal') {
           // *** REPLACE 'normal_reading.mp3' with your actual filename ***
           soundToPlay = 'normal_reading.wav';
      }

      // 4. Show success message
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data kolesterol berhasil disimpan!'), backgroundColor: Colors.green));

      // 5. Play sound and delay pop
      if (soundToPlay != null) {
          await _playSound(soundToPlay);
          // Wait a bit before closing
          await Future.delayed(const Duration(seconds: 2));
      } else {
          // Shorter delay if no sound
          await Future.delayed(const Duration(milliseconds: 500));
      }

      // 6. Close screen
      if (mounted) {
          Navigator.of(context).pop();
      }

    } catch (e) {
      print("Error saving Cholesterol or playing sound: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan data: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() { _isLoading = false; }); // Hide loading
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Input Kolesterol: ${widget.patientName}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Input Field ---
            const Text('Kolesterol Total (mg/dL)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _cholesterolController,
              keyboardType: TextInputType.number, // Integer input
              decoration: const InputDecoration(
                 hintText: 'e.g., 180',
                 prefixIcon: Icon(Icons.opacity_outlined), // Example icon
              ),
              // Validator for non-negative integer
              validator: (v) => (v == null || v.isEmpty || int.tryParse(v) == null || int.parse(v) < 0) ? 'Masukkan angka >= 0' : null,
            ),
            const SizedBox(height: 40),

            // --- Save Button ---
            ElevatedButton(
              onPressed: _isLoading ? null : _saveData, // Disable while loading
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Simpan Data'),
            ),
          ],
        ),
      ),
    );
  }
}