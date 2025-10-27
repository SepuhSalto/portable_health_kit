import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:portable_health_kit/services/firestore_service.dart';

class UricAcidInputScreen extends StatefulWidget {
  final String patientId;
  final String patientName;

  const UricAcidInputScreen({
    super.key,
    required this.patientId,
    required this.patientName
  });

  @override
  State<UricAcidInputScreen> createState() => _UricAcidInputScreenState();
}

class _UricAcidInputScreenState extends State<UricAcidInputScreen> {
  final _firestoreService = FirestoreService();
  final _uricAcidController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _uricAcidController.dispose();
    super.dispose();
  }

  Future<void> _saveData() async {
    // Validate input
    if (_uricAcidController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Mohon isi nilai asam urat.'),
          backgroundColor: Colors.red));
      return;
    }
    final double? uricAcidValue = double.tryParse(_uricAcidController.text);
    if (uricAcidValue == null || uricAcidValue < 0) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Mohon masukkan angka asam urat yang valid.'),
          backgroundColor: Colors.red));
      return;
    }

    setState(() { _isLoading = true; });

    // Prepare data map, setting other values to null
    final readingData = {
      'SystolicValue': null,
      'DiastolicValue': null,
      'BloodSugarValue': null,
      'UricAcidValue': uricAcidValue, // Add the new value
      'CholesterolValue': null,
      'WaistCircumferenceValue': null,
      'Timestamp': Timestamp.now(),
    };

    try {
      // Save to Firestore using the patient ID
      await _firestoreService.addHealthReadingToPatient(widget.patientId, readingData);

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Data asam urat berhasil disimpan!'),
          backgroundColor: Colors.green));
      if (mounted) Navigator.of(context).pop(); // Go back after saving
    } catch (e) {
      print("Error saving Uric Acid: $e"); // Log the error
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal menyimpan data: $e'),
          backgroundColor: Colors.red));
    } finally {
      // Ensure loading indicator is turned off even if an error occurs
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
            const Text(
              'Asam Urat (mg/dL)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)
            ),
            const SizedBox(height: 8),
            // Input field for Uric Acid
            TextFormField(
              controller: _uricAcidController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true), // Allow decimals
              decoration: const InputDecoration(
                hintText: 'e.g., 5.5',
                prefixIcon: Icon(Icons.science_outlined), // Example icon
              ),
              validator: (value) { // Basic validation
                if (value == null || value.isEmpty) {
                  return 'Mohon isi nilai asam urat';
                }
                if (double.tryParse(value) == null) {
                  return 'Masukkan angka yang valid';
                }
                 if (double.parse(value) < 0) {
                  return 'Nilai tidak boleh negatif';
                }
                return null;
              },
            ),
            const SizedBox(height: 40),
            // Save button
            ElevatedButton(
              onPressed: _isLoading ? null : _saveData, // Disable button while loading
              child: _isLoading
                  ? const SizedBox( // Show loading indicator
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