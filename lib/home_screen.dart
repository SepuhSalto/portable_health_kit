import 'package:flutter/material.dart';
import 'package:portable_health_kit/add_edit_alarm_screen.dart';

class HomeScreen extends StatelessWidget {
  // We add a Key here to ensure Flutter rebuilds this widget when the code changes.
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
            // --- Welcome Card (Unchanged) ---
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
                          Text(
                            'Selamat Datang!',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Aplikasi Bali-Sehat siap membantu Anda.',
                            style: TextStyle(fontSize: 14, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'Pembacaan Terakhir',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[800]),
            ),
            const SizedBox(height: 12),

            // --- Last Reading Card (Adjusted Sizes) ---
            Card(
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 50),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Jumat, 26 Sep 2025, 10:58 WITA',
                              style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                            Icon(Icons.check_circle, color: Theme.of(context).primaryColor),
                          ],
                        ),
                        const Divider(height: 24),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _HealthMetric(value: '120/80', unit: 'mmHg', label: 'Tekanan Darah'),
                            _HealthMetric(value: '95', unit: 'mg/dL', label: 'Gula Darah'),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 4.0, // Adjusted spacing
                          children: [
                            _buildStatusChip('Hipertensi Derajat 1', Colors.orange.shade700),
                            _buildStatusChip('Normal', Colors.green.shade700),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Positioned(
                    bottom: 10, // Adjusted position
                    right: 10,  // Adjusted position
                    child: ActionChip(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const AddEditAlarmScreen()));
                      },
                      avatar: Icon(Icons.add_alarm_outlined, size: 14, color: Theme.of(context).primaryColor), // Adjusted size
                      label: Text(
                        'Tambah Alarm',
                        style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 10), // Adjusted size
                      ),
                      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), // Adjusted padding
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.3)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildStatusChip(String label, Color color) {
    return Chip(
      label: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)), // Adjusted size
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0), // Adjusted padding
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
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
        Text(
          value,
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor), // Adjusted size
        ),
        Text(
          unit,
          style: const TextStyle(fontSize: 12, color: Colors.grey), // Adjusted size
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), // Adjusted size
        ),
      ],
    );
  }
}

