import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:portable_health_kit/main_navigation_screen.dart';
import 'package:portable_health_kit/services/firestore_service.dart';
import 'package:portable_health_kit/services/user_session_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PersonalDataInputScreen extends StatefulWidget {
  // This flag tells the screen if it's the very first time the app is run
  final bool isInitialSetup;

  const PersonalDataInputScreen({super.key, this.isInitialSetup = false});

  @override
  State<PersonalDataInputScreen> createState() => _PersonalDataInputScreenState();
}

class _PersonalDataInputScreenState extends State<PersonalDataInputScreen> {
  final _firestoreService = FirestoreService();
  final _sessionService = UserSessionService();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _addressController = TextEditingController();
  String? _selectedGender;
  bool _isLoading = false;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userId = _sessionService.currentUserId;
    if (userId != null) {
      setState(() {
        _isEditMode = true;
      });
      final userData = await _firestoreService.getUser(userId);
      if (userData != null && mounted) {
        _nameController.text = userData['Name'] ?? '';
        _ageController.text = userData['Age']?.toString() ?? '';
        _addressController.text = userData['Address'] ?? '';
        setState(() {
          _selectedGender = userData['Gender'];
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveData() async {
    if (_nameController.text.isEmpty || _ageController.text.isEmpty || _selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon lengkapi semua data yang diperlukan.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final userData = {
      'Name': _nameController.text,
      'Age': int.tryParse(_ageController.text) ?? 0,
      'Gender': _selectedGender,
      'Address': _addressController.text,
    };

    try {
      if (_isEditMode) {
        // UPDATE existing user
        await _firestoreService.updateUser(_sessionService.currentUserId!, userData);
      } else {
        // CREATE new user
        userData['createdAt'] = Timestamp.now();
        final newUserId = await _firestoreService.addUser(userData);
        _sessionService.setCurrentUserId(newUserId);
        // Save the user ID to the device for future app launches
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', newUserId);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data berhasil ${_isEditMode ? 'diperbarui' : 'disimpan'}!'), backgroundColor: Colors.green),
        );

        if (widget.isInitialSetup) {
          // If this was the first setup, go to the main app dashboard
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
          );
        } else {
          // Otherwise, just go back to the previous screen
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan data: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Data Diri' : 'Input Data Diri'),
        // Prevent going back during the initial, mandatory setup
        automaticallyImplyLeading: !widget.isInitialSetup,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTextField(controller: _nameController, label: 'Nama Lengkap', icon: Icons.person_outline),
            const SizedBox(height: 20),
            _buildTextField(controller: _ageController, label: 'Umur', icon: Icons.cake_outlined, keyboardType: TextInputType.number),
            const SizedBox(height: 20),
            _buildGenderDropdown(),
            const SizedBox(height: 20),
            _buildTextField(controller: _addressController, label: 'Alamat', icon: Icons.home_outlined, maxLines: 3),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveData,
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_isEditMode ? 'Perbarui Data' : 'Simpan Data'),
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
          ),
        ),
      ],
    );
  }

  Widget _buildGenderDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Jenis Kelamin', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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