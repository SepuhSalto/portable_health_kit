import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:portable_health_kit/patient_selection_screen.dart';
import 'package:portable_health_kit/services/firestore_service.dart';

class HomeScreen extends StatefulWidget {
  // NEW: Callback function from MainNavigationScreen
  final Function(int) onNavigateToInput;

  const HomeScreen({super.key, required this.onNavigateToInput});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  
  // NEW: State variables to hold the selected patient
  String? _selectedPatientId;
  String? _selectedPatientName;

  // NEW: Function to open the patient selection screen
  Future<void> _selectPatient() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PatientSelectionScreen(
          // We don't need a specific action, just selection
          action: PatientAction.viewHistory,
        ),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _selectedPatientId = result['id'];
        _selectedPatientName = result['name'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // NEW: Title changes based on selected patient
        title: Text(_selectedPatientName == null ? 'Beranda' : 'Beranda: $_selectedPatientName'),
        automaticallyImplyLeading: false,
        actions: [
          // NEW: Button to select a patient
          IconButton(
            icon: const Icon(Icons.person_search_outlined),
            tooltip: 'Pilih Pasien',
            onPressed: _selectPatient,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Welcome Card (Unchanged) ---
            Card(
              clipBehavior: Clip.antiAlias,
              child: Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Theme.of(context).primaryColor, Theme.of(context).colorScheme.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.favorite, color: Colors.white, size: 40),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Selamat Datang!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                          SizedBox(height: 4),
                          Text('Aplikasi Bali-Sehat siap membantu Anda.', style: TextStyle(fontSize: 14, color: Colors.white70)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- Live Data Section (HEAVILY MODIFIED) ---
            if (_selectedPatientId == null)
              // Show this if no patient is selected
              _buildAddDataCard(
                context,
                title: 'Silakan Pilih Pasien',
                description: 'Pilih pasien menggunakan tombol di kanan atas untuk melihat data kesehatan terbaru.',
                isPatientSelection: true,
              )
            else
              // Show this once a patient is selected
              StreamBuilder<QuerySnapshot>(
                // NEW: Use the new Firestore service function
                stream: _firestoreService.getPatientRecentReadingsStream(_selectedPatientId!),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return _buildAddDataCard(
                      context,
                      title: 'Data Kesehatan Belum Ada',
                      description: 'Input data kesehatan untuk pasien ini untuk melihat hasilnya di sini.',
                    );
                  }

                  final readings = snapshot.data!.docs;
                  
                  QueryDocumentSnapshot<Object?>? latestBpReading;
                  QueryDocumentSnapshot<Object?>? latestBsReading;
                  
                  try {
                    latestBpReading = readings.firstWhere((doc) => (doc.data() as Map<String, dynamic>)['SystolicValue'] != null);
                  } catch (e) { latestBpReading = null; }
                  
                  try {
                    latestBsReading = readings.firstWhere((doc) => (doc.data() as Map<String, dynamic>)['BloodSugarValue'] != null);
                  } catch (e) { latestBsReading = null; }

                  return Column(
                    children: [
                      if (latestBpReading != null)
                        _buildBloodPressureCard(context, latestBpReading.data() as Map<String, dynamic>)
                      else
                        _buildAddDataCard(context, title: 'Tekanan Darah Belum Diinput', description: 'Input data tekanan darah untuk pasien ini.'),
                      
                      const SizedBox(height: 16),
                      
                      if (latestBsReading != null)
                        _buildBloodSugarCard(context, latestBsReading.data() as Map<String, dynamic>)
                      else
                        _buildAddDataCard(context, title: 'Gula Darah Belum Diinput', description: 'Input data gula darah untuk pasien ini.'),
                    ],
  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // --- Card Widgets (MODIFIED) ---
  Widget _buildBloodPressureCard(BuildContext context, Map<String, dynamic> data) {
    final timestamp = (data['Timestamp'] as Timestamp).toDate();
    final int systolic = data['SystolicValue'];
    final int diastolic = data['DiastolicValue'];
    final category = _getBloodPressureCategory(systolic, diastolic);

    return Card(
      // REMOVED: The Stack widget
      child: Padding(
        // MODIFIED: Padding is simpler
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildCardHeader(context, timestamp),
            const Divider(height: 24),
            _HealthMetric(value: '$systolic/$diastolic', unit: 'mmHg', label: 'Tekanan Darah'),
            const SizedBox(height: 16),
            _buildStatusChip(category, _getBloodPressureColor(category)),
          ],
        ),
      ),
    );
  }

  Widget _buildBloodSugarCard(BuildContext context, Map<String, dynamic> data) {
    final timestamp = (data['Timestamp'] as Timestamp).toDate();
    final int bloodSugar = data['BloodSugarValue'];
    final category = _getBloodSugarCategory(bloodSugar);

    return Card(
      // REMOVED: The Stack widget
      child: Padding(
        // MODIFIED: Padding is simpler
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildCardHeader(context, timestamp),
            const Divider(height: 24),
            _HealthMetric(value: bloodSugar.toString(), unit: 'mg/dL', label: 'Gula Darah'),
            const SizedBox(height: 16),
            _buildStatusChip(category, _getBloodSugarColor(category)),
          ],
        ),
      ),
    );
  }

  // --- Helper Widgets ---
  Widget _buildCardHeader(BuildContext context, DateTime timestamp) {
    // ... (Unchanged) ...
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(DateFormat('EEEE, d MMM yyyy, HH:mm', 'id_ID').format(timestamp), style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500)),
        Icon(Icons.check_circle, color: Theme.of(context).primaryColor),
      ],
    );
  }

  // REMOVED: _buildAlarmButton widget

  Widget _buildAddDataCard(BuildContext context, {required String title, required String description, bool isPatientSelection = false}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(
              isPatientSelection ? Icons.person_search_outlined : Icons.add_chart_outlined,
              size: 40,
              color: Colors.grey[400]
            ),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(description, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // NEW: Use the correct callback
                if (isPatientSelection) {
                  _selectPatient();
                } else {
                  widget.onNavigateToInput(1); // Go to "Input Data" tab
                }
              },
              // NEW: Change button text based on context
              child: Text(isPatientSelection ? 'Pilih Pasien' : 'Input Data Sekarang'),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    // ... (Unchanged) ...
    return Chip(
      label: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  // --- Category Logic (Unchanged) ---
  String _getBloodPressureCategory(int systolic, int diastolic) {
    if (systolic >= 140 || diastolic >= 90) return 'Hipertensi Derajat 2';
    if (systolic >= 130 || diastolic >= 80) return 'Hipertensi Derajat 1';
    if (systolic >= 120) return 'Pra-hipertensi';
    return 'Normal';
  }
  Color _getBloodPressureColor(String category) {
    switch (category) {
      case 'Hipertensi Derajat 2': return Colors.red;
      case 'Hipertensi Derajat 1': return Colors.orange;
      case 'Pra-hipertensi': return Colors.yellow.shade800;
      default: return Colors.green;
    }
  }
  String _getBloodSugarCategory(int sugar) {
    if (sugar >= 200) return 'Diabetes';
    if (sugar >= 140) return 'Pradiabetes';
    return 'Normal';
  }
  Color _getBloodSugarColor(String category) {
    switch (category) {
      case 'Diabetes': return Colors.red;
      case 'Pradiabetes': return Colors.orange;
      default: return Colors.green;
    }
  }
}

class _HealthMetric extends StatelessWidget {
  // ... (Unchanged) ...
  final String value;
  final String unit;
  final String label;
  const _HealthMetric({required this.value, required this.unit, required this.label});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
        Text(unit, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }
}