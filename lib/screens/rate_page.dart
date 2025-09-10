import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class RateScreen extends StatefulWidget {
  final UserModel currentUser;
  const RateScreen({super.key, required this.currentUser});

  @override
  State<RateScreen> createState() => _RateScreenState();
}

class _RateScreenState extends State<RateScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<UserModel> users = [];
  int currentIndex = 0;
  double ratingValue = 5.0;
  bool _showRatingFlash = false;
  double _lastRatingValue = 0;
  bool _isLoading = true;
  List<String> _ratedUserIds = [];

  @override
  void initState() {
    super.initState();
    _loadRatedUsers();
  }

  // Load users that the current user has already rated
  Future<void> _loadRatedUsers() async {
    try {
      final ratedSnapshot = await _firestore
          .collection('ratings')
          .where('raterId', isEqualTo: widget.currentUser.uid)
          .get();

      setState(() {
        _ratedUserIds = ratedSnapshot.docs.map((doc) => doc['ratedUserId'] as String).toList();
      });
      
      _loadUsers();
    } catch (e) {
      print("Error loading rated users: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      final allUsers = snapshot.docs
          .map((doc) {
            final data = doc.data();
            return UserModel(
              uid: doc.id,
              name: data['name'] ?? '',
              gender: data['gender'] ?? '',
              lookingFor: data['lookingFor'] ?? 'Everyone',
              age: data['age'] ?? 0,
              city: data['city'] ?? '',
              bio: data['bio'] ?? '',
              interests: List<String>.from(data['interests'] ?? []),
              profilePics: List<String>.from(data['profilePics'] ?? []),
              averageRating: (data['averageRating'] ?? 0).toDouble(),
              occupation: data['occupation'] ?? '',
              education: data['education'] ?? '',
              height: data['height'] ?? 0,
              relationshipGoals: data['relationshipGoals'] ?? 'Not specified',
            );
          })
          .where((user) => user.uid != widget.currentUser.uid)
          .where(_isPotentialMatch)
          // Filter out already rated users
          .where((user) => !_ratedUserIds.contains(user.uid))
          .toList();

      setState(() {
        users = allUsers;
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading users: $e");
      setState(() => _isLoading = false);
    }
  }

  bool _isPotentialMatch(UserModel user) {
    final currentUserLookingFor = widget.currentUser.lookingFor.toLowerCase();
    final userGender = user.gender.toLowerCase();
    
    return currentUserLookingFor == 'everyone' || 
           currentUserLookingFor.contains(userGender);
  }

  Future<void> _submitRating(UserModel ratedUser, double rating) async {
    try {
      // Save rating to Firestore with the new structure
      await _firestore.collection('ratings').add({
        'raterId': widget.currentUser.uid,
        'ratedUserId': ratedUser.uid,
        'rating': rating,
        'timestamp': DateTime.now(),
      });

      // Update the rated user's average rating
      final ratingsSnapshot = await _firestore
          .collection('ratings')
          .where('ratedUserId', isEqualTo: ratedUser.uid)
          .get();

      double total = 0;
      int count = 0;
      
      for (var doc in ratingsSnapshot.docs) {
        total += doc['rating'];
        count++;
      }
      
      double newAverage = count > 0 ? total / count : 0;
      
      await _firestore
          .collection('users')
          .doc(ratedUser.uid)
          .update({'averageRating': newAverage});

      // Add to local list to prevent showing again
      setState(() {
        _ratedUserIds.add(ratedUser.uid);
        _showRatingFlash = true;
        _lastRatingValue = rating;
      });

      // Hide the flash after 1 second and move to next profile
      Future.delayed(const Duration(milliseconds: 800), () {
        setState(() {
          _showRatingFlash = false;
          currentIndex++;
          ratingValue = 5.0;
        });
      });

    } catch (e) {
      print("Error submitting rating: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show rating flash if active
    if (_showRatingFlash) {
      return Scaffold(
        backgroundColor: const Color(0xFF7B1E3C),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _lastRatingValue.toStringAsFixed(0),
                style: const TextStyle(
                  fontSize: 200,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Rating Submitted!",
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF7B1E3C),
      appBar: AppBar(
        title: const Text('Rate Profiles'),
        backgroundColor: const Color(0xFF7B1E3C),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : users.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "No more profiles to rate",
                        style: TextStyle(
                          fontSize: 20, 
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isLoading = true;
                            currentIndex = 0;
                          });
                          _loadRatedUsers();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF26A6A),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Check for New Profiles'),
                      ),
                    ],
                  ),
                )
              : currentIndex >= users.length
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "No more profiles to rate",
                            style: TextStyle(
                              fontSize: 20, 
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _isLoading = true;
                                currentIndex = 0;
                              });
                              _loadRatedUsers();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF26A6A),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Check for New Profiles'),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        // Profile Card - Main Focus
                        Expanded(
                          child: _buildProfileCard(users[currentIndex]),
                        ),
                        
                        // Minimal Rating Section
                        Container(
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 15),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDD8DB),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Min value indicator
                              Text(
                                '1',
                                style: TextStyle(
                                  color: const Color(0xFF7B1E3C).withOpacity(0.7),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              
                              // Slider
                              Expanded(
                                child: Slider(
                                  value: ratingValue,
                                  min: 1,
                                  max: 10,
                                  divisions: 9,
                                  activeColor: const Color(0xFF7B1E3C),
                                  inactiveColor: const Color(0xFFF26A6A).withOpacity(0.5),
                                  thumbColor: const Color(0xFF7B1E3C),
                                  onChanged: (value) {
                                    setState(() {
                                      ratingValue = value;
                                    });
                                  },
                                  onChangeEnd: (value) {
                                    // Automatically submit rating when user stops sliding
                                    _submitRating(users[currentIndex], value);
                                  },
                                ),
                              ),
                              
                              // Max value indicator
                              Text(
                                '10',
                                style: TextStyle(
                                  color: const Color(0xFF7B1E3C).withOpacity(0.7),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildProfileCard(UserModel user) {
    return SingleChildScrollView(
      child: Container(
        margin: const EdgeInsets.all(16),
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          color: const Color(0xFFFDD8DB),
          child: Column(
            children: [
              // Profile Image
              Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  image: user.profilePics.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(user.profilePics[0]),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: user.profilePics.isEmpty
                    ? Center(
                        child: Icon(
                          Icons.person, 
                          size: 100, 
                          color: const Color(0xFF7B1E3C).withOpacity(0.7),
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              const Color(0xFF7B1E3C).withOpacity(0.8),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
              ),
              
              // Profile Details
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7B1E3C),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${user.age} • ${user.gender} • ${user.city}",
                      style: TextStyle(
                        fontSize: 16, 
                        color: const Color(0xFF7B1E3C).withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    if (user.height > 0) ...[
                      Text(
                        "Height: ${user.height} cm",
                        style: TextStyle(
                          fontSize: 16, 
                          color: const Color(0xFF7B1E3C).withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    
                    if (user.occupation.isNotEmpty) ...[
                      Text(
                        "Occupation: ${user.occupation}",
                        style: TextStyle(
                          fontSize: 16, 
                          color: const Color(0xFF7B1E3C).withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    
                    if (user.education.isNotEmpty) ...[
                      Text(
                        "Education: ${user.education}",
                        style: TextStyle(
                          fontSize: 16, 
                          color: const Color(0xFF7B1E3C).withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    
                    if (user.relationshipGoals.isNotEmpty && 
                        user.relationshipGoals != 'Not specified') ...[
                      Text(
                        "Looking for: ${user.relationshipGoals}",
                        style: TextStyle(
                          fontSize: 16, 
                          color: const Color(0xFF7B1E3C).withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    
                    const SizedBox(height: 8),
                    Text(
                      user.bio,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF7B1E3C),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Interests
                    Wrap(
                      spacing: 8,
                      children: user.interests
                          .map(
                            (interest) => Chip(
                              label: Text(
                                interest,
                                style: const TextStyle(
                                  color: Colors.white,
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
            ],
          ),
        ),
      ),
    );
  }
}