import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/profile_service.dart';
import 'create_profile_screen.dart';
import 'edit_profile_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  final UserModel currentUser;
  const HomeScreen({super.key, required this.currentUser});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProfileService _profileService = ProfileService();
  UserModel? userProfile;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final profile = await _profileService.getProfile(uid);
    if (profile == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => CreateProfileScreen(uid: uid)),
      );
      return;
    }

    setState(() {
      userProfile = profile;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF7B1E3C),
        body: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF7B1E3C), // wine/maroon
              Color(0xFFF26A6A), // coral
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: userProfile == null
            ? const Center(
                child: Text(
                  "No profile found",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              )
            : Column(
                children: [
                  // Header with profile name
                  Container(
                    padding: const EdgeInsets.only(top: 50, bottom: 20),
                    child: Text(
                      "My Profile",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
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
                  ),
                  
                  // Profile Card
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      child: Card(
                        color: const Color(0xFFFDD8DB), // soft pink background
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 12,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              // Profile Image
                              Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 70,
                                    backgroundColor: const Color(0xFF7B1E3C).withOpacity(0.2),
                                    backgroundImage: userProfile!.profilePics.isNotEmpty
                                        ? NetworkImage(userProfile!.profilePics[0])
                                        : null,
                                    child: userProfile!.profilePics.isEmpty
                                        ? const Icon(Icons.person,
                                            size: 70, color: Color(0xFF7B1E3C))
                                        : null,
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF7B1E3C),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: const Color(0xFFFDD8DB), width: 3),
                                      ),
                                      child: IconButton(
                                        icon: const Icon(Icons.edit, size: 20, color: Colors.white),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => EditProfileScreen(user: userProfile!),
                                            ),
                                          ).then((_) => _loadProfile());
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 25),
                              
                              // Name and Basic Info
                              Text(
                                userProfile!.name,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF7B1E3C),
                                ),
                              ),
                              
                              const SizedBox(height: 8),
                              
                              Text(
                                "${userProfile!.age} • ${userProfile!.gender} • ${userProfile!.city}",
                                style: const TextStyle(
                                  fontSize: 16, 
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              
                              const SizedBox(height: 20),
                              
                              // Bio Section
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "About Me",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF7B1E3C),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      userProfile!.bio.isNotEmpty ? userProfile!.bio : "No bio yet",
                                      style: const TextStyle(
                                        fontSize: 16, 
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 20),
                              
                              // Interests Section
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Interests",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF7B1E3C),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: userProfile!.interests
                                          .map(
                                            (interest) => Chip(
                                              label: Text(
                                                interest,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              backgroundColor: const Color(0xFFF26A6A),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 30),
                              
                              // Action Buttons
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  // Edit Profile Button
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => EditProfileScreen(user: userProfile!),
                                        ),
                                      ).then((_) => _loadProfile());
                                    },
                                    icon: const Icon(Icons.edit, color: Colors.white),
                                    label: const Text("Edit Profile"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF7B1E3C),
                                      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                    ),
                                  ),
                                  
                                  // Logout Button
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      await FirebaseAuth.instance.signOut();
                                      Navigator.pushReplacement(
                                        context, 
                                        MaterialPageRoute(builder: (_) => const LoginScreen())
                                      );
                                    },
                                    icon: const Icon(Icons.logout, color: Colors.white),
                                    label: const Text("Logout"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFF26A6A),
                                      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}