import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'mate_page.dart';
import 'chat_screen.dart';
import 'rate_page.dart';
import '../models/user_model.dart';

class MainScreen extends StatefulWidget {
  final UserModel currentUser;
  const MainScreen({super.key, required this.currentUser});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 3; // CHANGED FROM 0 TO 3 to start on Profile page

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      RateScreen(currentUser: widget.currentUser),
      MateScreen(currentUser: widget.currentUser),
      ChatScreen(currentUser: widget.currentUser),
      HomeScreen(currentUser: widget.currentUser), // This is your profile page
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFFFF6600), // Orange from your logo
        unselectedItemColor: Colors.grey[400],
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed, // Ensures all 4 tabs show
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.star),
            label: "Rate",
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.favorite),
            label: "Mates",
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.chat),
            label: "Chats",
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: "Profile",
          ),
        ],
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}