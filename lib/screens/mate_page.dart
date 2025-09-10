import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class MateScreen extends StatefulWidget {
  final UserModel currentUser;
  const MateScreen({super.key, required this.currentUser});

  @override
  State<MateScreen> createState() => _MateScreenState();
}

class _MateScreenState extends State<MateScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<UserModel> users = [];
  int currentIndex = 0;
  bool _isSwiping = false;
  bool _showHeart = false;
  bool _showCross = false;
  bool _isLoading = true; // ADDED: Loading state
  
  // Add these two lists to track swiped users
  List<String> _swipedRightUsers = []; // Users you liked
  List<String> _swipedLeftUsers = [];  // Users you passed on

  @override
  void initState() {
    super.initState();
    _loadSwipedUsers().then((_) => _loadUsers());
  }

  // FIXED: Load already swiped users from Firestore
  Future<void> _loadSwipedUsers() async {
    try {
      // Load all swipes (both right and left)
      final swipesSnapshot = await _firestore
          .collection('users')
          .doc(widget.currentUser.uid)
          .collection('swipes')
          .get();

      // Clear previous lists
      _swipedRightUsers.clear();
      _swipedLeftUsers.clear();
      
      for (var doc in swipesSnapshot.docs) {
        final data = doc.data();
        if (data['type'] == 'right') {
          _swipedRightUsers.add(doc.id);
        } else if (data['type'] == 'left') {
          _swipedLeftUsers.add(doc.id);
        }
      }
    } catch (e) {
      print("Error loading swiped users: $e");
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
          // NEW: Filter out already swiped users
          .where((user) => !_swipedRightUsers.contains(user.uid))
          .where((user) => !_swipedLeftUsers.contains(user.uid))
          .toList();

      setState(() {
        users = allUsers;
        _isLoading = false; // ADDED: Set loading to false
      });
    } catch (e) {
      print("Error loading users: $e");
      setState(() => _isLoading = false); // ADDED: Set loading to false even on error
    }
  }

  bool _isPotentialMatch(UserModel user) {
    final currentUserLookingFor = widget.currentUser.lookingFor.toLowerCase();
    final userGender = user.gender.toLowerCase();
    
    return currentUserLookingFor == 'everyone' || 
           currentUserLookingFor.contains(userGender);
  }

  // Store swipe action in Firestore
  Future<void> _storeSwipe(String userId, String swipeType) async {
    try {
      await _firestore
          .collection('users')
          .doc(widget.currentUser.uid)
          .collection('swipes')
          .doc(userId)
          .set({
            'type': swipeType, // 'right' or 'left'
            'timestamp': DateTime.now(),
          });
    } catch (e) {
      print("Error storing swipe: $e");
    }
  }

  Future<void> _onSwipeRight(UserModel user) async {
    if (_isSwiping) return;
    _isSwiping = true;

    // Store the swipe action
    await _storeSwipe(user.uid, 'right');
    
    // Add to local list to prevent showing again
    _swipedRightUsers.add(user.uid);

    // Show heart animation
    setState(() => _showHeart = true);

    try {
      // Create a match
      await _firestore
          .collection('matches')
          .doc(widget.currentUser.uid)
          .collection('matchedUsers')
          .doc(user.uid)
          .set({
            'uid': user.uid,
            'timestamp': DateTime.now(),
            'name': user.name,
            'profilePic': user.profilePics.isNotEmpty ? user.profilePics[0] : '',
          });

      // Send hello message to the matched user
      await _firestore
          .collection('chats')
          .doc(_getChatId(widget.currentUser.uid, user.uid))
          .collection('messages')
          .add({
            'senderId': widget.currentUser.uid,
            'text': 'Hello! 👋',
            'timestamp': DateTime.now(),
            'type': 'text',
          });

      // Create chat document if it doesn't exist
      await _firestore
          .collection('chats')
          .doc(_getChatId(widget.currentUser.uid, user.uid))
          .set({
            'users': [widget.currentUser.uid, user.uid],
            'lastMessage': 'Hello! 👋',
            'lastMessageTime': DateTime.now(),
          });

      // Hide heart and move to next profile after delay
      Future.delayed(const Duration(milliseconds: 800), () {
        setState(() {
          _showHeart = false;
          currentIndex++;
          _isSwiping = false;
        });
      });

    } catch (e) {
      print("Error creating match: $e");
      setState(() {
        _showHeart = false;
        _isSwiping = false;
      });
    }
  }

  void _onSwipeLeft(UserModel user) async {
    if (_isSwiping) return;
    _isSwiping = true;

    // Store the swipe action
    await _storeSwipe(user.uid, 'left');
    
    // Add to local list to prevent showing again
    _swipedLeftUsers.add(user.uid);
    
    // Show cross animation
    setState(() => _showCross = true);
    
    // Hide cross and move to next profile after delay
    Future.delayed(const Duration(milliseconds: 800), () {
      setState(() {
        _showCross = false;
        currentIndex++;
        _isSwiping = false;
      });
    });
  }

  String _getChatId(String uid1, String uid2) {
    List<String> ids = [uid1, uid2];
    ids.sort();
    return '${ids[0]}_${ids[1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7B1E3C),
      appBar: AppBar(
        title: const Text('Find Mates'),
        backgroundColor: const Color(0xFF7B1E3C),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          if (_isLoading) // CHANGED: Use _isLoading instead of users.isEmpty
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          else if (users.isEmpty) // CHANGED: Check if users list is empty after loading
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "No more profiles to view",
                    style: TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      setState(() => _isLoading = true); // ADDED: Show loading
                      // Reload both swipes and users
                      _loadSwipedUsers().then((_) => _loadUsers());
                      setState(() => currentIndex = 0);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF26A6A),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Load More Profiles'),
                  ),
                ],
              ),
            )
          else if (currentIndex >= users.length)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "No more profiles to view",
                    style: TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      setState(() => _isLoading = true); // ADDED: Show loading
                      // Reload both swipes and users
                      _loadSwipedUsers().then((_) => _loadUsers());
                      setState(() => currentIndex = 0);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF26A6A),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Load More Profiles'),
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                // Single Profile Card
                Expanded(
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      // Detect swipe direction
                      if (details.delta.dx > 10) {
                        // Right swipe - Match
                        _onSwipeRight(users[currentIndex]);
                      } else if (details.delta.dx < -10) {
                        // Left swipe - Skip
                        _onSwipeLeft(users[currentIndex]);
                      }
                    },
                    child: _buildProfileCard(users[currentIndex]),
                  ),
                ),
                
                // Action Buttons - Positioned on maroon background
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
                  color: Colors.transparent,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Skip Button (X)
                      GestureDetector(
                        onTap: () => _onSwipeLeft(users[currentIndex]),
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                      
                      // Match Button (Heart)
                      GestureDetector(
                        onTap: () => _onSwipeRight(users[currentIndex]),
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.favorite,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          
          // Heart Animation Overlay
          if (_showHeart)
            IgnorePointer(
              child: Container(
                color: Colors.black.withOpacity(0.4),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.favorite,
                        color: Colors.green,
                        size: 100,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Sent hello to ${users[currentIndex].name}! 👋',
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          
          // Cross Animation Overlay
          if (_showCross)
            IgnorePointer(
              child: Container(
                color: Colors.black.withOpacity(0.4),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.close,
                        color: Colors.red,
                        size: 100,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Skipped ${users[currentIndex].name}',
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(UserModel user) {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: const Color(0xFFFDD8DB),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Profile Image
              Container(
                height: 400,
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