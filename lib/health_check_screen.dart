import 'package:flutter/material.dart';
import 'package:portable_health_kit/patient_selection_screen.dart'; // NEW
import 'package:portable_health_kit/personal_data_input_screen.dart';
import 'package:portable_health_kit/blood_pressure_input_screen.dart';
import 'package:portable_health_kit/blood_sugar_input_screen.dart';

class HealthCheckScreen extends StatelessWidget {
  const HealthCheckScreen({super.key});

  // Helper function to navigate to Patient Selection
  Future<void> _selectPatientAndNavigate(BuildContext context, PatientAction action) async {
    
    // First, go to the selection screen and wait for a result
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PatientSelectionScreen(action: action),
      ),
    );

    // If the user selected a patient (result is not null)
    if (result != null && result is Map<String, dynamic>) {
      final String patientId = result['id'];
      final String patientName = result['name'];

      // Now, navigate to the correct input screen
      if (action == PatientAction.inputBloodPressure) {
        Navigator.push(context, MaterialPageRoute(builder: (context) => BloodPressureInputScreen(patientId: patientId, patientName: patientName)));
      } else if (action == PatientAction.inputBloodSugar) {
        Navigator.push(context, MaterialPageRoute(builder: (context) => BloodSugarInputScreen(patientId: patientId, patientName: patientName)));
      }
      // You can add more actions here, like PatientAction.viewHistory
    }
  }

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
                icon: Icons.person_add_alt_1, // NEW Icon
                // CHANGED Label
                label: 'Register Pasien Baru', 
                onPressed: () {
                  // This now goes to the input screen in "create patient" mode
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const PersonalDataInputScreen()));
                },
              ),
              const SizedBox(height: 20),
              _buildMenuButton(
                context,
                icon: Icons.monitor_heart_outlined,
                label: 'Input Tekanan Darah',
                onPressed: () {
                  // NEW logic
                  _selectPatientAndNavigate(context, PatientAction.inputBloodPressure);
                },
              ),
              const SizedBox(height: 20),
              _buildMenuButton(
                context,
                icon: Icons.bloodtype_outlined,
                label: 'Input Gula Darah',
                onPressed: () {
                   // NEW logic
                   _selectPatientAndNavigate(context, PatientAction.inputBloodSugar);
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