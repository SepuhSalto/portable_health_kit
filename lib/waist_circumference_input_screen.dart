import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:portable_health_kit/services/firestore_service.dart';

class WaistCircumferenceInputScreen extends StatefulWidget {
  final String patientId;
  final String patientName;

  const WaistCircumferenceInputScreen({
    super.key,
    required this.patientId,
    required this.patientName
  });

  @override
  State<WaistCircumferenceInputScreen> createState() => _WaistCircumferenceInputScreenState();
}

class _WaistCircumferenceInputScreenState extends State<WaistCircumferenceInputScreen> {
  final _firestoreService = FirestoreService();
  final _waistController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _waistController.dispose();
    super.dispose();
  }

  Future<void> _saveData() async {
    // Validate input
    if (_waistController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Mohon isi nilai lingkar perut.'),
          backgroundColor: Colors.red));
      return;
    }
    final double? waistValue = double.tryParse(_waistController.text);
    if (waistValue == null || waistValue <= 0) { // Should be positive
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Mohon masukkan angka lingkar perut yang valid (lebih dari 0).'),
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
      'CholesterolValue': null,
      'WaistCircumferenceValue': waistValue, // Add the new value
      'Timestamp': Timestamp.now(),
    };

    try {
      // Save to Firestore using the patient ID
      await _firestoreService.addHealthReadingToPatient(widget.patientId, readingData);

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Data lingkar perut berhasil disimpan!'),
          backgroundColor: Colors.green));
      if (mounted) Navigator.of(context).pop(); // Go back after saving
    } catch (e) {
      print("Error saving Waist Circumference: $e"); // Log the error
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
      appBar: AppBar(title: Text('Input Lingkar Perut: ${widget.patientName}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Lingkar Perut (cm)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)
            ),
            const SizedBox(height: 8),
            // Input field for Waist Circumference
            TextFormField(
              controller: _waistController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true), // Allow decimals
              decoration: const InputDecoration(
                hintText: 'e.g., 85.5',
                prefixIcon: Icon(Icons.square_foot_outlined), // Example icon
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Mohon isi nilai lingkar perut';
                }
                if (double.tryParse(value) == null) {
                  return 'Masukkan angka yang valid';
                }
                 if (double.parse(value) <= 0) { // Check if positive
                  return 'Nilai harus lebih dari 0';
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