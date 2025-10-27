import 'package:flutter/material.dart';
import 'package:portable_health_kit/patient_selection_screen.dart'; // Handles patient selection
import 'package:portable_health_kit/personal_data_input_screen.dart'; // Screen to register new patient
import 'package:portable_health_kit/blood_pressure_input_screen.dart'; // BP input screen
import 'package:portable_health_kit/blood_sugar_input_screen.dart'; // BS input screen
// --- IMPORT NEW SCREENS ---
import 'package:portable_health_kit/uric_acid_input_screen.dart'; // Uric acid input screen
import 'package:portable_health_kit/cholesterol_input_screen.dart'; // Cholesterol input screen
import 'package:portable_health_kit/waist_circumference_input_screen.dart'; // Waist input screen


class HealthCheckScreen extends StatelessWidget {
  const HealthCheckScreen({super.key});

  /// Helper function to navigate first to Patient Selection,
  /// then to the appropriate input screen.
  ///
  /// Takes the build context, the action type, and a builder function
  /// that creates the target input screen widget.
  Future<void> _selectPatientAndNavigate(BuildContext context, PatientAction action, { required Widget Function(String patientId, String patientName) screenBuilder }) async {

    print("HealthCheckScreen: Initiating patient selection for action: $action");
    // Navigate to the PatientSelectionScreen and wait for a result.
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        // Pass the action to the selection screen (might be used for title or filtering later)
        builder: (context) => PatientSelectionScreen(action: action),
      ),
    );

    // Check if a patient was selected (result is not null and is a Map)
    // Also check if the current widget is still mounted after the await.
    if (result != null && result is Map<String, dynamic> && context.mounted) {
      // Extract patient ID and name from the result map.
      final String patientId = result['id'];
      final String patientName = result['name'];
      print("HealthCheckScreen: Patient selected - ID: $patientId, Name: $patientName. Navigating to input screen.");

      // Navigate to the specific input screen using the provided builder function.
      Navigator.push(context, MaterialPageRoute(
          builder: (context) => screenBuilder(patientId, patientName)
      ));
    } else if (result == null && context.mounted) {
      // Log if the selection was cancelled or failed.
       print("HealthCheckScreen: Patient selection cancelled or returned null.");
    } else if (!context.mounted) {
        print("HealthCheckScreen: Context became unmounted after patient selection.");
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

                // --- Button for Blood Pressure Input ---
                _buildMenuButton(
                  context,
                  icon: Icons.monitor_heart_outlined,
                  label: 'Input Tekanan Darah',
                  onPressed: () {
                    // Use helper to select patient then navigate
                    _selectPatientAndNavigate(
                        context,
                        PatientAction.inputBloodPressure, // Specific action
                        // Provide the builder for the target screen
                        screenBuilder: (id, name) => BloodPressureInputScreen(patientId: id, patientName: name)
                    );
                  },
                ),
                const SizedBox(height: 20),

                // --- Button for Blood Sugar Input ---
                _buildMenuButton(
                  context,
                  icon: Icons.bloodtype_outlined,
                  label: 'Input Gula Darah',
                  onPressed: () {
                     _selectPatientAndNavigate(
                         context,
                         PatientAction.inputBloodSugar, // Specific action
                         screenBuilder: (id, name) => BloodSugarInputScreen(patientId: id, patientName: name)
                    );
                  },
                ),
                const SizedBox(height: 20),

                // --- Button for Uric Acid Input ---
                _buildMenuButton(
                  context,
                  icon: Icons.science_outlined, // Icon representing lab/uric acid
                  label: 'Input Asam Urat',
                  onPressed: () {
                    _selectPatientAndNavigate(
                        context,
                        PatientAction.inputUricAcid, // Use specific action
                        screenBuilder: (id, name) => UricAcidInputScreen(patientId: id, patientName: name)
                    );
                  },
                ),
                const SizedBox(height: 20),

                // --- Button for Cholesterol Input ---
                _buildMenuButton(
                  context,
                  icon: Icons.opacity_outlined, // Icon representing cholesterol/lipids
                  label: 'Input Kolesterol',
                  onPressed: () {
                     _selectPatientAndNavigate(
                        context,
                         PatientAction.inputCholesterol, // Use specific action
                        screenBuilder: (id, name) => CholesterolInputScreen(patientId: id, patientName: name)
                    );
                  },
                ),
                const SizedBox(height: 20),

                // --- Button for Waist Circumference Input ---
                _buildMenuButton(
                  context,
                  icon: Icons.square_foot_outlined, // Icon representing measurement/waist
                  label: 'Input Lingkar Perut',
                  onPressed: () {
                     _selectPatientAndNavigate(
                        context,
                         PatientAction.inputWaist, // Use specific action
                        screenBuilder: (id, name) => WaistCircumferenceInputScreen(patientId: id, patientName: name)
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