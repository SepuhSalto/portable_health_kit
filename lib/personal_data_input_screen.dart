import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:portable_health_kit/main_navigation_screen.dart'; // No longer needed
import 'package:portable_health_kit/services/firestore_service.dart';
import 'package:portable_health_kit/services/user_session_service.dart';

class PersonalDataInputScreen extends StatefulWidget {
  // This screen is now ONLY for registering new patients
  // We can remove the isInitialSetup flag
  const PersonalDataInputScreen({super.key});

  @override
  State<PersonalDataInputScreen> createState() => _PersonalDataInputScreenState();
}

class _PersonalDataInputScreenState extends State<PersonalDataInputScreen> {
  final _firestoreService = FirestoreService();
  final _sessionService = UserSessionService();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _addressController = TextEditingController();
  // NEW: Controller for phone number
  final _phoneController = TextEditingController();

  String? _selectedGender;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _addressController.dispose();
    // NEW: Dispose the phone controller
    _phoneController.dispose(); 
    super.dispose();
  }

  Future<void> _saveData() async {
    if (_nameController.text.isEmpty || _ageController.text.isEmpty || _phoneController.text.isEmpty || _selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon lengkapi semua data (Nama, Umur, HP, Jenis Kelamin).'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() { _isLoading = true; });

    final patientData = {
      'Name': _nameController.text,
      'Age': int.tryParse(_ageController.text) ?? 0,
      'Gender': _selectedGender,
      'Address': _addressController.text,
      'Phone': _phoneController.text,
      'createdAt': Timestamp.now(),
      // NEW: Link this patient to the health worker who registered them
      'registeredByUserId': _sessionService.currentUserId,
    };

    try {
      // NEW: Use the addPatient function
      await _firestoreService.addPatient(patientData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pasien baru berhasil didaftarkan!'), backgroundColor: Colors.green),
        );
        // Just go back to the previous screen
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mendaftarkan pasien: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Title is now fixed
        title: const Text('Register Pasien Baru'), 
        automaticallyImplyLeading: true, // User can always go back
      ),
      body: SingleChildScrollView(
        // ... (The Column and all _buildTextField widgets are the same as before) ...
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTextField(controller: _nameController, label: 'Nama Lengkap', icon: Icons.person_outline),
            const SizedBox(height: 20),
            _buildTextField(controller: _ageController, label: 'Umur', icon: Icons.cake_outlined, keyboardType: TextInputType.number),
            const SizedBox(height: 20),
            _buildTextField(controller: _phoneController, label: 'Nomor HP', icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
            const SizedBox(height: 20),
            _buildGenderDropdown(),
            const SizedBox(height: 20),
            _buildTextField(controller: _addressController, label: 'Alamat', icon: Icons.home_outlined, maxLines: 3),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveData,
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Simpan Pasien'), // Updated button text
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            prefixIcon: Icon(icon),
            hintText: label,
          ),
        ),
      ],
    );
  }

  Widget _buildGenderDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Jenis Kelamin', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedGender,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.wc_outlined),
          ),
          hint: const Text('Pilih Jenis Kelamin'),
          onChanged: (String? newValue) {
            setState(() {
              _selectedGender = newValue;
            });
          },
          items: <String>['Laki-laki', 'Perempuan']
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ],
    );
  }
}