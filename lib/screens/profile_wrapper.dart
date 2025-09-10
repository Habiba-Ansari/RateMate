import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart'; // ← Make sure to import UserModel
import 'create_profile_screen.dart';
import 'home_screen.dart';

class ProfileWrapper extends StatelessWidget {
  const ProfileWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Not signed in")),
      );
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          // Profile does not exist → show CreateProfileScreen
          return CreateProfileScreen(uid: user.uid);
        }

        // Profile exists → create UserModel and show HomeScreen
        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final userModel = UserModel.fromMap(userData, user.uid);
        return HomeScreen(currentUser: userModel); // ← Remove 'const'
      },
    );
  }
}