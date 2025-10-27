import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:portable_health_kit/services/firestore_service.dart';

// This enum tells the screen what to do after a patient is selected
enum PatientAction {
  viewHistory,
  inputBloodPressure,
  inputBloodSugar,
  inputUricAcid,
  inputCholesterol,
  inputWaist
}

class PatientSelectionScreen extends StatefulWidget {
  // This tells the screen what action to perform
  final PatientAction action;

  const PatientSelectionScreen({super.key, required this.action});

  @override
  State<PatientSelectionScreen> createState() => _PatientSelectionScreenState();
}

class _PatientSelectionScreenState extends State<PatientSelectionScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  void _onPatientTapped(String patientId, String patientName) {
    // Based on the action, navigate to the correct screen
    // We will build these navigations in the next steps
    
    // For now, let's just pop and return the ID
    // TODO: Implement navigation
    print('Selected Patient $patientName with ID $patientId for action ${widget.action}');

    // This is where you would navigate:
    // if (widget.action == PatientAction.inputBloodPressure) {
    //   Navigator.push(context, MaterialPageRoute(builder: (context) => BloodPressureInputScreen(patientId: patientId, patientName: patientName)));
    // } 
    // ... etc.
    
    // For now, we just go back. We will update health_check_screen to handle this.
    Navigator.of(context).pop(
      {'id': patientId, 'name': patientName}
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Pasien'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.getPatientsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada pasien terdaftar.\nSilakan daftar pasien baru di laman "Input Data".',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          final patients = snapshot.data!.docs;

          return ListView.builder(
            itemCount: patients.length,
            itemBuilder: (context, index) {
              final patient = patients[index];
              final data = patient.data() as Map<String, dynamic>;
              
              final String name = data['Name'] ?? 'Tanpa Nama';
              final String info = "Umur: ${data['Age'] ?? '?'} • ${data['Phone'] ?? 'No HP'}";

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                    child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'P', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(info),
                  onTap: () => _onPatientTapped(patient.id, name),
                ),
              );
            },
          );
        },
      ),
    );
  }
}