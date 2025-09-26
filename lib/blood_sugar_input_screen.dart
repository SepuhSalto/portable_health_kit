import 'package:flutter/material.dart';

class BloodSugarInputScreen extends StatefulWidget {
  const BloodSugarInputScreen({super.key});

  @override
  State<BloodSugarInputScreen> createState() => _BloodSugarInputScreenState();
}

class _BloodSugarInputScreenState extends State<BloodSugarInputScreen> {
  final _bloodSugarController = TextEditingController();

  @override
  void dispose() {
    _bloodSugarController.dispose();
    super.dispose();
  }

  void _saveData() {
    final bloodSugar = _bloodSugarController.text;
    print('Saving Blood Sugar: $bloodSugar mg/dL');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Input Gula Darah'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Gula Darah Sewaktu (mg/dL)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _bloodSugarController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'e.g., 95',
                prefixIcon: Icon(Icons.bloodtype_outlined),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _saveData,
              child: const Text('Simpan Data'),
            ),
          ],
        ),
      ),
    );
  }
}