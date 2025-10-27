import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:portable_health_kit/services/firestore_service.dart';

class CholesterolInputScreen extends StatefulWidget {
  final String patientId;
  final String patientName;

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

  @override
  void dispose() {
    _cholesterolController.dispose();
    super.dispose();
  }

  Future<void> _saveData() async {
    // Validate input
    if (_cholesterolController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Mohon isi nilai kolesterol.'),
          backgroundColor: Colors.red));
      return;
    }
    // Cholesterol is usually an integer
    final int? cholesterolValue = int.tryParse(_cholesterolController.text);
    if (cholesterolValue == null || cholesterolValue < 0) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Mohon masukkan angka kolesterol yang valid.'),
          backgroundColor: Colors.red));
      return;
    }

    setState(() { _isLoading = true; });

    // Prepare data map, setting other values to null
    final readingData = {
      'SystolicValue': null,
      'DiastolicValue': null,
      'BloodSugarValue': null,
      'UricAcidValue': null,
      'CholesterolValue': cholesterolValue, // Add the new value
      'WaistCircumferenceValue': null,
      'Timestamp': Timestamp.now(),
    };

    try {
      // Save to Firestore using the patient ID
      await _firestoreService.addHealthReadingToPatient(widget.patientId, readingData);

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Data kolesterol berhasil disimpan!'),
          backgroundColor: Colors.green));
      if (mounted) Navigator.of(context).pop(); // Go back after saving
    } catch (e) {
      print("Error saving Cholesterol: $e"); // Log the error
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal menyimpan data: $e'),
          backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() { _isLoading = false; });
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
            const Text(
              'Kolesterol Total (mg/dL)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)
            ),
            const SizedBox(height: 8),
            // Input field for Cholesterol
            TextFormField(
              controller: _cholesterolController,
              keyboardType: TextInputType.number, // No decimals typically
              decoration: const InputDecoration(
                hintText: 'e.g., 180',
                prefixIcon: Icon(Icons.opacity_outlined), // Example icon
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Mohon isi nilai kolesterol';
                }
                if (int.tryParse(value) == null) {
                  return 'Masukkan angka bulat yang valid';
                }
                 if (int.parse(value) < 0) {
                  return 'Nilai tidak boleh negatif';
                }
                return null;
              },
            ),
            const SizedBox(height: 40),
            // Save button
            ElevatedButton(
              onPressed: _isLoading ? null : _saveData,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Simpan Data'),
            ),
          ],
        ),
      ),
    );
  }
}