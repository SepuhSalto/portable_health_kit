import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Charting library
import 'package:intl/intl.dart'; // For date formatting
import 'package:portable_health_kit/services/firestore_service.dart'; // Firestore service
import 'dart:math'; // For max function

// Enum to manage the time filter state for the chart
enum TimeFilter { all, day, week, month }

class PatientHistoryDetailScreen extends StatefulWidget {
  final String patientId;
  final String patientName;

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

  // State variables for chart line visibility
  bool _showSystolic = true;
  bool _showDiastolic = true;
  bool _showBloodSugar = true;
  bool _showUricAcid = false;
  bool _showCholesterol = false;
  bool _showWaist = false;

  // State variable for the selected time filter
  TimeFilter _selectedFilter = TimeFilter.all;

  // Future to hold the result of fetching patient data (including gender)
  late Future<Map<String, dynamic>?> _patientDataFuture;

  // *** NEW: State for interactive chart boundaries ***
  FlSpot? _touchedSpot; // To potentially highlight touched spot

  @override
  void initState() {
    super.initState();
    // Fetch patient data when the screen initializes
    _patientDataFuture = _firestoreService.getPatientData(widget.patientId);
  }


  // --- Category Helper Functions ---
  // (Includes _getBloodPressureCategory, _getBloodPressureColor, etc...)
  String _getBloodPressureCategory(int systolic, int diastolic) {
    if (systolic <= 0 || diastolic <= 0) return 'N/A';
    if (systolic >= 140 || diastolic >= 90) return 'Hipertensi Derajat 2';
    if (systolic >= 130 || diastolic >= 80) return 'Hipertensi Derajat 1';
    if (systolic >= 120) return 'Pra-hipertensi';
    if (systolic < 90 || diastolic < 60) return 'Hipotensi';
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
    if (sugar >= 200) return 'Diabetes';
    if (sugar >= 140) return 'Pradiabetes';
    if (sugar < 70) return 'Hipoglikemia';
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
       if (value >= 200) return 'Tinggi';
       return 'Normal';
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
      case TimeFilter.day: return now.subtract(const Duration(days: 1));
      case TimeFilter.week: return now.subtract(const Duration(days: 7));
      case TimeFilter.month: return now.subtract(const Duration(days: 30));
      default: return null;
    }
  }

  /// Formats the labels for the bottom (X) axis of the chart (time).
  Widget _bottomTitleWidgets(double value, TitleMeta meta) {
    final DateTime date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
    String text;
    // Show HH:mm for daily, d/M otherwise, adjust format based on total range if needed
    final double totalRange = meta.max - meta.min;
    if (_selectedFilter == TimeFilter.day || totalRange < const Duration(days: 2).inMilliseconds) {
      text = DateFormat('HH:mm').format(date);
    } else {
      text = DateFormat('d/M').format(date);
    }
    // Avoid drawing labels outside the visible axis range
    if (value < meta.min || value > meta.max) { return Container(); } // Check strict bounds

    return SideTitleWidget( axisSide: meta.axisSide, space: 8.0,
      child: Text(text, style: const TextStyle(color: Color(0xff67727d), fontWeight: FontWeight.bold, fontSize: 10)), );
  }

  /// Formats the labels for the left (Y) axis of the chart (value).
  Widget _leftTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(color: Color(0xff67727d), fontWeight: FontWeight.bold, fontSize: 11);
    // Avoid labels exactly on edges
    if (value == meta.max || value == meta.min) { return Container(); }
    // Format to integer
    return Text(value.toInt().toString(), style: style, textAlign: TextAlign.right);
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar( title: Text('Riwayat: ${widget.patientName}'), elevation: 1, ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _patientDataFuture,
        builder: (context, patientSnapshot) {
          // --- Handle Loading/Error for Patient Data ---
          if (patientSnapshot.connectionState == ConnectionState.waiting) { return const Center(child: CircularProgressIndicator()); }
          if (patientSnapshot.hasError || patientSnapshot.data == null) { return Center(child: Text("Error memuat detail pasien: ${patientSnapshot.error ?? 'Data tidak ditemukan'}")); }

          // --- Patient Data Loaded ---
          final patientData = patientSnapshot.data!;
          final String patientGender = patientData['Gender'] as String? ?? "Laki-laki";

          // --- StreamBuilder for Health Readings ---
          return StreamBuilder<QuerySnapshot>(
            stream: _firestoreService.getPatientHealthReadingsStream(widget.patientId),
            builder: (context, readingsSnapshot) {
              // --- Handle Loading/Error/No Data for Readings ---
              if (readingsSnapshot.connectionState == ConnectionState.waiting) { return const Center(child: CircularProgressIndicator()); }
              if (readingsSnapshot.hasError) { return Center(child: Text("Error memuat riwayat bacaan: ${readingsSnapshot.error}")); }
              // Handle no readings (show table and filters)
              if (!readingsSnapshot.hasData || readingsSnapshot.data!.docs.isEmpty) {
                 return SingleChildScrollView( padding: const EdgeInsets.all(16.0), child: Column( children: [ _buildNormalRangesTable(context), const SizedBox(height: 40), const Center( child: Text( 'Belum ada riwayat pemeriksaan.', style: TextStyle(fontSize: 18, color: Colors.grey), ), ), ], ), );
              }

              // --- Process Readings Data ---
              final readings = readingsSnapshot.data!.docs;
              final DateTime? startDate = _getStartDate(_selectedFilter);
              final filteredReadings = readings.where((doc) {
                    final data = doc.data() as Map<String, dynamic>?; if (data == null || data['Timestamp'] == null || !(data['Timestamp'] is Timestamp)) { return false; }
                    final timestamp = (data['Timestamp'] as Timestamp).toDate(); if (startDate == null) return true; return timestamp.isAfter(startDate);
               }).toList();

              // --- Handle No Data in Selected Time Range ---
              if (filteredReadings.isEmpty) {
                 return SingleChildScrollView( padding: const EdgeInsets.all(16.0), child: Column( crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _buildNormalRangesTable(context), const SizedBox(height: 24),
                      _buildChartCard( context, title: "Grafik Kesehatan", chart: Container( height: 220, alignment: Alignment.center, child: Text('Tidak ada data\ndalam rentang waktu ini.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])))),
                      // Show filters even when data is empty
                      Padding( padding: const EdgeInsets.symmetric(vertical: 12.0), child: Wrap( spacing: 8.0, children: TimeFilter.values.map((filter) { String label; switch (filter) { case TimeFilter.day: label = '24 Jam'; break; case TimeFilter.week: label = '7 Hari'; break; case TimeFilter.month: label = '30 Hari'; break; case TimeFilter.all: label = 'Semua'; break; } return ChoiceChip( label: Text(label), selected: _selectedFilter == filter, onSelected: (bool selected) { if (selected) setState(() { _selectedFilter = filter; }); }, /* Styles */ ); }).toList() ), ),
                      Wrap( spacing: 8.0, runSpacing: 4.0, children: [ FilterChip(label: const Text('Sistolik'), selected: _showSystolic, onSelected: (v){ setState(() => _showSystolic = v);}, /* Styles */), FilterChip(label: const Text('Diastolik'), selected: _showDiastolic, onSelected: (v){ setState(() => _showDiastolic = v);}, /* Styles */), FilterChip(label: const Text('Gula Darah'), selected: _showBloodSugar, onSelected: (v){ setState(() => _showBloodSugar = v);}, /* Styles */), FilterChip(label: const Text('Asam Urat'), selected: _showUricAcid, onSelected: (v){ setState(() => _showUricAcid = v);}, /* Styles */), FilterChip(label: const Text('Kolesterol'), selected: _showCholesterol, onSelected: (v){ setState(() => _showCholesterol = v);}, /* Styles */), FilterChip(label: const Text('Lingkar Perut'), selected: _showWaist, onSelected: (v){ setState(() => _showWaist = v);}, /* Styles */), ], ), ], ), );
              } // End if (filteredReadings.isEmpty)

              // --- Data Processing for Charts and Lists ---
              final List<FlSpot> systolicSpots = []; final List<FlSpot> diastolicSpots = []; final List<FlSpot> bloodSugarSpots = []; final List<FlSpot> uricAcidSpots = []; final List<FlSpot> cholesterolSpots = []; final List<FlSpot> waistSpots = [];
              final List<DocumentSnapshot> bpReadings = []; final List<DocumentSnapshot> bsReadings = []; final List<DocumentSnapshot> uaReadings = []; final List<DocumentSnapshot> cholReadings = []; final List<DocumentSnapshot> waistReadings = [];
              double minYValue = double.infinity, maxYValue = double.negativeInfinity; double minX = double.infinity, maxX = double.negativeInfinity; bool dataFoundForChart = false;

              // Process oldest first for correct chart order
              for (int i = filteredReadings.length - 1; i >= 0; i--) {
                final readingDoc = filteredReadings[i]; final reading = readingDoc.data() as Map<String, dynamic>; final timestamp = (reading['Timestamp'] as Timestamp).toDate(); final double xValue = timestamp.millisecondsSinceEpoch.toDouble();
                dataFoundForChart = true;
                if (xValue < minX) minX = xValue; if (xValue > maxX) maxX = xValue;
                void updateYRange(double? val) { if (val == null) return; if (val < minYValue) minYValue = val; if (val > maxYValue) maxYValue = val; }
                 if (reading['SystolicValue'] != null && reading['DiastolicValue'] != null) { final double sysVal = (reading['SystolicValue'] as num).toDouble(); final double diaVal = (reading['DiastolicValue'] as num).toDouble(); systolicSpots.add(FlSpot(xValue, sysVal)); diastolicSpots.add(FlSpot(xValue, diaVal)); bpReadings.add(readingDoc); updateYRange(sysVal); updateYRange(diaVal); }
                 if (reading['BloodSugarValue'] != null) { final double val = (reading['BloodSugarValue'] as num).toDouble(); bloodSugarSpots.add(FlSpot(xValue, val)); bsReadings.add(readingDoc); updateYRange(val); }
                 if (reading['UricAcidValue'] != null) { final double val = (reading['UricAcidValue'] as num).toDouble(); uricAcidSpots.add(FlSpot(xValue, val)); uaReadings.add(readingDoc); updateYRange(val); }
                 if (reading['CholesterolValue'] != null) { final double val = (reading['CholesterolValue'] as num).toDouble(); cholesterolSpots.add(FlSpot(xValue, val)); cholReadings.add(readingDoc); updateYRange(val); }
                 if (reading['WaistCircumferenceValue'] != null) { final double val = (reading['WaistCircumferenceValue'] as num).toDouble(); waistSpots.add(FlSpot(xValue, val)); waistReadings.add(readingDoc); updateYRange(val); }
              } // End data processing loop

              // --- Refine Axis Bounds ---
              if (!dataFoundForChart) { return const Center(child: Text("Tidak ada data valid.")); }
              // Y bounds
              double finalMinY = 0; double finalMaxY = 250;
              if (minYValue != double.infinity && maxYValue != double.negativeInfinity && minYValue <= maxYValue) { double yRange = maxYValue - minYValue; if (yRange == 0) yRange = 20; finalMinY = max(0, minYValue - yRange * 0.1); finalMaxY = maxYValue + yRange * 0.1; if (finalMaxY - finalMinY < 20) finalMaxY = finalMinY + 20; }
              else if (maxYValue != double.negativeInfinity) { finalMinY = max(0, maxYValue - 10); finalMaxY = maxYValue + 10; }

              // X bounds - Refined Padding
              if (minX >= maxX) { final centerTime = dataFoundForChart ? minX : DateTime.now().millisecondsSinceEpoch.toDouble(); minX = centerTime - const Duration(hours: 1).inMilliseconds; maxX = centerTime + const Duration(hours: 1).inMilliseconds; }
              else {
                 double timeRange = maxX - minX;
                 // Use smaller padding for longer time ranges to avoid squishing recent data
                 double xPadding = timeRange > const Duration(days: 7).inMilliseconds.toDouble()
                                    ? timeRange * 0.01 // 1% for long ranges
                                    : timeRange * 0.05; // 5% for shorter ranges
                 if (xPadding == 0) xPadding = const Duration(minutes: 15).inMilliseconds.toDouble();
                 minX -= xPadding;
                 maxX += xPadding;
              }


              // --- Build UI ---
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
                      // Pass data and refined bounds to the chart builder
                      chart: _buildCombinedChart( context, systolicSpots, diastolicSpots, bloodSugarSpots, uricAcidSpots, cholesterolSpots, waistSpots, minX, maxX, finalMinY, finalMaxY ),
                    ),
                    // Time Filter Chips
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Wrap( spacing: 8.0, children: TimeFilter.values.map((filter) {
                          String label; switch (filter) { case TimeFilter.day: label = '24 Jam'; break; case TimeFilter.week: label = '7 Hari'; break; case TimeFilter.month: label = '30 Hari'; break; case TimeFilter.all: label = 'Semua'; break; }
                          return ChoiceChip( label: Text(label), selected: _selectedFilter == filter, onSelected: (bool selected) { if (selected) setState(() { _selectedFilter = filter; }); }, selectedColor: Theme.of(context).primaryColor.withOpacity(0.2), checkmarkColor: Theme.of(context).primaryColor, labelStyle: TextStyle( color: _selectedFilter == filter ? Theme.of(context).primaryColorDark : Colors.black54, fontWeight: _selectedFilter == filter ? FontWeight.bold : FontWeight.normal) );
                       }).toList() ),
                    ),
                    // Data Type Filter Chips
                    Wrap( spacing: 8.0, runSpacing: 4.0, children: [
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
                    // Show lists newest first by reversing the collected lists
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

  /// Builds the combined line chart widget with interactive features.
  Widget _buildCombinedChart( BuildContext context, List<FlSpot> systolicSpots, List<FlSpot> diastolicSpots, List<FlSpot> bloodSugarSpots, List<FlSpot> uricAcidSpots, List<FlSpot> cholesterolSpots, List<FlSpot> waistSpots, double minX, double maxX, double minY, double maxY, ) {
    // --- Y Interval Calculation ---
    double yRange = maxY - minY; if (yRange <= 0) yRange = 50;
    double yInterval = (yRange / 5).clamp(5.0, 50.0);
    yInterval = (yInterval / 5).round() * 5.0; if (yInterval == 0) yInterval = 10;

    // --- X Interval Calculation ---
    final double timeRange = maxX - minX; double xInterval;
     if (timeRange <= 0) { xInterval = const Duration(hours: 6).inMilliseconds.toDouble(); }
     else if (_selectedFilter == TimeFilter.day) { xInterval = timeRange / 4; } // ~ every 6 hours
     else if (_selectedFilter == TimeFilter.week) { xInterval = timeRange / 6; } // ~ daily
     else { xInterval = timeRange / 5; } // ~ 5-6 labels for longer ranges
    if (xInterval <= 0) xInterval = const Duration(hours: 6).inMilliseconds.toDouble();


    return LineChart(
      LineChartData(
        // *** ENABLE CLIPPING ***
        clipData: const FlClipData.all(), // Clip line/dot drawing to chart boundaries

        // --- Grid ---
        gridData: FlGridData( show: true, drawVerticalLine: true, horizontalInterval: yInterval, verticalInterval: xInterval / 2, getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade300, strokeWidth: 0.5), getDrawingVerticalLine: (value) => FlLine(color: Colors.grey.shade300, strokeWidth: 0.5), ),
        // --- Axis Titles ---
        titlesData: FlTitlesData( show: true, rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles( sideTitles: SideTitles( showTitles: true, reservedSize: 32, interval: xInterval, getTitlesWidget: _bottomTitleWidgets, ), ),
          leftTitles: AxisTitles( sideTitles: SideTitles( showTitles: true, interval: yInterval, getTitlesWidget: _leftTitleWidgets, reservedSize: 45, ), ),
        ),
        // --- Border ---
        borderData: FlBorderData( show: true, border: Border.all(color: Colors.grey.shade400, width: 1) ),
        // --- Axis Limits ---
        minX: minX, maxX: maxX, minY: minY, maxY: maxY, // Use calculated bounds
        // --- Data Lines ---
        lineBarsData: [
          // --- Dotted Baseline at Y=0 ---
          _lineBarData( [FlSpot(minX, 0), FlSpot(maxX, 0)], Colors.grey.shade400, 'Zero', isDotted: true, showDots: false),

          // --- Actual Data Lines (Conditional, showDots: true) ---
          if (_showSystolic && systolicSpots.isNotEmpty) _lineBarData(systolicSpots, Colors.blue, 'Systolic', showDots: true),
          if (_showDiastolic && diastolicSpots.isNotEmpty) _lineBarData(diastolicSpots, Colors.red, 'Diastolic', showDots: true),
          if (_showBloodSugar && bloodSugarSpots.isNotEmpty) _lineBarData(bloodSugarSpots, Theme.of(context).primaryColor, 'Gula Darah', showDots: true),
          if (_showUricAcid && uricAcidSpots.isNotEmpty) _lineBarData(uricAcidSpots, Colors.purple, 'Asam Urat', showDots: true),
          if (_showCholesterol && cholesterolSpots.isNotEmpty) _lineBarData(cholesterolSpots, Colors.orange, 'Kolesterol', showDots: true),
          if (_showWaist && waistSpots.isNotEmpty) _lineBarData(waistSpots, Colors.teal, 'Lingkar Perut', showDots: true),
        ],
        // *** ENABLE TOUCH INTERACTIONS (ZOOM/PAN) ***
        lineTouchData: LineTouchData(
            enabled: true, // Enable touch interactions
            handleBuiltInTouches: true, // Use built-in pan/zoom
            touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
              // Optional: Handle specific touch events if needed (e.g., long press)
              // if (event is FlTapUpEvent && touchResponse?.lineBarSpots != null) {
              //    setState(() { _touchedSpot = touchResponse!.lineBarSpots!.first.spot; });
              // } else if (event is FlPanEndEvent) {
              //    setState(() { _touchedSpot = null; });
              // }
            },
            getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
               // Customize the indicator shown when touching a spot (optional)
              return spotIndexes.map((index) {
                return TouchedSpotIndicatorData(
                  FlLine(color: barData.color?.withOpacity(0.7) ?? Colors.blueAccent, strokeWidth: 3),
                  FlDotData( getDotPainter: (spot, percent, barData, index) =>
                      FlDotCirclePainter( radius: 6, color: barData.color ?? Colors.blueAccent, strokeWidth: 2, strokeColor: Colors.white, ),
                  ),
                );
              }).toList();
            },
            touchTooltipData: LineTouchTooltipData( // Tooltip config
                getTooltipColor: (touchedSpot) => Colors.blueGrey.shade800.withOpacity(0.9),
                 getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                    final dataSpots = touchedBarSpots.where((spot) => spot.bar.color != Colors.grey.shade400); // Filter out baseline
                    return dataSpots.map((barSpot) {
                       final flSpot = barSpot; String lineName = '';
                       // Determine line name based on color
                       if (barSpot.bar.color == Colors.blue) lineName = 'Sistolik';
                       else if (barSpot.bar.color == Colors.red) lineName = 'Diastolik';
                       else if (barSpot.bar.color == Theme.of(context).primaryColor) lineName = 'Gula Darah';
                       else if (barSpot.bar.color == Colors.purple) lineName = 'Asam Urat';
                       else if (barSpot.bar.color == Colors.orange) lineName = 'Kolesterol';
                       else if (barSpot.bar.color == Colors.teal) lineName = 'L. Perut';
                       else return null;

                      final dt = DateTime.fromMillisecondsSinceEpoch(flSpot.x.toInt());
                      final timeStr = DateFormat('d/M HH:mm').format(dt);

                      // Tooltip content: Name, Value, Time
                      return LineTooltipItem( '$lineName: ${flSpot.y.toStringAsFixed(1)}\n', TextStyle(color: barSpot.bar.color ?? Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                         children: [ TextSpan( text: timeStr, style: TextStyle( color: Colors.grey[400], fontSize: 10, fontWeight: FontWeight.normal), ), ]
                      );
                    }).whereType<LineTooltipItem>().toList();
                  }
            ),
        )
      ),
      // *** Add duration for animations when data changes ***
      // swapAnimationDuration: const Duration(milliseconds: 250), // Optional animation
      // swapAnimationCurve: Curves.linear, // Optional animation curve
    );
  }

  /// Creates configuration for a single line on the chart.
  /// Includes parameters for dot style and dotted line style.
  LineChartBarData _lineBarData(
      List<FlSpot> spots,
      Color color,
      String name,
      {bool isDotted = false, bool showDots = true} // Control dots and dash pattern
   ) {
    return LineChartBarData(
      spots: spots,
      isCurved: !isDotted,
      color: color,
      barWidth: isDotted ? 1.5 : 3.0, // Thicker lines for data
      isStrokeCapRound: !isDotted,
      // Configure dot appearance
      dotData: FlDotData(
        show: showDots, // Use parameter to control visibility
        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
          radius: 5.5, // *** INCREASED DOT RADIUS ***
          color: barData.color ?? Colors.blue, // Dot color matches line
          strokeWidth: 1.5, // White border around dot
          strokeColor: Colors.white,
        ),
        // Optional: Check if a dot is touched
        // checkToShowDot: (spot, barData) => spot == _touchedSpot, // Example: Only show touched dot
      ),
      dashArray: isDotted ? [3, 4] : null, // Dash pattern: 3 pixels line, 4 pixels gap
      belowBarData: BarAreaData( // Fill area below line
          show: !isDotted, // Don't fill below dotted line
          gradient: LinearGradient(colors: [ color.withOpacity(0.3), color.withOpacity(0.0) ], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
    );
  }

  /// Builds the container Card for the chart. (Unchanged)
  Widget _buildChartCard(BuildContext context, {required String title, required Widget chart}) {
     return Card( elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding( padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column( crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            // Use InteractiveViewer if built-in pan/zoom isn't sufficient (more complex setup)
            SizedBox( height: 220, child: chart ), ],
        ),
      ),
    );
  }

  // --- History List Building Widgets (Unchanged) ---
  Widget _buildHistorySection(BuildContext context, {required String title, required List<DocumentSnapshot> readings, required String type, required String gender}) {
     return Column( crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600)), const SizedBox(height: 12),
        if (readings.isEmpty) const Card(elevation: 1, child: Padding(padding: EdgeInsets.all(16.0), child: Center(child: Text('Tidak ada data.', style: TextStyle(color: Colors.grey)))))
        else ListView.builder( shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: readings.length,
            itemBuilder: (context, index) {
              final readingData = readings[index].data() as Map<String, dynamic>?; final timestamp = (readingData?['Timestamp'] as Timestamp?)?.toDate(); final dateStr = timestamp != null ? DateFormat('EEE, d MMM yyyy, HH:mm', 'id_ID').format(timestamp) : 'Tanggal tidak diketahui';
              if (readingData == null) { return Card(child: ListTile(title: Text('Data tidak valid [$index]'))); }
              switch (type) {
                case 'BP': final int systolic = (readingData['SystolicValue'] as num?)?.toInt() ?? 0; final int diastolic = (readingData['DiastolicValue'] as num?)?.toInt() ?? 0; final status = _getBloodPressureCategory(systolic, diastolic); final color = _getBloodPressureColor(status); return _buildHistoryItem( date: dateStr, icon: Icons.monitor_heart_outlined, iconColor: Colors.red.shade400, valueText: 'TD: $systolic / $diastolic mmHg', statusText: status, statusColor: color,);
                case 'BS': final int value = (readingData['BloodSugarValue'] as num?)?.toInt() ?? 0; final status = _getBloodSugarCategory(value); final color = _getBloodSugarColor(status); return _buildHistoryItem( date: dateStr, icon: Icons.bloodtype_outlined, iconColor: Colors.orange.shade700, valueText: 'Gula Darah: $value mg/dL', statusText: status, statusColor: color,);
                case 'UA': final double value = (readingData['UricAcidValue'] as num?)?.toDouble() ?? 0.0; final status = _getUricAcidCategory(value, gender); final color = _getUricAcidColor(status); return _buildHistoryItem( date: dateStr, icon: Icons.science_outlined, iconColor: Colors.purple.shade400, valueText: 'Asam Urat: ${value.toStringAsFixed(1)} mg/dL', statusText: status, statusColor: color,);
                case 'CHOL': final int value = (readingData['CholesterolValue'] as num?)?.toInt() ?? 0; final status = _getCholesterolCategory(value); final color = _getCholesterolColor(status); return _buildHistoryItem( date: dateStr, icon: Icons.opacity_outlined, iconColor: Colors.blueGrey.shade400, valueText: 'Kolesterol: $value mg/dL', statusText: status, statusColor: color,);
                case 'WAIST': final double value = (readingData['WaistCircumferenceValue'] as num?)?.toDouble() ?? 0.0; final status = _getWaistCategory(value, gender); final color = _getWaistColor(status); return _buildHistoryItem( date: dateStr, icon: Icons.square_foot_outlined, iconColor: Colors.teal.shade400, valueText: 'L. Perut: ${value.toStringAsFixed(1)} cm', statusText: status, statusColor: color,);
                default: return const SizedBox.shrink();
              }
            },
          ),
      ],
    );
  }

  /// Builds a single history item Card widget. (Unchanged)
  Widget _buildHistoryItem({required String date, required IconData icon, required Color iconColor, required String valueText, required String statusText, required Color statusColor}) {
      return Card( elevation: 1.5, margin: const EdgeInsets.only(bottom: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding( padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column( crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(date, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: Colors.grey[700])), const Divider(height: 16, thickness: 0.5),
            Row( children: [ Icon(icon, color: iconColor, size: 28), const SizedBox(width: 16),
                Expanded(child: Text(valueText, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 15))),
                if (statusText != 'N/A') Chip( label: Text( statusText, style: const TextStyle( color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)), backgroundColor: statusColor, padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, visualDensity: VisualDensity.compact, ) else const SizedBox.shrink(),
              ], ), ],
        ),
      ),
    );
   }


  // --- Normal Ranges Table Widgets (Unchanged) ---
  Widget _buildNormalRangesTable(BuildContext context) {
      return Card( margin: const EdgeInsets.only(bottom: 16.0), color: Theme.of(context).scaffoldBackgroundColor, elevation: 0, shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300) ),
      child: Padding( padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column( crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text( 'Nilai Normal Referensi', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium?.copyWith( fontWeight: FontWeight.bold, color: Theme.of(context).primaryColorDark,), ),
            const Divider(height: 16, thickness: 0.5),
            _buildNormalRangeRow(context, 'Asam Urat', 'Pria: 2,5–7,0 mg/dL\nWanita: 1,5–6,0 mg/dL'),
            _buildNormalRangeRow(context, 'Kolesterol', '< 200 mg/dL (Total)'),
            _buildNormalRangeRow(context, 'Gula Darah', 'Sewaktu: < 200 mg/dL'),
            _buildNormalRangeRow(context, 'Tekanan Darah', 'Optimal: < 120/80 mmHg'),
            _buildNormalRangeRow(context, 'Lingkar Perut', 'Pria: Max 101,6 cm\nWanita: Max 88,9 cm'), ],
        ),
      ),
    );
  }
  Widget _buildNormalRangeRow(BuildContext context, String label, String value) {
     return Padding( padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row( crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox( width: 110, child: Text( label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: Colors.black87), ), ),
          const SizedBox(width: 10),
          Expanded( child: Text( value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54), ), ), ],
      ),
    );
  }

} // End _PatientHistoryDetailScreenState