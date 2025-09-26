import 'package:flutter/material.dart';

class BloodPressureInputScreen extends StatefulWidget {
  const BloodPressureInputScreen({super.key});

  @override
  State<BloodPressureInputScreen> createState() => _BloodPressureInputScreenState();
}

class _BloodPressureInputScreenState extends State<BloodPressureInputScreen> {
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();

  @override
  void dispose() {
    _systolicController.dispose();
    _diastolicController.dispose();
    super.dispose();
  }

  void _saveData() {
    final systolic = _systolicController.text;
    final diastolic = _diastolicController.text;
    print('Saving Blood Pressure: Systolic: $systolic, Diastolic: $diastolic');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Input Tekanan Darah'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Sistolik (mmHg)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _systolicController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'e.g., 120',
                prefixIcon: Icon(Icons.arrow_upward),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Diastolik (mmHg)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _diastolicController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'e.g., 80',
                prefixIcon: Icon(Icons.arrow_downward),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _saveData,
              child: const Text('Simpan Data'),
            )
          ],
        ),
      ),
    );
  }
}