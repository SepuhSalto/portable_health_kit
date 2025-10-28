import 'package:flutter/material.dart';
import 'package:portable_health_kit/web_view_screen.dart'; // Import web_view_screen

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
      title: 'Hipertensi',
      description: 'Informasi lengkap mengenai hipertensi.',
      driveUrl: 'https://docs.google.com/presentation/d/1F_BL4lxS1ehaBkGADdYJL83ZV3votbEu/edit?usp=drive_link&ouid=116033809050488051387&rtpof=true&sd=true', // <-- PASTE YOUR PDF LINK HERE
      icon: Icons.slideshow_outlined, // PDF icon
    ),
    MateriItem(
      title: 'Diabetes Mellitus',
      description: 'Informasi lengkap mengenai diabetes mellitus.',
      driveUrl: 'https://docs.google.com/presentation/d/1V2hZ4sjp6vtiIEP4qvLwddFOHAp4xn-R/edit?usp=drive_link&ouid=116033809050488051387&rtpof=true&sd=true', // <-- PASTE YOUR PDF LINK HERE
      icon: Icons.slideshow_outlined, // PDF icon
    ),
    MateriItem(
      title: 'TERAPI KOMPLEMENTER UNTUK HIPERTENSI & DIABETES MELLITUS',
      description: 'Informasi lengkap mengenai terapi komplementer untuk hipertensi dan diabetes mellitus.',
      driveUrl: 'https://docs.google.com/presentation/d/1eJI86SxaCTu1nnJ3uzVSNSEgpPBT9vSX/edit?usp=drive_link&ouid=116033809050488051387&rtpof=true&sd=true', // <-- PASTE YOUR PDF LINK HERE
      icon: Icons.slideshow_outlined, // PDF icon
    ),
    MateriItem(
      title: 'Manuskrip Artikel PPDM',
      description: 'Pemberdayaan Potensi Kearifan Lokal Melalui Kelompok Agregat Masyarakat Desa Dalam Penanggulangan PTM',
      driveUrl: 'https://drive.google.com/file/d/1Wfw-YznH4AZNKeUu_a7TYV58lWKDOBfy/view?usp=drive_link', // <-- PASTE YOUR PDF LINK HERE
      icon: Icons.picture_as_pdf_outlined, // PDF icon
    ),
    MateriItem(
      title: 'MODUL PENYAKIT TIDAK MENULAR DAN TERAPI KOMPLEMENTER',
      description: 'PROGRAM PENGEMBANGAN DESA MITRA (PPDM) PEMBERDAYAAN POTENSI KEARIFAN LOKAL BALI MELALUI KELOMPOK AGREGAT MASYARAKAT DESA DALAM PENANGGULANGAN PENYAKIT TIDAK MENULAR DI DESA TIBUBENENG KECAMATAN KUTA UTARA',
      driveUrl: 'https://drive.google.com/file/d/12BsjCe9udLxLYw46AyRs5kb_rEnwNNa7/view?usp=drive_link', // <-- PASTE YOUR PDF LINK HERE
      icon: Icons.picture_as_pdf_outlined, // PDF icon
    ),
    MateriItem(
      title: 'CARA PEMBUATAN TERAPI HERBAL DENGAN SELEDRI',
      description: 'Video tutorial cara pembuatan terapi herbal dengan seledri.',
      driveUrl: 'https://drive.google.com/file/d/13yNk66fjK_cXRy5Qn5E0E0X6O5Kr0TOq/view?usp=drive_link', // <-- PASTE YOUR VIDEO LINK HERE
      icon: Icons.video_library_outlined, // Video icon
    ),
    MateriItem(
      title: 'Senam Kaki Diabetes (Video)',
      description: 'Video tutorial langkah-langkah senam kaki yang baik untuk penderita diabetes.',
      driveUrl: 'https://drive.google.com/file/d/1Flpc8nXQ588CAKU5t9hOC_aHpRRfbekP/view?usp=drive_link', // <-- PASTE YOUR VIDEO LINK HERE
      icon: Icons.video_library_outlined, // Video icon
    ),
    MateriItem(
      title: 'Teknik Akupresur',
      description: 'Video tutorial teknik akupresur ',
      driveUrl: 'https://drive.google.com/file/d/17DwcUKoHAvn9PuvAND2SY8Wz47pTCoRs/view?usp=drive_link', // <-- PASTE YOUR VIDEO LINK HERE
      icon: Icons.video_library_outlined, // Video icon
    ),
    MateriItem(
      title: 'Teknik Relaksasi Napas Dalam',
      description: 'Video tutorial teknik relaksasi napas dalam.',
      driveUrl: 'https://drive.google.com/file/d/1AwQlwXucR8kyqLJYVDIJBAEXA1cy45f4/view?usp=drive_link', // <-- PASTE YOUR VIDEO LINK HERE
      icon: Icons.video_library_outlined, // Video icon
    ),
    MateriItem(
      title: 'Terapi Musik Rindik Bali',
      description: 'Video Musik Rindik Bali',
      driveUrl: 'https://drive.google.com/file/d/17G2FVt1WqVdYc-LLRflse_jJPXnpLmXA/view?usp=drive_link', // <-- PASTE YOUR VIDEO LINK HERE
      icon: Icons.video_library_outlined, // Video icon
    ),
    // Add more MateriItem objects for each PDF and video link you have
  ];

  void _openInWebView(BuildContext context, MateriItem item) {
    print('Navigating to WebView for: ${item.title}, URL: ${item.driveUrl}');
    // Ensure URL is not empty before navigating
    if (item.driveUrl.isEmpty || !item.driveUrl.startsWith('http')) {
       _showErrorSnackbar('Link materi tidak valid.');
       return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WebViewScreen(
          title: item.title, // Pass title to AppBar
          url: item.driveUrl, // Pass URL to load
        ),
      ),
    );
  }

  // _showErrorSnackbar method remains the same
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
                _openInWebView(context, item);
              },
            ),
          );
        },
      ),
    );
  }
}