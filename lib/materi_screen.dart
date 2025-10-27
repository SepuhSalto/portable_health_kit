import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Import url_launcher

// Define a simple class to hold material info
class MateriItem {
  final String title;
  final String description;
  final String driveUrl;
  final IconData icon; // Icon to represent the type (PDF, video)

  MateriItem({
    required this.title,
    required this.description,
    required this.driveUrl,
    required this.icon,
  });
}

class MateriScreen extends StatefulWidget {
  const MateriScreen({super.key});

  @override
  State<MateriScreen> createState() => _MateriScreenState();
}

class _MateriScreenState extends State<MateriScreen> {
  // --- List of Your Materials ---
  // Replace these with your actual titles, descriptions, and Google Drive links
  final List<MateriItem> _materiList = [
    MateriItem(
      title: 'Panduan Diet Diabetes (PDF)',
      description: 'Informasi lengkap mengenai pengaturan makan untuk penderita diabetes.',
      driveUrl: 'YOUR_GOOGLE_DRIVE_PDF_LINK_1', // <-- PASTE YOUR PDF LINK HERE
      icon: Icons.picture_as_pdf_outlined, // PDF icon
    ),
    MateriItem(
      title: 'Senam Kaki Diabetes (Video)',
      description: 'Video tutorial langkah-langkah senam kaki yang baik untuk penderita diabetes.',
      driveUrl: 'YOUR_GOOGLE_DRIVE_VIDEO_LINK_1', // <-- PASTE YOUR VIDEO LINK HERE
      icon: Icons.video_library_outlined, // Video icon
    ),
    MateriItem(
      title: 'Manajemen Hipertensi (PDF)',
      description: 'Tips dan cara mengelola tekanan darah tinggi sehari-hari.',
      driveUrl: 'YOUR_GOOGLE_DRIVE_PDF_LINK_2', // <-- PASTE ANOTHER PDF LINK
      icon: Icons.picture_as_pdf_outlined,
    ),
    // Add more MateriItem objects for each PDF and video link you have
  ];

  /// Function to launch the URL
  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      // Try launching the URL. `launchUrl` handles opening browsers or apps.
      bool launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!launched) {
        print('Could not launch $urlString');
        _showErrorSnackbar('Tidak dapat membuka link: $urlString');
      }
    } catch (e) {
      print('Error launching URL $urlString: $e');
      _showErrorSnackbar('Terjadi kesalahan saat membuka link.');
    }
  }

  /// Helper to show error messages
  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Materi Edukasi'), // Updated title
        // Use theme colors
        automaticallyImplyLeading: false, // No back button on main tab
      ),
      body: ListView.builder(
        // Add padding around the list
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
        itemCount: _materiList.length, // Number of items in the list
        itemBuilder: (context, index) {
          final item = _materiList[index];
          // Build a Card for each material item
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0), // Spacing between cards
            elevation: 2,
            child: ListTile(
              // Leading icon based on material type
              leading: Icon(item.icon, color: Theme.of(context).primaryColor, size: 36),
              // Title of the material
              title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              // Description of the material
              subtitle: Text(item.description),
              // Trailing arrow to indicate tappable
              trailing: const Icon(Icons.chevron_right),
              // Action when the list tile is tapped
              onTap: () {
                print('Tapped on: ${item.title}, URL: ${item.driveUrl}');
                // Launch the Google Drive URL
                _launchURL(item.driveUrl);
              },
            ),
          );
        },
      ),
    );
  }
}