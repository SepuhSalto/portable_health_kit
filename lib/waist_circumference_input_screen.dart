import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:portable_health_kit/services/firestore_service.dart';
import 'package:audioplayers/audioplayers.dart'; // Import audioplayers

class WaistCircumferenceInputScreen extends StatefulWidget {
  final String patientId;
  final String patientName;
  final String patientGender; // Add gender

  const WaistCircumferenceInputScreen({
    super.key,
    required this.patientId,
    required this.patientName,
    required this.patientGender, // Require gender
  });

  @override
  State<WaistCircumferenceInputScreen> createState() => _WaistCircumferenceInputScreenState();
}

class _WaistCircumferenceInputScreenState extends State<WaistCircumferenceInputScreen> {
  final _firestoreService = FirestoreService();
  final _waistController = TextEditingController();
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
    _waistController.dispose();
    // Release player resources
    _audioPlayer.dispose();
    print("WaistCircumferenceInputScreen: AudioPlayer disposed.");
    super.dispose();
  }

  // --- Category Check Logic ---
   String _getWaistCategory(double value, String gender) {
       if (value <= 0) return 'N/A';
        // Ranges based on image_bb3438.jpg
       if (gender == 'Laki-laki') {
         if (value > 101.6) return 'Berlebih';
       } else { // Assume Perempuan
         if (value > 88.9) return 'Berlebih';
       }
       return 'Normal';
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
    if (_waistController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mohon isi nilai lingkar perut.'), backgroundColor: Colors.red));
      return;
    }
    final double? waistValue = double.tryParse(_waistController.text);
    // Check if parsing failed or value is not positive
    if (waistValue == null || waistValue <= 0) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mohon masukkan angka lingkar perut yang valid (lebih dari 0).'), backgroundColor: Colors.red));
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
      'CholesterolValue': null,
      'WaistCircumferenceValue': waistValue, // The value being saved
      'Timestamp': Timestamp.now(),
    };

    String? soundToPlay; // Sound to play after saving

    try {
      // 1. Save data
      await _firestoreService.addHealthReadingToPatient(widget.patientId, readingData);
      print("Waist Circumference data saved successfully.");

      // 2. Check category using passed gender
      final category = _getWaistCategory(waistValue, widget.patientGender);
      print("Saved Waist: $waistValue, Gender: ${widget.patientGender}, Category: $category");

      // 3. Determine sound
      if (category != 'Normal' && category != 'N/A') {
          // *** REPLACE 'abnormal_lingkar_perut.mp3' with your actual filename ***
          soundToPlay = 'abnormal_lingkar_perut.wav';
      } else if (category == 'Normal') {
           // *** REPLACE 'normal_reading.mp3' with your actual filename ***
           soundToPlay = 'normal_reading.wav';
      }

      // 4. Show success message
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data lingkar perut berhasil disimpan!'), backgroundColor: Colors.green));

      // 5. Play sound and delay pop
      if (soundToPlay != null) {
          await _playSound(soundToPlay);
          // Wait a bit before closing
          await Future.delayed(const Duration(seconds: 6));
      } else {
          // Shorter delay if no sound
          await Future.delayed(const Duration(milliseconds: 500));
      }

      // 6. Close screen
      if (mounted) {
          Navigator.of(context).pop();
      }

    } catch (e) {
      print("Error saving Waist Circumference or playing sound: $e");
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
      appBar: AppBar(title: Text('Input Lingkar Perut: ${widget.patientName}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Input Field ---
            const Text('Lingkar Perut (cm)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _waistController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true), // Allow decimals
              decoration: const InputDecoration(
                  hintText: 'e.g., 85.5',
                  prefixIcon: Icon(Icons.square_foot_outlined) // Example icon
              ),
              // Validator for positive number
              validator: (v) => (v == null || v.isEmpty || double.tryParse(v) == null || double.parse(v) <= 0) ? 'Masukkan angka > 0' : null,
            ),
            const SizedBox(height: 40),

            // --- Save Button ---
            ElevatedButton(
              onPressed: _isLoading ? null : _saveData, // Disable while loading
              child: _isLoading
                  ? const SizedBox( height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Simpan Data'),
            ),
          ],
        ),
      ),
    );
  }
}