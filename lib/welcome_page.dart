import 'package:concierge/auth/login_page.dart';
import 'package:flutter/material.dart';

import 'auth/signup_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF5C6BC0), Color(0xFF2A3990)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),

            // App Icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.2),
              ),
              child: const Icon(
                Icons.hotel, // Concierge/hotel-related icon
                size: 80,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 30),

            // Welcome Text
            const Text(
              'Welcome to Luxe Concierge',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 30),
              child: Text(
                'Your personal concierge service for a seamless hotel experience.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Get Started Button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () {
                // Navigate to next screen
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoginPage(onSignUpPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => SignUpPage(
                            onLoginPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ),
                      );
                    }),
                  ),
                );
              },
              icon: const Icon(Icons.arrow_forward, color: Color(0xFF2A3990)),
              label: const Text(
                'Get Started',
                style: TextStyle(
                  color: Color(0xFF2A3990),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Spacer(),

            // Bottom Text
            const Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: Text(
                'Experience Luxury, Redefined',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
