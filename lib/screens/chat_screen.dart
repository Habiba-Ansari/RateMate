import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class ChatScreen extends StatefulWidget {
  final UserModel currentUser;
  const ChatScreen({super.key, required this.currentUser});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<UserModel> _matchedUsers = [];
  UserModel? _selectedUser;
  Map<String, List<Map<String, dynamic>>> _messages = {};

  @override
  void initState() {
    super.initState();
    _loadMatchedUsers();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMatchedUsers() async {
    try {
      final snapshot = await _firestore
          .collection('matches')
          .doc(widget.currentUser.uid)
          .collection('matchedUsers')
          .get();

      final users = await Future.wait(
        snapshot.docs.map((doc) async {
          final userDoc = await _firestore
              .collection('users')
              .doc(doc['uid'])
              .get();
          
          if (!userDoc.exists) return null;
          
          final data = userDoc.data()!;
          return UserModel(
            uid: doc['uid'],
            name: data['name'] ?? 'Unknown',
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
        }),
      );

      setState(() => _matchedUsers = users.whereType<UserModel>().toList());
      if (_matchedUsers.isNotEmpty) {
        _selectUser(_matchedUsers.first);
      }
    } catch (e) {
      print("Error loading matched users: $e");
    }
  }

  void _selectUser(UserModel user) {
    setState(() => _selectedUser = user);
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _selectedUser == null) return;

    final message = _messageController.text.trim();
    _messageController.clear();

    final chatId = _getChatId(widget.currentUser.uid, _selectedUser!.uid);
    
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
            'senderId': widget.currentUser.uid,
            'text': message,
            'timestamp': DateTime.now(),
            'type': 'text',
          });

      // Update last message in chat document
      await _firestore
          .collection('chats')
          .doc(chatId)
          .set({
            'lastMessage': message,
            'lastMessageTime': DateTime.now(),
            'participants': [widget.currentUser.uid, _selectedUser!.uid],
          }, SetOptions(merge: true));

    } catch (e) {
      print("Error sending message: $e");
    }
  }

  String _getChatId(String uid1, String uid2) {
    List<String> ids = [uid1, uid2];
    ids.sort();
    return '${ids[0]}_${ids[1]}';
  }

  Widget _buildUserListItem(UserModel user, bool isSelected) {
    return Container(
      width: 70,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      constraints: const BoxConstraints(
        maxHeight: 80,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? const Color(0xFF7B1E3C) : Colors.transparent,
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 26,
              backgroundImage: user.profilePics.isNotEmpty
                  ? NetworkImage(user.profilePics[0])
                  : null,
              child: user.profilePics.isEmpty
                  ? const Icon(Icons.person, color: Colors.white, size: 24)
                  : null,
            ),
          ),
          const SizedBox(height: 6),
          Flexible(
            child: Text(
              user.name.split(' ')[0],
              style: TextStyle(
                color: isSelected ? const Color(0xFF7B1E3C) : const Color(0xFF555555),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isMe) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isMe ? const Color(0xFF7B1E3C) : const Color(0xFFF26A6A),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(4),
                bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
              ),
            ),
            child: Text(
              message['text'],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7B1E3C),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.only(top: 15, bottom: 15),
              decoration: BoxDecoration(
                color: const Color(0xFF7B1E3C),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Text(
                'Messages',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),

            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFFDD8DB),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    // User List
                    if (_matchedUsers.isNotEmpty)
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _matchedUsers.length,
                          itemBuilder: (context, index) {
                            final user = _matchedUsers[index];
                            final isSelected = _selectedUser?.uid == user.uid;
                            
                            return GestureDetector(
                              onTap: () => _selectUser(user),
                              child: _buildUserListItem(user, isSelected),
                            );
                          },
                        ),
                      ),

                    // Chat Messages
                    Expanded(
                      child: _selectedUser == null
                          ? Center(
                              child: Text(
                                _matchedUsers.isEmpty
                                    ? 'No matches yet'
                                    : 'Select a chat to start messaging',
                                style: const TextStyle(
                                  color: Color(0xFF7B1E3C),
                                  fontSize: 16,
                                ),
                              ),
                            )
                          : Container(
                              margin: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: StreamBuilder<QuerySnapshot>(
                                stream: _firestore
                                    .collection('chats')
                                    .doc(_getChatId(widget.currentUser.uid, _selectedUser!.uid))
                                    .collection('messages')
                                    .orderBy('timestamp', descending: false)
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) {
                                    return const Center(child: CircularProgressIndicator());
                                  }

                                  final messages = snapshot.data!.docs
                                      .map((doc) => doc.data() as Map<String, dynamic>)
                                      .toList();

                                  if (messages.isEmpty) {
                                    return Center(
                                      child: Text(
                                        'No messages yet. Start the conversation!',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 16,
                                        ),
                                      ),
                                    );
                                  }

                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    if (_scrollController.hasClients) {
                                      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                                    }
                                  });

                                  return ListView.builder(
                                    controller: _scrollController,
                                    padding: const EdgeInsets.all(16),
                                    itemCount: messages.length,
                                    itemBuilder: (context, index) {
                                      final message = messages[index];
                                      final isMe = message['senderId'] == widget.currentUser.uid;
                                      return _buildMessageBubble(message, isMe);
                                    },
                                  );
                                },
                              ),
                            ),
                    ),

                    // Message Input - CORRECTED: Reduced bottom padding since nav bar is removed
                    if (_selectedUser != null)
                      Container(
                        padding: const EdgeInsets.all(16), // Changed from EdgeInsets.fromLTRB(16, 16, 16, 70)
                        color: Colors.transparent,
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(25),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _messageController,
                                        decoration: const InputDecoration(
                                          hintText: 'Type a message...',
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                                        ),
                                        onSubmitted: (_) => _sendMessage(),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.send, color: Color(0xFF7B1E3C)),
                                      onPressed: _sendMessage,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}