import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:portable_health_kit/patient_selection_screen.dart'; // Patient selection screen
import 'package:portable_health_kit/services/firestore_service.dart'; // Firestore interaction

// Ensure PatientAction enum includes values used here, defined in patient_selection_screen.dart
// enum PatientAction { viewHistory, inputBloodPressure, /* ... other actions ... */ }

class HomeScreen extends StatefulWidget {
  // Callback function provided by MainNavigationScreen to switch tabs
  final Function(int) onNavigateToInput;

  const HomeScreen({super.key, required this.onNavigateToInput});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Firestore service instance
  final FirestoreService _firestoreService = FirestoreService();

  // State variables to hold the currently selected patient's ID and name
  String? _selectedPatientId;
  String? _selectedPatientName;
  // State variable to hold the full patient document data (including gender)
  Map<String, dynamic>? _selectedPatientData;
  // Flag to indicate when patient details are being fetched
  bool _isLoadingPatientData = false;

  /// Opens the PatientSelectionScreen to allow the user to choose a patient.
  /// Fetches the selected patient's full data (including gender) from Firestore.
  Future<void> _selectPatient() async {
    print("HomeScreen: Opening patient selection...");
    // Navigate to the selection screen and wait for the result
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PatientSelectionScreen(
          // Use a generic action, as we just need to select a patient here
          action: PatientAction.viewHistory, // Make sure this enum exists
        ),
      ),
    );

    // If a patient was selected (result is not null and is a Map)
    // and the widget is still mounted
    if (result != null && result is Map<String, dynamic> && mounted) {
      final newPatientId = result['id'];
      final newPatientName = result['name'];
      print("HomeScreen: Patient selected - ID: $newPatientId, Name: $newPatientName. Fetching details...");

      // Set loading state and update basic info immediately
      setState(() {
        _isLoadingPatientData = true;
        _selectedPatientId = newPatientId;
        _selectedPatientName = newPatientName;
        _selectedPatientData = null; // Clear old data while loading
      });

      // Fetch the full patient data using the Firestore service
      final patientData = await _firestoreService.getPatientData(newPatientId);

      // Check mount status again after the async operation
      if (mounted) {
        // Update state with the fetched patient data (or null if failed)
        setState(() {
          _selectedPatientData = patientData;
          _isLoadingPatientData = false; // Turn off loading indicator
           // Update name again from fetched data for consistency (optional)
           _selectedPatientName = patientData?['Name'] as String? ?? newPatientName;
        });
        // Provide user feedback if data fetching failed
        if (patientData == null) {
             print("HomeScreen: Warning - Could not fetch patient data for ID $newPatientId");
             ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(content: Text('Gagal memuat detail lengkap pasien $newPatientName.'), backgroundColor: Colors.orange),
             );
        } else {
             // Log success and the fetched gender
             print("HomeScreen: Patient data fetched successfully. Gender: ${_selectedPatientData?['Gender']}");
        }
      }
    } else {
       print("HomeScreen: Patient selection cancelled or returned null.");
       // Optional: Clear selection if user cancels
       // setState(() {
       //   _selectedPatientId = null; _selectedPatientName = null; _selectedPatientData = null;
       // });
    }
  }

  /// Helper function to find the most recent document in a list of snapshots
  /// that contains a non-null value for the specified field name.
  /// Assumes `docs` are sorted newest first.
  Map<String, dynamic>? _findLatestReading(List<QueryDocumentSnapshot<Object?>> docs, String fieldName) {
      try {
          // Use firstWhere to find the first document matching the criteria
          final doc = docs.firstWhere(
              (d) {
                  // Safely cast data to Map, check if field exists and is not null
                  final data = d.data() as Map<String, dynamic>?;
                  return data != null && data.containsKey(fieldName) && data[fieldName] != null;
              }
          );
          // Return the data map if a document is found
          return doc.data() as Map<String, dynamic>;
      } catch (e) {
          // Return null if no matching document is found (firstWhere throws if none found)
          // print("HomeScreen: No recent reading found for field '$fieldName'."); // Optional log
          return null;
      }
  }


  @override
  Widget build(BuildContext context) {
    // Safely get the patient's gender from the fetched data, provide a default.
    // This default is used *before* data is loaded or if 'Gender' field is missing.
    final String currentPatientGender = _selectedPatientData?['Gender'] as String? ?? "Laki-laki";

    return Scaffold(
      // --- AppBar ---
      appBar: AppBar(
        // Show patient name in title, or default "Beranda"
        title: Text(_selectedPatientName == null ? 'Beranda' : 'Pasien: $_selectedPatientName'),
        automaticallyImplyLeading: false, // No back arrow
        actions: [
          // Button to open patient selection
          IconButton(
            icon: const Icon(Icons.person_search_outlined),
            tooltip: 'Pilih Pasien',
            onPressed: _selectPatient,
          ),
          const SizedBox(width: 8), // Spacing at the end of AppBar
        ],
        elevation: 1, // Subtle shadow
      ),
      // --- Body Content ---
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0), // Padding for all content
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Welcome Card ---
            Card(
              clipBehavior: Clip.antiAlias,
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // Rounded corners
              child: Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  // Green gradient using theme colors
                  gradient: LinearGradient(
                    colors: [ Theme.of(context).primaryColor, Theme.of(context).colorScheme.secondary ],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.favorite_border, color: Colors.white, size: 40),
                    const SizedBox(width: 16),
                    const Expanded(
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
            const SizedBox(height: 24), // Spacing after welcome card

            // --- Main Data Display Area ---
            // Show loading indicator while fetching patient details after selection
            if (_isLoadingPatientData)
              const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 40.0), child: CircularProgressIndicator()))
            // Show prompt card if no patient is currently selected
            else if (_selectedPatientId == null)
              _buildAddDataCard(
                context,
                title: 'Silakan Pilih Pasien',
                description: 'Pilih pasien menggunakan tombol di kanan atas untuk melihat data kesehatan terbaru.',
                isPatientSelection: true, // Indicates this card should trigger patient selection
              )
            // If a patient is selected, show their recent health readings via StreamBuilder
            else
              StreamBuilder<QuerySnapshot>(
                // Listen to the stream for the selected patient's recent readings
                stream: _firestoreService.getPatientRecentReadingsStream(_selectedPatientId!),
                builder: (context, snapshot) {
                  // --- Handle Stream Loading State ---
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    // Show a smaller loading indicator within the stream area
                    return const Center(child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ));
                  }
                  // --- Handle Stream Error State ---
                   if (snapshot.hasError) {
                       print("HomeScreen: Error in Health Readings StreamBuilder: ${snapshot.error}");
                       // Show a specific error card for stream errors
                       return _buildErrorCard(context, snapshot.error);
                   }
                  // --- Handle No Readings Data State ---
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    // Show prompt to add data if patient selected but no readings exist yet
                    return _buildAddDataCard(
                      context,
                      title: 'Data Kesehatan Belum Ada',
                      description: 'Input data kesehatan untuk pasien ini untuk melihat hasilnya di sini.',
                      isPatientSelection: false, // Indicates this card should trigger navigating to input
                    );
                  }

                  // --- Readings Data Available ---
                  final readings = snapshot.data!.docs; // List of recent reading documents (newest first)

                  // Find the most recent document containing a value for each type
                  final latestBpData = _findLatestReading(readings, 'SystolicValue');
                  final latestBsData = _findLatestReading(readings, 'BloodSugarValue');
                  final latestUaData = _findLatestReading(readings, 'UricAcidValue');
                  final latestCholData = _findLatestReading(readings, 'CholesterolValue');
                  final latestWaistData = _findLatestReading(readings, 'WaistCircumferenceValue');

                  // Build the column displaying the data cards
                  return Column(
                    // Ensure cards stretch horizontally
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Blood Pressure Card (or prompt if no data)
                      if (latestBpData != null)
                        _buildBloodPressureCard(context, latestBpData)
                      else
                         _buildAddDataCard(context, title: 'Tekanan Darah Belum Diinput', description: 'Input data tekanan darah untuk pasien ini.'),
                      const SizedBox(height: 16),

                      // Blood Sugar Card (or prompt)
                      if (latestBsData != null)
                        _buildBloodSugarCard(context, latestBsData)
                      else
                        _buildAddDataCard(context, title: 'Gula Darah Belum Diinput', description: 'Input data gula darah untuk pasien ini.'),
                      const SizedBox(height: 16),

                      // Uric Acid Card (or prompt) - Pass the fetched gender
                      if (latestUaData != null)
                        _buildUricAcidCard(context, latestUaData, currentPatientGender)
                      else
                        _buildAddDataCard(context, title: 'Asam Urat Belum Diinput', description: 'Input data asam urat untuk pasien ini.'),
                      const SizedBox(height: 16),

                      // Cholesterol Card (or prompt)
                      if (latestCholData != null)
                        _buildCholesterolCard(context, latestCholData)
                      else
                        _buildAddDataCard(context, title: 'Kolesterol Belum Diinput', description: 'Input data kolesterol untuk pasien ini.'),
                       const SizedBox(height: 16),

                      // Waist Circumference Card (or prompt) - Pass the fetched gender
                      if (latestWaistData != null)
                        _buildWaistCard(context, latestWaistData, currentPatientGender)
                      else
                        _buildAddDataCard(context, title: 'Lingkar Perut Belum Diinput', description: 'Input data lingkar perut untuk pasien ini.'),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // --- Card Building Widgets ---

  /// Builds the card displaying the latest Blood Pressure reading.
  Widget _buildBloodPressureCard(BuildContext context, Map<String, dynamic> data) {
    final timestamp = (data['Timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
    final int systolic = (data['SystolicValue'] as num?)?.toInt() ?? 0;
    final int diastolic = (data['DiastolicValue'] as num?)?.toInt() ?? 0;
    final category = _getBloodPressureCategory(systolic, diastolic);
    final color = _getBloodPressureColor(category);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildCardHeader(context, timestamp),
            const Divider(height: 24, thickness: 0.5),
            _HealthMetric(value: '$systolic / $diastolic', unit: 'mmHg', label: 'Tekanan Darah'),
            const SizedBox(height: 16),
            _buildStatusChip(category, color),
          ],
        ),
      ),
    );
  }

  /// Builds the card displaying the latest Blood Sugar reading.
  Widget _buildBloodSugarCard(BuildContext context, Map<String, dynamic> data) {
     final timestamp = (data['Timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
    final int bloodSugar = (data['BloodSugarValue'] as num?)?.toInt() ?? 0;
    final category = _getBloodSugarCategory(bloodSugar);
    final color = _getBloodSugarColor(category);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildCardHeader(context, timestamp),
            const Divider(height: 24, thickness: 0.5),
            _HealthMetric(value: bloodSugar.toString(), unit: 'mg/dL', label: 'Gula Darah'),
            const SizedBox(height: 16),
            _buildStatusChip(category, color),
          ],
        ),
      ),
    );
  }

  /// Builds the card displaying the latest Uric Acid reading, using patient gender.
  Widget _buildUricAcidCard(BuildContext context, Map<String, dynamic> data, String gender) {
    final timestamp = (data['Timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
    final double uricAcid = (data['UricAcidValue'] as num?)?.toDouble() ?? 0.0;
    // Use the passed gender for accurate category
    final category = _getUricAcidCategory(uricAcid, gender);
    final color = _getUricAcidColor(category);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildCardHeader(context, timestamp),
            const Divider(height: 24, thickness: 0.5),
            _HealthMetric(value: uricAcid.toStringAsFixed(1), unit: 'mg/dL', label: 'Asam Urat'),
            const SizedBox(height: 16),
            _buildStatusChip(category, color), // Display status chip
          ],
        ),
      ),
    );
  }

  /// Builds the card displaying the latest Cholesterol reading.
  Widget _buildCholesterolCard(BuildContext context, Map<String, dynamic> data) {
    final timestamp = (data['Timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
    final int cholesterol = (data['CholesterolValue'] as num?)?.toInt() ?? 0;
    final category = _getCholesterolCategory(cholesterol);
    final color = _getCholesterolColor(category);

     return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildCardHeader(context, timestamp),
            const Divider(height: 24, thickness: 0.5),
            _HealthMetric(value: cholesterol.toString(), unit: 'mg/dL', label: 'Kolesterol Total'),
            const SizedBox(height: 16),
            _buildStatusChip(category, color),
          ],
        ),
      ),
    );
  }

  /// Builds the card displaying the latest Waist Circumference reading, using patient gender.
  Widget _buildWaistCard(BuildContext context, Map<String, dynamic> data, String gender) {
    final timestamp = (data['Timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
    final double waist = (data['WaistCircumferenceValue'] as num?)?.toDouble() ?? 0.0;
    // Use the passed gender for accurate category
    final category = _getWaistCategory(waist, gender);
    final color = _getWaistColor(category);

     return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildCardHeader(context, timestamp),
            const Divider(height: 24, thickness: 0.5),
            _HealthMetric(value: waist.toStringAsFixed(1), unit: 'cm', label: 'Lingkar Perut'),
            const SizedBox(height: 16),
            _buildStatusChip(category, color), // Display status chip
          ],
        ),
      ),
    );
  }


  // --- Helper Widgets ---

  /// Builds the header row for data cards (Timestamp and Checkmark).
  Widget _buildCardHeader(BuildContext context, DateTime timestamp) {
     return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Display formatted timestamp
        Text(
          DateFormat('EEE, d MMM yyyy, HH:mm', 'id_ID').format(timestamp),
          style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500)
        ),
        // Checkmark icon
        Icon(Icons.check_circle_outline, color: Theme.of(context).primaryColor, size: 18),
      ],
    );
  }

  /// Builds the placeholder card shown when no patient is selected or data is missing.
  Widget _buildAddDataCard(BuildContext context, {
      required String title,
      required String description,
      bool isPatientSelection = false // Flag determines button action/text
  }) {
    return Card(
      color: Colors.white,
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Center content vertically
          children: [
            Icon(
              isPatientSelection ? Icons.person_search_outlined : Icons.add_chart_outlined,
              size: 40,
              color: Colors.grey[400]
            ),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 8),
            Text(description, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Determine action based on the flag
                if (isPatientSelection) {
                  _selectPatient(); // Trigger patient selection
                } else {
                  // Navigate to the "Input Data" tab (assuming index 1)
                  widget.onNavigateToInput(1);
                }
              },
              // Change button text accordingly
              child: Text(isPatientSelection ? 'Pilih Pasien Sekarang' : 'Input Data Sekarang'),
            )
          ],
        ),
      ),
    );
  }

  /// Builds an error card to display StreamBuilder or data fetching errors.
   Widget _buildErrorCard(BuildContext context, Object? error) {
      return Card(
      color: Colors.red[50], // Light red background
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 40, color: Colors.red[700]),
            const SizedBox(height: 16),
            const Text('Gagal Memuat Data', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
            const SizedBox(height: 8),
            Text(
              "Terjadi kesalahan saat memuat data:\n${error?.toString() ?? 'Kesalahan tidak diketahui'}",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red[900])
            ),
             const SizedBox(height: 24),
             // Button to allow retrying patient selection
             ElevatedButton(
               onPressed: _selectPatient,
               style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]), // Use red button for error context
               child: const Text('Coba Pilih Pasien Lagi'),
             )
          ],
        ),
      ),
    );
   }

  /// Builds a small, colored chip to display the status category (e.g., Normal, Tinggi).
  Widget _buildStatusChip(String label, Color color) {
    // Return an empty container if label is empty or indicates no applicable status
    if (label.isEmpty || label == 'N/A') {
      return const SizedBox.shrink(); // Don't show a chip if status is not applicable
    }
    return Chip(
      label: Text(
        label,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)
      ),
      backgroundColor: color, // Color determined by category logic
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, // Minimize tap area
      visualDensity: VisualDensity.compact, // Make chip visually smaller
    );
  }

  // --- Category Logic Functions ---
  // (These determine the text and color of the status chips)

  String _getBloodPressureCategory(int systolic, int diastolic) {
    if (systolic <= 0 || diastolic <= 0) return 'N/A'; // Handle invalid input
    if (systolic >= 140 || diastolic >= 90) return 'Hipertensi Derajat 2';
    if (systolic >= 130 || diastolic >= 80) return 'Hipertensi Derajat 1';
    if (systolic >= 120) return 'Pra-hipertensi';
    if (systolic < 90 || diastolic < 60) return 'Hipotensi'; // Added low BP category
    return 'Normal';
  }
  Color _getBloodPressureColor(String category) {
    switch (category) {
      case 'Hipertensi Derajat 2': return Colors.red.shade900; // Darker Red
      case 'Hipertensi Derajat 1': return Colors.red.shade600;
      case 'Pra-hipertensi': return Colors.orange.shade700;
      case 'Hipotensi': return Colors.blue.shade600; // Blue for low
      case 'Normal': return Colors.green.shade700; // Darker Green
      default: return Colors.grey.shade600; // Default grey
    }
  }
  String _getBloodSugarCategory(int sugar) {
     if (sugar <= 0) return 'N/A';
    // Assuming 'sewaktu' (random) blood sugar levels from image_bb3438.jpg
    if (sugar >= 200) return 'Diabetes';
    if (sugar >= 140) return 'Pradiabetes';
    if (sugar < 70) return 'Hipoglikemia'; // Added low sugar category
    return 'Normal';
  }
  Color _getBloodSugarColor(String category) {
    switch (category) {
      case 'Diabetes': return Colors.red.shade900;
      case 'Pradiabetes': return Colors.orange.shade700;
      case 'Hipoglikemia': return Colors.blue.shade600; // Blue for low
      case 'Normal': return Colors.green.shade700;
      default: return Colors.grey.shade600;
    }
  }
  String _getUricAcidCategory(double value, String gender) {
     if (value <= 0) return 'N/A';
     // Ranges based on image_bb3438.jpg
    if (gender == 'Laki-laki') {
      if (value > 7.0) return 'Tinggi';
      if (value < 2.5) return 'Rendah';
    } else { // Assume Perempuan
      if (value > 6.0) return 'Tinggi';
      if (value < 1.5) return 'Rendah';
    }
    return 'Normal';
  }
  Color _getUricAcidColor(String category) {
    switch (category) {
      case 'Tinggi': return Colors.red.shade700;
      case 'Rendah': return Colors.blue.shade600; // Blue for low
      case 'Normal': return Colors.green.shade700;
      default: return Colors.grey.shade600;
    }
  }
  String _getWaistCategory(double value, String gender) {
      if (value <= 0) return 'N/A';
      // Ranges based on image_bb3438.jpg
     if (gender == 'Laki-laki') {
       if (value > 101.6) return 'Berlebih';
     } else { // Assume Perempuan
       if (value > 88.9) return 'Berlebih';
     }
     return 'Normal';
  }
   Color _getWaistColor(String category) {
    switch (category) {
      case 'Berlebih': return Colors.orange.shade700; // Orange for excess
      case 'Normal': return Colors.green.shade700;
      default: return Colors.grey.shade600;
    }
   }
   String _getCholesterolCategory(int value) {
      if (value <= 0) return 'N/A';
      // Range based on image_bb3438.jpg (Total Cholesterol)
     if (value >= 200) return 'Tinggi';
     // Could add borderline category (200-239) if needed
     return 'Normal'; // (< 200)
   }
    Color _getCholesterolColor(String category) {
     switch (category) {
       case 'Tinggi': return Colors.red.shade700;
       // Add borderline color if category exists
       case 'Normal': return Colors.green.shade700;
       default: return Colors.grey.shade600;
     }
   }

} // End _HomeScreenState class


/// Reusable widget to display a large health metric value with its unit and label.
class _HealthMetric extends StatelessWidget {
  final String value;
  final String unit;
  final String label;

  const _HealthMetric({required this.value, required this.unit, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      // Center align the metric elements
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Large value text using primary theme color
        Text(
            value,
            style: TextStyle(
                fontSize: 32, // Make value larger
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor
            )
        ),
        // Smaller unit text in grey
        Text(unit, style: TextStyle(fontSize: 13, color: Colors.grey[600])), // Slightly larger unit
        const SizedBox(height: 6), // Increase spacing
        // Label text
        Text(
            label,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87) // Slightly larger label
        ),
      ],
    );
  }
}