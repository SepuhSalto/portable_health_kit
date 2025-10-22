import 'package:flutter/material.dart';
import 'package:portable_health_kit/main_navigation_screen.dart';
import 'package:portable_health_kit/services/user_session_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _logInHealthWorker();
  }

  Future<void> _logInHealthWorker() async {
    // This assumes the app is only for the health worker
    // and they don't need to log in or register.
    
    // We set a single, hard-coded ID for the entire "kiosk"
    UserSessionService().setCurrentUserId("clinic_bali_sehat_01");

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      // Always go directly to the main app
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (build method is unchanged) ...
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite, color: Colors.white, size: 80),
            SizedBox(height: 20),
            Text(
              'Bali-Sehat',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
