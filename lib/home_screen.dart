import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:portable_health_kit/add_edit_alarm_screen.dart';
import 'package:portable_health_kit/health_check_screen.dart';
import 'package:portable_health_kit/services/firestore_service.dart';
import 'package:portable_health_kit/services/user_session_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final UserSessionService _sessionService = UserSessionService();

  @override
  Widget build(BuildContext context) {
    final String? currentUserId = _sessionService.currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Beranda'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Welcome Card ---
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

            // --- Live Data Section ---
            if (currentUserId == null)
              const Center(child: Text('Error: User ID tidak ditemukan.'))
            else
              StreamBuilder<QuerySnapshot>(
                stream: _firestoreService.getRecentReadingsStream(currentUserId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return _buildAddDataCard(
                      context,
                      title: 'Data Kesehatan Belum Ada',
                      description: 'Input data kesehatan Anda untuk melihat hasilnya di sini.',
                    );
                  }

                  final readings = snapshot.data!.docs;
                  
                  // Find the latest BP and BS readings from the list in Dart code
                  QueryDocumentSnapshot<Object?>? latestBpReading;
                  QueryDocumentSnapshot<Object?>? latestBsReading;
                  
                  try {
                    latestBpReading = readings.firstWhere((doc) => (doc.data() as Map<String, dynamic>)['SystolicValue'] != null);
                  } catch (e) {
                    latestBpReading = null;
                  }
                  
                  try {
                    latestBsReading = readings.firstWhere((doc) => (doc.data() as Map<String, dynamic>)['BloodSugarValue'] != null);
                  } catch (e) {
                    latestBsReading = null;
                  }

                  return Column(
                    children: [
                      if (latestBpReading != null)
                        _buildBloodPressureCard(context, latestBpReading.data() as Map<String, dynamic>)
                      else
                        _buildAddDataCard(context, title: 'Tekanan Darah Belum Diinput', description: 'Input data tekanan darah Anda untuk melihat hasilnya di sini.'),
                      
                      const SizedBox(height: 16),
                      
                      // CARD 2: Latest Blood Sugar
                      if (latestBsReading != null)
                        _buildBloodSugarCard(context, latestBsReading.data() as Map<String, dynamic>)
                      else
                        _buildAddDataCard(context, title: 'Gula Darah Belum Diinput', description: 'Input data gula darah Anda untuk melihat hasilnya di sini.'),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // --- Card Widgets ---
  Widget _buildBloodPressureCard(BuildContext context, Map<String, dynamic> data) {
    final timestamp = (data['Timestamp'] as Timestamp).toDate();
    final int systolic = data['SystolicValue'];
    final int diastolic = data['DiastolicValue'];
    final category = _getBloodPressureCategory(systolic, diastolic);

    return Card(
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 50),
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
          _buildAlarmButton(context),
        ],
      ),
    );
  }

  Widget _buildBloodSugarCard(BuildContext context, Map<String, dynamic> data) {
    final timestamp = (data['Timestamp'] as Timestamp).toDate();
    final int bloodSugar = data['BloodSugarValue'];
    final category = _getBloodSugarCategory(bloodSugar);

    return Card(
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 50),
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
          _buildAlarmButton(context),
        ],
      ),
    );
  }

  // --- Helper Widgets ---
  Widget _buildCardHeader(BuildContext context, DateTime timestamp) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(DateFormat('EEEE, d MMM yyyy, HH:mm', 'id_ID').format(timestamp), style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500)),
        Icon(Icons.check_circle, color: Theme.of(context).primaryColor),
      ],
    );
  }

  Positioned _buildAlarmButton(BuildContext context) {
    return Positioned(
      bottom: 10,
      right: 10,
      child: ActionChip(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AddEditAlarmScreen()));
        },
        avatar: Icon(Icons.add_alarm_outlined, size: 16, color: Theme.of(context).primaryColor),
        label: Text('Tambah Alarm', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 12)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.3)),
        ),
      ),
    );
  }

  Widget _buildAddDataCard(BuildContext context, {required String title, required String description}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(Icons.add_chart_outlined, size: 40, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(description, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const HealthCheckScreen()));
              },
              child: const Text('Input Data Sekarang'),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Chip(
      label: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  // --- Category Logic ---
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