import 'package:flutter/material.dart';
import 'personal_data_input_screen.dart'; // New import
import 'blood_pressure_input_screen.dart';
import 'blood_sugar_input_screen.dart';

class HealthCheckScreen extends StatelessWidget {
  const HealthCheckScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Input Data'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildMenuButton(
                context,
                icon: Icons.person_outline,
                label: 'Input Data Diri',
                onPressed: () {
                   Navigator.push(context, MaterialPageRoute(builder: (context) => const PersonalDataInputScreen()));
                },
              ),
              const SizedBox(height: 20),
              _buildMenuButton(
                context,
                icon: Icons.monitor_heart_outlined,
                label: 'Input Tekanan Darah',
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const BloodPressureInputScreen()));
                },
              ),
              const SizedBox(height: 20),
              _buildMenuButton(
                context,
                icon: Icons.bloodtype_outlined,
                label: 'Input Gula Darah',
                onPressed: () {
                   Navigator.push(context, MaterialPageRoute(builder: (context) => const BloodSugarInputScreen()));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context, {required IconData icon, required String label, required VoidCallback onPressed}) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 28),
      label: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 20),
      ),
    );
  }
}