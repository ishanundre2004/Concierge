import 'package:concierge/home_page.dart';
import 'package:concierge/profile_page.dart';
import 'package:concierge/welcome_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasData && snapshot.data != null) {
          // User is logged in, check if profile is complete
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(snapshot.data!.uid)
                .get(),
            builder: (context, profileSnapshot) {
              if (profileSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              } else if (profileSnapshot.hasData && profileSnapshot.data != null) {
                final userData = profileSnapshot.data!.data() as Map<String, dynamic>?;
                if (userData != null && userData['profilePicture'] != null && userData['profilePicture'].isNotEmpty) {
                  // Profile is complete, navigate to Home
                  return const HomePage();
                } else {
                  // Profile is incomplete, navigate to Profile Setup
                  return const ProfileSetupPage();
                }
              } else {
                // Profile data not found, navigate to Profile Setup
                return const ProfileSetupPage();
              }
            },
          );
        } else {
          // User is not logged in, navigate to Welcome Page
          return const WelcomePage();
        }
      },
    );
  }
}