import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'main_screen.dart'; // Import MainScreen instead
import '../models/user_model.dart'; // Import your UserModel

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          // Create a temporary UserModel (you'll need to fetch full user data later)
          final tempUser = UserModel(
            uid: snapshot.data!.uid,
            name: 'Loading...', // Placeholder
            gender: '',
            lookingFor: '',
            age: 0,
            city: '',
            bio: '',
            interests: [],
            profilePics: [],
            averageRating: 0.0,
            occupation: '',
            education: '',
            height: 0,
            relationshipGoals: '',
          );
          
          // Return MainScreen instead of RateScreen
          return MainScreen(currentUser: tempUser);
        }

        return const LoginScreen();
      },
    );
  }
}