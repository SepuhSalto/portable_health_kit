import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:portable_health_kit/services/firestore_service.dart';

class BloodPressureInputScreen extends StatefulWidget {
  // NEW: Add patientId and patientName
  final String patientId;
  final String patientName;

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

  @override
  void dispose() {
    _systolicController.dispose();
    _diastolicController.dispose();
    super.dispose();
  }

  Future<void> _saveData() async {
    if (_systolicController.text.isEmpty || _diastolicController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mohon isi nilai sistolik dan diastolik.'), backgroundColor: Colors.red));
      return;
    }
    
    // We no longer need the health worker's ID here
    // final currentUserId = _sessionService.currentUserId;

    setState(() { _isLoading = true; });

    final readingData = {
      'SystolicValue': int.tryParse(_systolicController.text) ?? 0,
      'DiastolicValue': int.tryParse(_diastolicController.text) ?? 0,
      'BloodSugarValue': null,
      'Timestamp': Timestamp.now(),
    };

    try {
      // NEW: Use the new service function with the patientId
      await _firestoreService.addHealthReadingToPatient(widget.patientId, readingData);

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data tekanan darah berhasil disimpan!'), backgroundColor: Colors.green));
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
      appBar: AppBar(title: Text('Input TD for ${widget.patientName}')),
      body: SingleChildScrollView(
        // ... (Rest of build method is unchanged) ...
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Sistolic (mmHg)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(controller: _systolicController, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'e.g., 120', prefixIcon: Icon(Icons.arrow_upward))),
            const SizedBox(height: 20),
            const Text('Diastolic (mmHg)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(controller: _diastolicController, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'e.g., 80', prefixIcon: Icon(Icons.arrow_downward))),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveData,
              child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Simpan Data'),
            )
          ],
        ),
      ),
    );
  }
}