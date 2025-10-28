import 'package:flutter/material.dart';
import 'package:portable_health_kit/patient_selection_screen.dart'; // Handles patient selection
import 'package:portable_health_kit/personal_data_input_screen.dart'; // Screen to register new patient
import 'package:portable_health_kit/blood_pressure_input_screen.dart'; // BP input screen
import 'package:portable_health_kit/blood_sugar_input_screen.dart'; // BS input screen
// --- IMPORT NEW SCREENS ---
import 'package:portable_health_kit/uric_acid_input_screen.dart'; // Uric acid input screen
import 'package:portable_health_kit/cholesterol_input_screen.dart'; // Cholesterol input screen
import 'package:portable_health_kit/waist_circumference_input_screen.dart'; // Waist input screen
import 'package:portable_health_kit/services/firestore_service.dart';

class HealthCheckScreen extends StatelessWidget {
  const HealthCheckScreen({super.key});

  /// Helper function to navigate first to Patient Selection,
  /// then to the appropriate input screen.
  ///
  /// Takes the build context, the action type, and a builder function
  /// that creates the target input screen widget.
  Future<void> _selectPatientAndNavigate(BuildContext context, PatientAction action, { required Widget Function(String patientId, String patientName, String patientGender) screenBuilder }) async {

    print("HealthCheckScreen: Initiating patient selection for action: $action");
    final FirestoreService firestoreService = FirestoreService(); // Instance for fetching gender

    print("HealthCheckScreen: Initiating patient selection for action: $action");
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PatientSelectionScreen(action: action)),
    );

    if (result != null && result is Map<String, dynamic> && context.mounted) {
      final String patientId = result['id'];
      final String patientName = result['name'];
      print("HealthCheckScreen: Patient selected - ID: $patientId, Name: $patientName. Fetching gender...");

      // Fetch patient data to get gender
      final patientData = await firestoreService.getPatientData(patientId);
      final String patientGender = patientData?['Gender'] as String? ?? "Laki-laki"; // Default if not found
      print("HealthCheckScreen: Gender fetched: $patientGender. Navigating to input screen.");


      // Navigate to the specific input screen, passing gender
      Navigator.push(context, MaterialPageRoute(
          builder: (context) => screenBuilder(patientId, patientName, patientGender) // Pass gender
      ));
    } else {
       print("HealthCheckScreen: Patient selection cancelled or failed.");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Input Data Kesehatan'), // More descriptive title
        automaticallyImplyLeading: false, // No back arrow on a main tab screen
      ),
      // Use SingleChildScrollView to prevent overflow on smaller screens
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            // Consistent padding around the column of buttons
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // Center buttons vertically if space allows
              crossAxisAlignment: CrossAxisAlignment.stretch, // Make buttons fill horizontal space
              children: [
                // --- Button to Register New Patient ---
                _buildMenuButton(
                  context,
                  icon: Icons.person_add_alt_1, // Specific icon for adding patient
                  label: 'Register Pasien Baru',
                  onPressed: () {
                    print("HealthCheckScreen: Navigating to PersonalDataInputScreen.");
                    // Navigate directly to the patient registration form
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const PersonalDataInputScreen()));
                  },
                ),
                const SizedBox(height: 20), // Spacing between buttons

                _buildMenuButton(
                  context, icon: Icons.monitor_heart_outlined, label: 'Input Tekanan Darah',
                  onPressed: () {
                    _selectPatientAndNavigate( context, PatientAction.inputBloodPressure,
                        // Pass a default/placeholder gender as BP doesn't use it
                        screenBuilder: (id, name, gender) => BloodPressureInputScreen(patientId: id, patientName: name)
                    );
                  },
                ),
                const SizedBox(height: 20),

                // BS Button (Pass placeholder gender - not needed)
                _buildMenuButton(
                   context, icon: Icons.bloodtype_outlined, label: 'Input Gula Darah',
                  onPressed: () {
                     _selectPatientAndNavigate( context, PatientAction.inputBloodSugar,
                         screenBuilder: (id, name, gender) => BloodSugarInputScreen(patientId: id, patientName: name)
                    );
                  },
                ),
                const SizedBox(height: 20),

                // UA Button (Pass gender)
                _buildMenuButton(
                  context, icon: Icons.science_outlined, label: 'Input Asam Urat',
                  onPressed: () {
                    _selectPatientAndNavigate( context, PatientAction.inputUricAcid,
                        // Pass the fetched gender
                        screenBuilder: (id, name, gender) => UricAcidInputScreen(patientId: id, patientName: name, patientGender: gender)
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Cholesterol Button (Pass placeholder gender - not needed)
                _buildMenuButton(
                  context, icon: Icons.opacity_outlined, label: 'Input Kolesterol',
                  onPressed: () {
                     _selectPatientAndNavigate( context, PatientAction.inputCholesterol,
                        screenBuilder: (id, name, gender) => CholesterolInputScreen(patientId: id, patientName: name)
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Waist Button (Pass gender)
                _buildMenuButton(
                  context, icon: Icons.square_foot_outlined, label: 'Input Lingkar Perut',
                  onPressed: () {
                     _selectPatientAndNavigate( context, PatientAction.inputWaist,
                        // Pass the fetched gender
                        screenBuilder: (id, name, gender) => WaistCircumferenceInputScreen(patientId: id, patientName: name, patientGender: gender)
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Reusable widget builder for the menu buttons.
  Widget _buildMenuButton(BuildContext context, {required IconData icon, required String label, required VoidCallback onPressed}) {
    return ElevatedButton.icon(
      onPressed: onPressed, // The action to perform on tap
      icon: Icon(icon, size: 28), // Icon displayed on the button
      label: Text(
        label,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600) // Consistent text style
      ),
      // Styling from the app's theme, ensuring consistency
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 20), // Vertical padding for button height
        // Background and foreground colors are typically handled by ElevatedButtonThemeData in main.dart
      ),
    );
  }
}