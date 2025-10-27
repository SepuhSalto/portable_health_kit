import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Charting library
import 'package:intl/intl.dart'; // For date formatting
import 'package:portable_health_kit/services/firestore_service.dart'; // Firestore service

// Enum to manage the time filter state for the chart
enum TimeFilter { all, day, week, month }

class PatientHistoryDetailScreen extends StatefulWidget {
  final String patientId;
  final String patientName;
  // Gender will be fetched internally now

  const PatientHistoryDetailScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<PatientHistoryDetailScreen> createState() =>
      _PatientHistoryDetailScreenState();
}

class _PatientHistoryDetailScreenState
    extends State<PatientHistoryDetailScreen> {
  // Instance of Firestore service to fetch data
  final FirestoreService _firestoreService = FirestoreService();

  // State variables to control chart line visibility
  bool _showSystolic = true;
  bool _showDiastolic = true;
  bool _showBloodSugar = true;
  bool _showUricAcid = false; // Initially off
  bool _showCholesterol = false;
  bool _showWaist = false;

  // State variable for the selected time filter
  TimeFilter _selectedFilter = TimeFilter.all;

  // Future to hold the result of fetching patient data (including gender)
  late Future<Map<String, dynamic>?> _patientDataFuture;

  @override
  void initState() {
    super.initState();
    // Fetch patient data when the screen initializes
    _patientDataFuture = _firestoreService.getPatientData(widget.patientId);
  }


  // --- Category Helper Functions (Used for list item status/color) ---

  String _getBloodPressureCategory(int systolic, int diastolic) {
    if (systolic <= 0 || diastolic <= 0) return 'N/A'; // Handle invalid/missing data
    if (systolic >= 140 || diastolic >= 90) return 'Hipertensi Derajat 2';
    if (systolic >= 130 || diastolic >= 80) return 'Hipertensi Derajat 1';
    if (systolic >= 120) return 'Pra-hipertensi';
    if (systolic < 90 || diastolic < 60) return 'Hipotensi'; // Low BP
    return 'Normal';
  }

  Color _getBloodPressureColor(String category) {
    switch (category) {
      case 'Hipertensi Derajat 2': return Colors.red.shade900;
      case 'Hipertensi Derajat 1': return Colors.red.shade600;
      case 'Pra-hipertensi': return Colors.orange.shade700;
      case 'Hipotensi': return Colors.blue.shade600;
      case 'Normal': return Colors.green.shade700;
      default: return Colors.grey.shade600;
    }
  }

  String _getBloodSugarCategory(int sugar) {
     if (sugar <= 0) return 'N/A';
    // Assuming 'sewaktu' (random) blood sugar levels from image_bb3438.jpg
    if (sugar >= 200) return 'Diabetes';
    if (sugar >= 140) return 'Pradiabetes';
    if (sugar < 70) return 'Hipoglikemia'; // Low sugar
    return 'Normal';
  }

  Color _getBloodSugarColor(String category) {
    switch (category) {
      case 'Diabetes': return Colors.red.shade900;
      case 'Pradiabetes': return Colors.orange.shade700;
      case 'Hipoglikemia': return Colors.blue.shade600;
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
      case 'Rendah': return Colors.blue.shade600;
      case 'Normal': return Colors.green.shade700;
      default: return Colors.grey.shade600;
    }
  }

   String _getCholesterolCategory(int value) {
       if (value <= 0) return 'N/A';
       // Range based on image_bb3438.jpg (Total Cholesterol)
       if (value >= 200) return 'Tinggi';
       // Could add borderline (200-239) if needed
       return 'Normal'; // (< 200)
     }

   Color _getCholesterolColor(String category) {
       switch (category) {
         case 'Tinggi': return Colors.red.shade700;
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
        case 'Berlebih': return Colors.orange.shade700;
        case 'Normal': return Colors.green.shade700;
        default: return Colors.grey.shade600;
      }
    }


  // --- Helper Functions for Chart Time Filter & Axis ---

  /// Calculates the start date based on the selected time filter.
  DateTime? _getStartDate(TimeFilter filter) {
    final now = DateTime.now();
    switch (filter) {
      case TimeFilter.day:
        return now.subtract(const Duration(days: 1));
      case TimeFilter.week:
        return now.subtract(const Duration(days: 7));
      case TimeFilter.month:
        return now.subtract(const Duration(days: 30));
      case TimeFilter.all:
      default:
        return null; // No filter
    }
  }

  /// Formats the labels for the bottom (X) axis of the chart (time).
  Widget _bottomTitleWidgets(double value, TitleMeta meta) {
    final DateTime date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
    String text;
    // Show time for daily view, date for others
    if (_selectedFilter == TimeFilter.day) {
      text = DateFormat('HH:mm').format(date);
    } else {
      text = DateFormat('d/M').format(date);
    }

    // Avoid drawing labels outside the axis range
    if (value <= meta.min || value >= meta.max) {
      return Container();
    }

    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 8.0,
      child: Text(text, style: const TextStyle(color: Color(0xff67727d), fontWeight: FontWeight.bold, fontSize: 10)),
    );
  }

  /// Formats the labels for the left (Y) axis of the chart (value).
  Widget _leftTitleWidgets(double value, TitleMeta meta) {
    // Show integer values
    const style = TextStyle(color: Color(0xff67727d), fontWeight: FontWeight.bold, fontSize: 11);
    // Avoid labels at the very top/bottom edge for cleaner look
    if (value == meta.max || value == meta.min) {
        return Container();
    }
    return Text(value.toInt().toString(), style: style, textAlign: TextAlign.right);
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Riwayat: ${widget.patientName}'),
        elevation: 1,
      ),
      // Use FutureBuilder to fetch patient data (including gender) first
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _patientDataFuture, // The future initiated in initState
        builder: (context, patientSnapshot) {
          // --- Handle Loading Patient Data ---
          if (patientSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // --- Handle Error Fetching Patient Data ---
          if (patientSnapshot.hasError || patientSnapshot.data == null) {
            print("History Detail Error fetching patient: ${patientSnapshot.error}");
             return Center(child: Padding(
                 padding: const EdgeInsets.all(20.0),
                 child: Text(
                     "Error memuat detail pasien.\n${patientSnapshot.error ?? 'Data tidak ditemukan'}",
                     style: TextStyle(color: Colors.red[700]),
                     textAlign: TextAlign.center
                 ),
             ));
          }

          // --- Patient Data Loaded Successfully ---
          final patientData = patientSnapshot.data!;
          // Get gender, provide a default ("Laki-laki") if missing
          final String patientGender = patientData['Gender'] as String? ?? "Laki-laki";
          print("History Detail: Using gender '$patientGender' for categories.");

          // --- Now use StreamBuilder for the Health Readings ---
          return StreamBuilder<QuerySnapshot>(
            stream: _firestoreService.getPatientHealthReadingsStream(widget.patientId),
            builder: (context, readingsSnapshot) {
              // --- Handle Readings Loading State ---
              if (readingsSnapshot.connectionState == ConnectionState.waiting) {
                // Show loading indicator but keep AppBar visible
                return const Center(child: CircularProgressIndicator());
              }
              // --- Handle Readings Stream Error ---
              if (readingsSnapshot.hasError) {
                print("History Detail Readings Stream Error: ${readingsSnapshot.error}");
                return Center(child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text("Error memuat riwayat bacaan: ${readingsSnapshot.error}", style: TextStyle(color: Colors.red[700]), textAlign: TextAlign.center),
                ));
              }
              // --- Handle No Readings Data State ---
              if (!readingsSnapshot.hasData || readingsSnapshot.data!.docs.isEmpty) {
                // Show normal ranges even if there's no history yet
                 return SingleChildScrollView(
                     padding: const EdgeInsets.all(16.0),
                     child: Column(
                       children: [
                         _buildNormalRangesTable(context),
                         const SizedBox(height: 40),
                         const Center(
                            child: Text(
                              'Belum ada riwayat pemeriksaan.',
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                          ),
                       ],
                     ),
                 );
              }

              // --- Process Readings Data ---
              final readings = readingsSnapshot.data!.docs;
              final DateTime? startDate = _getStartDate(_selectedFilter);

              // Filter readings based on timestamp
              final filteredReadings = readings.where((doc) {
                final data = doc.data() as Map<String, dynamic>?;
                if (data == null || data['Timestamp'] == null || !(data['Timestamp'] is Timestamp)) {
                  return false; // Skip invalid
                }
                final timestamp = (data['Timestamp'] as Timestamp).toDate();
                if (startDate == null) return true; // 'All'
                return timestamp.isAfter(startDate);
              }).toList();

              // --- Handle No Data in Selected Time Range ---
              if (filteredReadings.isEmpty) {
                return SingleChildScrollView( // Allow scrolling to see filters/table
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                          _buildNormalRangesTable(context), // Show table
                          const SizedBox(height: 24),
                          // Show an empty chart card structure
                          _buildChartCard(
                              context,
                              title: "Grafik Kesehatan",
                              chart: Container( // Placeholder content for empty chart
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Tidak ada data untuk grafik',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                              )
                          ),
                          // --- Time Filter Chips (Included) ---
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            child: Wrap(
                              spacing: 8.0,
                              children: TimeFilter.values.map((filter) {
                                  String label;
                                  switch (filter) {
                                      case TimeFilter.day: label = '24 Jam'; break;
                                      case TimeFilter.week: label = '7 Hari'; break;
                                      case TimeFilter.month: label = '30 Hari'; break;
                                      case TimeFilter.all: label = 'Semua'; break;
                                  }
                                  return ChoiceChip(
                                    label: Text(label),
                                    selected: _selectedFilter == filter,
                                    onSelected: (bool selected) {
                                      if (selected) setState(() { _selectedFilter = filter; });
                                    },
                                    selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                                    checkmarkColor: Theme.of(context).primaryColor,
                                    labelStyle: TextStyle(
                                        color: _selectedFilter == filter ? Theme.of(context).primaryColorDark : Colors.black54,
                                        fontWeight: _selectedFilter == filter ? FontWeight.bold : FontWeight.normal
                                    )
                                  );
                              }).toList(),
                            ),
                          ),
                          // --- Data Type Filter Chips (Included) ---
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 4.0,
                            children: [
                              FilterChip(label: const Text('Sistolik'), selected: _showSystolic, onSelected: (v){ setState(() => _showSystolic = v);}, selectedColor: Colors.blue[100], checkmarkColor: Colors.blue[800],),
                              FilterChip(label: const Text('Diastolik'), selected: _showDiastolic, onSelected: (v){ setState(() => _showDiastolic = v);}, selectedColor: Colors.red[100], checkmarkColor: Colors.red[800],),
                              FilterChip(label: const Text('Gula Darah'), selected: _showBloodSugar, onSelected: (v){ setState(() => _showBloodSugar = v);}, selectedColor: Theme.of(context).primaryColor.withOpacity(0.2), checkmarkColor: Theme.of(context).primaryColor,),
                              FilterChip(label: const Text('Asam Urat'), selected: _showUricAcid, onSelected: (v){ setState(() => _showUricAcid = v);}, selectedColor: Colors.purple[100], checkmarkColor: Colors.purple[800],),
                              FilterChip(label: const Text('Kolesterol'), selected: _showCholesterol, onSelected: (v){ setState(() => _showCholesterol = v);}, selectedColor: Colors.orange[100], checkmarkColor: Colors.orange[800],),
                              FilterChip(label: const Text('Lingkar Perut'), selected: _showWaist, onSelected: (v){ setState(() => _showWaist = v);}, selectedColor: Colors.teal[100], checkmarkColor: Colors.teal[800],),
                            ],
                          ),
                          const SizedBox(height: 40),
                          // --- Message ---
                          const Center(
                          child: Text(
                            'Tidak ada data dalam rentang waktu yang dipilih.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                );
              }

              // --- Data Processing for Charts and Lists ---
              final List<FlSpot> systolicSpots = [];
              final List<FlSpot> diastolicSpots = [];
              final List<FlSpot> bloodSugarSpots = [];
              final List<FlSpot> uricAcidSpots = [];
              final List<FlSpot> cholesterolSpots = [];
              final List<FlSpot> waistSpots = [];
              final List<DocumentSnapshot> bpReadings = [];
              final List<DocumentSnapshot> bsReadings = [];
              final List<DocumentSnapshot> uaReadings = [];
              final List<DocumentSnapshot> cholReadings = [];
              final List<DocumentSnapshot> waistReadings = [];

              double minYValue = double.infinity, maxYValue = double.negativeInfinity;
              double minX = double.infinity, maxX = double.negativeInfinity;
              bool dataFoundForChart = false;

              // Process oldest first for chart X-axis order
              for (int i = filteredReadings.length - 1; i >= 0; i--) {
                final readingDoc = filteredReadings[i];
                final reading = readingDoc.data() as Map<String, dynamic>;
                final timestamp = (reading['Timestamp'] as Timestamp).toDate();
                final double xValue = timestamp.millisecondsSinceEpoch.toDouble();
                dataFoundForChart = true;

                if (xValue < minX) minX = xValue;
                if (xValue > maxX) maxX = xValue;

                void updateYRange(double? val) { // Handle potential nulls safely
                    if (val == null) return;
                    if (val < minYValue) minYValue = val;
                    if (val > maxYValue) maxYValue = val;
                }

                // Populate Blood Pressure
                 if (reading['SystolicValue'] != null && reading['DiastolicValue'] != null) {
                   final double sysVal = (reading['SystolicValue'] as num).toDouble();
                   final double diaVal = (reading['DiastolicValue'] as num).toDouble();
                   systolicSpots.add(FlSpot(xValue, sysVal));
                   diastolicSpots.add(FlSpot(xValue, diaVal));
                   bpReadings.add(readingDoc);
                   updateYRange(sysVal); updateYRange(diaVal);
                 }
                // Populate Blood Sugar
                 if (reading['BloodSugarValue'] != null) {
                   final double val = (reading['BloodSugarValue'] as num).toDouble();
                   bloodSugarSpots.add(FlSpot(xValue, val));
                   bsReadings.add(readingDoc);
                   updateYRange(val);
                 }
                 // Populate Uric Acid
                 if (reading['UricAcidValue'] != null) {
                   final double val = (reading['UricAcidValue'] as num).toDouble();
                   uricAcidSpots.add(FlSpot(xValue, val));
                   uaReadings.add(readingDoc);
                   updateYRange(val);
                 }
                 // Populate Cholesterol
                 if (reading['CholesterolValue'] != null) {
                   final double val = (reading['CholesterolValue'] as num).toDouble();
                   cholesterolSpots.add(FlSpot(xValue, val));
                   cholReadings.add(readingDoc);
                   updateYRange(val);
                 }
                 // Populate Waist Circumference
                 if (reading['WaistCircumferenceValue'] != null) {
                   final double val = (reading['WaistCircumferenceValue'] as num).toDouble();
                   waistSpots.add(FlSpot(xValue, val));
                   waistReadings.add(readingDoc);
                   updateYRange(val);
                 }
              } // End data processing loop

              // --- Refine Axis Bounds ---
              if (!dataFoundForChart) {
                  // Fallback if loop somehow didn't find data (should be caught earlier)
                  return const Center(child: Text("Tidak ada data valid untuk ditampilkan."));
              }
              // Calculate final Y bounds with padding, ensuring min is not negative
              double finalMinY = 0;
              double finalMaxY = 250; // Default max
              if (minYValue != double.infinity && maxYValue != double.negativeInfinity && minYValue <= maxYValue) {
                  double yRange = maxYValue - minYValue;
                  // Add 10% padding top and bottom, but ensure min stays >= 0
                  finalMinY = (minYValue - yRange * 0.1).clamp(0, double.infinity);
                  finalMaxY = maxYValue + yRange * 0.1;
                  // Ensure a minimum range (e.g., 20 units) if values are very close
                  if (finalMaxY - finalMinY < 20) finalMaxY = finalMinY + 20;
              } else if (maxYValue != double.negativeInfinity) { // Handle single Y value case
                   finalMinY = (maxYValue - 10).clamp(0, double.infinity);
                   finalMaxY = maxYValue + 10;
              }


              // Ensure minX and maxX define a valid range, adding padding
              if (minX >= maxX) {
                 final centerTime = dataFoundForChart ? minX : DateTime.now().millisecondsSinceEpoch.toDouble();
                 minX = centerTime - const Duration(hours: 1).inMilliseconds;
                 maxX = centerTime + const Duration(hours: 1).inMilliseconds;
              } else {
                 double xPadding = (maxX - minX) * 0.05; // 5% padding
                 // Avoid zero padding if range is tiny
                 if (xPadding == 0) xPadding = const Duration(minutes: 30).inMilliseconds.toDouble();
                 minX -= xPadding;
                 maxX += xPadding;
              }

              // --- Build UI with Processed Data ---
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildNormalRangesTable(context), // Reference table
                    const SizedBox(height: 24),
                    _buildChartCard( // Chart display
                      context,
                      title: 'Grafik Kesehatan',
                      chart: _buildCombinedChart(
                          context,
                          systolicSpots, diastolicSpots, bloodSugarSpots,
                          uricAcidSpots, cholesterolSpots, waistSpots,
                          minX, maxX, finalMinY, finalMaxY // Pass refined bounds
                      ),
                    ),
                    // Time Filter Chips
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Wrap(
                        spacing: 8.0,
                        children: TimeFilter.values.map((filter) {
                            String label;
                            switch (filter) {
                                case TimeFilter.day: label = '24 Jam'; break;
                                case TimeFilter.week: label = '7 Hari'; break;
                                case TimeFilter.month: label = '30 Hari'; break;
                                case TimeFilter.all: label = 'Semua'; break;
                            }
                            return ChoiceChip(
                               label: Text(label),
                               selected: _selectedFilter == filter,
                               onSelected: (bool selected) {
                                 if (selected) setState(() { _selectedFilter = filter; });
                               },
                               selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                               checkmarkColor: Theme.of(context).primaryColor,
                               labelStyle: TextStyle(
                                  color: _selectedFilter == filter ? Theme.of(context).primaryColorDark : Colors.black54,
                                  fontWeight: _selectedFilter == filter ? FontWeight.bold : FontWeight.normal
                               )
                            );
                        }).toList(),
                      ),
                    ),
                    // Data Type Filter Chips
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: [
                        FilterChip(label: const Text('Sistolik'), selected: _showSystolic, onSelected: (v){ setState(() => _showSystolic = v);}, selectedColor: Colors.blue[100], checkmarkColor: Colors.blue[800],),
                        FilterChip(label: const Text('Diastolik'), selected: _showDiastolic, onSelected: (v){ setState(() => _showDiastolic = v);}, selectedColor: Colors.red[100], checkmarkColor: Colors.red[800],),
                        FilterChip(label: const Text('Gula Darah'), selected: _showBloodSugar, onSelected: (v){ setState(() => _showBloodSugar = v);}, selectedColor: Theme.of(context).primaryColor.withOpacity(0.2), checkmarkColor: Theme.of(context).primaryColor,),
                        FilterChip(label: const Text('Asam Urat'), selected: _showUricAcid, onSelected: (v){ setState(() => _showUricAcid = v);}, selectedColor: Colors.purple[100], checkmarkColor: Colors.purple[800],),
                        FilterChip(label: const Text('Kolesterol'), selected: _showCholesterol, onSelected: (v){ setState(() => _showCholesterol = v);}, selectedColor: Colors.orange[100], checkmarkColor: Colors.orange[800],),
                        FilterChip(label: const Text('Lingkar Perut'), selected: _showWaist, onSelected: (v){ setState(() => _showWaist = v);}, selectedColor: Colors.teal[100], checkmarkColor: Colors.teal[800],),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // --- History Lists Section (Pass gender) ---
                    _buildHistorySection(context, title: 'Riwayat Tekanan Darah', readings: bpReadings.reversed.toList(), type: 'BP', gender: patientGender),
                    const SizedBox(height: 24),
                    _buildHistorySection(context, title: 'Riwayat Gula Darah', readings: bsReadings.reversed.toList(), type: 'BS', gender: patientGender),
                    const SizedBox(height: 24),
                    _buildHistorySection(context, title: 'Riwayat Asam Urat', readings: uaReadings.reversed.toList(), type: 'UA', gender: patientGender),
                    const SizedBox(height: 24),
                    _buildHistorySection(context, title: 'Riwayat Kolesterol', readings: cholReadings.reversed.toList(), type: 'CHOL', gender: patientGender),
                    const SizedBox(height: 24),
                    _buildHistorySection(context, title: 'Riwayat Lingkar Perut', readings: waistReadings.reversed.toList(), type: 'WAIST', gender: patientGender),
                  ],
                ),
              );
            }, // End Readings StreamBuilder builder
          ); // End Readings StreamBuilder
        }, // End Patient FutureBuilder builder
      ), // End Patient FutureBuilder
    ); // End Scaffold
  } // End build method


  // --- Chart Building Widgets ---

  /// Builds the combined line chart widget using provided data and bounds.
  Widget _buildCombinedChart(
    BuildContext context,
    List<FlSpot> systolicSpots, List<FlSpot> diastolicSpots, List<FlSpot> bloodSugarSpots,
    List<FlSpot> uricAcidSpots, List<FlSpot> cholesterolSpots, List<FlSpot> waistSpots,
    double minX, double maxX, double minY, double maxY,
  ) {
    // Determine Y-axis interval based on calculated range
    double yRange = maxY - minY;
    // Ensure yRange is positive to avoid division by zero or negative interval
    if (yRange <= 0) yRange = 50; // Default range if calculation fails
    double yInterval = (yRange / 5).clamp(5.0, 50.0); // Aim for ~5 labels, clamp interval
    yInterval = (yInterval / 5).round() * 5.0; // Round to nearest 5
    if (yInterval == 0) yInterval = 10; // Prevent zero interval

    // Determine X-axis interval based on calculated range and selected time filter
    final double timeRange = maxX - minX;
    double xInterval;
    // Adjust interval for better label density based on the time span shown
     if (_selectedFilter == TimeFilter.day && timeRange > 0) {
        xInterval = timeRange / 4; // More labels for 24h view (e.g., every 6 hours)
     } else if (_selectedFilter == TimeFilter.week && timeRange > 0) {
         xInterval = timeRange / 6; // Labels roughly daily
     } else if (timeRange > 0){
         xInterval = timeRange / 5; // Fewer labels for month/all
     } else {
         xInterval = const Duration(hours: 6).inMilliseconds.toDouble(); // Default interval if range is zero
     }
    // Prevent zero interval
    if (xInterval <= 0) xInterval = const Duration(hours: 6).inMilliseconds.toDouble();


    return LineChart(
      LineChartData(
        // --- Grid ---
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: yInterval, // Align horizontal lines with Y labels
          verticalInterval: xInterval / 2, // Finer vertical grid (optional)
          getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade300, strokeWidth: 0.5),
          getDrawingVerticalLine: (value) => FlLine(color: Colors.grey.shade300, strokeWidth: 0.5),
        ),
        // --- Axis Titles ---
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          // Bottom (X) axis - Time
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32, // Space for labels
              interval: xInterval, // Use calculated interval
              getTitlesWidget: _bottomTitleWidgets, // Formatting function
            ),
          ),
          // Left (Y) axis - Value
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: yInterval, // Use calculated interval
              getTitlesWidget: _leftTitleWidgets, // Formatting function
              reservedSize: 45, // Wider space for labels like '100', '200'
            ),
          ),
        ),
        // --- Border ---
        borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey.shade400, width: 1) // Visible border
        ),
        // --- Axis Limits ---
        minX: minX, maxX: maxX, minY: minY, maxY: maxY, // Use calculated bounds
        // --- Data Lines ---
        lineBarsData: [
          // Conditionally add lines based on toggle state and if data exists
          if (_showSystolic && systolicSpots.isNotEmpty) _lineBarData(systolicSpots, Colors.blue, 'Sistolik'),
          if (_showDiastolic && diastolicSpots.isNotEmpty) _lineBarData(diastolicSpots, Colors.red, 'Diastolik'),
          if (_showBloodSugar && bloodSugarSpots.isNotEmpty) _lineBarData(bloodSugarSpots, Theme.of(context).primaryColor, 'Gula Darah'),
          if (_showUricAcid && uricAcidSpots.isNotEmpty) _lineBarData(uricAcidSpots, Colors.purple, 'Asam Urat'),
          if (_showCholesterol && cholesterolSpots.isNotEmpty) _lineBarData(cholesterolSpots, Colors.orange, 'Kolesterol'),
          if (_showWaist && waistSpots.isNotEmpty) _lineBarData(waistSpots, Colors.teal, 'Lingkar Perut'),
        ],
        // --- Tooltip Customization ---
        lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (touchedSpot) => Colors.blueGrey.shade800.withOpacity(0.9), // Darker background
                 getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                    // Map each touched spot to a tooltip item
                    return touchedBarSpots.map((barSpot) {
                      final flSpot = barSpot;
                      // Determine line name based on color (or pass name differently if needed)
                      String lineName = '';
                       if (barSpot.bar.color == Colors.blue) lineName = 'Sistolik';
                       else if (barSpot.bar.color == Colors.red) lineName = 'Diastolik';
                       else if (barSpot.bar.color == Theme.of(context).primaryColor) lineName = 'Gula Darah';
                       else if (barSpot.bar.color == Colors.purple) lineName = 'Asam Urat';
                       else if (barSpot.bar.color == Colors.orange) lineName = 'Kolesterol';
                       else if (barSpot.bar.color == Colors.teal) lineName = 'L. Perut';

                      // Format timestamp from X value
                      final dt = DateTime.fromMillisecondsSinceEpoch(flSpot.x.toInt());
                      final timeStr = DateFormat('d/M HH:mm').format(dt);

                      // Create the tooltip item with name, value, and time
                      return LineTooltipItem(
                        '$lineName: ${flSpot.y.toStringAsFixed(1)}\n', // Value (1 decimal place)
                        TextStyle(color: barSpot.bar.color ?? Colors.white, fontWeight: FontWeight.bold),
                         children: [ // Add timestamp as a smaller second line
                            TextSpan(
                               text: timeStr,
                               style: TextStyle( color: Colors.grey[400], fontSize: 10, fontWeight: FontWeight.normal),
                             ),
                          ]
                      );
                    }).toList();
                  }
            ),
             handleBuiltInTouches: true, // Enable default tap/drag behaviors
        )
      ),
    );
  }

  /// Creates configuration for a single line on the chart.
  LineChartBarData _lineBarData(List<FlSpot> spots, Color color, String name) {
    return LineChartBarData(
      spots: spots, // Data points
      isCurved: true, // Smooth line
      color: color, // Line color
      barWidth: 2.5, // Line thickness
      isStrokeCapRound: true, // Rounded line ends
      dotData: const FlDotData(show: false), // Hide individual points
      belowBarData: BarAreaData( // Fill area below line
          show: true,
          gradient: LinearGradient(colors: [
            color.withOpacity(0.3), // Gradient fill
            color.withOpacity(0.0)
          ], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
    );
  }

  /// Builds the container Card for the chart.
  Widget _buildChartCard(BuildContext context, {required String title, required Widget chart}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Consistent rounding
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Chart title using theme style
            Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            // Chart widget container with fixed height
            SizedBox( height: 220, child: chart ),
          ],
        ),
      ),
    );
  }

  // --- History List Building Widgets ---

  /// Builds a section containing a title and a list of history items for a specific data type.
  Widget _buildHistorySection(BuildContext context, {required String title, required List<DocumentSnapshot> readings, required String type, required String gender}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title using theme style
        Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        // Message if no readings for this type
        if (readings.isEmpty)
          const Card(elevation: 1, child: Padding(padding: EdgeInsets.all(16.0), child: Center(child: Text('Tidak ada data.', style: TextStyle(color: Colors.grey)))))
        // Build list if readings exist
        else
          ListView.builder(
            // Prevent nested scrolling issues
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: readings.length,
            itemBuilder: (context, index) {
              // Safely extract data and timestamp
              final readingData = readings[index].data() as Map<String, dynamic>?;
              final timestamp = (readingData?['Timestamp'] as Timestamp?)?.toDate();
              final dateStr = timestamp != null
                ? DateFormat('EEE, d MMM yyyy, HH:mm', 'id_ID').format(timestamp)
                : 'Tanggal tidak diketahui';

              // Handle cases where data might be malformed
              if (readingData == null) {
                  return Card(child: ListTile(title: Text('Data tidak valid [$index]')));
              }

              // --- Build list item based on data type ---
              switch (type) {
                case 'BP':
                  final int systolic = (readingData['SystolicValue'] as num?)?.toInt() ?? 0;
                  final int diastolic = (readingData['DiastolicValue'] as num?)?.toInt() ?? 0;
                  final status = _getBloodPressureCategory(systolic, diastolic);
                  final color = _getBloodPressureColor(status);
                  return _buildHistoryItem( date: dateStr, icon: Icons.monitor_heart_outlined, iconColor: Colors.red.shade400,
                      valueText: 'TD: $systolic / $diastolic mmHg', statusText: status, statusColor: color,);
                case 'BS':
                  final int value = (readingData['BloodSugarValue'] as num?)?.toInt() ?? 0;
                  final status = _getBloodSugarCategory(value);
                  final color = _getBloodSugarColor(status);
                   return _buildHistoryItem( date: dateStr, icon: Icons.bloodtype_outlined, iconColor: Colors.orange.shade700,
                      valueText: 'Gula Darah: $value mg/dL', statusText: status, statusColor: color,);
                case 'UA':
                  final double value = (readingData['UricAcidValue'] as num?)?.toDouble() ?? 0.0;
                  final status = _getUricAcidCategory(value, gender); // Use passed gender
                  final color = _getUricAcidColor(status);
                   return _buildHistoryItem( date: dateStr, icon: Icons.science_outlined, iconColor: Colors.purple.shade400,
                      valueText: 'Asam Urat: ${value.toStringAsFixed(1)} mg/dL', statusText: status, statusColor: color,);
                case 'CHOL':
                  final int value = (readingData['CholesterolValue'] as num?)?.toInt() ?? 0;
                  final status = _getCholesterolCategory(value);
                  final color = _getCholesterolColor(status);
                   return _buildHistoryItem( date: dateStr, icon: Icons.opacity_outlined, iconColor: Colors.blueGrey.shade400,
                      valueText: 'Kolesterol: $value mg/dL', statusText: status, statusColor: color,);
                case 'WAIST':
                   final double value = (readingData['WaistCircumferenceValue'] as num?)?.toDouble() ?? 0.0;
                   final status = _getWaistCategory(value, gender); // Use passed gender
                   final color = _getWaistColor(status);
                   return _buildHistoryItem( date: dateStr, icon: Icons.square_foot_outlined, iconColor: Colors.teal.shade400,
                      valueText: 'L. Perut: ${value.toStringAsFixed(1)} cm', statusText: status, statusColor: color,);
                default:
                  return const SizedBox.shrink(); // Hide if type is unknown
              }
            },
          ),
      ],
    );
  }

  /// Builds a single history item Card widget for the lists.
  Widget _buildHistoryItem(
      {required String date, required IconData icon, required Color iconColor, required String valueText, required String statusText, required Color statusColor}) {
        return Card(
      elevation: 1.5,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date display
            Text(date, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: Colors.grey[700])), // Adjusted style
            const Divider(height: 16, thickness: 0.5),
            // Row containing icon, value, and status chip
            Row(
              children: [
                Icon(icon, color: iconColor, size: 28), // Icon
                const SizedBox(width: 16),
                // Value text (takes available space)
                Expanded(child: Text(valueText, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 15))),
                // Status chip (only shown if status is not 'N/A')
                if (statusText != 'N/A')
                   Chip(
                     label: Text( statusText, style: const TextStyle( color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                     backgroundColor: statusColor, // Color based on status
                     padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                     materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, // Compact size
                     visualDensity: VisualDensity.compact,
                   )
                 else
                   const SizedBox.shrink(), // Don't show chip if status is N/A
              ],
            ),
          ],
        ),
      ),
    );
   }


  // --- Normal Ranges Table Widgets ---

  /// Builds the Card containing the normal reference values table.
  Widget _buildNormalRangesTable(BuildContext context) {
     return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      color: Theme.of(context).scaffoldBackgroundColor, // Match background
      elevation: 0, // No shadow
      shape: RoundedRectangleBorder(
           borderRadius: BorderRadius.circular(12),
           side: BorderSide(color: Colors.grey.shade300) // Subtle border
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0), // Adjusted padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Table Title
            Text(
              'Nilai Normal Referensi',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColorDark, // Use darker primary color
              ),
            ),
            const Divider(height: 16, thickness: 0.5), // Thinner divider
            // Rows for each reference value
            _buildNormalRangeRow(context, 'Asam Urat', 'Pria: 2,5–7,0 mg/dL\nWanita: 1,5–6,0 mg/dL'),
            _buildNormalRangeRow(context, 'Kolesterol', '< 200 mg/dL (Total)'),
            _buildNormalRangeRow(context, 'Gula Darah', 'Sewaktu: < 200 mg/dL'),
            _buildNormalRangeRow(context, 'Tekanan Darah', 'Optimal: < 120/80 mmHg'),
            _buildNormalRangeRow(context, 'Lingkar Perut', 'Pria: Max 101,6 cm\nWanita: Max 88,9 cm'),
          ],
        ),
      ),
    );
  }

  /// Builds a single row within the normal ranges table (Label + Value).
  Widget _buildNormalRangeRow(BuildContext context, String label, String value) {
     return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Align top if value wraps
        children: [
          // Label (fixed width)
          SizedBox(
            width: 110, // Consistent width for alignment
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: Colors.black87),
            ),
          ),
          const SizedBox(width: 10), // Space
          // Value (takes remaining space)
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

} // End _PatientHistoryDetailScreenState class