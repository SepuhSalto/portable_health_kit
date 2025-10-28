import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:portable_health_kit/services/firestore_service.dart';
import 'package:audioplayers/audioplayers.dart'; // Import audioplayers

class BloodSugarInputScreen extends StatefulWidget {
  final String patientId;
  final String patientName;
  // No gender needed

  const BloodSugarInputScreen({
    super.key,
    required this.patientId,
    required this.patientName
  });

  @override
  State<BloodSugarInputScreen> createState() => _BloodSugarInputScreenState();
}

class _BloodSugarInputScreenState extends State<BloodSugarInputScreen> {
  final _firestoreService = FirestoreService();
  final _bloodSugarController = TextEditingController();
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
    _bloodSugarController.dispose();
    // Release player resources
    _audioPlayer.dispose();
    print("BloodSugarInputScreen: AudioPlayer disposed.");
    super.dispose();
  }

  // --- Category Check Logic ---
  String _getBloodSugarCategory(int sugar) {
     if (sugar <= 0) return 'N/A';
    // Assuming 'sewaktu' (random)
    if (sugar >= 200) return 'Diabetes';
    if (sugar >= 140) return 'Pradiabetes';
    if (sugar < 70) return 'Hipoglikemia';
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
    if (_bloodSugarController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mohon isi nilai gula darah.'), backgroundColor: Colors.red));
      return;
    }
    final int? bloodSugarValue = int.tryParse(_bloodSugarController.text);
     // Check if parsing failed or value is negative (allow 0 if medically valid)
     if (bloodSugarValue == null || bloodSugarValue < 0) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mohon masukkan angka gula darah yang valid (>= 0).'), backgroundColor: Colors.red));
       return;
    }
    // --- End Validation ---

    setState(() { _isLoading = true; }); // Show loading

    // Prepare data map
    final readingData = {
      'SystolicValue': null,
      'DiastolicValue': null,
      'BloodSugarValue': bloodSugarValue, // The value being saved
      'UricAcidValue': null,
      'CholesterolValue': null,
      'WaistCircumferenceValue': null,
      'Timestamp': Timestamp.now(),
    };

    String? soundToPlay; // Sound to play after saving

    try {
      // 1. Save data
      await _firestoreService.addHealthReadingToPatient(widget.patientId, readingData);
      print("Blood Sugar data saved successfully.");

      // 2. Check category
      final category = _getBloodSugarCategory(bloodSugarValue);
      print("Saved BS: $bloodSugarValue, Category: $category");

      // 3. Determine sound
      if (category != 'Normal' && category != 'N/A') {
          // *** REPLACE 'abnormal_gula_darah.mp3' with your actual filename ***
          soundToPlay = 'abnormal_gula_darah.wav';
      } else if (category == 'Normal') {
           // *** REPLACE 'normal_reading.mp3' with your actual filename ***
           soundToPlay = 'normal_reading.wav';
      }

      // 4. Show success message
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data gula darah berhasil disimpan!'), backgroundColor: Colors.green));

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
      print("Error saving BS or playing sound: $e");
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
      appBar: AppBar(title: Text('Input Gula Darah: ${widget.patientName}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Input Field ---
            const Text('Gula Darah Sewaktu (mg/dL)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
                controller: _bloodSugarController,
                keyboardType: TextInputType.number, // Number keyboard
                decoration: const InputDecoration(
                    hintText: 'e.g., 110',
                    prefixIcon: Icon(Icons.bloodtype_outlined)
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