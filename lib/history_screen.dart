import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:portable_health_kit/patient_history_detail_screen.dart'; // NEW
import 'package:portable_health_kit/services/firestore_service.dart';
// import 'package:portable_health_kit/services/user_session_service.dart'; // No longer needed

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Pasien'),
        automaticallyImplyLeading: false,
        // NEW: Search Bar
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight - 8),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari nama pasien...',
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                hintStyle: const TextStyle(color: Colors.white70),
                fillColor: Colors.white.withOpacity(0.2),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // NEW: Stream from 'patients' collection
        stream: _firestoreService.getPatientsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Tidak ada pasien terdaftar.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          // NEW: Filter logic
          final patients = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final name = (data['Name'] ?? '').toLowerCase();
            return name.contains(_searchQuery);
          }).toList();

          if (patients.isEmpty) {
            return const Center(
              child: Text(
                'Pasien tidak ditemukan.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          // NEW: Build a list of patients
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: patients.length,
            itemBuilder: (context, index) {
              final patient = patients[index];
              final data = patient.data() as Map<String, dynamic>;
              final String name = data['Name'] ?? 'Tanpa Nama';
              final String info = "Umur: ${data['Age'] ?? '?'} • ${data['Phone'] ?? 'No HP'}";

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                    child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'P', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(info),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // NEW: Navigate to the detail screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PatientHistoryDetailScreen(
                          patientId: patient.id,
                          patientName: name,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

