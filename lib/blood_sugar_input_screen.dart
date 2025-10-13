import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:portable_health_kit/services/firestore_service.dart';
import 'package:portable_health_kit/services/user_session_service.dart';

class BloodSugarInputScreen extends StatefulWidget {
  const BloodSugarInputScreen({super.key});
  @override
  State<BloodSugarInputScreen> createState() => _BloodSugarInputScreenState();
}

class _BloodSugarInputScreenState extends State<BloodSugarInputScreen> {
  final _firestoreService = FirestoreService();
  final _sessionService = UserSessionService();
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
    final currentUserId = _sessionService.currentUserId;
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak ada pengguna aktif.'), backgroundColor: Colors.red));
      return;
    }
    setState(() { _isLoading = true; });

    final readingData = {
      // These two lines are the crucial fix
      'SystolicValue': null,
      'DiastolicValue': null,
      'BloodSugarValue': int.tryParse(_bloodSugarController.text) ?? 0,
      'Timestamp': Timestamp.now(),
    };

    try {
      await _firestoreService.addHealthReading(currentUserId, readingData);
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
      appBar: AppBar(title: const Text('Input Gula Darah')),
      body: SingleChildScrollView(
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