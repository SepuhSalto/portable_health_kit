import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:portable_health_kit/services/firestore_service.dart';
import 'package:audioplayers/audioplayers.dart'; // Import audioplayers

class UricAcidInputScreen extends StatefulWidget {
  final String patientId;
  final String patientName;
  final String patientGender;

  const UricAcidInputScreen({
    super.key,
    required this.patientId,
    required this.patientName,
    required this.patientGender,
  });

  @override
  State<UricAcidInputScreen> createState() => _UricAcidInputScreenState();
}

class _UricAcidInputScreenState extends State<UricAcidInputScreen> {
  final _firestoreService = FirestoreService();
  final _uricAcidController = TextEditingController();
  bool _isLoading = false;
  // Keep a single player instance for the screen
  late AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    // Initialize the player in initState
    _audioPlayer = AudioPlayer();
    // Optional: Configure player settings if needed (e.g., release mode)
    // _audioPlayer.setReleaseMode(ReleaseMode.stop);
  }


  @override
  void dispose() {
    _uricAcidController.dispose();
    // Release player resources when screen is disposed
    _audioPlayer.dispose();
    print("UricAcidInputScreen: AudioPlayer disposed.");
    super.dispose();
  }

  // --- Category Check Logic ---
  String _getUricAcidCategory(double value, String gender) {
      if (value <= 0) return 'N/A';
      if (gender == 'Laki-laki') {
          if (value > 7.0) return 'Tinggi';
          if (value < 2.5) return 'Rendah';
      } else { // Assume Perempuan
          if (value > 6.0) return 'Tinggi';
          if (value < 1.5) return 'Rendah';
      }
      return 'Normal';
  }
  // --- End Category Check ---

  /// Plays a sound from the assets folder.
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
    if (_uricAcidController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mohon isi nilai asam urat.'), backgroundColor: Colors.red));
      return;
    }
    final double? uricAcidValue = double.tryParse(_uricAcidController.text);
    if (uricAcidValue == null || uricAcidValue < 0) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mohon masukkan angka asam urat yang valid.'), backgroundColor: Colors.red));
      return;
    }
    // --- End Validation ---

    setState(() { _isLoading = true; });

    final readingData = {
      'SystolicValue': null,
      'DiastolicValue': null,
      'BloodSugarValue': null,
      'UricAcidValue': uricAcidValue,
      'CholesterolValue': null,
      'WaistCircumferenceValue': null,
      'Timestamp': Timestamp.now(),
    };

    String? soundToPlay; // Variable to hold which sound to play

    try {
      // Save data first
      await _firestoreService.addHealthReadingToPatient(widget.patientId, readingData);
      print("Uric Acid data saved successfully.");

      // --- Check Category ---
      final category = _getUricAcidCategory(uricAcidValue, widget.patientGender);
      print("Saved Uric Acid: $uricAcidValue, Gender: ${widget.patientGender}, Category: $category");

      // --- Determine Sound ---
      if (category != 'Normal' && category != 'N/A') {
          // *** REPLACE 'abnormal_asam_urat.mp3' with your actual filename ***
          soundToPlay = 'abnormal_asam_urat.wav';
      } else if (category == 'Normal') {
           // *** REPLACE 'normal_reading.mp3' with your actual filename for normal readings ***
           soundToPlay = 'normal_reading.wav';
      }
      // --- End Sound Determination ---

      // Show success message (do this before playing sound/delaying pop)
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data asam urat berhasil disimpan!'), backgroundColor: Colors.green));

      // --- Play Sound (if determined) ---
      if (soundToPlay != null) {
          await _playSound(soundToPlay);
          // *** ADD DELAY: Wait for sound to play for a bit before popping ***
          // Adjust duration as needed (e.g., 2 seconds)
          await Future.delayed(const Duration(seconds: 6));
      } else {
          // If no sound needs to play, add a shorter delay before popping
          await Future.delayed(const Duration(milliseconds: 500));
      }
      // --- End Play Sound ---

      // --- Pop Screen ---
      if (mounted) {
           Navigator.of(context).pop();
      }
      // --- End Pop Screen ---

    } catch (e) {
      print("Error saving Uric Acid or playing sound: $e");
      if (mounted) { // Show error only if saving failed
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan data: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Input Asam Urat: ${widget.patientName}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Asam Urat (mg/dL)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _uricAcidController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration( hintText: 'e.g., 5.5', prefixIcon: Icon(Icons.science_outlined), ),
              validator: (v) => (v == null || v.isEmpty || double.tryParse(v) == null || double.parse(v) < 0) ? 'Nilai >= 0' : null,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveData,
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