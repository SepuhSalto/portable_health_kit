import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:portable_health_kit/services/firestore_service.dart';

// NEW: Enum to manage the time filter state
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
  final FirestoreService _firestoreService = FirestoreService();

  // State for graph toggles (unchanged)
  bool _showSystolic = true;
  bool _showDiastolic = true;
  bool _showBloodSugar = true;

  // NEW: State for time filter
  TimeFilter _selectedFilter = TimeFilter.all;

  // --- Category Helper Functions (Unchanged) ---
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
  // --- End Helper Functions ---

  // NEW: Helper to get the start date for the filter
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
        return null;
    }
  }
  
  // NEW: Helper to format the bottom (X-axis) titles
  Widget _bottomTitleWidgets(double value, TitleMeta meta) {
    // value is millisecondsSinceEpoch
    final DateTime date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
    String text;
    
    // Show time for 24-hour view, show date for others
    if (_selectedFilter == TimeFilter.day) {
      text = DateFormat('HH:mm').format(date);
    } else {
      text = DateFormat('d/M').format(date);
    }

    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 8.0,
      child: Text(text, style: const TextStyle(color: Color(0xff67727d), fontWeight: FontWeight.bold, fontSize: 10)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.patientName),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService
            .getPatientHealthReadingsStream(widget.patientId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Tidak ada riwayat pemeriksaan.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          final readings = snapshot.data!.docs;

          // --- NEW: Filter readings based on _selectedFilter ---
          final DateTime? startDate = _getStartDate(_selectedFilter);
          final filteredReadings = readings.where((doc) {
            if (startDate == null) return true; // 'All'
            final timestamp = (doc.data() as Map<String, dynamic>)['Timestamp'] as Timestamp;
            return timestamp.toDate().isAfter(startDate);
          }).toList();

          if (filteredReadings.isEmpty) {
             return const Center(
              child: Text(
                'Tidak ada data dalam rentang waktu ini.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }
          
          // --- Data Processing for Charts and Lists ---
          final List<FlSpot> systolicSpots = [];
          final List<FlSpot> diastolicSpots = [];
          final List<FlSpot> bloodSugarSpots = [];
          final List<DocumentSnapshot> bpReadings = [];
          final List<DocumentSnapshot> bsReadings = [];

          // Get min/max timestamps for the chart's X-axis
          final double minX = (filteredReadings.last.data() as Map<String, dynamic>)['Timestamp'].millisecondsSinceEpoch.toDouble();
          final double maxX = (filteredReadings.first.data() as Map<String, dynamic>)['Timestamp'].millisecondsSinceEpoch.toDouble();

          for (int i = 0; i < filteredReadings.length; i++) {
            final readingDoc = filteredReadings[i];
            final reading = readingDoc.data() as Map<String, dynamic>;
            final timestamp = (reading['Timestamp'] as Timestamp);
            
            // THE FIX: Use the timestamp for the X value
            final double xValue = timestamp.millisecondsSinceEpoch.toDouble();

            if (reading['SystolicValue'] != null) {
              systolicSpots.add(FlSpot(
                  xValue, (reading['SystolicValue'] as int).toDouble()));
              diastolicSpots.add(FlSpot(
                  xValue, (reading['DiastolicValue'] as int).toDouble()));
              bpReadings.add(readingDoc); // Add the original doc
            }
            if (reading['BloodSugarValue'] != null) {
              bloodSugarSpots.add(FlSpot(
                  xValue, (reading['BloodSugarValue'] as int).toDouble()));
              bsReadings.add(readingDoc); // Add the original doc
            }
          }

          // Note: No need to reverse. The spots are already in timestamp order.

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Combined Chart ---
                _buildChartCard(
                  context,
                  title: 'Grafik Kesehatan',
                  chart: _buildCombinedChart(
                    context, 
                    systolicSpots,
                    diastolicSpots, 
                    bloodSugarSpots,
                    minX,
                    maxX
                  ),
                ),
                
                // --- NEW: Time Filter Chips ---
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Wrap(
                    spacing: 8.0,
                    children: [
                      ChoiceChip(
                        label: const Text('24 Jam'),
                        selected: _selectedFilter == TimeFilter.day,
                        onSelected: (bool selected) {
                          setState(() { _selectedFilter = TimeFilter.day; });
                        },
                      ),
                      ChoiceChip(
                        label: const Text('7 Hari'),
                        selected: _selectedFilter == TimeFilter.week,
                        onSelected: (bool selected) {
                          setState(() { _selectedFilter = TimeFilter.week; });
                        },
                      ),
                      ChoiceChip(
                        label: const Text('30 Hari'),
                        selected: _selectedFilter == TimeFilter.month,
                        onSelected: (bool selected) {
                          setState(() { _selectedFilter = TimeFilter.month; });
                        },
                      ),
                       ChoiceChip(
                        label: const Text('Semua'),
                        selected: _selectedFilter == TimeFilter.all,
                        onSelected: (bool selected) {
                          setState(() { _selectedFilter = TimeFilter.all; });
                        },
                      ),
                    ],
                  ),
                ),

                // --- NEW: Data Type Filter Chips ---
                Wrap(
                  spacing: 8.0,
                  children: [
                    FilterChip(
                      label: const Text('Sistolik'),
                      selected: _showSystolic,
                      onSelected: (bool value) {
                        setState(() { _showSystolic = value; });
                      },
                      selectedColor: Colors.blue[100],
                      checkmarkColor: Colors.blue[800],
                    ),
                    FilterChip(
                      label: const Text('Diastolik'),
                      selected: _showDiastolic,
                      onSelected: (bool value) {
                        setState(() { _showDiastolic = value; });
                      },
                      selectedColor: Colors.red[100],
                      checkmarkColor: Colors.red[800],
                    ),
                    FilterChip(
                      label: const Text('Gula Darah'),
                      selected: _showBloodSugar,
                      onSelected: (bool value) {
                        setState(() { _showBloodSugar = value; });
                      },
                      selectedColor: Colors.green[100],
                      checkmarkColor: Colors.green[800],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // --- Separate History Lists ---
                _buildHistorySection(
                  context,
                  title: 'Riwayat Tekanan Darah',
                  readings: bpReadings, // This list is now correctly filtered
                  isBloodPressure: true,
                ),
                const SizedBox(height: 24),
                _buildHistorySection(
                  context,
                  title: 'Riwayat Gula Darah',
                  readings: bsReadings, // This list is now correctly filtered
                  isBloodPressure: false,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- Combined Chart Widget (MODIFIED) ---
  Widget _buildCombinedChart(
    BuildContext context,
    List<FlSpot> systolicSpots,
    List<FlSpot> diastolicSpots,
    List<FlSpot> bloodSugarSpots,
    double minX, // NEW
    double maxX, // NEW
  ) {
    // Calculate a dynamic interval for the X-axis labels (e.g., show 4 labels)
    final double timeRange = maxX - minX;
    final double xInterval = timeRange > 0 ? timeRange / 4 : 1;
    
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          getDrawingHorizontalLine: (value) =>
              const FlLine(color: Colors.black12, strokeWidth: 1),
          getDrawingVerticalLine: (value) =>
              const FlLine(color: Colors.black12, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          // NEW: Configure Bottom (X-axis) Titles
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32, // Space for the labels
              interval: xInterval, // Set the dynamic interval
              getTitlesWidget: _bottomTitleWidgets, // Use our formatting function
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 50,
              getTitlesWidget: _leftTitleWidgets,
              reservedSize: 42,
            ),
          ),
        ),
        borderData: FlBorderData(
            show: true, border: Border.all(color: const Color(0xffe7e7e7))),
        // NEW: Set min/max X and Y values
        minX: minX,
        maxX: maxX,
        minY: 40,
        maxY: 250,
        lineBarsData: [
          // Conditionally add lines based on state (unchanged)
          if (_showSystolic && systolicSpots.isNotEmpty)
            _lineBarData(systolicSpots, Colors.blue),
          if (_showDiastolic && diastolicSpots.isNotEmpty)
            _lineBarData(diastolicSpots, Colors.red),
          if (_showBloodSugar && bloodSugarSpots.isNotEmpty)
            _lineBarData(bloodSugarSpots, Theme.of(context).primaryColor),
        ],
      ),
    );
  }
  
  // --- History List Widgets (Unchanged) ---
  Widget _buildHistorySection(BuildContext context,
      {required String title,
      required List<DocumentSnapshot> readings,
      required bool isBloodPressure}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800]),
        ),
        const SizedBox(height: 12),
        if (readings.isEmpty)
          const Card(
              child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Tidak ada data.')))
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: readings.length,
            itemBuilder: (context, index) {
              final readingData = readings[index].data() as Map<String, dynamic>;
              final timestamp = (readingData['Timestamp'] as Timestamp).toDate();

              if (isBloodPressure) {
                final int systolic = readingData['SystolicValue'];
                final int diastolic = readingData['DiastolicValue'];
                final bpStatus = _getBloodPressureCategory(systolic, diastolic);
                final bpColor = _getBloodPressureColor(bpStatus);
                return _buildHistoryItem(
                  date: DateFormat('d MMM, HH:mm', 'id_ID').format(timestamp),
                  icon: Icons.monitor_heart,
                  iconColor: Colors.red,
                  valueText: 'TD: $systolic/$diastolic mmHg',
                  statusText: bpStatus,
                  statusColor: bpColor,
                );
              } else {
                final int bloodSugar = readingData['BloodSugarValue'];
                final bsStatus = _getBloodSugarCategory(bloodSugar);
                final bsColor = _getBloodSugarColor(bsStatus);
                return _buildHistoryItem(
                  date: DateFormat('d MMM, HH:mm', 'id_ID').format(timestamp),
                  icon: Icons.bloodtype,
                  iconColor: Colors.orange,
                  valueText: 'GD: $bloodSugar mg/dL',
                  statusText: bsStatus,
                  statusColor: bsColor,
                );
              }
            },
          ),
      ],
    );
  }

  Widget _buildHistoryItem(
      {required String date,
      required IconData icon,
      required Color iconColor,
      required String valueText,
      required String statusText,
      required Color statusColor}) {
    // ... (Unchanged) ...
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(date,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Divider(height: 20),
            Row(
              children: [
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 8),
                Text(valueText, style: const TextStyle(fontSize: 14)),
                const Spacer(),
                Text(statusText,
                    style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- Chart Helper Widgets ---
  Widget _leftTitleWidgets(double value, TitleMeta meta) {
    // ... (Unchanged) ...
    const style =
        TextStyle(color: Color(0xff67727d), fontWeight: FontWeight.bold, fontSize: 12);
    return Text(value.toInt().toString(),
        style: style, textAlign: TextAlign.left);
  }

  LineChartBarData _lineBarData(List<FlSpot> spots, Color color) {
    // ... (Unchanged) ...
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 4,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(colors: [
            color.withOpacity(0.3),
            color.withOpacity(0.0)
          ], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
    );
  }

  Widget _buildChartCard(BuildContext context,
      {required String title, required Widget chart}) {
    // ... (Unchanged) ...
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            SizedBox(height: 150, child: chart),
          ],
        ),
      ),
    );
  }
}