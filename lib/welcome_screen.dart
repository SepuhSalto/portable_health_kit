import 'package:flutter/material.dart';
import 'package:portable_health_kit/personal_data_input_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // We use a Stack to layer the image, gradient, and content
      body: Stack(
        fit: StackFit.expand, // Make the stack fill the entire screen
        children: [
          // 1. The Background Image
          Image.asset(
            'assets/images/welcome_illustration.jpg',
            fit: BoxFit.cover, // Ensures the image covers the whole screen
          ),

          // 2. The White Gradient Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  Colors.white.withOpacity(0.8),
                  Colors.white.withOpacity(0.0), // Fades to transparent
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                stops: const [0.0, 0.4, 1.0], // Controls where the gradient starts and ends
              ),
            ),
          ),

          // 3. The Content (Text and Button)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end, // Align content to the bottom
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Selamat Datang di Bali-Sehat',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32, // Larger font size
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800], // Darker text for better contrast
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Asisten kesehatan dan budaya pribadi Anda, siap membantu memantau kondisi dan memberikan relaksasi.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                      height: 1.5, // Improved line spacing for readability
                    ),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => const PersonalDataInputScreen(isInitialSetup: true),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                       padding: const EdgeInsets.symmetric(vertical: 20), // Taller button
                    ),
                    child: const Text('Mulai Sekarang'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

