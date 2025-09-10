import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart'; // ADD THIS IMPORT
import 'screens/auth_wrapper.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'models/user_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RateMate',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        // Apply Poppins font to entire app
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
        appBarTheme: AppBarTheme(
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 20.0,
            fontWeight: FontWeight.w600, // Semi-bold
            color: Colors.white,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            textStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          labelStyle: GoogleFonts.poppins(),
          hintStyle: GoogleFonts.poppins(),
        ),
      ),
      home: FutureBuilder(
        future: _initializeFirebase(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen();
          }
          return const AuthWrapper();
        },
      ),
    );
  }

  Future<bool> _initializeFirebase() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }
}

// Simple splash screen
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7B1E3C),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            const SizedBox(height: 20),
            Text(
              'RateMate',
              style: GoogleFonts.poppins( // Applied Poppins font
                fontSize: 32,
                fontWeight: FontWeight.w700, // Bold
                color: Colors.white,
                shadows: [
                  Shadow(
                    blurRadius: 10.0,
                    color: Colors.black.withOpacity(0.3),
                    offset: const Offset(2.0, 2.0),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// Updated AuthWrapper to properly handle user data
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        if (authSnapshot.hasData && authSnapshot.data != null) {
          // User is logged in, fetch their complete profile
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(authSnapshot.data!.uid)
                .get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const SplashScreen();
              }

              if (userSnapshot.hasError) {
                print("Error fetching user data: ${userSnapshot.error}");
                return const LoginScreen(); // Fallback to login if error
              }

              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                
                // Create UserModel with all required fields
                final currentUser = UserModel(
                  uid: authSnapshot.data!.uid,
                  name: userData['name'] ?? 'User',
                  gender: userData['gender'] ?? '',
                  lookingFor: userData['lookingFor'] ?? 'Everyone',
                  age: userData['age'] ?? 0,
                  city: userData['city'] ?? '',
                  bio: userData['bio'] ?? '',
                  interests: List<String>.from(userData['interests'] ?? []),
                  profilePics: List<String>.from(userData['profilePics'] ?? []),
                  averageRating: (userData['averageRating'] ?? 0).toDouble(),
                  occupation: userData['occupation'] ?? '',
                  education: userData['education'] ?? '',
                  height: userData['height'] ?? 0,
                  relationshipGoals: userData['relationshipGoals'] ?? 'Not specified',
                );

                return MainScreen(currentUser: currentUser);
              }

              // User document doesn't exist in Firestore
              return const LoginScreen();
            },
          );
        }

        // User is not logged in
        return const LoginScreen();
      },
    );
  }
}