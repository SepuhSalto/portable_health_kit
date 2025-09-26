import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Kesehatan'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildChartCard(
              context,
              title: 'Grafik Tekanan Darah',
              chart: _buildBloodPressureChart(context),
            ),
            const SizedBox(height: 20),
            _buildChartCard(
              context,
              title: 'Grafik Gula Darah',
              chart: _buildBloodSugarChart(context),
            ),
            const SizedBox(height: 24),
            Text(
              'Detail Pemeriksaan',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[800]),
            ),
            const SizedBox(height: 12),
            _buildHistoryItem(
              context: context,
              date: '25 Sep, 22:30',
              bp: '120/80',
              bs: '95',
              bpStatus: 'Normal',
              bsStatus: 'Normal',
              bpColor: Colors.green,
              bsColor: Colors.green,
            ),
            _buildHistoryItem(
              context: context,
              date: '24 Sep, 21:15',
              bp: '135/85',
              bs: '150',
              bpStatus: 'Hipertensi Derajat 1',
              bsStatus: 'Pradiabetes',
              bpColor: Colors.orange,
              bsColor: Colors.orange,
            ),
            _buildHistoryItem(
              context: context,
              date: '23 Sep, 20:00',
              bp: '142/91',
              bs: '180',
              bpStatus: 'Hipertensi Derajat 2',
              bsStatus: 'Pradiabetes',
              bpColor: Colors.red,
              bsColor: Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard(BuildContext context, {required String title, required Widget chart}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            SizedBox(height: 150, child: chart),
          ],
        ),
      ),
    );
  }

  Widget _buildBloodPressureChart(BuildContext context) {
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          _lineBarData(const [FlSpot(0, 120), FlSpot(1, 125), FlSpot(2, 122), FlSpot(3, 130), FlSpot(4, 135)], Colors.blue),
          _lineBarData(const [FlSpot(0, 80), FlSpot(1, 82), FlSpot(2, 81), FlSpot(3, 85), FlSpot(4, 88)], Colors.red),
        ],
      ),
    );
  }

  Widget _buildBloodSugarChart(BuildContext context) {
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          _lineBarData(const [FlSpot(0, 95), FlSpot(1, 105), FlSpot(2, 110), FlSpot(3, 98), FlSpot(4, 150)], Theme.of(context).primaryColor)
        ],
      ),
    );
  }

  LineChartBarData _lineBarData(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 4,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [color.withOpacity(0.3), color.withOpacity(0.0)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
    );
  }

  Widget _buildHistoryItem({required BuildContext context, required String date, required String bp, required String bs, required String bpStatus, required String bsStatus, required Color bpColor, required Color bsColor}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(date, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Divider(height: 20),
            Row(
              children: [
                const Icon(Icons.monitor_heart, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Text('TD: $bp mmHg', style: const TextStyle(fontSize: 14)),
                const Spacer(),
                Text(bpStatus, style: TextStyle(color: bpColor, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.bloodtype, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Text('GD: $bs mg/dL', style: const TextStyle(fontSize: 14)),
                const Spacer(),
                Text(bsStatus, style: TextStyle(color: bsColor, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}