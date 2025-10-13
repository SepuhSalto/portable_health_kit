import 'package:flutter/material.dart';
import 'package:portable_health_kit/main_navigation_screen.dart';
import 'package:portable_health_kit/services/user_session_service.dart';
import 'package:portable_health_kit/welcome_screen.dart'; // Import the new welcome screen
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkUserStatus();
  }

  Future<void> _checkUserStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      if (userId != null && userId.isNotEmpty) {
        // User is already registered, go to the main dashboard
        UserSessionService().setCurrentUserId(userId);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        );
      } else {
        // THIS IS THE CHANGE: Go to the Welcome Screen for new users
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
