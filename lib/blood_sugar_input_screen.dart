import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:portable_health_kit/services/firestore_service.dart';

class BloodSugarInputScreen extends StatefulWidget {
  // NEW: Add patientId and patientName
  final String patientId;
  final String patientName;

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

  @override
  void dispose() {
    _bloodSugarController.dispose();
    super.dispose();
  }

  Future<void> _saveData() async {
    if (_bloodSugarController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mohon isi nilai gula darah.'), backgroundColor: Colors.red));
      return;
    }
    
    // final currentUserId = _sessionService.currentUserId; // No longer needed
    
    setState(() { _isLoading = true; });

    final readingData = {
      'SystolicValue': null,
      'DiastolicValue': null,
      'BloodSugarValue': int.tryParse(_bloodSugarController.text) ?? 0,
      'Timestamp': Timestamp.now(),
    };

    try {
      // NEW: Use the new service function with the patientId
      await _firestoreService.addHealthReadingToPatient(widget.patientId, readingData);

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data gula darah berhasil disimpan!'), backgroundColor: Colors.green));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan data: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // NEW: Show which patient we are inputting for
      appBar: AppBar(title: Text('Input GD for ${widget.patientName}')),
      body: SingleChildScrollView(
        // ... (Rest of build method is unchanged) ...
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Gula Darah Sewaktu (mg/dL)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(controller: _bloodSugarController, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'e.g., 95', prefixIcon: Icon(Icons.bloodtype_outlined))),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveData,
              child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Simpan Data'),
            ),
          ],
        ),
      ),
    );
  }
}