import 'package:flutter/material.dart';

class PersonalDataInputScreen extends StatefulWidget {
  const PersonalDataInputScreen({super.key});

  @override
  State<PersonalDataInputScreen> createState() => _PersonalDataInputScreenState();
}

class _PersonalDataInputScreenState extends State<PersonalDataInputScreen> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _addressController = TextEditingController();
  String? _selectedGender;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _saveData() {
    // TODO: Implement Firestore saving logic
    print('Name: ${_nameController.text}');
    print('Age: ${_ageController.text}');
    print('Gender: $_selectedGender');
    print('Address: ${_addressController.text}');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Input Data Diri'),
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
              onPressed: _saveData,
              child: const Text('Simpan Data'),
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